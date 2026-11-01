import assert from "node:assert/strict";
import { test } from "node:test";
import { paneState } from "../.config/opencode/plugins/tmux-agent-status/status.js";

function context({
  tabs = [],
  route = { type: "session", sessionID: "root" },
  running = [],
  permissions = [],
  forms = [],
} = {}) {
  return {
    ui: {
      tabs: { enabled: () => tabs.length > 0, list: () => tabs },
      router: { current: () => route },
    },
    data: {
      session: {
        root: () => "root",
        family: () => ["root", "child"],
        status: (id) => (running.includes(id) ? "running" : "idle"),
        permission: { list: (id) => (permissions.includes(id) ? [{}] : []) },
        form: { list: (id) => (forms.includes(id) ? [{}] : []) },
      },
    },
  };
}

test("open tabs aggregate busy and waiting, with waiting taking priority", () => {
  const tabs = [{ busy: true }, { attention: true }];
  const ctx = context({ tabs });
  assert.equal(paneState(ctx), "waiting");
  tabs[1].attention = false;
  assert.equal(paneState(ctx), "busy");
  tabs[0].busy = false;
  assert.equal(paneState(ctx), "clear");
  tabs[1].unread = "error";
  assert.equal(paneState(ctx), "waiting");
});

test("events in another terminal cannot change this pane", () => {
  assert.equal(
    paneState(context({
      running: ["unrelated"], permissions: ["unrelated"], forms: ["unrelated"],
    })),
    "clear",
  );
  assert.equal(
    paneState(context({
      tabs: [{ busy: false }], running: ["root"], permissions: ["root"],
    })),
    "clear",
  );
});

test("without tabs, child completion does not clear a running parent", () => {
  assert.equal(paneState(context({ running: ["root"] })), "busy");
  assert.equal(paneState(context({ running: ["child"] })), "busy");
  assert.equal(paneState(context()), "clear");
});

test("child permission and question requests take priority over running", () => {
  assert.equal(
    paneState(context({ running: ["root"], permissions: ["child"] })),
    "waiting",
  );
  assert.equal(
    paneState(context({ running: ["root"], forms: ["child"] })),
    "waiting",
  );
  assert.equal(
    paneState(context({
      running: ["root"], route: { type: "session", sessionID: "child" },
    })),
    "busy",
  );
});

test("home without open tabs clears the pane", () => {
  assert.equal(
    paneState(context({ route: { type: "home" }, running: ["root"] })),
    "clear",
  );
});
