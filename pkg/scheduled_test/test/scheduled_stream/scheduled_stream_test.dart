// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library scheduled_test.scheduled_stream_test;

import 'dart:async';

import 'package:scheduled_test/scheduled_stream.dart';
import 'package:unittest/unittest.dart';
import 'package:scheduled_test/src/utils.dart';

void main() {
  group("a completed stream with no elements", () {
    var stream;
    setUp(() {
      var controller = new StreamController()..close();
      stream = new ScheduledStream(controller.stream);

      // Wait for [stream] to register the wrapped stream's close event.
      return pumpEventQueue();
    });

    test("throws an error for [next]", () {
      expect(stream.next(), throwsStateError);
    });

    test("returns false for [hasNext]", () {
      expect(stream.hasNext, completion(isFalse));
    });

    test("emittedValues is empty", () {
      expect(stream.emittedValues, isEmpty);
    });

    test("allValues is empty", () {
      expect(stream.allValues, isEmpty);
    });

    test("close() does nothing", () {
      // This just shouldn't throw any exceptions.
      stream.close();
    });

    test("fork() returns a closed stream", () {
      var fork = stream.fork();
      expect(fork.emittedValues, isEmpty);
      expect(fork.allValues, isEmpty);
      expect(fork.next(), throwsStateError);
      expect(fork.hasNext, completion(isFalse));
    });
  });

  group("a stream that completes later with no elements", () {
    var controller;
    var stream;
    setUp(() {
      controller = new StreamController();
      stream = new ScheduledStream(controller.stream);
    });

    test("throws an error for [next]", () {
      expect(stream.next(), throwsStateError);
      return new Future(controller.close);
    });

    test("returns false for [hasNext]", () {
      expect(stream.hasNext, completion(isFalse));
      return new Future(controller.close);
    });

    test("emittedValues is empty", () {
      expect(stream.emittedValues, isEmpty);
    });

    test("allValues is empty", () {
      expect(stream.allValues, isEmpty);
    });

    test("fork() returns a stream that closes when the controller is closed",
        () {
      var fork = stream.fork();
      expect(fork.emittedValues, isEmpty);
      expect(fork.allValues, isEmpty);

      var nextComplete = false;
      expect(fork.next().whenComplete(() {
        nextComplete = true;
      }), throwsStateError);

      var hasNextComplete = false;
      expect(fork.hasNext.whenComplete(() {
        hasNextComplete = true;
      }), completion(isFalse));

      // Pump the event queue to give [next] and [hasNext] a chance to
      // (incorrectly) fire.
      return pumpEventQueue().then((_) {
        expect(nextComplete, isFalse);
        expect(hasNextComplete, isFalse);

        controller.close();
      });
    });
  });

  test("forking and then closing a stream closes the fork", () {
    var stream = new ScheduledStream(new StreamController().stream);
    var fork = stream.fork();
    expect(fork.emittedValues, isEmpty);
    expect(fork.allValues, isEmpty);

    var nextComplete = false;
    expect(fork.next().whenComplete(() {
      nextComplete = true;
    }), throwsStateError);

    var hasNextComplete = false;
    expect(fork.hasNext.whenComplete(() {
      hasNextComplete = true;
    }), completion(isFalse));

    // Pump the event queue to give [next] and [hasNext] a chance to
    // (incorrectly) fire.
    return pumpEventQueue().then((_) {
      expect(nextComplete, isFalse);
      expect(hasNextComplete, isFalse);

      stream.close();
    });
  });

  group("a completed stream with several values", () {
    var stream;
    setUp(() {
      var controller = new StreamController<int>()
          ..add(1)..add(2)..add(3)..close();
      stream = new ScheduledStream<int>(controller.stream);

      return pumpEventQueue();
    });

    test("next() returns each value then throws an error", () {
      return stream.next().then((value) {
        expect(value, equals(1));
        return stream.next();
      }).then((value) {
        expect(value, equals(2));
        return stream.next();
      }).then((value) {
        expect(value, equals(3));
        expect(stream.next(), throwsStateError);
      });
    });

    test("parallel next() calls are disallowed", () {
      expect(stream.next(), completion(equals(1)));
      expect(stream.next(), throwsStateError);
    });

    test("parallel hasNext calls are allowed", () {
      expect(stream.hasNext, completion(isTrue));
      expect(stream.hasNext, completion(isTrue));
    });

    test("hasNext returns true until there are no more values", () {
      return stream.hasNext.then((hasNext) {
        expect(hasNext, isTrue);
        return stream.next();
      }).then((_) => stream.hasNext).then((hasNext) {
        expect(hasNext, isTrue);
        return stream.next();
      }).then((_) => stream.hasNext).then((hasNext) {
        expect(hasNext, isTrue);
        return stream.next();
      }).then((_) => expect(stream.hasNext, completion(isFalse)));
    });

    test("emittedValues returns the values that have been emitted", () {
      expect(stream.emittedValues, isEmpty);

      return stream.next().then((_) {
        expect(stream.emittedValues, equals([1]));
        return stream.next();
      }).then((_) {
        expect(stream.emittedValues, equals([1, 2]));
        return stream.next();
      }).then((_) {
        expect(stream.emittedValues, equals([1, 2, 3]));
      });
    });

    test("allValues returns all values that the inner stream emitted", () {
      expect(stream.allValues, equals([1, 2, 3]));
    });

    test("closing the stream means it doesn't emit additional events", () {
      return stream.next().then((_) {
        stream.close();
        expect(stream.next(), throwsStateError);
      });
    });

    test("a fork created before any values are emitted emits all values", () {
      var fork = stream.fork();
      return fork.next().then((value) {
        expect(value, equals(1));
        return fork.next();
      }).then((value) {
        expect(value, equals(2));
        return fork.next();
      }).then((value) {
        expect(value, equals(3));
        expect(fork.next(), throwsStateError);
      });
    });

    test("a fork created after some values are emitted emits remaining values",
        () {
      var fork;
      return stream.next().then((_) {
        fork = stream.fork();
        return fork.next();
      }).then((value) {
        expect(value, equals(2));
        return fork.next();
      }).then((value) {
        expect(value, equals(3));
        expect(fork.next(), throwsStateError);
      });
    });

    test("a fork doesn't push forward its parent stream", () {
      var fork = stream.fork();
      return fork.next().then((_) {
        expect(stream.next(), completion(equals(1)));
      });
    });

    test("closing a fork doesn't close its parent stream", () {
      var fork = stream.fork();
      fork.close();
      expect(stream.next(), completion(equals(1)));
    });

    test("closing a stream closes its forks immediately", () {
      var fork = stream.fork();
      return stream.next().then((_) {
        stream.close();
        expect(fork.next(), throwsStateError);
      });
    });
  });

  group("a stream with several values added asynchronously", () {
    var stream;
    setUp(() {
      var controller = new StreamController<int>();
      stream = new ScheduledStream<int>(controller.stream);

      pumpEventQueue().then((_) {
        controller.add(1);
        return pumpEventQueue();
      }).then((_) {
        controller.add(2);
        return pumpEventQueue();
      }).then((_) {
        controller.add(3);
        return pumpEventQueue();
      }).then((_) {
        controller.close();
      });
    });

    test("next() returns each value then throws an error", () {
      return stream.next().then((value) {
        expect(value, equals(1));
        return stream.next();
      }).then((value) {
        expect(value, equals(2));
        return stream.next();
      }).then((value) {
        expect(value, equals(3));
        expect(stream.next(), throwsStateError);
      });
    });

    test("parallel next() calls are disallowed", () {
      expect(stream.next(), completion(equals(1)));
      expect(stream.next(), throwsStateError);
    });

    test("parallel hasNext calls are allowed", () {
      expect(stream.hasNext, completion(isTrue));
      expect(stream.hasNext, completion(isTrue));
    });

    test("hasNext returns true until there are no more values", () {
      return stream.hasNext.then((hasNext) {
        expect(hasNext, isTrue);
        return stream.next();
      }).then((_) => stream.hasNext).then((hasNext) {
        expect(hasNext, isTrue);
        return stream.next();
      }).then((_) => stream.hasNext).then((hasNext) {
        expect(hasNext, isTrue);
        return stream.next();
      }).then((_) => expect(stream.hasNext, completion(isFalse)));
    });

    test("emittedValues returns the values that have been emitted", () {
      expect(stream.emittedValues, isEmpty);

      return stream.next().then((_) {
        expect(stream.emittedValues, equals([1]));
        return stream.next();
      }).then((_) {
        expect(stream.emittedValues, equals([1, 2]));
        return stream.next();
      }).then((_) {
        expect(stream.emittedValues, equals([1, 2, 3]));
      });
    });

    test("allValues returns all values that the inner stream emitted", () {
      expect(stream.allValues, isEmpty);

      return stream.next().then((_) {
        expect(stream.allValues, equals([1]));
        return stream.next();
      }).then((_) {
        expect(stream.allValues, equals([1, 2]));
        return stream.next();
      }).then((_) {
        expect(stream.allValues, equals([1, 2, 3]));
      });
    });

    test("closing the stream means it doesn't emit additional events", () {
      return stream.next().then((_) {
        stream.close();
        expect(stream.next(), throwsStateError);
      });
    });

    test("a fork created before any values are emitted emits all values", () {
      var fork = stream.fork();
      return fork.next().then((value) {
        expect(value, equals(1));
        return fork.next();
      }).then((value) {
        expect(value, equals(2));
        return fork.next();
      }).then((value) {
        expect(value, equals(3));
        expect(fork.next(), throwsStateError);
      });
    });

    test("a fork created after some values are emitted emits remaining values",
        () {
      var fork;
      return stream.next().then((_) {
        fork = stream.fork();
        return fork.next();
      }).then((value) {
        expect(value, equals(2));
        return fork.next();
      }).then((value) {
        expect(value, equals(3));
        expect(fork.next(), throwsStateError);
      });
    });

    test("a fork doesn't push forward its parent stream", () {
      var fork = stream.fork();
      return fork.next().then((_) {
        expect(stream.next(), completion(equals(1)));
      });
    });

    test("closing a fork doesn't close its parent stream", () {
      var fork = stream.fork();
      fork.close();
      expect(stream.next(), completion(equals(1)));
    });

    test("closing a stream closes its forks immediately", () {
      var fork = stream.fork();
      return stream.next().then((_) {
        stream.close();
        expect(fork.next(), throwsStateError);
      });
    });
  });
}
