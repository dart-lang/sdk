// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Verifies that compiler can remove bounds checks when told by pragma.

import 'package:expect/expect.dart';
import 'package:vm/testing/il_matchers.dart';

import 'dart:typed_data';

@pragma('vm:never-inline')
@pragma('vm:testing:print-flow-graph')
int direct_uint8list_has_bounds_check(Uint8List list) {
  int result = 0;
  for (int i = 0; i < 10; i++) {
    result = list[i];
  }
  return result;
}

@pragma('vm:unsafe:no-bounds-checks')
@pragma('vm:never-inline')
@pragma('vm:testing:print-flow-graph')
int direct_uint8list_no_bounds_check(Uint8List list) {
  int result = 0;
  for (int i = 0; i < 10; i++) {
    result = list[i];
  }
  return result;
}

@pragma('vm:prefer-inline')
int helper_uint8list_no_pragma(Uint8List list) {
  int result = 0;
  for (int i = 0; i < 10; i++) {
    result = list[i];
  }
  return result;
}

@pragma('vm:never-inline')
@pragma('vm:testing:print-flow-graph')
int inlined_uint8list_has_bounds_check(Uint8List list) {
  if (helper_uint8list_no_pragma(list) == 42) {
    return 42;
  }
  return 0;
}

@pragma('vm:prefer-inline')
@pragma('vm:unsafe:no-bounds-checks')
int helper_uint8list_pragma(Uint8List list) {
  int result = 0;
  for (int i = 0; i < 10; i++) {
    result = list[i];
  }
  return result;
}

// For whatever reason, this passes even without the fix, despite real-world
// example in CFE (AbstractScanner.select) as well as a test in the VM
// (runtime/vm/compiler/backend/redundancy_elimination_test.cc,
// BoundsCheckElimination_Pragma_Inline) needs the fix.
@pragma('vm:never-inline')
@pragma('vm:testing:print-flow-graph')
int inlined_uint8list_no_bounds_check(Uint8List list, bool b) {
  if (b) {
    return helper_uint8list_pragma(list);
  } else {
    return helper_uint8list_pragma(list) + 42;
  }
}

@pragma('vm:never-inline')
@pragma('vm:testing:print-flow-graph')
int direct_string_has_bounds_check(String s) {
  int result = 0;
  for (int i = 0; i < 10; i++) {
    result = s.codeUnitAt(i);
  }
  return result;
}

@pragma('vm:unsafe:no-bounds-checks')
@pragma('vm:never-inline')
@pragma('vm:testing:print-flow-graph')
int direct_string_no_bounds_check(String s) {
  int result = 0;
  for (int i = 0; i < 10; i++) {
    result = s.codeUnitAt(i);
  }
  return result;
}

@pragma('vm:prefer-inline')
int helper_string_no_pragma(String s) {
  int result = 0;
  for (int i = 0; i < 10; i++) {
    result = s.codeUnitAt(i);
  }
  return result;
}

@pragma('vm:never-inline')
@pragma('vm:testing:print-flow-graph')
int inlined_string_has_bounds_check(String s) {
  if (helper_string_no_pragma(s) == 42) {
    return 42;
  }
  return 0;
}

@pragma('vm:prefer-inline')
@pragma('vm:unsafe:no-bounds-checks')
int helper_string_pragma(String s) {
  int result = 0;
  for (int i = 0; i < 10; i++) {
    result = s.codeUnitAt(i);
  }
  return result;
}

@pragma('vm:never-inline')
@pragma('vm:testing:print-flow-graph')
int inlined_string_no_bounds_check(String s) {
  if (helper_string_pragma(s) == 42) {
    return 42;
  }
  return 0;
}

void main() {
  // Uint8List access directly.
  direct_uint8list_has_bounds_check(new Uint8List(20));
  direct_uint8list_no_bounds_check(new Uint8List(20));

  // Uint8List access via inlined function.
  inlined_uint8list_has_bounds_check(new Uint8List(20));
  inlined_uint8list_no_bounds_check(
      new Uint8List(20), new Uint8List(20).toString().length.isEven);

  // String access directly.
  direct_string_has_bounds_check(new Uint8List(20).toString());
  direct_string_no_bounds_check(new Uint8List(20).toString());

  // String access via inlined function.
  inlined_string_has_bounds_check(new Uint8List(20).toString());
  inlined_string_no_bounds_check(new Uint8List(20).toString());
}

void extractAllInstructions(dynamic data, List<String> into) {
  if (data is Map) {
    for (var entry in data.entries) {
      if (entry.key == "o" && entry.value is String) {
        into.add(entry.value);
      } else {
        extractAllInstructions(entry.value, into);
      }
    }
  } else if (data is List) {
    for (var entry in data) {
      extractAllInstructions(entry, into);
    }
  } else {
    if (data is int || data is String) {
      // ok
    } else {
      print("Notice: Unhandled data: ${data.runtimeType}: $data");
    }
  }
}

bool hasCheckBounds(FlowGraph graph) {
  List<String> ils = [];
  extractAllInstructions(graph.blocks(), ils);
  for (String il in ils) {
    if (il == "GenericCheckBound") return true;
  }
  return false;
}

void matchIL$direct_uint8list_has_bounds_check(FlowGraph graph) {
  Expect.isTrue(hasCheckBounds(graph), "should have bounds checks");
}

void matchIL$direct_uint8list_no_bounds_check(FlowGraph graph) {
  Expect.isFalse(hasCheckBounds(graph), "should not have bounds checks");
}

void matchIL$inlined_uint8list_has_bounds_check(FlowGraph graph) {
  Expect.isTrue(hasCheckBounds(graph), "should have bounds checks");
}

void matchIL$inlined_uint8list_no_bounds_check(FlowGraph graph) {
  Expect.isFalse(hasCheckBounds(graph), "should not have bounds checks");
}

void matchIL$direct_string_has_bounds_check(FlowGraph graph) {
  Expect.isTrue(hasCheckBounds(graph), "should have bounds checks");
}

void matchIL$direct_string_no_bounds_check(FlowGraph graph) {
  Expect.isFalse(hasCheckBounds(graph), "should not have bounds checks");
}

void matchIL$inlined_string_has_bounds_check(FlowGraph graph) {
  Expect.isTrue(hasCheckBounds(graph), "should have bounds checks");
}

void matchIL$inlined_string_no_bounds_check(FlowGraph graph) {
  Expect.isFalse(hasCheckBounds(graph), "should not have bounds checks");
}
