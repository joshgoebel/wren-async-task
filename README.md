# [RFC] Async API exploration and minimal proposal

See: https://github.com/wren-lang/wren-cli/issues/99

I was playing around with fibers and wanted to start to build something like an async framework but realized we may be missing just the tiniest infrastructure to make that possible.  Following is the larger context - skip to just the end if you'd like my proposal.

Here is the idea I started with:

```js
var s = SlowService.new()
var a = Task.run { s.printTimeDots() }
var b = Task.run { s.loadFiles() }
var c = Task.run { s.loadGraphics() }
Task.await([a,b,c])
```

I would like to just put those tasks into the scheduler and then wait for them to all complete asynchronously.

The only **core** thing missing seems to be `Scheduler.add(fiber)`.  You can add *new* functions to the Scheduler, but you cannot ask it to resume the current Fiber later.  Perhaps you could nest the transfer inside a wrapper function insider yet another Fiber (the one `add` creates) - but *ugh*... that sounds sounds like pain for no reason.

We need a way to be able to insert the current fiber into the queue of Fibers eligible for resumption later.  This isn't super helpful on it's own but typically what you would do is first insert a Fiber *ahead* of you - so that Fiber would run and then when it slept you would be next to resume control, ie:

```js
// schedule some function
Scheduler.add(fn)
// schedule myself
Scheduler.add(Fiber.current)
// transfer control to the scheduled function (fn)
Scheduler.runNextScheduled_()
```

So let's add that, it's a 4 line patch to `static add(_)`:

```js
  static add(callable) {
    // v--- ADD
    if (callable is Fiber) {
      __scheduled.add(callable)
      return
    }
    // ^--- ADD
    __scheduled.add(Fiber.new {
      callable.call()
      runNextScheduled_()
    })
  }
```

Perfect, now we can build basic Async support on this alone. 

```js
class Async {
  static waitForOthers() {
    Scheduler.add(Fiber.current)
    Fiber.suspend()
  }
  static run(fn) {
    Scheduler.add(fn)
    Scheduler.add(Fiber.current)
    Scheduler.runNextScheduled_()
  }
}
```

You'll see `run` looks like *exactly* what we described above. `wait` just inserts us at the end of the scheduling queue and then suspends (trusting the Scheduler to resume us later when `runNextScheduled_()` is called).  This assumes the function we are calling will do so at some point (use any of the async `IO` calls, `Timer.sleep`, etc.)

And on then top of this foundation you can build higher level abstractions.  Given the following small `Task` class the sample code at the very beginning now works.

```js
class Task {
    static run(fn) { Task.new(fn).run() }
    construct new(fn) { _fn = fn }
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
            if (list.any { |task| task.isRunning }) {
                Async.waitForOthers()
            } else {
                break
            }
        }
    }
}
```

### The Proposal

**Minimally**

- Add support for `add(fiber)` to the Scheduler API

```js
  static add(callable) {
    if (callable is Fiber) {
      __scheduled.add(callable)
      return
    }
    // ...
  }
```

This is the foundational thing needed for building these patterns on top of the existing Scheduler.  If this was added then I think many types of async patterns could be explored outside the scope of the CLI to see what works best.

**If we take it a step further**

- Add an `Async` class to wrap up common async patterns 
- or consider adding these methods to Scheduler directly

```js
class Async {
  static waitForOthers() {
    Scheduler.add(Fiber.current)
    Fiber.suspend()
  }
  static run(fn) {
    Scheduler.add(fn)
    Scheduler.add(Fiber.current)
    Scheduler.runNextScheduled_()
  }
}
```

**Peripheral**

I think higher level abstractions - such as the `Task` class shown here could be provided by libraries outside of the CLI Core - again all depending on how minimal we wish to keep CLI.

CC @ChayimFriedman2 Related to our prior discussion.