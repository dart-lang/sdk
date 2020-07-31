// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../driver_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(FunctionExpressionTest);
    defineReflectiveTests(FunctionExpressionWithNnbdTest);
  });
}

@reflectiveTest
class FunctionExpressionTest extends DriverResolutionTest {
  test_contextFunctionType_returnType_async_expressionBody() async {
    await assertNoErrorsInCode('''
Future<num> Function() v = () async => 0;
''');
    _assertReturnType('() async =>', 'Future<int>');
  }

  test_contextFunctionType_returnType_async_expressionBody2() async {
    await assertNoErrorsInCode('''
T foo<T>() => throw 0;

Future<int> Function() v = () async => foo();
''');
    assertTypeArgumentTypes(
      findNode.methodInvocation('foo();'),
      ['FutureOr<int>'],
    );
    _assertReturnType('() async => foo', 'Future<int>');
  }

  test_contextFunctionType_returnType_async_expressionBody3() async {
    await assertNoErrorsInCode('''
Future<int> Function() v = () async => Future.value(0);
''');
    _assertReturnType('() async =>', 'Future<int>');
  }

  test_contextFunctionType_returnType_async_expressionBody_object() async {
    await assertNoErrorsInCode('''
T foo<T>() => throw 0;

Object Function() v = () async => foo();
''');

    assertTypeArgumentTypes(
      findNode.methodInvocation('foo();'),
      [
        typeStringByNullability(
          nullable: 'FutureOr<Object?>',
          legacy: 'FutureOr<Object>',
        ),
      ],
    );

    _assertReturnType(
      '() async => foo',
      typeStringByNullability(
        nullable: 'Future<Object?>',
        legacy: 'Future<Object>',
      ),
    );
  }

  test_contextFunctionType_returnType_asyncStar_blockBody() async {
    await assertNoErrorsInCode('''
Stream<num> Function() v = () async* {
  yield 0;
};
''');
    _assertReturnType('() async*', 'Stream<int>');
  }

  test_contextFunctionType_returnType_asyncStar_blockBody2() async {
    await assertNoErrorsInCode('''
T foo<T>() => throw 0;

Stream<int> Function() v = () async* {
  yield foo();
};
''');
    assertTypeArgumentTypes(
      findNode.methodInvocation('foo();'),
      ['int'],
    );
    _assertReturnType('() async*', 'Stream<int>');
  }

  test_contextFunctionType_returnType_sync_blockBody() async {
    await assertNoErrorsInCode('''
num Function() v = () {
  return 0;
};
''');
    _assertReturnType('() {', 'int');
  }

  test_contextFunctionType_returnType_sync_blockBody2() async {
    await assertNoErrorsInCode('''
T foo<T>() => throw 0;

int Function() v = () {
  return foo();
};
''');
    assertTypeArgumentTypes(
      findNode.methodInvocation('foo();'),
      ['int'],
    );
    _assertReturnType('() {', 'int');
  }

  test_contextFunctionType_returnType_sync_expressionBody() async {
    await assertNoErrorsInCode('''
num Function() v = () => 0;
''');
    _assertReturnType('() =>', 'int');
  }

  test_contextFunctionType_returnType_sync_expressionBody2() async {
    await assertNoErrorsInCode('''
T foo<T>() => throw 0;

int Function() v = () => foo();
''');
    assertTypeArgumentTypes(
      findNode.methodInvocation('foo();'),
      ['int'],
    );
    _assertReturnType('() => foo', 'int');
  }

  test_contextFunctionType_returnType_syncStar_blockBody() async {
    await assertNoErrorsInCode('''
Iterable<num> Function() v = () sync* {
  yield 0;
};
''');
    _assertReturnType('() sync*', 'Iterable<int>');
  }

  test_contextFunctionType_returnType_syncStar_blockBody2() async {
    await assertNoErrorsInCode('''
T foo<T>() => throw 0;

Iterable<int> Function() v = () sync* {
  yield foo();
};
''');
    assertTypeArgumentTypes(
      findNode.methodInvocation('foo();'),
      ['int'],
    );
    _assertReturnType('() sync*', 'Iterable<int>');
  }

