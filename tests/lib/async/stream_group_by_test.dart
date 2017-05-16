// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library stream_group_by_test;

import "dart:async";

import "package:expect/expect.dart";
import "package:async_helper/async_helper.dart";

int len(x) => x.length;
String wrap(x) => "[$x]";

void main() {
  asyncStart();
  // groupBy.
  test("splits", () async {
    var grouped = stringStream.groupBy<int>(len);
    var byLength = <int, Future<List<String>>>{};
    await for (GroupedEvents<int, String> group in grouped) {
      byLength[group.key] = group.values.toList();
    }
    Expect.listEquals([1, 2, 4, 3], byLength.keys.toList());
    expectCompletes(byLength[1], ["a", "b"]);
    expectCompletes(byLength[2], ["ab"]);
    expectCompletes(byLength[3], ["abe", "lea"]);
    expectCompletes(byLength[4], ["abel", "bell", "able", "abba"]);
  });

  test("empty", () async {
    var grouped = emptyStream.groupBy<int>(len);
    var byLength = <int, Future<List<String>>>{};
    await for (GroupedEvents<int, String> group in grouped) {
      byLength[group.key] = group.values.toList();
    }
    Expect.isTrue(byLength.isEmpty);
  });

  test("single group", () async {
    var grouped = repeatStream(5, "x").groupBy<int>(len);
    var byLength = <int, Future<List<String>>>{};
    await for (GroupedEvents<int, String> group in grouped) {
      byLength[group.key] = group.values.toList();
    }
    Expect.listEquals([1], byLength.keys.toList());
    expectCompletes(byLength[1], ["x", "x", "x", "x", "x"]);
  });

  test("with error", () async {
    var grouped = stringErrorStream(3).groupBy<int>(len);
    var byLength = <int, Future<List<String>>>{};
    bool caught = false;
    try {
      await for (GroupedEvents<int, String> group in grouped) {
        byLength[group.key] = group.values.toList();
      }
    } catch (e) {
      Expect.equals("BAD", e);
      caught = true;
    }
    Expect.isTrue(caught);
    Expect.listEquals([1, 2, 4], byLength.keys.toList());
    expectCompletes(byLength[1], ["a", "b"]);
    expectCompletes(byLength[2], ["ab"]);
    expectCompletes(byLength[4], ["abel"]);
  });

  // For comparison with later tests.
  test("no pause or cancel", () async {
    var grouped = stringStream.groupBy<int>(len);
    var events = [];
    var futures = [];
    await grouped.forEach((sg) {
      var key = sg.key;
      var sub;
      sub = sg.values.listen((value) {
        events.add("$key:$value");
      });
      var c = new Completer();
      futures.add(c.future);
      sub.onDone(() {
        c.complete(null);
      });
    });
    await Future.wait(futures);
    Expect.listEquals([
      "1:a",
      "2:ab",
      "1:b",
      "4:abel",
      "3:abe",
      "4:bell",
      "4:able",
      "4:abba",
      "3:lea",
    ], events);
  });

  test("pause on group", () async {
    // Pausing the individial group's stream just makes it buffer.
    var grouped = stringStream.groupBy<int>(len);
    var events = [];
    var futures = [];
    await grouped.forEach((sg) {
      var key = sg.key;
      var sub;
      sub = sg.values.listen((value) {
        events.add("$key:$value");
        if (value == "a") {
          // Pause until a later timer event, which is after stringStream
          // has delivered all events.
          sub.pause(new Future.delayed(Duration.ZERO, () {}));
        }
      });
      var c = new Completer();
      futures.add(c.future);
      sub.onDone(() {
        c.complete(null);
      });
    });
    await Future.wait(futures);
    Expect.listEquals([
      "1:a",
      "2:ab",
      "4:abel",
      "3:abe",
      "4:bell",
      "4:able",
      "4:abba",
      "3:lea",
      "1:b"
    ], events);
  });

  test("pause on group-stream", () async {
    // Pausing the stream returned by groupBy stops everything.
    var grouped = stringStream.groupBy<int>(len);
    var events = [];
    var futures = [];
    var done = new Completer();
    var sub;
    sub = grouped.listen((sg) {
      var key = sg.key;
      futures.add(sg.values.forEach((value) {
        events.add("$key:$value");
        if (value == "a") {
          // Pause everything until a later timer event.
          asyncStart();
          var eventSnapshot = events.toList();
          var delay = new Future.delayed(Duration.ZERO).then((_) {
            // No events added.
            Expect.listEquals(eventSnapshot, events);
            asyncEnd(); // Ensures this test has run.
          });
          sub.pause(delay);
        }
      }));
    });
    sub.onDone(() {
      done.complete(null);
    });
    futures.add(done.future);
    await Future.wait(futures);
    Expect.listEquals([
      "1:a",
      "2:ab",
      "1:b",
      "4:abel",
      "3:abe",
      "4:bell",
      "4:able",
      "4:abba",
      "3:lea",
    ], events);
  });

  test("cancel on group", () async {
    // Cancelling the individial group's stream just makes that one stop.
    var grouped = stringStream.groupBy<int>(len);
    var events = [];
    var futures = [];
    await grouped.forEach((sg) {
      var key = sg.key;
      var sub;
      var c = new Completer();
      sub = sg.values.listen((value) {
        events.add("$key:$value");
        if (value == "bell") {
          // Pause until a later timer event, which is after stringStream
          // has delivered all events.
          sub.cancel();
          c.complete(null);
        }
      });
      futures.add(c.future);
      sub.onDone(() {
        c.complete(null);
      });
    });
    await Future.wait(futures);
    Expect.listEquals([
      "1:a",
      "2:ab",
      "1:b",
      "4:abel",
      "3:abe",
      "4:bell",
      "3:lea",
    ], events);
  });

  test("cancel on group-stream", () async {
    // Cancel the stream returned by groupBy ends everything.
    var grouped = stringStream.groupBy<int>(len);
    var events = [];
    var futures = [];
    var done = new Completer();
    var sub;
    sub = grouped.listen((sg) {
      var key = sg.key;
      futures.add(sg.values.forEach((value) {
        events.add("$key:$value");
        if (value == "bell") {
          // Pause everything until a later timer event.
          futures.add(sub.cancel());
          done.complete();
        }
      }));
    });
    futures.add(done.future);
    await Future.wait(futures);
    Expect.listEquals([
      "1:a",
      "2:ab",
      "1:b",
      "4:abel",
      "3:abe",
      "4:bell",
    ], events);
  });

  asyncEnd();
}

