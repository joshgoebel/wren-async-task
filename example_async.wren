import "timer" for Timer
import "io" for Stdout
import "scheduler" for Scheduler
import "./async-task" for Async, Task



var ONE_SECOND = 100

class Slow {
    construct new() {}
    loadFiles() {
        System.print("fetching files")
        Timer.sleep(ONE_SECOND * 5)
        System.print("files loaded")
    }
    loadGraphics() {
        System.print("fetching graphics")
        Timer.sleep(ONE_SECOND * 5)
        System.print("Graphics loaded")
    }
    time() {
        for (i in 0..10) {
            System.write(".")
            Stdout.flush()
            Timer.sleep(ONE_SECOND)
        }
    }
}

var s = Slow.new()
var a = Task.run { s.time() }
var b = Task.run { s.loadFiles() }
var c = Task.run { s.loadGraphics() }
Task.await([a,b,c])

System.print("done")
Stdout.flush()
// while(true) {
//     Timer.sleep(20)
// }
