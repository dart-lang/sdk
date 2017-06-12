// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';
import 'package:async_helper/async_helper.dart';
import 'dart:async';
import 'event_helper.dart';

class DecrementingTransformerSink implements EventSink {
  final outSink;
  DecrementingTransformerSink(this.outSink);

  void add(int i) => outSink.add(i - 1);
  void addError(int e, [st]) => outSink.addError(e - 1, st);
  void close() => outSink.close();
}

class FutureWaitingTransformerSink implements EventSink {
  final outSink;
  final closeFuture;
  FutureWaitingTransformerSink(this.outSink, this.closeFuture);

  void add(Future future) {
    future.then(outSink.add);
  }

  void addError(Future e, [st]) {
    e.then((val) {
      outSink.addError(val, st);
    });
  }

  void close() {
    closeFuture.whenComplete(outSink.close);
  }
}

class ZoneTransformerSink implements EventSink {
  final outSink;
  ZoneTransformerSink(this.outSink);

  void add(_) {
    outSink.add(Zone.current);
  }

  void addError(_, [st]) {
    outSink.add(Zone.current);
  }

  void close() {
    outSink.add(Zone.current);
    outSink.close();
  }
}

class TypeChangingSink implements EventSink<int> {
  final EventSink<String> outSink;
  TypeChangingSink(this.outSink);

  void add(int data) {
    outSink.add(data.toString());
  }

  void addError(error, [st]) {
    outSink.addError(error, st);
  }

  void close() {
    outSink.close();
  }
}

class SinkTransformer<S, T> implements StreamTransformer<S, T> {
  final Function sinkMapper;
  SinkTransformer(this.sinkMapper);

  Stream<T> bind(Stream<S> stream) {
    return new Stream<T>.eventTransformed(stream, sinkMapper);
  }
}

get currentStackTrace {
  try {
    throw 0;
  } catch (e, st) {
    return st;
  }
}

// In most cases the callback will be 'asyncEnd'. Errors are reported
// asynchronously. We want to give them time to surface before reporting
// asynchronous tests as done.
void delayCycles(callback, int nbCycles) {
  if (nbCycles == 0) {
    callback();
    return;
  }
  Timer.run(() {
    delayCycles(callback, nbCycles - 1);
  });
}

