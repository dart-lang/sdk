// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/util/ast_data_extractor.dart';
import 'package:front_end/src/testing/id.dart' show ActualData, Id;
import 'package:front_end/src/testing/id_testing.dart' show DataInterpreter;
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../util/id_testing_helper.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(TypePromotionTest);
  });
}

@reflectiveTest
class TypePromotionTest {
  Future<void> resolveCode(String code) async {
    if (await checkTests(
        code,
        const _TypePromotionDataComputer(),
        FeatureSet.forTesting(
            sdkVersion: '2.2.2', additionalFeatures: [Feature.non_nullable]))) {
      fail('Failure(s)');
    }
  }

  test_assignment() async {
    await resolveCode(r'''
f(Object x) {
  if (x is String) {
    x = 42;
    x;
  }
}
''');
  }

  test_binaryExpression_ifNull() async {
    await resolveCode(r'''
void f(Object x) {
  ((x is num) || (throw 1)) ?? ((/*num*/ x is int) || (throw 2));
  /*num*/ x;
}
''');
  }

  test_binaryExpression_ifNull_rightUnPromote() async {
    await resolveCode(r'''
void f(Object x, Object y, Object z) {
  if (x is int) {
    /*int*/ x;
    y ?? (x = z);
    x;
  }
}
''');
  }

  test_conditional_both() async {
    await resolveCode(r'''
void f(bool b, Object x) {
  b ? ((x is num) || (throw 1)) : ((x is int) || (throw 2));
  /*num*/ x;
}
''');
  }

  test_conditional_else() async {
    await resolveCode(r'''
void f(bool b, Object x) {
  b ? 0 : ((x is int) || (throw 2));
  x;
}
''');
  }

  test_conditional_then() async {
    await resolveCode(r'''
void f(bool b, Object x) {
  b ? ((x is num) || (throw 1)) : 0;
  x;
}
''');
  }

  test_do_condition_isNotType() async {
    await resolveCode(r'''
void f(Object x) {
  do {
    x;
  } while (x is! String);
  /*String*/ x;
}
''');
  }

  test_do_condition_isType() async {
    await resolveCode(r'''
void f(Object x) {
  do {
    x;
  } while (x is String);
  x;
}
''');
  }

  test_do_outerIsType() async {
    await resolveCode(r'''
void f(bool b, Object x) {
  if (x is String) {
    do {
      /*String*/ x;
    } while (b);
    /*String*/ x;
  }
}
''');
  }

  test_do_outerIsType_loopAssigned_body() async {
    await resolveCode(r'''
void f(bool b, Object x) {
  if (x is String) {
    do {
      x;
      x = x.length;
    } while (b);
    x;
  }
}
''');
  }

  test_do_outerIsType_loopAssigned_condition() async {
    await resolveCode(r'''
void f(bool b, Object x) {
  if (x is String) {
    do {
      x;
      x = x.length;
    } while (x != 0);
    x;
  }
}
''');
  }

  test_do_outerIsType_loopAssigned_condition2() async {
    await resolveCode(r'''
void f(bool b, Object x) {
  if (x is String) {
    do {
      x;
    } while ((x = 1) != 0);
    x;
  }
}
''');
  }

  test_for_declaredVar() async {
    await resolveCode(r'''
void f() {
  for (Object x = g(); x is int; x = g()) {
    /*int*/ x;
  }
}
''');
  }

  test_for_outerIsType() async {
    await resolveCode(r'''
void f(bool b, Object x) {
  if (x is String) {
    for (; b;) {
      /*String*/ x;
    }
    /*String*/ x;
  }
}
''');
  }

  test_for_outerIsType_loopAssigned_body() async {
    await resolveCode(r'''
void f(bool b, Object x) {
  if (x is String) {
    for (; b;) {
      x;
      x = 42;
    }
    x;
  }
}
''');
  }

  test_for_outerIsType_loopAssigned_condition() async {
    await resolveCode(r'''
void f(Object x) {
  if (x is String) {
    for (; (x = 42) > 0;) {
      x;
    }
    x;
  }
}
''');
  }

  test_for_outerIsType_loopAssigned_updaters() async {
    await resolveCode(r'''
void f(bool b, Object x) {
  if (x is String) {
    for (; b; x = 42) {
      x;
    }
    x;
  }
}
''');
  }

  test_forEach_outerIsType_loopAssigned() async {
    await resolveCode(r'''
void f(Object x) {
  Object v1;
  if (x is String) {
    for (var _ in (v1 = [0, 1, 2])) {
      x;
      x = 42;
    }
    x;
  }
}
''');
  }

  test_functionExpression_isType() async {
    await resolveCode(r'''
void f() {
  void g(Object x) {
    if (x is String) {
      /*String*/ x;
    }
    x = 42;
  }
}
''');
  }

