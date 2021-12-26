# Coroutine
# Contains async state of a called function

class_name Coroutine
extends Reference

const Callable := preload("callable.gd")

# Emitted on the final execution
# Can be used along with `replay`
# Returns the final result
signal completed(final_result)
# Emitted at the start of each coroutine
signal started()
# Emitted at the end of each coroutine once it stops yielding
# Returns the latest result
signal ended(result)

var _callable : Callable
var _replay = 1
var _state : GDScriptFunctionState = null
var _result = null

# Coroutine.new(callable: Callable, replay : int | bool)
# callable (Callable): The function to call
# replay (int | bool): How many times to call the function
#                      Using `true` repeats until cancelled
func _init(callable: Callable, replay = 1):
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

# cancel(finish_resuming: bool)
# Cancels processing of the coroutine
# finish_resuming (bool): true will allow function to `resume` until completion, false will destroy the function state
func cancel(finish_resuming := false) -> void:
    self._callable = null
    if not finish_resuming:
        _update_state(null)

# is_valid() -> bool
# Returns true if calling `resume()` would change the state
func is_valid() -> bool:
    return self._callable != null or self._state is GDScriptFunctionState
