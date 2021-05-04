import "scheduler" for Scheduler
import "timer" for Timer

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
        // we need to very quickly yield control back to the Scheduler incase
        // any fibers have been added with Scheduler.add so that they will be
        // started by the scheduler before we fall into Async.waitForOthers()
        // and suspend the VM waiting for UV callbacks
        Timer.sleep(0)
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