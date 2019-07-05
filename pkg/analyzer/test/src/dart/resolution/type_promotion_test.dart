// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/dart/analysis/experiments.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'driver_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(TypePromotionTest);
  });
}

@reflectiveTest
class TypePromotionTest extends DriverResolutionTest {
  @override
  AnalysisOptionsImpl get analysisOptions =>
      AnalysisOptionsImpl()..enabledExperiments = [EnableString.non_nullable];

  /// Assert that the identifier at the [search] string is a local variable
  /// or a formal parameter, and has its declared type, not promoted to a more
  /// specific type.
  void assertNotPromoted(String search) {
    var node = findNode.simple(search);
    var element = node.staticElement as VariableElement;
    expect(node.staticType, element.type, reason: search);
  }

  /// Assert that the identifier at the [search] has the [expectedType].
  void assertPromoted(String search, String expectedType) {
    var node = findNode.simple(search);
    assertElementTypeString(node.staticType, expectedType);
  }

  Future<void> resolveCode(String code) async {
    addTestFile(code);
    await resolveTestFile();
  }

  test_assignment() async {
    await resolveCode(r'''
f(Object x) {
  if (x is String) {
    x = 42;
    x; // 1
  }
}
''');
    assertNotPromoted('x; // 1');
  }

  test_binaryExpression_ifNull() async {
    await resolveCode(r'''
void f(Object x) {
  ((x is num) || (throw 1)) ?? ((x is int) || (throw 2));
  x; // 1
}
''');
    assertPromoted('x; // 1', 'num');
  }

  test_binaryExpression_ifNull_rightUnPromote() async {
    await resolveCode(r'''
void f(Object x, Object y, Object z) {
  if (x is int) {
    x; // 1
    y ?? (x = z);
    x; // 2
  }
}
''');
    assertPromoted('x; // 1', 'int');
    assertNotPromoted('x; // 2');
  }

  test_conditional_both() async {
    await resolveCode(r'''
void f(bool b, Object x) {
  b ? ((x is num) || (throw 1)) : ((x is int) || (throw 2));
  x; // 1
}
''');
    assertPromoted('x; // 1', 'num');
  }

  test_conditional_else() async {
    await resolveCode(r'''
void f(bool b, Object x) {
  b ? 0 : ((x is int) || (throw 2));
  x; // 1
}
''');
    assertNotPromoted('x; // 1');
  }

  test_conditional_then() async {
    await resolveCode(r'''
void f(bool b, Object x) {
  b ? ((x is num) || (throw 1)) : 0;
  x; // 1
}
''');
    assertNotPromoted('x; // 1');
  }

  test_do_condition_isNotType() async {
    await resolveCode(r'''
void f(Object x) {
  do {
    x; // 1
  } while (x is! String);
  x; // 2
}
''');
    assertNotPromoted('x; // 1');
    assertPromoted('x; // 2', 'String');
  }

  test_do_condition_isType() async {
    await resolveCode(r'''
void f(Object x) {
  do {
    x; // 1
  } while (x is String);
  x; // 2
}
''');
    assertNotPromoted('x; // 1');
    assertNotPromoted('x; // 2');
  }

  test_do_outerIsType() async {
    await resolveCode(r'''
void f(bool b, Object x) {
  if (x is String) {
    do {
      x; // 1
    } while (b);
    x; // 2
  }
}
''');
    assertPromoted('x; // 1', 'String');
    assertPromoted('x; // 2', 'String');
  }

  test_do_outerIsType_loopAssigned_body() async {
    await resolveCode(r'''
void f(bool b, Object x) {
  if (x is String) {
    do {
      x; // 1
      x = x.length;
    } while (b);
    x; // 2
  }
}
''');
    assertNotPromoted('x; // 1');
    assertNotPromoted('x; // 2');
  }

  test_do_outerIsType_loopAssigned_condition() async {
    await resolveCode(r'''
void f(bool b, Object x) {
  if (x is String) {
    do {
      x; // 1
      x = x.length;
    } while (x != 0);
    x; // 2
  }
}
''');
    assertNotPromoted('x != 0');
    assertNotPromoted('x; // 1');
    assertNotPromoted('x; // 2');
  }

