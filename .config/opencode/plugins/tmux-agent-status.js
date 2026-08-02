// Marks the tmux pane running this opencode session busy/waiting/idle, reusing
// the shared ~/.tmux/agent-status.sh helper - the same per-pane indicator the
// tmux status bar renders for Claude Code. State is pane-scoped; the helper
// starts the spinner daemon on "busy" and clears the pane on "clear".
//
// Event mapping mirrors the herdr-agent-state.js plugin (the reference for
// opencode's event names), collapsed to three indicator states.
import { execFile, execFileSync } from "node:child_process";

const PANE = process.env.TMUX_PANE;
const IN_TMUX = Boolean(process.env.TMUX) && Boolean(PANE);
const SCRIPT = `${process.env.HOME}/.tmux/agent-status.sh`;

// Subagent (task tool) sessions carry a parentID; their lifecycle events would
// otherwise clobber the pane's real (root-agent) state, so we learn their ids
// and drop them - except a child waiting on the user must still surface.
const childSessions = new Set();
let lastState = null;

function setState(state) {
  if (!IN_TMUX || state === lastState) return;
  lastState = state;
  // Fire and forget; the script guards on $TMUX/$TMUX_PANE (inherited via env).
  execFile(SCRIPT, [state], { env: process.env }, () => {});
}

function clearSync() {
  if (!IN_TMUX) return;
  try {
    execFileSync(SCRIPT, ["clear"], { env: process.env });
  } catch {
    // best effort - nothing to do if tmux is already gone
  }
}

function sessionIDFromProperties(properties) {
  return typeof properties?.sessionID === "string" && properties.sessionID
    ? properties.sessionID
    : undefined;
}

export const TmuxAgentStatusPlugin = async () => {
  if (!IN_TMUX) return {};

  // Clear the indicator if opencode is killed mid-response, so the pane does
  // not keep a stuck spinner (the graceful path clears via session.idle).
  process.on("exit", clearSync);
  process.on("SIGINT", () => {
    clearSync();
    process.exit(0);
  });
  process.on("SIGTERM", () => {
    clearSync();
    process.exit(0);
  });

  return {
    "chat.message": async ({ sessionID }) => {
      if (sessionID && childSessions.has(sessionID)) return;
      setState("busy");
    },
    event: async ({ event }) => {
      const type = event?.type;
      const properties = event?.properties ?? {};
      const sessionID = sessionIDFromProperties(properties);

      const info = properties.info;
      if (info?.id && info.parentID) childSessions.add(info.id);

      if (sessionID && childSessions.has(sessionID)) {
        // Report a child's blocked/unblocked state without touching which
        // session owns the pane.
        switch (type) {
          case "permission.asked":
          case "question.asked":
            setState("waiting");
            break;
          case "permission.replied":
          case "question.replied":
          case "question.rejected":
            setState("busy");
            break;
          default:
            break;
        }
        return;
      }

      switch (type) {
        case "session.status": {
          // { type: "idle" | "busy" | ... }; older builds used a bare string.
          const kind =
            typeof properties.status === "string"
              ? properties.status
              : properties.status?.type;
          if (kind === "idle") setState("clear");
          else if (kind) setState("busy");
          break;
        }
        case "tool.execute.before":
        case "tool.execute.after":
        case "permission.replied":
        case "question.replied":
        case "question.rejected":
        case "session.compacted":
          setState("busy");
          break;
        case "permission.asked":
        case "question.asked":
        case "session.error":
          setState("waiting");
          break;
        case "session.idle":
          setState("clear");
          break;
        default:
          break;
      }
    },
  };
};
