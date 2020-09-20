// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import "package:expect/expect.dart";
import "package:async_helper/async_helper.dart";

extension StreamRepeatLatestExtension<T extends Object> on Stream<T> {
  Stream<T> repeatLatest() {
    var done = false;
    T? latest = null;
    var currentListeners = <MultiStreamController<T>>{};
    this.listen((event) {
      latest = event;
      for (var listener in [...currentListeners]) listener.addSync(event);
    }, onError: (Object error, StackTrace stack) {
      for (var listener in [...currentListeners])
        listener.addErrorSync(error, stack);
    }, onDone: () {
      done = true;
      latest = null;
      for (var listener in currentListeners) listener.closeSync();
      currentListeners.clear();
    });
    return Stream.multi((controller) {
      if (done) {
        controller.close();
        return;
      }
      currentListeners.add(controller);
      var latestValue = latest;
      if (latestValue != null) controller.add(latestValue);
      controller.onCancel = () {
        currentListeners.remove(controller);
      };
    });
  }
}

void main() {
  asyncStart();
  testStreamsIndependent();
  asyncTest(testStreamNonOverlap);
  asyncTest(testRepeatLatest);
  asyncTest(testIncorrectUse);
  asyncEnd();
}

/// Test that the streams can provide different events.
void testStreamsIndependent() {
  var log = <String>[];
  var index = 0;
  var multi = Stream<List<int>>.multi((c) {
    var id = ++index;
    log.add("$id");
    for (var i = 0; i < id + 1; i++) {
      c.add([id, i]);
    }
    c.close();
  });
  void logList(List<int> l) {
    log.add("${l.first}-${l.last}");
  }

  asyncStart();
  Future.wait([multi.forEach(logList), multi.forEach(logList)])
      .whenComplete(() {
    Expect.equals(7, log.length);
    for (var element in ["1", "1-0", "1-1", "2", "2-0", "2-1", "2-2"]) {
      Expect.isTrue(log.contains(element));
    }
    asyncEnd();
  });
}

/// Test that stream can be listened to again after having no listener.
Future<void> testStreamNonOverlap() async {
  var completer = Completer<Object?>();
  MultiStreamController<int>? controller;
  var stream = Stream<int>.multi((c) {
    controller = c;
    c.onCancel = () {
      controller = null;
      if (!completer.isCompleted) completer.complete(null);
    };
  });
  for (var i in [1, 2, 3]) {
    var log = <Object?>[];
    var subscription = stream.listen((v) {
      log.add(v);
      if (!completer.isCompleted) completer.complete(v);
    }, onError: (e, s) {
      log.add(e);
      if (!completer.isCompleted) completer.complete(e);
    }, onDone: () {
      log.add(null);
      if (!completer.isCompleted) completer.complete(null);
    });
    Expect.isNotNull(controller);
    controller!.add(1);
    await completer.future;
    Expect.listEquals([1], log);

    completer = Completer();
    controller!.add(2);
    await completer.future;
    Expect.listEquals([1, 2], log);

    completer = Completer();
    if (i == 2) {
      subscription.cancel();
    } else {
      controller!.close();
    }
    await completer.future;
    Expect.listEquals([1, 2, if (i != 2) null], log);
  }
}

/// Test that the [Stream.repeatLatest] example code works as described.
Future<void> testRepeatLatest() async {
  var c = StreamController<int>();
  var repStream = c.stream.repeatLatest();

  var f1 = repStream.first;
  c.add(1);
  var v1 = await f1;
  Expect.equals(1, v1);

  var f2 = repStream.take(2).toList();
  c.add(2);
  var l2 = await f2;
  Expect.listEquals([1, 2], l2);

  var f3 = repStream.take(2).toList();
  c.add(3);
  var l3 = await f3;
  Expect.listEquals([2, 3], l3);
}

// Test that errors are thrown when required,
// and use after cancel is ignored.
Future<void> testIncorrectUse() async {
  {
    var lock = Completer();
    var lock2 = Completer();
    var stream = Stream.multi((c) async {
      c.add(2);
      await lock.future;
      Expect.isTrue(!c.hasListener);
      c.add(2);
      c.addError("Error");
      c.close();
      // No adding after close.
      Expect.throws<StateError>(() => c.add(3));
      Expect.throws<StateError>(() => c.addSync(3));
      Expect.throws<StateError>(() => c.addError("E"));
      Expect.throws<StateError>(() => c.addErrorSync("E"));
      Expect.throws<StateError>(() => c.addStream(Stream.empty()));
      lock2.complete();
    });
    await for (var v in stream) {
      Expect.equals(2, v);
      break; // Cancels subscription.
    }
    lock.complete();
    await lock2.future;
  }

  {
    var lock = Completer();
    var lock2 = Completer();
    var stream = Stream.multi((c) async {
      c.add(2);
      await lock.future;
      Expect.isTrue(!c.hasListener);
      c.addSync(2);
      c.addErrorSync("Error");
      c.closeSync();
      // No adding after close.
      Expect.throws<StateError>(() => c.add(3));
      Expect.throws<StateError>(() => c.addSync(3));
      Expect.throws<StateError>(() => c.addError("E"));
      Expect.throws<StateError>(() => c.addErrorSync("E"));
      Expect.throws<StateError>(() => c.addStream(Stream.empty()));
      lock2.complete();
    });
    await for (var v in stream) {
      Expect.equals(2, v);
      break; // Cancels subscription.
    }
    lock.complete();
    await lock2.future;
  }

  {
    var stream = Stream.multi((c) async {
      var c2 = StreamController();
      c.addStream(c2.stream);
      // Now adding stream, cannot add events at the same time (for now!).
      Expect.throws<StateError>(() => c.add(1));
      Expect.throws<StateError>(() => c.addSync(1));
      Expect.throws<StateError>(() => c.addError("Error"));
      Expect.throws<StateError>(() => c.addErrorSync("Error"));
      Expect.throws<StateError>(() => c.close());
      Expect.throws<StateError>(() => c.closeSync());
      await c2.close();
      c.add(42);
      c.close();
    });
    await for (var v in stream) {
      Expect.equals(42, v);
    }
  }
}