  test_do_outerIsType_loopAssigned_condition2() async {
    await resolveCode(r'''
void f(bool b, Object x) {
  if (x is String) {
    do {
      x; // 1
    } while ((x = 1) != 0);
    x; // 2
  }
}
''');
    assertNotPromoted('x; // 1');
    assertNotPromoted('x; // 2');
  }

  test_for_outerIsType() async {
    await resolveCode(r'''
void f(bool b, Object x) {
  if (x is String) {
    for (; b;) {
      x; // 1
    }
    x; // 2
  }
}
''');
    assertPromoted('x; // 1', 'String');
    assertPromoted('x; // 2', 'String');
  }

  test_for_outerIsType_loopAssigned_body() async {
    await resolveCode(r'''
void f(bool b, Object x) {
  if (x is String) {
    for (; b;) {
      x; // 1
      x = 42;
    }
    x; // 2
  }
}
''');
    assertNotPromoted('x; // 1');
    assertNotPromoted('x; // 2');
  }

  test_for_outerIsType_loopAssigned_condition() async {
    await resolveCode(r'''
void f(Object x) {
  if (x is String) {
    for (; (x = 42) > 0;) {
      x; // 1
    }
    x; // 2
  }
}
''');
    assertNotPromoted('x; // 1');
    assertNotPromoted('x; // 2');
  }

  test_for_outerIsType_loopAssigned_updaters() async {
    await resolveCode(r'''
void f(bool b, Object x) {
  if (x is String) {
    for (; b; x = 42) {
      x; // 1
    }
    x; // 2
  }
}
''');
    assertNotPromoted('x; // 1');
    assertNotPromoted('x; // 2');
  }

  test_forEach_outerIsType_loopAssigned() async {
    await resolveCode(r'''
void f(Object x) {
  Object v1;
  if (x is String) {
    for (var _ in (v1 = [0, 1, 2])) {
      x; // 1
      x = 42;
    }
    x; // 2
  }
}
''');
    assertNotPromoted('x; // 1');
    assertNotPromoted('x; // 2');
  }

  test_functionExpression_isType() async {
    await resolveCode(r'''
void f() {
  void g(Object x) {
    if (x is String) {
      x; // 1
    }
    x = 42;
  }
}
''');
    assertPromoted('x; // 1', 'String');
  }

  test_functionExpression_isType_mutatedInClosure2() async {
    await resolveCode(r'''
void f() {
  void g(Object x) {
    if (x is String) {
      x; // 1
    }
    
    void h() {
      x = 42;
    }
  }
}
''');
    assertNotPromoted('x; // 1');
  }

  test_functionExpression_outerIsType_assignedOutside() async {
    await resolveCode(r'''
void f(Object x) {
  void Function() g;
  
  if (x is String) {
    x; // 1

    g = () {
      x; // 2
    };
  }

  x = 42;
  x; // 3
  g();
}
''');
    assertPromoted('x; // 1', 'String');
    assertNotPromoted('x; // 2');
    assertNotPromoted('x; // 3');
  }

  test_if_combine_empty() async {
    await resolveCode(r'''
main(bool b, Object v) {
  if (b) {
    v is int || (throw 1);
  } else {
    v is String || (throw 2);
  }
  v; // 3
}
''');
    assertNotPromoted('v; // 3');
  }

  test_if_conditional_isNotType() async {
    await resolveCode(r'''
f(bool b, Object v) {
  if (b ? (v is! int) : (v is! num)) {
    v; // 1
  } else {
    v; // 2
  }
  v; // 3
}
''');
    assertNotPromoted('v; // 1');
    assertPromoted('v; // 2', 'num');
    assertNotPromoted('v; // 3');
  }

  test_if_conditional_isType() async {
    await resolveCode(r'''
f(bool b, Object v) {
  if (b ? (v is int) : (v is num)) {
    v; // 1
  } else {
    v; // 2
  }
  v; // 3
}
''');
    assertPromoted('v; // 1', 'num');
    assertNotPromoted('v; // 2');
    assertNotPromoted('v; // 3');
  }

  test_if_isNotType() async {
    await resolveCode(r'''
main(v) {
  if (v is! String) {
    v; // 1
  } else {
    v; // 2
  }
  v; // 3
}
''');
    assertNotPromoted('v; // 1');
    assertPromoted('v; // 2', 'String');
    assertNotPromoted('v; // 3');
  }

