# Callable
# Custom FuncRef implementation that incremements reference count for `instance`

var instance
var funcname : String

func _init(instance, funcname: String) -> void:
    self.instance = instance
    self.funcname = funcname

func call_func(args := []):
    return self.instance.callv(self.funcname, args)