  test_functionExpression_isType_mutatedInClosure2() async {
    await resolveCode(r'''
void f() {
  void g(Object x) {
    if (x is String) {
      x;
    }
    
    void h() {
      x = 42;
    }
  }
}
''');
  }

  test_functionExpression_outerIsType_assignedOutside() async {
    await resolveCode(r'''
void f(Object x) {
  void Function() g;
  
  if (x is String) {
    /*String*/ x;

    g = () {
      x;
    };
  }

  x = 42;
  x;
  g();
}
''');
  }

  test_if_combine_empty() async {
    await resolveCode(r'''
main(bool b, Object v) {
  if (b) {
    v is int || (throw 1);
  } else {
    v is String || (throw 2);
  }
  v;
}
''');
  }

  test_if_conditional_isNotType() async {
    await resolveCode(r'''
f(bool b, Object v) {
  if (b ? (v is! int) : (v is! num)) {
    v;
  } else {
    /*num*/ v;
  }
  v;
}
''');
  }

  test_if_conditional_isType() async {
    await resolveCode(r'''
f(bool b, Object v) {
  if (b ? (v is int) : (v is num)) {
    /*num*/ v;
  } else {
    v;
  }
  v;
}
''');
  }

  test_if_isNotType() async {
    await resolveCode(r'''
main(v) {
  if (v is! String) {
    v;
  } else {
    /*String*/ v;
  }
  v;
}
''');
  }

  test_if_isNotType_return() async {
    await resolveCode(r'''
main(v) {
  if (v is! String) return;
  /*String*/ v;
}
''');
  }

  test_if_isNotType_throw() async {
    await resolveCode(r'''
main(v) {
  if (v is! String) throw 42;
  /*String*/ v;
}
''');
  }

  test_if_isType() async {
    await resolveCode(r'''
main(v) {
  if (v is String) {
    /*String*/ v;
  } else {
    v;
  }
  v;
}
''');
  }

  test_if_isType_thenNonBoolean() async {
    await resolveCode(r'''
f(Object x) {
  if ((x is String) != 3) {
    x;
  }
}
''');
  }

  test_if_logicalNot_isType() async {
    await resolveCode(r'''
main(v) {
  if (!(v is String)) {
    v;
  } else {
    /*String*/ v;
  }
  v;
}
''');
  }

  test_if_then_isNotType_return() async {
    await resolveCode(r'''
void f(bool b, Object x) {
  if (b) {
    if (x is! String) return;
  }
  x;
}
''');
  }

  test_logicalOr_throw() async {
    await resolveCode(r'''
main(v) {
  v is String || (throw 42);
  /*String*/ v;
}
''');
  }

  test_null_check_does_not_promote_non_nullable_type() async {
    await resolveCode(r'''
f(int x) {
  if (x != null) {
    x;
  } else {
    x;
  }
}
''');
  }

  test_null_check_promotes_nullable_type() async {
    await resolveCode(r'''
f(int? x) {
  if (x != null) {
    /*int*/ x;
  } else {
    x;
  }
}
''');
  }

  test_potentiallyMutatedInClosure() async {
    await resolveCode(r'''
f(Object x) {
  localFunction() {
    x = 42;
  }

  if (x is String) {
    localFunction();
    x;
  }
}
''');
  }

  test_potentiallyMutatedInScope() async {
    await resolveCode(r'''
f(Object x) {
  if (x is String) {
    /*String*/ x;
  }

  x = 42;
}
''');
  }

  test_switch_outerIsType_assignedInCase() async {
    await resolveCode(r'''
void f(int e, Object x) {
  if (x is String) {
    switch (e) {
      L: case 1:
        x;
        break;
      case 2: // no label
        /*String*/ x;
        break;
      case 3:
        x = 42;
        continue L;
    }
    x;
  }
}
''');
  }

  test_tryCatch_assigned_body() async {
    await resolveCode(r'''
void f(Object x) {
  if (x is! String) return;
  /*String*/ x;
  try {
    x = 42;
    g(); // might throw
    if (x is! String) return;
    /*String*/ x;
  } catch (_) {}
  x;
}

void g() {}
''');
  }

  test_tryCatch_isNotType_exit_body() async {
    await resolveCode(r'''
void f(Object x) {
  try {
    if (x is! String) return;
    /*String*/ x;
  } catch (_) {}
  x;
}

void g() {}
''');
  }

  test_tryCatch_isNotType_exit_body_catch() async {
    await resolveCode(r'''
void f(Object x) {
  try {
    if (x is! String) return;
    /*String*/ x;
  } catch (_) {
    if (x is! String) return;
    /*String*/ x;
  }
  /*String*/ x;
}

void g() {}
''');
  }

  test_tryCatch_isNotType_exit_body_catchRethrow() async {
    await resolveCode(r'''
void f(Object x) {
  try {
    if (x is! String) return;
    /*String*/ x;
  } catch (_) {
    x;
    rethrow;
  }
  /*String*/ x;
}

void g() {}
''');
  }

