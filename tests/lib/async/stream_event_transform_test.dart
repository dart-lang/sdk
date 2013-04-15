// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library stream_event_transform_test;

import "package:expect/expect.dart";
import 'dart:async';
import '../../../pkg/unittest/lib/unittest.dart';
import 'event_helper.dart';

void handleData(int data, EventSink<int> sink) {
  sink.addError("$data");
  sink.add(data + 1);
}

void handleError(error, EventSink<int> sink) {
  String value = error;
  int data = int.parse(value);
  sink.add(data);
  sink.addError("${data + 1}");
}

void handleDone(EventSink<int> sink) {
  sink.add(99);
  sink.close();
}

class EventTransformer extends StreamEventTransformer<int,int> {
  void handleData(int data, EventSink<int> sink) {
    sink.addError("$data");
    sink.add(data + 1);
  }

  void handleError(String value, EventSink<int> sink) {
    int data = int.parse(value);
    sink.add(data);
    sink.addError("${data + 1}");
  }

  void handleDone(EventSink<int> sink) {
    sink.add(99);
    sink.close();
  }
}

main() {
  {
    StreamController c = new StreamController();
    Events expected = new Events()..error("0")..add(1)
                                  ..error("1")..add(2)
                                  ..add(3)..error("4")
                                  ..add(99)..close();
    Events input = new Events()..add(0)..add(1)..error("3")..close();
    Events actual = new Events.capture(
        c.stream.transform(new EventTransformer()));
    actual.onDone(() {
      Expect.listEquals(expected.events, actual.events);
    });
    input.replay(c);
  }

  {
    StreamController c = new StreamController();
    Events expected = new Events()..error("0")..add(1)
                                  ..error("1")..add(2)
                                  ..add(3)..error("4")
                                  ..add(99)..close();
    Events input = new Events()..add(0)..add(1)..error("3")..close();
    Events actual = new Events.capture(
        c.stream.transform(new StreamTransformer(
            handleData: handleData,
            handleError: handleError,
            handleDone: handleDone
        )));
    actual.onDone(() {
      Expect.listEquals(expected.events, actual.events);
    });
    input.replay(c);
  }
}
