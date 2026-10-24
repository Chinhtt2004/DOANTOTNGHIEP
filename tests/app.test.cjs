const assert = require("node:assert/strict");
const fs = require("node:fs");
const vm = require("node:vm");
const { test } = require("node:test");

// Exercise the real handlers with a fixed clock and an in-memory browser shell.
// No application logic is duplicated here; browser rendering is checked separately.
function demo(savedState) {
  let now = Date.parse("2026-10-24T03:00:00Z"); // 10:00 in Vietnam
  class Clock extends Date {
    constructor(...args) { super(...(args.length ? args : [now])); }
    static now() { return now; }
  }
  const nodes = new Map();
  const node = (selector) => {
    if (!nodes.has(selector)) nodes.set(selector, { innerHTML: "", textContent: "", style: {}, classList: { add() {}, remove() {}, toggle() {} }, open: false, showModal() { this.open = true; }, close() { this.open = false; }, focus() {} });
    return nodes.get(selector);
  };
  const storage = new Map(savedState ? [["troday-wireframe-v5-20261023", JSON.stringify(savedState)]] : []);
  const context = vm.createContext({
    Date: Clock, Intl, structuredClone, URLSearchParams, URL,
    setTimeout: () => 1, clearTimeout() {},
    localStorage: { getItem: (key) => storage.get(key) || null, setItem: (key, value) => storage.set(key, value) },
    document: { querySelector: node, querySelectorAll: () => [], addEventListener() {} },
    window: { scrollTo() {} }, location: { search: "" },
    FormData: class {
      constructor(form) { this.values = form.values; }
      get(key) { const value = this.values[key]; return Array.isArray(value) ? value[0] : value ?? null; }
      getAll(key) { const value = this.values[key]; return value == null ? [] : Array.isArray(value) ? value : [value]; }
    }
  });
  vm.runInContext(fs.readFileSync(`${__dirname}/../app.js`, "utf8"), context);
  const api = vm.runInContext("({ state: () => state, handleAction, handleForm, render, renderResidents, roomLoad, appointmentTimestamp, todayISO, openAppointment })", context);
  const state = api.state();
  state.role = "landlord"; state.view = "residents";
  return { state, api, node, action: api.handleAction, submit: (name, values) => api.handleForm({ dataset: { form: name }, values }), now: (value) => { now = Date.parse(value); } };
}
const byId = (items, id) => items.find((item) => item.id === id);
const k2 = (d) => byId(d.state.contracts, "k2");
const join = (d) => byId(d.state.joinRequests, "join1");
function change(d, type, extra = {}) {
  const request = { id: "change-test", contractId: "k2", status: "READY_TO_APPLY", type, effective: "2026-10-24", ...extra };
  d.state.changeRequests.push(request);
  return request;
}

