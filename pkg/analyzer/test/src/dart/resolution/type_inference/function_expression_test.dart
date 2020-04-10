// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/src/error/codes.dart';
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

  test_returnType_async_blockBody() async {
    await resolveTestCode('''
var v = () async {
  return 0;
};
''');
    _assertReturnType('() async {', 'Future<int>');
  }

  test_returnType_async_expressionBody() async {
    await resolveTestCode('''
var v = () async => 0;
''');
    _assertReturnType('() async =>', 'Future<int>');
  }

  test_returnType_asyncStar_blockBody() async {
    await resolveTestCode('''
var v = () async* {
  yield 0;
};
''');
    _assertReturnType('() async* {', 'Stream<int>');
  }

  test_returnType_sync_blockBody() async {
    await resolveTestCode('''
var v = () {
  return 0;
};
''');
    _assertReturnType('() {', 'int');
  }

  test_returnType_sync_blockBody_notNullable() async {
    await resolveTestCode('''
var v = (bool b) {
  if (b) return 0;
  return 1.2;
};
''');
    _assertReturnType('(bool b) {', 'num');
  }

  test_returnType_sync_blockBody_notNullable_switch_onEnum() async {
    var expectedErrors = expectedErrorsByNullability(
      nullable: [],
      legacy: [
        error(HintCode.MISSING_RETURN, 28, 102),
      ],
    );
    await assertErrorsInCode('''
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
''', expectedErrors);
    _assertReturnType('(E e) {', 'int');
  }

  test_returnType_sync_blockBody_notNullable_switch_onEnum_imported() async {
    newFile('/test/lib/a.dart', content: r'''
enum E { a, b }
''');

    var expectedErrors = expectedErrorsByNullability(
      nullable: [],
      legacy: [
        error(HintCode.MISSING_RETURN, 34, 108),
      ],
    );
    await assertErrorsInCode('''
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
''', expectedErrors);
    _assertReturnType('(p.E e) {', 'int');
  }

  test_returnType_sync_blockBody_null_hasReturn() async {
    await resolveTestCode('''
var v = (bool b) {
  if (b) return;
};
''');
    _assertReturnType('(bool b) {', 'Null');
  }

  test_returnType_sync_blockBody_null_noReturn() async {
    await resolveTestCode('''
var v = () {};
''');
    _assertReturnType('() {}', 'Null');
  }

  test_returnType_sync_blockBody_nullable() async {
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

  test_returnType_sync_blockBody_nullable_switch() async {
    var expectedErrors = expectedErrorsByNullability(
      nullable: [],
      legacy: [
        error(HintCode.MISSING_RETURN, 11, 68),
      ],
    );
    await assertErrorsInCode('''
main() {
  (int a) {
    switch (a) {
      case 0:
        return 0;
    }
  };
}
''', expectedErrors);
    _assertReturnType(
      '(int a) {',
      typeStringByNullability(nullable: 'int?', legacy: 'int'),
    );
  }

  test_returnType_sync_expressionBody_Never() async {
    await resolveTestCode('''
var v = () => throw 42;
''');
    _assertReturnType(
      '() =>',
      typeStringByNullability(nullable: 'Never', legacy: 'Null'),
    );
  }

  test_returnType_sync_expressionBody_notNullable() async {
    await resolveTestCode('''
var v = () => 42;
''');
    _assertReturnType('() =>', 'int');
  }

  test_returnType_sync_expressionBody_Null() async {
    await resolveTestCode('''
var v = () => null;
''');
    _assertReturnType('() =>', 'Null');
  }

  test_returnType_syncStar_blockBody() async {
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

  test_optOut_returnType_expressionBody_Null() async {
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
