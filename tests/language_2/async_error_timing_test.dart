// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'package:expect/expect.dart';
import 'package:async_helper/async_helper.dart';

class AsyncTracker {
  int runningAsyncs = 0;
  List expectedEvents;
  final List actualEvents = [];

  AsyncTracker() {
    asyncStart();
  }

  void start(String event) {
    actualEvents.add("start $event");
    runningAsyncs++;
  }

  void stop(String event) {
    actualEvents.add("stop $event");
    if (--runningAsyncs == 0) {
      Expect.listEquals(expectedEvents, actualEvents);
      asyncEnd();
    }
  }

  void add(e) {
    actualEvents.add(e);
  }
}

void test1() {
  var tracker = new AsyncTracker();

  Future foo() async {
    tracker.add("error-foo");
    throw "foo";
  }

  tracker.start("micro1");
  scheduleMicrotask(() {
    tracker.start("micro2");
    scheduleMicrotask(() {
      tracker.stop("micro2");
    });
    tracker.stop("micro1");
  });

  tracker.start("foo");
  foo().catchError((e) {
    tracker.stop("foo");
  });
  tracker.start("micro3");
  scheduleMicrotask(() {
    tracker.stop("micro3");
  });

  tracker.expectedEvents = [
    "start micro1",
    "start foo",
    "error-foo",
    "start micro3",
    "start micro2",
    "stop micro1",
    "stop foo",
    "stop micro3",
    "stop micro2",
  ];
}

void test2() {
  var tracker = new AsyncTracker();

  Future bar() async {
    tracker.add("await null");
    await null;
    tracker.add("error-bar");
    throw "bar";
  }

  tracker.start("micro1");
  scheduleMicrotask(() {
    tracker.start("micro2");
    scheduleMicrotask(() {
      tracker.start("micro3");
      scheduleMicrotask(() {
        tracker.stop("micro3");
      });
      tracker.stop("micro2");
    });
    tracker.stop("micro1");
  });

  tracker.start("bar");
  bar().catchError((e) {
    tracker.stop("bar");
  });
  tracker.start("micro4");
  scheduleMicrotask(() {
    tracker.start("micro5");
    scheduleMicrotask(() {
      tracker.stop("micro5");
    });
    tracker.stop("micro4");
  });

  tracker.expectedEvents = [
    "start micro1",
    "start bar",
    "await null",
    "start micro4",
    "start micro2",
    "stop micro1",
    "error-bar",
    "stop bar",
    "start micro5",
    "stop micro4",
    "start micro3",
    "stop micro2",
    "stop micro5",
    "stop micro3",
  ];
}

void test3() {
  var tracker = new AsyncTracker();

  Future gee() async {
    tracker.add("error-gee");
    return new Future.error("gee");
  }

  tracker.start("micro1");
  scheduleMicrotask(() {
    tracker.start("micro2");
    scheduleMicrotask(() {
      tracker.stop("micro2");
    });
    tracker.stop("micro1");
  });

  tracker.start("gee");
  gee().catchError((e) {
    tracker.stop("gee");
  });
  tracker.start("micro3");
  scheduleMicrotask(() {
    tracker.stop("micro3");
  });

  tracker.expectedEvents = [
    "start micro1",
    "start gee",
    "error-gee",
    "start micro3",
    "start micro2",
    "stop micro1",
    "stop gee",
    "stop micro3",
    "stop micro2",
  ];
}

void test4() {
  var tracker = new AsyncTracker();

  Future toto() async {
    tracker.add("await null");
    await null;
    tracker.add("error-toto");
    return new Future.error("toto");
  }

  tracker.start("micro1");
  scheduleMicrotask(() {
    tracker.start("micro2");
    scheduleMicrotask(() {
      tracker.start("micro3");
      scheduleMicrotask(() {
        tracker.stop("micro3");
      });
      tracker.stop("micro2");
    });
    tracker.stop("micro1");
  });

  tracker.start("toto");
  toto().catchError((e) {
    tracker.stop("toto");
  });
  tracker.start("micro4");
  scheduleMicrotask(() {
    tracker.start("micro5");
    scheduleMicrotask(() {
      tracker.stop("micro5");
    });
    tracker.stop("micro4");
  });

  tracker.expectedEvents = [
    "start micro1",
    "start toto",
    "await null",
    "start micro4",
    "start micro2",
    "stop micro1",
    "error-toto",
    "start micro5",
    "stop micro4",
    "start micro3",
    "stop micro2",
    "stop toto",
    "stop micro5",
    "stop micro3",
  ];
}

void test5() {
  var tracker = new AsyncTracker();

  Future foo() async {
    tracker.add("throw");
    throw "foo";
  }

  bar() async {
    tracker.start('micro');
    scheduleMicrotask(() {
      tracker.stop('micro');
    });
    try {
      tracker.start('foo');
      await foo();
    } catch (e) {
      tracker.stop('foo');
    }
    tracker.stop("bar");
  }

  tracker.start('bar');

  tracker.expectedEvents = [
    "start bar",
    "start micro",
    "start foo",
    "throw",
    "stop micro",
    "stop foo",
    "stop bar",
  ];
}

main() {
  asyncStart();
  test1();
  test2();
  test3();
  test4();
  asyncEnd();
}