test("one remaining resident is preselected for an explicit representative handover", () => {
  const d = demo(); d.action("move-out", "k2:o2");
  assert.equal(k2(d).status, "ACTIVE");
  assert.ok(k2(d).members.every((m) => m.status === "ACTIVE"));
  assert.match(d.api.renderResidents(), /Đỗ Bích Ngọc/);
  assert.match(d.node("#dialog-body").innerHTML, /hệ thống đã chọn sẵn/);
  assert.match(d.node("#dialog-body").innerHTML, /value="o3"/);
  d.submit("representative-handover", { contractId: "k2", departingId: "o2", successorId: "o3", reason: "Mai rời phòng", consent: "yes" });
  assert.equal(k2(d).tenantId, "ngoc"); assert.equal(k2(d).representativeId, "o3");
  assert.equal(k2(d).members[0].status, "LEFT"); assert.equal(k2(d).members[1].status, "ACTIVE");
  assert.equal(k2(d).status, "ACTIVE"); assert.equal(byId(d.state.rooms, "r3").status, "OCCUPIED");
  assert.equal(k2(d).representativeHistory.length, 2);
  assert.equal(k2(d).representativeHistory[0].toAt, k2(d).representativeHistory[1].fromAt);
  assert.equal(k2(d).representativeHistory[1].consentRecordedBy, "quan");
});
test("multiple eligible residents require choosing one, without silently assigning", () => {
  const d = demo(); k2(d).members.push({ id: "o-bao", tenantId: "bao", name: "Bảo", status: "ACTIVE", moveIn: "2026-10-23" });
  d.action("move-out", "k2:o2"); assert.match(d.node("#dialog-body").innerHTML, /Chọn một người đang ở/);
  d.submit("representative-handover", { contractId: "k2", departingId: "o2", successorId: "", reason: "Rời", consent: "yes" });
  assert.equal(k2(d).tenantId, "mai");
  d.submit("representative-handover", { contractId: "k2", departingId: "o2", successorId: "o-bao", reason: "Bảo nhận đại diện", consent: "yes" });
  assert.equal(k2(d).tenantId, "bao"); assert.equal(k2(d).members[1].status, "ACTIVE");
});
test("handover requires recorded consent and rejects planned, foreign or locked successors atomically", () => {
  for (const kind of ["no-consent", "planned", "foreign", "locked"]) {
    const d = demo();
    if (kind === "planned") k2(d).members[1].status = "PLANNED";
    if (kind === "locked") d.state.lockedUsers = ["ngoc"];
    const before = JSON.stringify(k2(d));
    d.submit("representative-handover", { contractId: "k2", departingId: "o2", successorId: kind === "foreign" ? "o1" : "o3", reason: "Bàn giao", consent: kind === "no-consent" ? "" : "yes" });
    assert.equal(JSON.stringify(k2(d)), before, kind);
  }
});
test("handover rechecks permissions and contract state at submission", () => {
  for (const kind of ["tenant", "closed", "stale"]) {
    const d = demo(); d.action("move-out", "k2:o2");
    if (kind === "tenant") d.state.role = "tenant";
    if (kind === "closed") k2(d).status = "TERMINATED";
    if (kind === "stale") k2(d).members[1].status = "LEFT";
    d.submit("representative-handover", { contractId: "k2", departingId: "o2", successorId: "o3", reason: "Bàn giao", consent: "yes" });
    assert.equal(k2(d).tenantId, "mai", kind); assert.equal(k2(d).members[0].status, "ACTIVE", kind);
  }
});
test("history survives reload, repeated submission and multiple successive handovers", () => {
  const d = demo(); const values = { contractId: "k2", departingId: "o2", successorId: "o3", reason: "Ngọc tiếp quản", consent: "yes" };
  d.submit("representative-handover", values); d.submit("representative-handover", values);
  assert.equal(k2(d).representativeHistory.length, 2);
  const reload = demo(d.state); assert.equal(k2(reload).representativeHistory.length, 2);
  assert.equal(k2(reload).representativeHistory[0].fromAt, null);
  k2(reload).members.push({ id: "o-bao", tenantId: "bao", name: "Bảo", status: "ACTIVE", moveIn: "2026-10-24" });
  reload.now("2026-10-24T04:00:00Z");
  reload.submit("representative-handover", { contractId: "k2", departingId: "o3", successorId: "o-bao", reason: "Bảo tiếp quản", consent: "yes" });
  assert.equal(k2(reload).representativeHistory.length, 3);
  assert.equal(k2(reload).representativeHistory.filter((h) => !h.ended).length, 1);
  reload.action("representative-history", "k2");
  assert.match(reload.node("#dialog-body").innerHTML, /Phạm Thu Mai/); assert.match(reload.node("#dialog-body").innerHTML, /Đỗ Bích Ngọc/);
});
test("handover cancels old consents but preserves issued bills and signed revisions", () => {
  const d = demo(); d.action("approve-join", "join1");
  const bills = JSON.stringify(d.state.invoices); const revisions = JSON.stringify(k2(d).revisions);
  d.submit("representative-handover", { contractId: "k2", departingId: "o2", successorId: "o3", reason: "Bàn giao", consent: "yes" });
  assert.equal(join(d).status, "CANCELLED"); assert.equal(d.state.changeRequests[0].status, "CANCELLED");
  assert.equal(JSON.stringify(d.state.invoices), bills); assert.equal(JSON.stringify(k2(d).revisions), revisions);
  assert.equal(d.state.notifications.filter((n) => n.contractId === "k2").length, 2);
  d.submit("invoice", { contractId: "k2", period: "2026-11", due: "2026-11-28", other: "0", discount: "0" });
  assert.equal(d.state.invoices.at(-1).payerId, "ngoc");
  d.state.view = "contracts"; d.state.selectedContract = "k2"; d.api.render();
  assert.match(d.node("#app-main").innerHTML, /Đã hủy/);
});
test("the final successor's departure closes their tenure without losing earlier history", () => {
  const d = demo(); d.submit("representative-handover", { contractId: "k2", departingId: "o2", successorId: "o3", reason: "Bàn giao", consent: "yes" });
  const first = JSON.stringify(k2(d).representativeHistory[0]);
  d.now("2026-10-24T04:00:00Z"); d.action("move-out", "k2:o3");
  assert.equal(k2(d).status, "TERMINATED");
  assert.ok(k2(d).representativeHistory.every((entry) => entry.ended));
  assert.equal(k2(d).representativeHistory[1].toAt, "2026-10-24T04:00:00.000Z");
  assert.equal(JSON.stringify(k2(d).representativeHistory[0]), first);
});
test("an old representative's roommate invitation cannot reuse their consent after handover", () => {
  const d = demo(); d.submit("representative-handover", { contractId: "k2", departingId: "o2", successorId: "o3", reason: "Bàn giao", consent: "yes" });
  d.state.role = "tenant"; const before = d.state.joinRequests.length;
  d.action("accept-roommate", "rm2");
  assert.equal(d.state.joinRequests.length, before);
  assert.match(d.node("#toast").textContent, /đại diện cũ/);
});
test("new-rental handover preserves the original viewing tenant", () => {
  const d = demo(); const c = byId(d.state.contracts, "k1");
  byId(d.state.rooms, "r5").capacity = 2; c.status = "ACTIVE"; c.members[0].status = "ACTIVE";
  c.members.push({ id: "o-bao", tenantId: "bao", name: "Bảo", status: "ACTIVE", moveIn: "2026-10-24" });
  d.submit("representative-handover", { contractId: "k1", departingId: "o1", successorId: "o-bao", reason: "Bảo tiếp quản", consent: "yes" });
  assert.equal(c.tenantId, "bao"); assert.equal(c.viewingTenantId, "lan");
  assert.equal(byId(d.state.viewings, "v3").tenantId, "lan");
  d.state.role = "tenant"; d.state.view = "contracts"; d.state.selectedContract = "k1"; d.api.render();
  assert.match(d.node("#app-main").innerHTML, /HD-2026-041/);
  assert.doesNotMatch(d.node("#app-main").innerHTML, /data-action="open-change"/);
});
test("a regular member may leave without closing the contract", () => {
  const d = demo(); d.action("move-out", "k2:o3");
  assert.equal(k2(d).status, "ACTIVE");
  assert.equal(k2(d).members[1].moveOut, "2026-10-24");
  assert.equal(k2(d).members[1].moveOutConfirmedBy, "quan");
});
test("last departure closes the contract and cancels open joins", () => {
  const d = demo(); d.action("move-out", "k2:o3"); d.action("move-out", "k2:o2");
  assert.equal(k2(d).status, "TERMINATED");
  assert.equal(join(d).status, "CANCELLED");
  assert.equal(byId(d.state.rooms, "r3").status, "AVAILABLE");
});
test("old inconsistent saved data retains Ngoc and marks the room occupied", () => {
  const original = demo(); k2(original).status = "TERMINATED";
  k2(original).members[0].status = "LEFT";
  byId(original.state.rooms, "r3").status = "AVAILABLE";
  const d = demo(original.state);
  assert.equal(byId(d.state.rooms, "r3").status, "OCCUPIED");
  assert.match(d.api.renderResidents(), /Đỗ Bích Ngọc/);
  assert.match(d.api.renderResidents(), /Cần đối soát/);
});
test("two occupants plus one reservation block a second approval", () => {
  const d = demo(); d.action("approve-join", "join1");
  d.state.joinRequests.push({ ...join(d), id: "join2", applicantId: "lan", status: "PENDING_LANDLORD" });
  d.action("approve-join", "join2");
  assert.equal(join(d).status, "APPROVED");
  assert.equal(byId(d.state.joinRequests, "join2").status, "PENDING_LANDLORD");
  assert.equal(d.api.roomLoad("r3"), 3);
});
test("planned initial members consume capacity too", () => {
  const d = demo(); k2(d).members.push({ id: "planned", name: "Dự kiến", status: "PLANNED" });
  d.action("approve-join", "join1"); assert.equal(join(d).status, "PENDING_LANDLORD");
});
test("approval expires after 48 hours and cannot complete", () => {
  const d = demo(); d.action("approve-join", "join1");
  d.now("2026-10-26T03:00:00Z"); d.action("complete-join", "join1");
  assert.equal(join(d).status, "EXPIRED"); assert.equal(k2(d).members.length, 2);
});
test("old approvals lacking expiry release their unbounded hold", () => {
  const original = demo(); join(original).status = "APPROVED";
  const d = demo(original.state); assert.equal(join(d).status, "EXPIRED");
});
for (const status of ["TERMINATED", "EXPIRED", "CANCELLED", "CONFIRMED"]) {
  test(`approved join cannot move into a ${status} contract`, () => {
    const d = demo(); d.action("approve-join", "join1"); k2(d).status = status;
    d.action("complete-join", "join1");
    assert.equal(k2(d).members.length, 2); assert.equal(join(d).status, "APPROVED");
  });
}
test("join completion is linked to one stay and is idempotent", () => {
  const d = demo(); d.action("approve-join", "join1"); d.action("complete-join", "join1"); d.action("complete-join", "join1");
  assert.equal(k2(d).members.length, 3); assert.equal(join(d).status, "COMPLETED");
  const member = byId(k2(d).members, join(d).completedRoomTenantId);
  assert.equal(member.joinRequestId, "join1"); assert.equal(member.moveInConfirmedBy, "quan");
});
test("room capacity cannot be reduced below people and holds", () => {
  const d = demo(); d.action("approve-join", "join1");
  d.submit("room", { roomId: "r3", code: "P305", area: "30", price: "5400000", deposit: "5400000", capacity: "2", status: "OCCUPIED" });
  assert.equal(byId(d.state.rooms, "r3").capacity, 3);
});
test("initial occupants can all move in or arrive separately", () => {
  const d = demo(); const c = byId(d.state.contracts, "k1");
  byId(d.state.rooms, "r5").capacity = 2;
  c.status = "CONFIRMED"; c.revisionStatus = "CONFIRMED";
  c.members.push({ id: "extra", tenantId: null, name: "Bạn ở cùng", status: "PLANNED", moveIn: "" });
  d.submit("move-in", { contractId: "k1", date: "2026-10-24", memberIds: ["o1"] });
  assert.equal(c.status, "ACTIVE"); assert.equal(c.members[1].status, "PLANNED");
  assert.match(d.api.renderResidents(), /Bạn ở cùng/);
  d.submit("move-in", { contractId: "k1", date: "2026-10-24", memberIds: ["extra"] });
  assert.ok(c.members.every((m) => m.status === "ACTIVE"));
});
test("activation requires the representative and validates the entire selection before writing", () => {
  const d = demo(); const c = byId(d.state.contracts, "k1"); c.status = "CONFIRMED"; c.revisionStatus = "CONFIRMED";
  byId(d.state.rooms, "r5").capacity = 2;
  c.members.push({ id: "extra", tenantId: "ngoc", name: "Ngọc", status: "PLANNED" });
  d.submit("move-in", { contractId: "k1", date: "2026-10-24", memberIds: ["extra"] });
  assert.equal(c.status, "CONFIRMED");
  d.submit("move-in", { contractId: "k1", date: "2026-10-24", memberIds: ["o1", "extra"] });
  assert.ok(c.members.every((m) => m.status === "PLANNED"));
});
test("a group can move in in one confirmation", () => {
  const d = demo(); const c = byId(d.state.contracts, "k1"); c.status = "CONFIRMED"; c.revisionStatus = "CONFIRMED";
  byId(d.state.rooms, "r5").capacity = 2;
  c.members.push({ id: "extra", tenantId: null, name: "Bạn ở cùng", status: "PLANNED" });
  d.submit("move-in", { contractId: c.id, date: "2026-10-24", memberIds: ["o1", "extra"] });
  assert.equal(c.status, "ACTIVE"); assert.ok(c.members.every((m) => m.status === "ACTIVE"));
});
test("termination records departure dates and cancels planned people and joins", () => {
  const d = demo(); k2(d).members.push({ id: "extra", status: "PLANNED" });
  change(d, "TERMINATION"); d.action("apply-change", "change-test");
  assert.equal(k2(d).status, "TERMINATED");
  assert.ok(k2(d).members.slice(0, 2).every((m) => m.status === "LEFT" && m.moveOut === "2026-10-24" && m.moveOutConfirmedAt));
  assert.equal(k2(d).members[2].status, "CANCELLED"); assert.equal(join(d).status, "CANCELLED");
});
test("transfer carries all open members, preserves history, and then supports group arrival", () => {
  const d = demo(); const request = change(d, "TRANSFER", { targetRoomId: "r1" });
  d.action("apply-change", request.id);
  const next = byId(d.state.contracts, request.resultContractId);
  assert.equal(next.members.length, 2); assert.equal(next.previousContractId, "k2");
  assert.ok(k2(d).members.every((m) => m.status === "LEFT" && m.moveOut === "2026-10-24"));
  assert.ok(next.members.every((m) => m.status === "PLANNED" && !m.moveOut && !m.moveInConfirmedAt && !m.joinRequestId));
  d.submit("move-in", { contractId: next.id, date: "2026-10-24", memberIds: next.members.map((m) => m.id) });
  assert.equal(next.status, "ACTIVE"); assert.ok(next.members.every((m) => m.status === "ACTIVE"));
});
test("transfer to a room too small makes no partial changes", () => {
  const d = demo(); byId(d.state.rooms, "r1").capacity = 1;
  const before = JSON.stringify(d.state.contracts); const request = change(d, "TRANSFER", { targetRoomId: "r1" });
  d.action("apply-change", request.id);
  assert.equal(JSON.stringify(d.state.contracts), before); assert.equal(request.status, "READY_TO_APPLY");
});
test("closing cannot place move-out before any member's move-in", () => {
  const d = demo(); k2(d).members[1].moveIn = "2026-10-24";
  const request = change(d, "TERMINATION", { effective: "2026-10-23" }); d.action("apply-change", request.id);
  assert.equal(k2(d).status, "ACTIVE");
});
test("viewing times are Vietnam times even when the host timezone is different", () => {
  const d = demo(); assert.equal(d.api.appointmentTimestamp("2026-10-24", "10:00"), Date.parse("2026-10-24T03:00:00Z"));
  d.now("2026-10-24T18:30:00Z"); assert.equal(d.api.todayISO(), "2026-10-25");
  assert.ok(Number.isNaN(d.api.appointmentTimestamp("2026-02-30", "10:00")));
  d.api.openAppointment(); assert.match(d.node("#dialog-body").innerHTML, /value="02:00"/);
});
test("past times today are rejected; actual intervals and overlap boundaries are respected", () => {
  const d = demo(); const values = { conversationId: "c1", roomId: "r1", date: "2026-10-24", time: "09:00", duration: "60" };
  const count = d.state.viewings.length; d.submit("appointment", values); assert.equal(d.state.viewings.length, count);
  d.submit("appointment", { ...values, time: "10:30", duration: "30" });
  assert.equal(d.state.viewings.length, count + 1);
  assert.equal(d.state.viewings.at(-1).startsAt, "2026-10-24T03:30:00.000Z");
  d.submit("appointment", { ...values, time: "10:45" }); assert.equal(d.state.viewings.length, count + 1);
  d.submit("appointment", { ...values, time: "11:00" }); assert.equal(d.state.viewings.length, count + 2);
});
test("attendance and no-show cannot be recorded ahead of their time", () => {
  const d = demo(); const v = byId(d.state.viewings, "v1"); v.date = "2026-10-24"; v.time = "11:00";
  d.action("confirm-attendance", "v1"); assert.equal(v.status, "SCHEDULED");
  d.action("no-show", "v1"); assert.equal(v.status, "SCHEDULED");
  d.now("2026-10-24T05:00:00Z"); d.action("no-show", "v1"); assert.equal(v.status, "NO_SHOW");
});
test("cancelling a viewing records the actor and reason and frees the interval", () => {
  const d = demo(); d.submit("cancel-viewing", { viewingId: "v1", reason: "Đổi kế hoạch" });
  const v = byId(d.state.viewings, "v1"); assert.equal(v.status, "CANCELLED"); assert.equal(v.cancelledBy, "quan"); assert.ok(v.cancelledAt);
});
test("withdrawal is blocked by a live contract and allowed after its cancellation", () => {
  const d = demo(); d.state.role = "tenant"; d.action("withdraw-rent", "v3");
  assert.equal(byId(d.state.viewings, "v3").decision, "AGREED");
  d.state.role = "landlord"; d.submit("cancel-contract", { contractId: "k1", reason: "Hai bên đồng ý hủy" });
  assert.equal(byId(d.state.contracts, "k1").members[0].status, "CANCELLED");
  d.state.role = "tenant"; d.action("withdraw-rent", "v3");
  assert.equal(byId(d.state.viewings, "v3").decision, "WITHDRAWN"); assert.ok(byId(d.state.viewings, "v3").rentalWithdrawnAt);
});
test("new contract rejects more initial members than the room allows", () => {
  const d = demo(); byId(d.state.viewings, "v2").decision = "AGREED";
  const count = d.state.contracts.length;
  d.submit("create-contract", { viewingId: "v2", start: "2026-10-24", end: "2027-10-24", rent: "4200000", deposit: "4200000", members: "A, 123\nB, 456\nC, 789", terms: "Thỏa thuận" });
  assert.equal(d.state.contracts.length, count);
});
