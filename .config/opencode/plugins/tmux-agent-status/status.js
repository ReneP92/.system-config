// Only sessions open in this terminal may affect its tmux pane. Tab status
// already includes child sessions and pending permission/question requests.
export function paneState(context) {
  const tabs = context.ui.tabs.enabled() ? context.ui.tabs.list() : [];
  if (tabs.length) {
    if (tabs.some((tab) => tab.attention || tab.unread === "error"))
      return "waiting";
    return tabs.some((tab) => tab.busy) ? "busy" : "clear";
  }

  const route = context.ui.router.current();
  if (route.type !== "session") return "clear";

  const sessions = context.data.session;
  const root = sessions.root(route.sessionID);
  const family = new Set([root, route.sessionID, ...sessions.family(root)]);
  for (const id of family) {
    if (sessions.permission.list(id)?.length || sessions.form.list(id)?.length)
      return "waiting";
  }
  return [...family].some((id) => sessions.status(id) === "running")
    ? "busy"
    : "clear";
}
