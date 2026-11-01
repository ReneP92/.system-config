import { Plugin } from "@opencode/plugin";

// Discovery entrypoint. Pane state belongs to the terminal client, not the
// shared server, which may serve several terminals (or run on another host).
export default Plugin.define({
  id: "tmux-agent-status",
  setup() {},
});
