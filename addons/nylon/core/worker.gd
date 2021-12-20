extends Node

class Coroutine:
    # Coroutine
    # Contains async state of a called function

    extends Reference

    # Emitted on the final execution
    # Can be used along with `replay`
    # Returns the final result
    signal completed(final_result)
    # Emitted at the start of each coroutine
    signal started()
    # Emitted at the end of each coroutine once it stops yielding
    # Returns the latest result
    signal ended(result)

    var _callable : FuncRef
    var _replay = 1
    var _state : GDScriptFunctionState = null
    var _result = null

    # Coroutine.new(callable: FuncRef, replay : int | bool)
    # callable (FuncRef): The function to call
    # replay (int | bool): How many times to call the function
    #                      Using `true` repeats until cancelled
    func _init(callable: FuncRef, replay = 1):
        self._callable = callable
        self._replay = replay

    # _update_state(result)
    # Update the state and emit `ended` signal when invalid
    func _update_state(result):
        self._result = result
        self._state = result

        if not self._state is GDScriptFunctionState:
            self.emit_signal("ended", self._result)

    # resume()
    # Resumes processing the function
    # Decrements the `replay` by 1 when using an `int`
    # Coroutines that return `false` will cancel and end execution
    # Emits `started`, `ended` and `completed`
    func resume() -> void:
        var cancelled : bool = self._result is bool and self._result
        if self._state is GDScriptFunctionState:
            self._update_state(self._state.resume())
        elif self._replay is int and 0 < self._replay and not cancelled:
            self.emit_signal("started")
            self._update_state(self._callable.call_func())
            self._replay -= 1
        elif self._replay is bool and true == self._replay and not cancelled:
            self.emit_signal("started")
            self._update_state(self._callable.call_func())
        else:
            self._callable = null
            self.emit_signal("completed", self._result)

    # is_valid() -> bool
    # Returns true if calling `resume()` would change the state
    func is_valid() -> bool:
        return self._callable != null

enum WorkerProcessMode {IDLE, PHYSICS}
export(WorkerProcessMode) var process_mode := WorkerProcessMode.IDLE setget set_process_mode, get_process_mode
func set_process_mode(new_process_mode: int) -> void:
    process_mode = new_process_mode
    set_process(WorkerProcessMode.IDLE == process_mode)
    set_physics_process(WorkerProcessMode.PHYSICS == process_mode)
func get_process_mode() -> int:
    return process_mode

# List of coroutines
var _coroutines := []

func _ready() -> void:
    set_process_mode(process_mode)

func _process(_delta: float) -> void:
    _run_coroutines()

func _physics_process(_delta: float) -> void:
    _run_coroutines()

# run_async(callable: FuncRef, replay: int | bool) -> Coroutine
# callable (FuncRef): The function to call
# replay (int | bool): How many times to call the function
#                      Using `true` repeats until cancelled
func run_async(callable: FuncRef, replay = 1) -> Coroutine:
    return _append_coroutine(Coroutine.new(callable, replay))

# _run_coroutines()
# Runs all coroutines and throws away ones that are no longer valid
func _run_coroutines():
    var valid_coroutines := _coroutines.duplicate()
    _coroutines.clear()
    for coroutine in valid_coroutines:
        coroutine.resume()
        _append_coroutine(coroutine)

# _append_coroutine(coroutine: Coroutine) -> Coroutine
# Append a coroutine if it is valid and return it
# coroutine (Coroutine): The coroutine to add, and invalid one results in a no-op
# Returns Coroutine The same coroutine if it is valid, null otherwise
func _append_coroutine(coroutine: Coroutine) -> Coroutine:
    if coroutine.is_valid():
        _coroutines.append(coroutine)
        return coroutine

    return null
