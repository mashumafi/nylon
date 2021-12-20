# InteractiveLoader
# Load a list resource files and yield between each stages

# Emitted on each stage
# Returns the current stage and total number of stages
signal progress(current, total)
# Emitted when the loader completes
# Returns false on failure and a list of resources on success
signal finished(result)

var loaders := []
var stage_count := 0

# InteractiveLoader.new(paths: Array)
# paths (Array[String]): List of resource paths to load
func _init(paths: Array):
    for path in paths:
        var loader := ResourceLoader.load_interactive(path)
        stage_count += loader.get_stage_count()
        loaders.append(loader)

# load_interactive()
# Loads resources one stage at a time
func load_interactive():
    var stage := 0
    var resources := []
    while not loaders.empty():
        yield()
        var loader := loaders.back() as ResourceInteractiveLoader
        var res := loader.poll()
        emit_signal("progress", stage + loader.get_stage(), stage_count)
        match res:
            ERR_FILE_EOF:
                stage += loader.get_stage()
                resources.append(loader.get_resource())
                loaders.pop_back()
            OK:
                pass
            _:
                emit_signal("finished", false)
                return false

    emit_signal("finished", resources)
    return resources
