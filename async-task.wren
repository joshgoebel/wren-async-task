import "scheduler" for Scheduler

class Async {
  static waitForOthers() {
    addSelfToScheduler()
    Fiber.suspend()
  }
  static addSelfToScheduler() {
    var fiber_current = Fiber.current
    Scheduler.add( Fn.new {
        fiber_current.transfer()
    })
  }
  static run(fn) {
    Scheduler.add(fn)
    addSelfToScheduler()
    Scheduler.runNextScheduled_()
  }
}

class Task {
    static run(fn) { Task.new(fn).run() }
    construct new(fn) {
        _fn = fn
    }
    isRunning { !_isDone }
    run() {
        Async.run {
            _fn.call()
            _isDone = true
        }
        return this
    }
    static await(list) {
        while(true) {
            // System.print(list.map { |task| !task.isRunning }.toList)
            if (list.any { |task| task.isRunning }) {
                Async.waitForOthers()
            } else {
                break
            }
        }
    }
}