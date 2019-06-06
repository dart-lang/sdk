// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Tests for how variables and scoping work with for elements.
import 'package:expect/expect.dart';

import 'utils.dart';

String global = "global";

void main() {
  testClosure();
  Test().shadowing();
  Test().reuseVariable();
}

void testClosure() {
  var closures = [];
  capture(callback) {
    closures.add(callback);
    return callback();
  }

  reset() {
    closures.clear();
  }

  // Close over for-in loop variable in element.
  var list = [for (var i in [0, 1]) () => i];
  Expect.equals(0, list[0]());
  Expect.equals(1, list[1]());

  // Close over loop variable in element.
  list = [for (var i = 0; i < 2; i++) () => i];
  Expect.equals(0, list[0]());
  Expect.equals(1, list[1]());

  // Close over variable in condition expression.
  var list2 = [for (var i = 0; capture(() => i++) < 2;) i];
  Expect.equals(1, closures[0]());
  Expect.equals(2, closures[1]());
  Expect.listEquals([1, 2], list2);
  reset();

  // Close over variable in increment expression.
  var list3 = [for (var i = 0; i < 2; capture(() => i++)) i];
  Expect.equals(1, closures[0]());
  Expect.equals(2, closures[1]());
  Expect.listEquals([0, 1], list3);
  reset();
}

class TestBase {
  String inherited = "inherited";
}

class Test extends TestBase {
  static String staticField = "static field";

  String field = "field";

  void shadowing() {
    var local = "local";

    // C-style for.
    var list = [
      for (var global = "for"; global != null; global = null) global
    ];
    Expect.listEquals(["for"], list);

    list = [
      for (var staticField = "for"; staticField != null; staticField = null)
        staticField
    ];
    Expect.listEquals(["for"], list);

    list = [
      for (var field = "for"; field != null; field = null) field
    ];
    Expect.listEquals(["for"], list);

    list = [
      for (var inherited = "for"; inherited != null; inherited = null) inherited
    ];
    Expect.listEquals(["for"], list);

    list = [
      for (var local = "for"; local != null; local = null) local
    ];
    Expect.listEquals(["for"], list);

    list = [
      for (var outer = "outer"; outer != null; outer = null)
        for (var outer = "for"; outer != null; outer = null)
          outer
    ];
    Expect.listEquals(["for"], list);

    // For-in.
    list = [for (var global in ["for"]) global];
    Expect.listEquals(["for"], list);

    list = [for (var staticField in ["for"]) staticField];
    Expect.listEquals(["for"], list);

    list = [for (var field in ["for"]) field];
    Expect.listEquals(["for"], list);

    list = [for (var inherited in ["for"]) inherited];
    Expect.listEquals(["for"], list);

    list = [for (var local in ["for"]) local];
    Expect.listEquals(["for"], list);

    list = [for (var outer in ["outer"]) for (var outer in ["for"]) outer];
    Expect.listEquals(["for"], list);
  }

  void reuseVariable() {
    var local = "local";

    // C-style for.
    var list = [
      for (global = "for"; global == "for"; global = "after") global
    ];
    Expect.listEquals(["for"], list);
    Expect.equals("after", global);
    global = "global";

    list = [
      for (staticField = "for"; staticField == "for"; staticField = "after")
        staticField
    ];
    Expect.listEquals(["for"], list);
    Expect.equals("after", staticField);
    staticField = "staticField";

    list = [
      for (field = "for"; field == "for"; field = "after") field
    ];
    Expect.listEquals(["for"], list);
    Expect.equals("after", field);
    field = "field";

    list = [
      for (inherited = "for"; inherited == "for"; inherited = "after") inherited
    ];
    Expect.listEquals(["for"], list);
    Expect.equals("after", inherited);
    inherited = "inherited";

    list = [
      for (local = "for"; local == "for"; local = "after") local
    ];
    Expect.listEquals(["for"], list);
    Expect.equals("after", local);
    local = "local";

    list = [
      for (var outer = "outer"; outer == "outer"; outer = "outer after") ...[
        for (outer = "for"; outer == "for"; outer = "after") outer,
        outer
      ]
    ];
    Expect.listEquals(["for", "after"], list);

    // For-in.
    list = [for (global in ["for"]) global];
    Expect.listEquals(["for"], list);
    Expect.equals("for", global);
    global = "global";

    list = [for (staticField in ["for"]) staticField];
    Expect.listEquals(["for"], list);
    Expect.equals("for", staticField);
    staticField = "staticField";

    list = [for (field in ["for"]) field];
    Expect.listEquals(["for"], list);
    Expect.equals("for", field);
    field = "field";

    list = [for (inherited in ["for"]) inherited];
    Expect.listEquals(["for"], list);
    Expect.equals("for", inherited);
    inherited = "inherited";

    list = [for (local in ["for"]) local];
    Expect.listEquals(["for"], list);
    Expect.equals("for", local);
    local = "local";

    list = [
      for (var outer in ["outer"]) ...[
        for (outer in ["for"]) outer,
        outer
      ]
    ];
    Expect.listEquals(["for", "for"], list);
  }
}
