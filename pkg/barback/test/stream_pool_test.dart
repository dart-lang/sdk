// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library barback.test.stream_pool_test;

import 'dart:async';

import 'package:barback/src/stream_pool.dart';
import 'package:barback/src/utils.dart';
import 'package:scheduled_test/scheduled_test.dart';

import 'utils.dart';

main() {
  initConfig();

  group("buffered", () {
    test("buffers events from multiple inputs", () {
      var pool = new StreamPool<String>();

      var controller1 = new StreamController<String>();
      pool.add(controller1.stream);
      controller1.add("first");

      var controller2 = new StreamController<String>();
      pool.add(controller2.stream);
      controller2.add("second");

      // Call [toList] asynchronously to be sure that the events have been
      // buffered beforehand and aren't just being received unbuffered.
      expect(newFuture(() => pool.stream.toList()),
          completion(equals(["first", "second"])));

      pumpEventQueue().then((_) => pool.close());
    });

    test("buffers errors from multiple inputs", () {
      var pool = new StreamPool<String>();

      var controller1 = new StreamController<String>();
      pool.add(controller1.stream);
      controller1.add("first");

      var controller2 = new StreamController<String>();
      pool.add(controller2.stream);
      controller2.add("second");
      controller1.addError("third");
      controller2.addError("fourth");
      controller1.add("fifth");

      expect(newFuture(() {
        return pool.stream.transform(new StreamTransformer.fromHandlers(
            handleData: (data, sink) => sink.add(["data", data]),
            handleError: (error, stackTrace, sink) {
          sink.add(["error", error]);
        })).toList();
      }), completion(equals([
        ["data", "first"],
        ["data", "second"],
        ["error", "third"],
        ["error", "fourth"],
        ["data", "fifth"]
      ])));

      pumpEventQueue().then((_) => pool.close());
    });

    test("buffers inputs from a broadcast stream", () {
      var pool = new StreamPool<String>();
      var controller = new StreamController<String>.broadcast();
      pool.add(controller.stream);
      controller.add("first");
      controller.add("second");

      // Call [toList] asynchronously to be sure that the events have been
      // buffered beforehand and aren't just being received unbuffered.
      expect(newFuture(() => pool.stream.toList()),
          completion(equals(["first", "second"])));

      pumpEventQueue().then((_) => pool.close());
    });
  });

  group("broadcast", () {
    test("doesn't buffer inputs", () {
      var pool = new StreamPool<String>.broadcast();

      var controller1 = new StreamController<String>.broadcast();
      pool.add(controller1.stream);
      controller1.add("first");

      var controller2 = new StreamController<String>.broadcast();
      pool.add(controller2.stream);
      controller2.add("second");

      // Call [toList] asynchronously to be sure that the events have been
      // buffered beforehand and aren't just being received unbuffered.
      expect(newFuture(() => pool.stream.toList()), completion(isEmpty));

      pumpEventQueue().then((_) => pool.close());
    });

    test("doesn't buffer errors", () {
      var pool = new StreamPool<String>.broadcast();

      var controller1 = new StreamController<String>.broadcast();
      pool.add(controller1.stream);
      controller1.addError("first");

      var controller2 = new StreamController<String>.broadcast();
      pool.add(controller2.stream);
      controller2.addError("second");

      expect(newFuture(() {
        return pool.stream.transform(new StreamTransformer.fromHandlers(
            handleData: (data, sink) => sink.add(data),
            handleError: (error, stackTrace, sink) { sink.add(error); }))
            .toList();
      }), completion(isEmpty));

      pumpEventQueue().then((_) => pool.close());
    });

    test("doesn't buffer inputs from a buffered stream", () {
      var pool = new StreamPool<String>.broadcast();
      var controller = new StreamController<String>();
      pool.add(controller.stream);
      controller.add("first");
      controller.add("second");

      expect(pumpEventQueue().then((_) => pool.stream.toList()),
          completion(isEmpty));

      pumpEventQueue().then((_) => pool.close());
    });
  });

  for (var type in ["buffered", "broadcast"]) {
    group(type, () {
      var pool;
      var bufferedController;
      var bufferedStream;
      var bufferedSyncController;
      var broadcastController;
      var broadcastStream;
      var broadcastSyncController;

      setUp(() {
        if (type == "buffered") {
          pool = new StreamPool<String>();
        } else {
          pool = new StreamPool<String>.broadcast();
        }

        bufferedController = new StreamController<String>();
        pool.add(bufferedController.stream);

        bufferedSyncController = new StreamController<String>(sync: true);
        pool.add(bufferedSyncController.stream);

        broadcastController = new StreamController<String>.broadcast();
        pool.add(broadcastController.stream);

        broadcastSyncController =
          new StreamController<String>.broadcast(sync: true);
        pool.add(broadcastSyncController.stream);
      });

      test("emits events to a listener", () {
        expect(pool.stream.toList(), completion(equals(["first", "second"])));

        bufferedController.add("first");
        broadcastController.add("second");
        pumpEventQueue().then((_) => pool.close());
      });

      test("emits sync events synchronously", () {
        var events = [];
        pool.stream.listen(events.add);

        bufferedSyncController.add("first");
        expect(events, equals(["first"]));

        broadcastSyncController.add("second");
        expect(events, equals(["first", "second"]));
      });

      test("emits async events asynchronously", () {
        var events = [];
        pool.stream.listen(events.add);

        bufferedController.add("first");
        broadcastController.add("second");
        expect(events, isEmpty);

        expect(pumpEventQueue().then((_) => events),
            completion(equals(["first", "second"])));
      });

      test("doesn't emit events from removed streams", () {
        expect(pool.stream.toList(), completion(equals(["first", "third"])));

        bufferedController.add("first");
        expect(pumpEventQueue().then((_) {
          pool.remove(bufferedController.stream);
          bufferedController.add("second");
        }).then((_) {
          broadcastController.add("third");
          return pumpEventQueue();
        }).then((_) {
          pool.remove(broadcastController.stream);
          broadcastController.add("fourth");
          pool.close();
        }), completes);
      });
    });
  }
}