  test_downward_argumentType_Never() async {
    await assertNoErrorsInCode(r'''
void foo(void Function(Never) a) {}

main() {
  foo((x) {});
}
''');

    assertParameterElementType(
      findNode.simpleParameter('x) {}'),
      typeStringByNullability(
        nullable: 'Object?',
        legacy: 'Object',
      ),
    );
  }

  test_downward_argumentType_Null() async {
    await resolveTestCode(r'''
void foo(void Function(Null) a) {}

main() {
  foo((x) {});
}
''');

    assertParameterElementType(
      findNode.simpleParameter('x) {}'),
      typeStringByNullability(
        nullable: 'Object?',
        legacy: 'Object',
      ),
    );
  }

  test_noContext_returnType_async_blockBody() async {
    await resolveTestCode('''
var v = () async {
  return 0;
};
''');
    _assertReturnType('() async {', 'Future<int>');
  }

  test_noContext_returnType_async_expressionBody() async {
    await resolveTestCode('''
var v = () async => 0;
''');
    _assertReturnType('() async =>', 'Future<int>');
  }

  test_noContext_returnType_asyncStar_blockBody() async {
    await resolveTestCode('''
var v = () async* {
  yield 0;
};
''');
    _assertReturnType('() async* {', 'Stream<int>');
  }

  test_noContext_returnType_sync_blockBody() async {
    await resolveTestCode('''
var v = () {
  return 0;
};
''');
    _assertReturnType('() {', 'int');
  }

  test_noContext_returnType_sync_blockBody_dynamic() async {
    await resolveTestCode('''
var v = (dynamic a) {
  return a;
};
''');
    _assertReturnType('(dynamic a) {', 'dynamic');
  }

  test_noContext_returnType_sync_blockBody_Never() async {
    await resolveTestCode('''
var v = () {
  throw 42;
};
''');
    _assertReturnType(
      '() {',
      typeStringByNullability(nullable: 'Never', legacy: 'Null'),
    );
  }

  test_noContext_returnType_sync_blockBody_notNullable() async {
    await resolveTestCode('''
var v = (bool b) {
  if (b) return 0;
  return 1.2;
};
''');
    _assertReturnType('(bool b) {', 'num');
  }

  test_noContext_returnType_sync_blockBody_notNullable_switch_onEnum() async {
    await assertNoErrorsInCode('''
enum E { a, b }

main() {
  (E e) {
    switch (e) {
      case E.a:
        return 0;
      case E.b:
        return 1;
    }
  };
}
''');
    _assertReturnType('(E e) {', 'int');
  }

  test_noContext_returnType_sync_blockBody_notNullable_switch_onEnum_imported() async {
    newFile('/test/lib/a.dart', content: r'''
enum E { a, b }
''');

    await assertNoErrorsInCode('''
import 'a.dart' as p;

main() {
  (p.E e) {
    switch (e) {
      case p.E.a:
        return 0;
      case p.E.b:
        return 1;
    }
  };
}
''');
    _assertReturnType('(p.E e) {', 'int');
  }

  test_noContext_returnType_sync_blockBody_null_hasReturn() async {
    await resolveTestCode('''
var v = (bool b) {
  if (b) return;
};
''');
    _assertReturnType('(bool b) {', 'Null');
  }

  test_noContext_returnType_sync_blockBody_null_noReturn() async {
    await resolveTestCode('''
var v = () {};
''');
    _assertReturnType('() {}', 'Null');
  }

  test_noContext_returnType_sync_blockBody_nullable() async {
    await resolveTestCode('''
var v = (bool b) {
  if (b) return 0;
};
''');
    _assertReturnType(
      '(bool b) {',
      typeStringByNullability(nullable: 'int?', legacy: 'int'),
    );
  }

  test_noContext_returnType_sync_blockBody_nullable_switch() async {
    await assertNoErrorsInCode('''
main() {
  (int a) {
    switch (a) {
      case 0:
        return 0;
    }
  };
}
''');
    _assertReturnType(
      '(int a) {',
      typeStringByNullability(nullable: 'int?', legacy: 'int'),
    );
  }

