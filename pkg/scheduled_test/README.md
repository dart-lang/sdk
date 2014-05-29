A package for writing readable tests of asynchronous behavior.

This package works by building up a queue of asynchronous tasks called a
"schedule", then executing those tasks in order. This allows the tests to
read like synchronous, linear code, despite executing asynchronously.

The `scheduled_test` package is built on top of `unittest`, and should be
imported instead of `unittest`. It provides its own version of [group],
[test], and [setUp], and re-exports most other APIs from unittest.

To schedule a task, call the [schedule] function. For example:

```dart
import 'package:scheduled_test/scheduled_test.dart';

void main() {
  test('writing to a file and reading it back should work', () {
    schedule(() {
      // The schedule won't proceed until the returned Future has
      // completed.
      return new File("output.txt").writeAsString("contents");
    });

    schedule(() {
      return new File("output.txt").readAsString().then((contents) {
        // The normal unittest matchers can still be used.
        expect(contents, equals("contents"));
      });
    });
  });
}
```

## Setting up and tearing down

The `scheduled_test` package defines its own [setUp] method that works just
like the one in `unittest`. Tasks can be scheduled in [setUp]; they'll be
run before the tasks scheduled by tests in that group. [currentSchedule] is
also set in the [setUp] callback.

This package doesn't have an explicit `tearDown` method. Instead, the
[currentSchedule.onComplete] and [currentSchedule.onException] task queues
can have tasks scheduled during [setUp]. For example:

```dart
import 'package:scheduled_test/scheduled_test.dart';

void main() {
  var tempDir;
  setUp(() {
    schedule(() {
      return createTempDir().then((dir) {
        tempDir = dir;
      });
    });

    currentSchedule.onComplete.schedule(() => deleteDir(tempDir));
  });

  // ...
}
```

## Passing values between tasks

It's often useful to use values computed in one task in other tasks that are
scheduled afterwards. There are two ways to do this. The most
straightforward is just to define a local variable and assign to it. For
example:

```dart
import 'package:scheduled_test/scheduled_test.dart';

void main() {
  test('computeValue returns 12', () {
    var value;

    schedule(() {
      return computeValue().then((computedValue) {
        value = computedValue;
      });
    });

    schedule(() => expect(value, equals(12)));
  });
}
```

However, this doesn't scale well, especially when you start factoring out
calls to [schedule] into library methods. For that reason, [schedule]
returns a [Future] that will complete to the same value as the return
value of the task. For example:

```dart
import 'package:scheduled_test/scheduled_test.dart';

void main() {
  test('computeValue returns 12', () {
    var valueFuture = schedule(() => computeValue());
    schedule(() {
      valueFuture.then((value) => expect(value, equals(12)));
    });
  });
}
```

## Out-of-Band Callbacks

Sometimes your tests will have callbacks that don't fit into the schedule.
It's important that errors in these callbacks are still registered, though,
and that [Schedule.onException] and [Schedule.onComplete] still run after
they finish. When using `unittest`, you wrap these callbacks with
`expectAsyncN`; when using `scheduled_test`, you use [wrapAsync] or
[wrapFuture].

[wrapAsync] has two important functions. First, any errors that occur in it
will be passed into the [Schedule] instead of causing the whole test to
crash. They can then be handled by [Schedule.onException] and
[Schedule.onComplete]. Second, a task queue isn't considered finished until
all of its [wrapAsync]-wrapped functions have been called. This ensures that
[Schedule.onException] and [Schedule.onComplete] will always run after all
the test code in the main queue.

Note that the [completes], [completion], and [throws] matchers use
[wrapAsync] internally, so they're safe to use in conjunction with scheduled
tests.

Here's an example of a test using [wrapAsync] to catch errors thrown in the
callback of a fictional `startServer` function:

```dart
import 'package:scheduled_test/scheduled_test.dart';

void main() {
  test('sendRequest sends a request', () {
    startServer(wrapAsync((request) {
      expect(request.body, equals('payload'));
      request.response.close();
    }));

    schedule(() => sendRequest('payload'));
  });
}
```

[wrapFuture] works similarly to [wrapAsync], but instead of wrapping a
single callback it wraps a whole [Future] chain. Like [wrapAsync], it
ensures that the task queue doesn't complete until the out-of-band chain has
finished, and that any errors in the chain are piped back into the scheduled
test. For example:

```dart
import 'package:scheduled_test/scheduled_test.dart';

void main() {
  test('sendRequest sends a request', () {
    wrapFuture(server.nextRequest.then((request) {
      expect(request.body, equals('payload'));
      expect(request.headers['content-type'], equals('text/plain'));
    }));

    schedule(() => sendRequest('payload'));
  });
}
```

## Timeouts

`scheduled_test` has a built-in timeout of 5 seconds (configurable via
[Schedule.timeout]). This timeout is aware of the structure of the schedule;
this means that it will reset for each task in a queue, when moving between
queues, or almost any other sort of interaction with [currentSchedule]. As
long as the [Schedule] knows your test is making some sort of progress, it
won't time out.

If a single task might take a long time, you can also manually tell the
[Schedule] that it's making progress by calling [Schedule.heartbeat], which
will reset the timeout whenever it's called.

[pub]: http://pub.dartlang.org
[pkg]: http://pub.dartlang.org/packages/scheduled_test