  test_if_isNotType_return() async {
    await resolveCode(r'''
main(v) {
  if (v is! String) return;
  v; // ref
}
''');
    assertPromoted('v; // ref', 'String');
  }

  test_if_isNotType_throw() async {
    await resolveCode(r'''
main(v) {
  if (v is! String) throw 42;
  v; // ref
}
''');
    assertPromoted('v; // ref', 'String');
  }

  test_if_isType() async {
    await resolveCode(r'''
main(v) {
  if (v is String) {
    v; // 1
  } else {
    v; // 2
  }
  v; // 3
}
''');
    assertPromoted('v; // 1', 'String');
    assertNotPromoted('v; // 2');
    assertNotPromoted('v; // 3');
  }

  test_if_isType_thenNonBoolean() async {
    await resolveCode(r'''
f(Object x) {
  if ((x is String) != 3) {
    x; // 1
  }
}
''');
    assertNotPromoted('x; // 1');
  }

  test_if_logicalNot_isType() async {
    await resolveCode(r'''
main(v) {
  if (!(v is String)) {
    v; // 1
  } else {
    v; // 2
  }
  v; // 3
}
''');
    assertNotPromoted('v; // 1');
    assertPromoted('v; // 2', 'String');
    assertNotPromoted('v; // 3');
  }

  test_if_then_isNotType_return() async {
    await resolveCode(r'''
void f(bool b, Object x) {
  if (b) {
    if (x is! String) return;
  }
  x; // 1
}
''');
    assertNotPromoted('x; // 1');
  }

  test_logicalOr_throw() async {
    await resolveCode(r'''
main(v) {
  v is String || (throw 42);
  v; // ref
}
''');
    assertPromoted('v; // ref', 'String');
  }

  test_potentiallyMutatedInClosure() async {
    await resolveCode(r'''
f(Object x) {
  localFunction() {
    x = 42;
  }

  if (x is String) {
    localFunction();
    x; // 1
  }
}
''');
    assertNotPromoted('x; // 1');
  }

  test_potentiallyMutatedInScope() async {
    await resolveCode(r'''
f(Object x) {
  if (x is String) {
    x; // 1
  }

  x = 42;
}
''');
    assertPromoted('x; // 1', 'String');
  }

  test_switch_outerIsType_assignedInCase() async {
    await resolveCode(r'''
void f(int e, Object x) {
  if (x is String) {
    switch (e) {
      L: case 1:
        x; // 1
        break;
      case 2: // no label
        x; // 2
        break;
      case 3:
        x = 42;
        continue L;
    }
    x; // 3
  }
}
''');
    assertNotPromoted('x; // 1');
    assertPromoted('x; // 2', 'String');
    assertNotPromoted('x; // 3');
  }

  test_tryCatch_assigned_body() async {
    await resolveCode(r'''
void f(Object x) {
  if (x is! String) return;
  x; // 1
  try {
    x = 42;
    g(); // might throw
    if (x is! String) return;
    x; // 2
  } catch (_) {}
  x; // 3
}

void g() {}
''');
    assertPromoted('x; // 1', 'String');
    assertPromoted('x; // 2', 'String');
    assertNotPromoted('x; // 3');
  }

  test_tryCatch_isNotType_exit_body() async {
    await resolveCode(r'''
void f(Object x) {
  try {
    if (x is! String) return;
    x; // 1
  } catch (_) {}
  x; // 2
}

void g() {}
''');
    assertPromoted('x; // 1', 'String');
    assertNotPromoted('x; // 2');
  }

  test_tryCatch_isNotType_exit_body_catch() async {
    await resolveCode(r'''
void f(Object x) {
  try {
    if (x is! String) return;
    x; // 1
  } catch (_) {
    if (x is! String) return;
    x; // 2
  }
  x; // 3
}

void g() {}
''');
    assertPromoted('x; // 1', 'String');
    assertPromoted('x; // 2', 'String');
    assertPromoted('x; // 3', 'String');
  }

  test_tryCatch_isNotType_exit_body_catchRethrow() async {
    await resolveCode(r'''
void f(Object x) {
  try {
    if (x is! String) return;
    x; // 1
  } catch (_) {
    x; // 2
    rethrow;
  }
  x; // 3
}

void g() {}
''');
    assertPromoted('x; // 1', 'String');
    assertNotPromoted('x; // 2');
    assertPromoted('x; // 3', 'String');
  }

