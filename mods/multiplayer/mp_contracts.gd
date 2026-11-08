extends Node

# Delivery contracts.
#
# The game's DeliveryDirector calls the truck, counts what lands in its bed and
# pays when the order is full. Left running on every player it did all of that
# once per player: each had their own truck on their own timer, and a finished
# contract paid on the guest too, which reached the host as more money, so the
# bonus came twice.
#
# Only the host's director runs now. A guest's is stopped, and the host sends
# the contract as it stands; the guest's truck, stack and board follow it.

const TICK := 0.5
const FULL_TICK := 3.0   # everything again now and then, for a guest that just came in

var mp: Node
var world: Node
var _t := 0.0
var _full_t := 0.0
var _last := {}
var _stopped := false
var _reported_index := -1
var _truck_contract := -1


func start(mp_node: Node, world_node: Node) -> void:
	mp = mp_node
	world = world_node


func shutdown() -> void:
	var dd := _director()
	if _stopped and dd != null:
		dd.set_process(true)
	_stopped = false


func _director() -> Node:
	var dd: Variant = world.get("deliveries") if world != null and is_instance_valid(world) else null
	return dd if dd != null and is_instance_valid(dd) else null


func _truck() -> Node:
	var tr: Variant = world.get("truck") if world != null and is_instance_valid(world) else null
	return tr if tr != null and is_instance_valid(tr) else null


func _process(delta: float) -> void:
	if mp == null or not mp.active() or multiplayer.multiplayer_peer == null:
		return
	if not mp.is_host:
		var dd := _director()
		if dd != null and dd.is_processing():
			dd.set_process(false)
			_stopped = true
		return
	if mp.players.size() < 2:
		return
	_t += delta
	_full_t += delta
	if _t < TICK:
		return
	_t = 0.0
	var now := _state()
	if now == _last and _full_t < FULL_TICK:
		return
	_full_t = 0.0
	_last = now
	mp._rx_contract.rpc(now)


func _state() -> Dictionary:
	var tr := _truck()
	var index: int = GameState.contract_index
	var truck_state := int(tr.get("state")) if tr != null else -1
	if truck_state == DeliveryTruck.State.ARRIVING or (truck_state == DeliveryTruck.State.PARKED and _truck_contract < 0):
		_truck_contract = index
	elif truck_state == DeliveryTruck.State.LEAVING and _truck_contract < 0:
		_truck_contract = maxi(0, index - 1)
	elif truck_state == DeliveryTruck.State.AWAY:
		_truck_contract = -1
	return {
		"index": index,
		"delivered": GameState.contract_delivered,
		"parts": GameState.contract_parts.duplicate(),
		"done": GameState.contracts_done.keys(),
		"truck": truck_state,
		"rig": _truck_contract,
		"cargo": _cargo(tr),
	}


func _cargo(tr: Node) -> Dictionary:
	var counts := {}
	if tr == null:
		return counts
	var models: Dictionary = tr.get("_load")
	for id in models:
		var mesh: MultiMesh = models[id].multimesh
		var count := mesh.visible_instance_count
		if count > 0:
			counts[id] = count
	return counts


func send_now(pid: int) -> void:
	mp._rx_contract.rpc_id(pid, _state())


func on_state(s: Dictionary) -> void:
	if mp.is_host:
		return
	var index := int(s.get("index", GameState.contract_index))
	var delivered := int(s.get("delivered", 0))
	var parts: Dictionary = s.get("parts", {})
	var progress_changed: bool = index != GameState.contract_index \
		or delivered != GameState.contract_delivered or parts != GameState.contract_parts
	var was_index := _reported_index
	_reported_index = index
	var tr := _truck()
	# a contract closed on the host: tick it off here too
	if was_index >= 0 and index > was_index:
		var dd := _director()
		if dd != null and dd.get("panel") != null:
			dd.panel.mark_complete(DeliveryBook.title_of(was_index))
		Audio.play("sell_register", -2.0)
		Audio.play_delayed("coins", 0.18, -3.0)
	GameState.contract_index = index
	GameState.contract_delivered = delivered
	GameState.contract_parts = parts.duplicate()
	var done := {}
	for id in s.get("done", []):
		done[str(id)] = true
	# which contracts, not how many: one finished on each side kept the count
	# equal and the list wrong
	var theirs: Array = done.keys()
	theirs.sort()
	var ours: Array = []
	for id in GameState.contracts_done:
		ours.append(str(id))
	ours.sort()
	if theirs != ours:
		GameState.contracts_done = done
	if progress_changed or theirs != ours:
		GameState.contracts_changed.emit()
	if tr != null:
		_sync_truck(tr, int(s.get("truck", -1)), int(s.get("rig", -1)), s.get("cargo", {}))
	var dd2 := _director()
	if dd2 != null:
		dd2._restate()


func _sync_truck(tr: Node, state: int, rig: int, cargo: Dictionary) -> void:
	var have := _cargo(tr)
	var reset := rig != _truck_contract
	for id in have:
		if int(have[id]) > int(cargo.get(id, 0)):
			reset = true
	var dd := _director()
	if reset and rig >= 0 and dd != null:
		dd._rig(rig)
		_truck_contract = rig
	_follow_truck(tr, state)
	if rig < 0:
		_truck_contract = -1
		return
	have = _cargo(tr)
	for id in cargo:
		for i in maxi(0, int(cargo[id]) - int(have.get(id, 0))):
			tr.stack_one(id)


# The truck drives itself once told to come or go, so only the moves are sent.
func _follow_truck(tr: Node, want: int) -> void:
	var st := int(tr.get("state"))
	if want < 0 or want == st:
		return
	match want:
		DeliveryTruck.State.ARRIVING:
			tr.arrive()
		DeliveryTruck.State.PARKED:
			if st == DeliveryTruck.State.AWAY:
				tr.snap_parked()
		DeliveryTruck.State.LEAVING, DeliveryTruck.State.AWAY:
			if st == DeliveryTruck.State.ARRIVING:
				tr.snap_parked()
			tr.depart()
