import { execFileSync } from "node:child_process";
import { Plugin } from "@opencode/plugin/tui";
import { createEffect } from "solid-js";
import { paneState } from "./status.js";

export default Plugin.define({
  id: "tmux-agent-status",
  setup(context) {
    if (!process.env.TMUX || !process.env.TMUX_PANE) return;

    const env = { ...process.env };
    const script = `${env.HOME}/.tmux/agent-status.sh`;
    let lastState;
    function setState(state) {
      if (state === lastState) return;
      try {
        // Serialize these short local writes so a late busy update cannot
        // overwrite clear. Bound execution if tmux is unavailable or stuck.
        execFileSync(script, [state], { env, stdio: "ignore", timeout: 1000 });
        lastState = state;
      } catch {
        // Best effort; retry on the next state update if the helper failed.
      }
    }

    const clear = () => setState("clear");
    const unregister = context.ui.slot({
      append: "app",
      render() {
        createEffect(() => setState(paneState(context)));
        return null;
      },
    });
    process.on("exit", clear);

    return () => {
      unregister();
      process.off("exit", clear);
      clear();
    };
  },
});