  test_tryCatch_isNotType_exit_catch() async {
    await resolveCode(r'''
void f(Object x) {
  try {
  } catch (_) {
    if (x is! String) return;
    x; // 1
  }
  x; // 2
}

void g() {}
''');
    assertPromoted('x; // 1', 'String');
    assertNotPromoted('x; // 2');
  }

  test_tryCatchFinally_outerIsType() async {
    await resolveCode(r'''
void f(Object x) {
  if (x is String) {
    try {
      x; // 1
    } catch (_) {
      x; // 2
    } finally {
      x; // 3
    }
    x; // 4
  }
}

void g() {}
''');
    assertPromoted('x; // 1', 'String');
    assertPromoted('x; // 2', 'String');
    assertPromoted('x; // 3', 'String');
    assertPromoted('x; // 4', 'String');
  }

  test_tryCatchFinally_outerIsType_assigned_body() async {
    await resolveCode(r'''
void f(Object x) {
  if (x is String) {
    try {
      x; // 1
      x = 42;
      g();
    } catch (_) {
      x; // 2
    } finally {
      x; // 3
    }
    x; // 4
  }
}

void g() {}
''');
    assertPromoted('x; // 1', 'String');
    assertNotPromoted('x; // 2');
    assertNotPromoted('x; // 3');
    assertNotPromoted('x; // 4');
  }

  test_tryCatchFinally_outerIsType_assigned_catch() async {
    await resolveCode(r'''
void f(Object x) {
  if (x is String) {
    try {
      x; // 1
    } catch (_) {
      x; // 2
      x = 42;
    } finally {
      x; // 3
    }
    x; // 4
  }
}
''');
    assertPromoted('x; // 1', 'String');
    assertPromoted('x; // 2', 'String');
    assertNotPromoted('x; // 3');
    assertNotPromoted('x; // 4');
  }

  test_tryFinally_outerIsType_assigned_body() async {
    await resolveCode(r'''
void f(Object x) {
  if (x is String) {
    try {
      x; // 1
      x = 42;
    } finally {
      x; // 2
    }
    x; // 3
  }
}
''');
    assertPromoted('x; // 1', 'String');
    assertNotPromoted('x; // 2');
    assertNotPromoted('x; // 3');
  }

  test_tryFinally_outerIsType_assigned_finally() async {
    await resolveCode(r'''
void f(Object x) {
  if (x is String) {
    try {
      x; // 1
    } finally {
      x; // 2
      x = 42;
    }
    x; // 3
  }
}
''');
    assertPromoted('x; // 1', 'String');
    assertPromoted('x; // 2', 'String');
    assertNotPromoted('x; // 3');
  }

  test_while_condition_false() async {
    await resolveCode(r'''
void f(Object x) {
  while (x is! String) {
    x; // 1
  }
  x; // 2
}
''');
    assertNotPromoted('x; // 1');
    assertPromoted('x; // 2', 'String');
  }

  test_while_condition_true() async {
    await resolveCode(r'''
void f(Object x) {
  while (x is String) {
    x; // 1
  }
  x; // 2
}
''');
    assertPromoted('x; // 1', 'String');
    assertNotPromoted('x; // 2');
  }

  test_while_outerIsType() async {
    await resolveCode(r'''
void f(bool b, Object x) {
  if (x is String) {
    while (b) {
      x; // 1
    }
    x; // 2
  }
}
''');
    assertPromoted('x; // 1', 'String');
    assertPromoted('x; // 2', 'String');
  }

  test_while_outerIsType_loopAssigned_body() async {
    await resolveCode(r'''
void f(bool b, Object x) {
  if (x is String) {
    while (b) {
      x; // 1
      x = x.length;
    }
    x; // 2
  }
}
''');
    assertNotPromoted('x; // 1');
    assertNotPromoted('x; // 2');
  }

  test_while_outerIsType_loopAssigned_condition() async {
    await resolveCode(r'''
void f(bool b, Object x) {
  if (x is String) {
    while (x != 0) {
      x; // 1
      x = x.length;
    }
    x; // 2
  }
}
''');
    assertNotPromoted('x != 0');
    assertNotPromoted('x; // 1');
    assertNotPromoted('x; // 2');
  }
}
