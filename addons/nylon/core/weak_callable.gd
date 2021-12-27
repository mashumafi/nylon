# WeakCallable
# Safely calls methods of `WeakRef` objects

class_name WeakCallable
extends Reference

var instance : WeakRef
var funcname : String

# WeakCallable.new(instance: WeakRef, funcname: String)
# instance (WeakRef): The object to call the method of
# funcname (String): The method name to call
func _init(instance: WeakRef, funcname: String):
    self.instance = instance
    self.funcname = funcname

# call_func()
# Calls the function if the instance is valid
func call_func():
    var ref = instance.get_ref()
    if ref:
        return ref.call(funcname)

    return true # Cancel infinite replay