  test_noContext_returnType_sync_expressionBody_dynamic() async {
    await resolveTestCode('''
var v = (dynamic a) => a;
''');
    _assertReturnType('(dynamic a) =>', 'dynamic');
  }

  test_noContext_returnType_sync_expressionBody_Never() async {
    await resolveTestCode('''
var v = () => throw 42;
''');
    _assertReturnType(
      '() =>',
      typeStringByNullability(nullable: 'Never', legacy: 'Null'),
    );
  }

  test_noContext_returnType_sync_expressionBody_notNullable() async {
    await resolveTestCode('''
var v = () => 42;
''');
    _assertReturnType('() =>', 'int');
  }

  test_noContext_returnType_sync_expressionBody_Null() async {
    await resolveTestCode('''
main() {
  var v = () => null;
  v;
}
''');
    _assertReturnType('() =>', 'Null');
  }

  test_noContext_returnType_syncStar_blockBody() async {
    await resolveTestCode('''
var v = () sync* {
  yield 0;
};
''');
    _assertReturnType('() sync* {', 'Iterable<int>');
  }

  void _assertReturnType(String search, String expected) {
    var element = findNode.functionExpression(search).declaredElement;
    assertType(element.returnType, expected);
  }
}

@reflectiveTest
class FunctionExpressionWithNnbdTest extends FunctionExpressionTest {
  @override
  AnalysisOptionsImpl get analysisOptions => AnalysisOptionsImpl()
    ..contextFeatures = FeatureSet.forTesting(
        sdkVersion: '2.6.0', additionalFeatures: [Feature.non_nullable]);

  @override
  bool get typeToStringWithNullability => true;

  test_contextFunctionType_nonNullify() async {
    newFile('/test/lib/a.dart', content: r'''
// @dart = 2.7

int Function(int a) v;
''');

    await assertNoErrorsInCode('''
import 'a.dart';

T foo<T>() => throw 0;

void f() {
  v = (a) {
    return foo();
  };
}
''');
    assertType(findElement.parameter('a').type, 'int');
    _assertReturnType('(a) {', 'int');
  }

  test_contextFunctionType_nonNullify_returnType_takeActual() async {
    newFile('/test/lib/a.dart', content: r'''
// @dart = 2.7

void foo(int Function() x) {}
''');
    await assertNoErrorsInCode('''
import 'a.dart';

void test(int? a) {
  foo(() => a);
}
''');
    _assertReturnType('() => a', 'int?');
  }

  test_contextFunctionType_nonNullify_returnType_takeContext() async {
    newFile('/test/lib/a.dart', content: r'''
// @dart = 2.7

void foo(int Function() x) {}
''');
    await assertNoErrorsInCode('''
import 'a.dart';

void test(dynamic a) {
  foo(() => a);
}
''');
    _assertReturnType('() => a', 'int');
  }

  test_contextFunctionType_returnType_async_blockBody_objectQ() async {
    await assertNoErrorsInCode('''
T foo<T>() => throw 0;

Object? Function() v = () async {
  return foo();
};
''');
    assertTypeArgumentTypes(
      findNode.methodInvocation('foo();'),
      ['FutureOr<Object?>'],
    );
    _assertReturnType('() async', 'Future<Object?>');
  }

  test_contextFunctionType_returnType_async_blockBody_objectQ2() async {
    await assertNoErrorsInCode('''
T foo<T>() => throw 0;

Object? Function() v = () async {
  return;
};
''');
    _assertReturnType('() async', 'Future<Null>');
  }

  test_contextFunctionType_returnType_async_expressionBody_objectQ() async {
    await assertNoErrorsInCode('''
T foo<T>() => throw 0;

Object? Function() v = () async => foo();
''');
    assertTypeArgumentTypes(
      findNode.methodInvocation('foo();'),
      ['FutureOr<Object?>'],
    );
    _assertReturnType('() async => foo', 'Future<Object?>');
  }

  test_optOut_downward_returnType_expressionBody_Null() async {
    newFile('/test/lib/a.dart', content: r'''
void foo(Map<String, String> Function() f) {}
''');
    await resolveTestCode('''
// @dart = 2.5
import 'a.dart';

void main() {
  foo(() => null);
}
''');
    _assertReturnType('() =>', 'Null*');
  }
}
