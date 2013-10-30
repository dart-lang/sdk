// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library barback.test.stream_replayer_test;

import 'dart:async';

import 'package:barback/src/stream_replayer.dart';
import 'package:barback/src/utils.dart';
import 'package:unittest/unittest.dart';

import 'utils.dart';

main() {
  initConfig();

  test("a replay that's retrieved before the stream is finished replays the "
      "stream", () {
    var controller = new StreamController<int>();
    var replay = new StreamReplayer<int>(controller.stream).getReplay();

    controller.add(1);
    controller.add(2);
    controller.add(3);
    controller.close();

    expect(replay.toList(), completion(equals([1, 2, 3])));
  });

  test("a replay that's retrieved after the stream is finished replays the "
      "stream", () {
    var controller = new StreamController<int>();
    var replayer = new StreamReplayer<int>(controller.stream);

    controller.add(1);
    controller.add(2);
    controller.add(3);
    controller.close();

    expect(replayer.getReplay().toList(), completion(equals([1, 2, 3])));
  });

  test("multiple replays each replay the stream", () {
    var controller = new StreamController<int>();
    var replayer = new StreamReplayer<int>(controller.stream);

    var replay1 = replayer.getReplay();
    controller.add(1);
    controller.add(2);
    controller.add(3);
    controller.close();
    var replay2 = replayer.getReplay();

    expect(replay1.toList(), completion(equals([1, 2, 3])));
    expect(replay2.toList(), completion(equals([1, 2, 3])));
  });

  test("the replayed stream doesn't close until the source stream closes", () {
    var controller = new StreamController<int>();
    var replay = new StreamReplayer<int>(controller.stream).getReplay();
    var isClosed = false;
    replay.last.then((_) {
      isClosed = true;
    });

    controller.add(1);
    controller.add(2);
    controller.add(3);

    expect(pumpEventQueue().then((_) {
      expect(isClosed, isFalse);
      controller.close();
      return pumpEventQueue();
    }).then((_) {
      expect(isClosed, isTrue);
    }), completes);
  });

  test("the wrapped stream isn't opened if there are no replays", () {
    var isOpened = false;
    var controller = new StreamController<int>(onListen: () {
      isOpened = true;
    });
    var replayer = new StreamReplayer<int>(controller.stream);

    expect(pumpEventQueue().then((_) => isOpened), completion(isFalse));
  });

  test("the wrapped stream isn't opened if no replays are opened", () {
    var isOpened = false;
    var controller = new StreamController<int>(onListen: () {
      isOpened = true;
    });
    var replayer = new StreamReplayer<int>(controller.stream);
    replayer.getReplay();
    replayer.getReplay();

    expect(pumpEventQueue().then((_) => isOpened), completion(isFalse));
  });
}