main() {
  {
    // Simple test: use the SinkTransformer (using the Stream.eventTransformed
    // constructor) to transform a sequence of numbers. This is basically
    // similar to a map.
    asyncStart();
    new Stream.fromIterable([1, 2, 3])
        .transform(new SinkTransformer(
            (sink) => new DecrementingTransformerSink(sink)))
        .toList()
        .then((list) {
      Expect.listEquals([0, 1, 2], list);
      asyncEnd();
    });
  }

  {
    // Similar test as above: but this time also transform errors. Also
    // checks that the stack trace is correctly passed through.
    asyncStart();
    var controller;
    var events = [];
    var stackTrace = currentStackTrace;
    controller = new StreamController(onListen: () {
      controller.add(499);
      controller.addError(42, stackTrace);
      controller.close();
    });
    controller.stream
        .transform(new SinkTransformer(
            (sink) => new DecrementingTransformerSink(sink)))
        .listen((data) {
      events.add(data);
    }, onError: (e, st) {
      events.add(e);
      events.add(st);
    }, onDone: () {
      Expect.listEquals([498, 41, stackTrace], events);
      asyncEnd();
    });
  }

  {
    // Test that the output sink of the transformer can be used asynchronously.
    asyncStart();
    var controller;
    var events = [];
    var stackTrace = currentStackTrace;
    var completer1 = new Completer();
    var completer2 = new Completer();
    var completer3 = new Completer();
    var closeCompleter = new Completer();
    controller = new StreamController(onListen: () {
      controller.add(completer1.future);
      controller.addError(completer2.future, stackTrace);
      controller.add(completer3.future);
      controller.close();
    });
    controller.stream
        .transform(new SinkTransformer((sink) =>
            new FutureWaitingTransformerSink(sink, closeCompleter.future)))
        .listen((data) {
      events.add(data);
    }, onError: (e, st) {
      events.add(e);
      events.add(st);
    }, onDone: () {
      Expect.listEquals(["error2", stackTrace, "future3", "future1"], events);
      asyncEnd();
    });
    Timer.run(() {
      completer2.complete("error2");
      Timer.run(() {
        completer3.complete("future3");
        Timer.run(() {
          completer1.complete("future1");
          scheduleMicrotask(closeCompleter.complete);
        });
      });
    });
  }

  {
    // Test that the output sink of the transformer can be used asynchronously
    // and that events are paused if necessary.
    asyncStart();
    var controller;
    var events = [];
    var stackTrace = currentStackTrace;
    var completer1 = new Completer.sync();
    var completer2 = new Completer.sync();
    var completer3 = new Completer.sync();
    var closeCompleter = new Completer();
    controller = new StreamController(onListen: () {
      controller.add(completer1.future);
      controller.addError(completer2.future, stackTrace);
      controller.add(completer3.future);
      controller.close();
    });
    var subscription;
    completer1.future.then((_) {
      Expect.isTrue(subscription.isPaused);
    });
    completer2.future.then((_) {
      Expect.isTrue(subscription.isPaused);
    });
    completer3.future.then((_) {
      Expect.isTrue(subscription.isPaused);
    });
    subscription = controller.stream
        .transform(new SinkTransformer((sink) =>
            new FutureWaitingTransformerSink(sink, closeCompleter.future)))
        .listen((data) {
      Expect.isFalse(subscription.isPaused);
      events.add(data);
    }, onError: (e, st) {
      events.add(e);
      events.add(st);
    }, onDone: () {
      Expect.listEquals(["error2", stackTrace, "future3", "future1"], events);
      asyncEnd();
    });
    Timer.run(() {
      subscription.pause();
      completer2.complete("error2");
      Timer.run(() {
        subscription.resume();
        Timer.run(() {
          Expect.listEquals(["error2", stackTrace], events);
          subscription.pause();
          completer3.complete("future3");
          Timer.run(() {
            subscription.resume();
            Timer.run(() {
              Expect.listEquals(["error2", stackTrace, "future3"], events);
              subscription.pause();
              completer1.complete("future1");
              subscription.resume();
              scheduleMicrotask(closeCompleter.complete);
            });
          });
        });
      });
    });
  }

  {
    // Test that the output sink of the transformer reports errors when the
    // stream is already closed.
    asyncStart();
    var controller;
    var events = [];
    var stackTrace = currentStackTrace;
    var completer1 = new Completer();
    var completer2 = new Completer();
    var completer3 = new Completer();
    var closeCompleter = new Completer();
    controller = new StreamController(onListen: () {
      controller.add(completer1.future);
      controller.addError(completer2.future, stackTrace);
      controller.add(completer3.future);
      controller.close();
    });

    bool streamIsDone = false;
    int errorCount = 0;
    runZoned(() {
      controller.stream
          .transform(new SinkTransformer((sink) =>
              new FutureWaitingTransformerSink(sink, closeCompleter.future)))
          .listen((data) {
        events.add(data);
      }, onError: (e, st) {
        events.add(e);
        events.add(st);
      }, onDone: () {
        Expect.listEquals([], events);
        streamIsDone = true;
      });
    }, onError: (e) {
      Expect.isTrue(e is StateError);
      errorCount++;
    });
    closeCompleter.complete();
    Timer.run(() {
      Expect.isTrue(streamIsDone);
      // Each of the delayed completions should trigger an unhandled error
      // in the zone the stream was listened to.
      Timer.run(() {
        completer1.complete(499);
      });
      Timer.run(() {
        completer2.complete(42);
      });
      Timer.run(() {
        completer3.complete(99);
      });
      delayCycles(() {
        Expect.equals(3, errorCount);
        asyncEnd();
      }, 5);
    });
  }

  {
    // Test that the transformer is executed in the zone it was listened to.
    asyncStart();
    var stackTrace = currentStackTrace;
    var events = [];
    var controller;
    controller = new StreamController(onListen: () {
      // Events are added outside the zone.
      controller.add(499);
      controller.addError(42, stackTrace);
      controller.close();
    });
    Zone zone = Zone.current.fork();
    var stream = controller.stream.transform(
        new SinkTransformer((sink) => new ZoneTransformerSink(sink)));
    zone.run(() {
      stream.listen((data) {
        events.add(data);
      }, onDone: () {
        Expect.listEquals([zone, zone, zone], events);
        delayCycles(asyncEnd, 3);
      });
    });
  }

  {
    // Just make sure that the generic types are correct everywhere.
    asyncStart();
    new Stream.fromIterable([1, 2, 3])
        .transform(new SinkTransformer<int, String>(
            (sink) => new TypeChangingSink(sink)))
        .toList()
        .then((list) {
      Expect.listEquals(["1", "2", "3"], list);
      asyncEnd();
    });
  }
}
