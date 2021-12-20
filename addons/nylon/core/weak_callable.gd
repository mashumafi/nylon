# WeakCallable
# Safely calls methods of `WeakRef` objects

class_name WeakCallable
extends Reference

var object : WeakRef
var func_name : String

# WeakCallable.new(object: WeakRef, func_name: String)
# object (WeakRef): The object to call the method of
# func_name (String): The method name to call
func _init(object: WeakRef, func_name: String):
    self.object = object
    self.func_name = func_name

# call_func()
# Calls the function if the object is valid
func call_func():
    var ref = object.get_ref()
    if ref:
        return ref.call(func_name)

    return true # Cancel infinite replay