expectCompletes(future, result) {
  asyncStart();
  future.then((v) {
    if (result is List) {
      Expect.listEquals(result, v);
    } else {
      Expect.equals(v, result);
    }
    asyncEnd();
  }, onError: (e, s) {
    Expect.fail("$e\n$s");
  });
}

void test(name, func) {
  asyncStart();
  func().then((_) {
    asyncEnd();
  }, onError: (e, s) {
    Expect.fail("$name: $e\n$s");
  });
}

var strings = const [
  "a",
  "ab",
  "b",
  "abel",
  "abe",
  "bell",
  "able",
  "abba",
  "lea"
];

Stream<String> get stringStream async* {
  for (var string in strings) {
    yield string;
  }
}

Stream get emptyStream async* {}

Stream repeatStream(int count, value) async* {
  for (var i = 0; i < count; i++) {
    yield value;
  }
}

// Just some valid stack trace.
var stack = StackTrace.current;

Stream<String> stringErrorStream(int errorAfter) async* {
  for (int i = 0; i < strings.length; i++) {
    yield strings[i];
    if (i == errorAfter) {
      // Emit error, but continue afterwards.
      yield* new Future.error("BAD", stack).asStream();
    }
  }
}

Stream intStream(int count, [int start = 0]) async* {
  for (int i = 0; i < count; i++) {
    yield start++;
  }
}

Stream timerStream(int count, Duration interval) async* {
  for (int i = 0; i < count; i++) {
    await new Future.delayed(interval);
    yield i;
  }
}