  test_tryCatch_isNotType_exit_catch() async {
    await resolveCode(r'''
void f(Object x) {
  try {
  } catch (_) {
    if (x is! String) return;
    /*String*/ x;
  }
  x;
}

void g() {}
''');
  }

  test_tryCatchFinally_outerIsType() async {
    await resolveCode(r'''
void f(Object x) {
  if (x is String) {
    try {
      /*String*/ x;
    } catch (_) {
      /*String*/ x;
    } finally {
      /*String*/ x;
    }
    /*String*/ x;
  }
}

void g() {}
''');
  }

  test_tryCatchFinally_outerIsType_assigned_body() async {
    await resolveCode(r'''
void f(Object x) {
  if (x is String) {
    try {
      /*String*/ x;
      x = 42;
      g();
    } catch (_) {
      x;
    } finally {
      x;
    }
    x;
  }
}

void g() {}
''');
  }

  test_tryCatchFinally_outerIsType_assigned_catch() async {
    await resolveCode(r'''
void f(Object x) {
  if (x is String) {
    try {
      /*String*/ x;
    } catch (_) {
      /*String*/ x;
      x = 42;
    } finally {
      x;
    }
    x;
  }
}
''');
  }

  test_tryFinally_outerIsType_assigned_body() async {
    await resolveCode(r'''
void f(Object x) {
  if (x is String) {
    try {
      /*String*/ x;
      x = 42;
    } finally {
      x;
    }
    x;
  }
}
''');
  }

  test_tryFinally_outerIsType_assigned_finally() async {
    await resolveCode(r'''
void f(Object x) {
  if (x is String) {
    try {
      /*String*/ x;
    } finally {
      /*String*/ x;
      x = 42;
    }
    x;
  }
}
''');
  }

  test_while_condition_false() async {
    await resolveCode(r'''
void f(Object x) {
  while (x is! String) {
    x;
  }
  /*String*/ x;
}
''');
  }

  test_while_condition_true() async {
    await resolveCode(r'''
void f(Object x) {
  while (x is String) {
    /*String*/ x;
  }
  x;
}
''');
  }

  test_while_outerIsType() async {
    await resolveCode(r'''
void f(bool b, Object x) {
  if (x is String) {
    while (b) {
      /*String*/ x;
    }
    /*String*/ x;
  }
}
''');
  }

  test_while_outerIsType_loopAssigned_body() async {
    await resolveCode(r'''
void f(bool b, Object x) {
  if (x is String) {
    while (b) {
      x;
      x = x.length;
    }
    x;
  }
}
''');
  }

  test_while_outerIsType_loopAssigned_condition() async {
    await resolveCode(r'''
void f(bool b, Object x) {
  if (x is String) {
    while (x != 0) {
      x;
      x = x.length;
    }
    x;
  }
}
''');
  }
}

class _TypePromotionDataComputer extends DataComputer<DartType> {
  const _TypePromotionDataComputer();

  @override
  DataInterpreter<DartType> get dataValidator =>
      const _TypePromotionDataInterpreter();

  @override
  void computeUnitData(
      CompilationUnit unit, Map<Id, ActualData<DartType>> actualMap) {
    _TypePromotionDataExtractor(unit.declaredElement.source.uri, actualMap)
        .run(unit);
  }
}

class _TypePromotionDataExtractor extends AstDataExtractor<DartType> {
  _TypePromotionDataExtractor(Uri uri, Map<Id, ActualData<DartType>> actualMap)
      : super(uri, actualMap);

  @override
  DartType computeNodeValue(Id id, AstNode node) {
    if (node is SimpleIdentifier && node.inGetterContext()) {
      var element = node.staticElement;
      if (element is LocalVariableElement || element is ParameterElement) {
        TypeImpl promotedType = node.staticType;
        TypeImpl declaredType = (element as VariableElement).type;
        // TODO(paulberry): once type equality has been updated to account for
        // nullability, isPromoted should just be
        // `promotedType != declaredType`.  See dartbug.com/37587.
        var isPromoted = promotedType != declaredType ||
            promotedType.nullabilitySuffix != declaredType.nullabilitySuffix;
        if (isPromoted) {
          return promotedType;
        }
      }
    }
    return null;
  }
}

class _TypePromotionDataInterpreter implements DataInterpreter<DartType> {
  const _TypePromotionDataInterpreter();

  @override
  String getText(DartType actualData) => actualData.toString();

  @override
  String isAsExpected(DartType actualData, String expectedData) {
    if (actualData.toString() == expectedData) {
      return null;
    } else {
      return 'Expected $expectedData, got $actualData';
    }
  }

  @override
  bool isEmpty(DartType actualData) => actualData == null;
}
