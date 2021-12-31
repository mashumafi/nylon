extends Nylon

const Coroutine := preload("coroutine.gd")

# List of coroutines
var _coroutines := []

# run_async(instance: Object, funcname: String, replay: int | bool) -> Coroutine
# instance (Object): object to call a function
# funcname (String): name of the function to call
# replay (int | bool): How many times to call the function
#                      Using `true` repeats until cancelled
func run_async(instance, funcname: String, replay = 1) -> Coroutine:
    return _append_coroutine(Coroutine.new(Callable.new(instance, funcname), replay))

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
