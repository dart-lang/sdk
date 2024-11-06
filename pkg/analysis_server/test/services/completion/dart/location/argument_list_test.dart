// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../../client/completion_driver_test.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ArgumentListTest);
    defineReflectiveTests(FlutterArgumentListTest);
    defineReflectiveTests(NamedArgumentListTest);
  });
}

@reflectiveTest
class ArgumentListTest extends AbstractCompletionDriverTest
    with ArgumentListTestCases {}

mixin ArgumentListTestCases on AbstractCompletionDriverTest {
  Future<void> test_afterColon_beforeRightParen() async {
    await computeSuggestions('''
void f() {foo(bar: ^);}
''');
    assertResponse(r'''
suggestions
  const
    kind: keyword
  true
    kind: keyword
  false
    kind: keyword
  null
    kind: keyword
  switch
    kind: keyword
''');
  }

  Future<void> test_afterColon_beforeRightParen_partial() async {
    await computeSuggestions('''
void f() {foo(bar: n^);}
''');
    assertResponse(r'''
replacement
  left: 1
suggestions
  null
    kind: keyword
''');
  }

  Future<void> test_afterComma_beforeIndexExpression() async {
    await computeSuggestions('''
void f(List<int> l0) {
  g(0, ^l0[1]);
}
void g(int i, int j) {}
''');

    assertResponse(r'''
replacement
  right: 2
suggestions
  l0
    kind: parameter
  true
    kind: keyword
  false
    kind: keyword
  null
    kind: keyword
  const
    kind: keyword
  switch
    kind: keyword
''');
  }

  Future<void> test_afterComma_beforeMethodInvocation() async {
    allowedIdentifiers = {'random'};
    await computeSuggestions('''
class OC {
  OC(int a, double b);
}
void f(int n) {
  var random = Random();
  var list = List<OC>.generate(n, (i) => OC(i, ^random.nextInt(n)));
}
''');

    assertResponse(r'''
replacement
  right: 6
suggestions
  random
    kind: localVariable
  null
    kind: keyword
  false
    kind: keyword
  true
    kind: keyword
  const
    kind: keyword
  switch
    kind: keyword
''');
  }

  Future<void> test_afterInt_beforeRightParen() async {
    await computeSuggestions('''
void f() { print(42^); }
''');
    assertResponse(r'''
suggestions
''');
  }

  Future<void> test_afterLeftParen_beforeRightParen() async {
    await computeSuggestions('''
void f() {foo(^);}
''');
    assertResponse(r'''
suggestions
  const
    kind: keyword
  true
    kind: keyword
  false
    kind: keyword
  null
    kind: keyword
  switch
    kind: keyword
''');
  }

  Future<void> test_afterLeftParen_beforeRightParen_factoryConstructor() async {
    printerConfiguration
      ..withDocumentation = true
      ..withElement = true;

    await computeSuggestions('''
class A {
  int fff;
  A._({this.fff});
  factory A({int fff}) = A._;
}
void f() {
  new A(^);
}
''');

    assertResponse(r'''
suggestions
  |fff: |
    kind: namedArgument
    element
      name: fff
      kind: parameter
''');
  }

  Future<void>
  test_afterLeftParen_beforeRightParen_fieldFormal_withDocumentation() async {
    printerConfiguration
      ..withDocumentation = true
      ..withElement = true;

    await computeSuggestions('''
class A {
  /// aaa
  ///
  /// bbb
  /// ccc
  int fff;
  A({this.fff});
}
void f() {
  new A(^);
}
''');

    assertResponse(r'''
suggestions
  |fff: |
    kind: namedArgument
    docComplete: aaa\n\nbbb\nccc
    docSummary: aaa
    element
      name: fff
      kind: parameter
''');
  }

  Future<void>
  test_afterLeftParen_beforeRightParen_fieldFormal_withoutDocumentation() async {
    printerConfiguration
      ..withDocumentation = true
      ..withElement = true;

    await computeSuggestions('''
class A {
  int fff;
  A({this.fff});
}
void f() {
  new A(^);
}
''');

    assertResponse(r'''
suggestions
  |fff: |
    kind: namedArgument
    element
      name: fff
      kind: parameter
''');
  }

  Future<void> test_afterLeftParen_beforeRightParen_partial() async {
    await computeSuggestions('''
void f() {foo(n^);}
''');
    assertResponse(r'''
replacement
  left: 1
suggestions
  null
    kind: keyword
''');
  }
}

@reflectiveTest
class FlutterArgumentListTest extends AbstractCompletionDriverTest
    with FlutterArgumentListTestCases {
  @override
  bool get includeKeywords => false;
}

mixin FlutterArgumentListTestCases on AbstractCompletionDriverTest {
  Future<void> test_afterComma_beforeRightParen_inInstanceCreation_1() async {
    writeTestPackageConfig(flutter: true);

    await computeSuggestions('''
import 'package:flutter/material.dart';

build() => new Row(
    key: null,
    ^
  );
''');

    printerConfiguration.filter = (suggestion) {
      return suggestion.completion.startsWith('children');
    };

    assertResponse(r'''
suggestions
  children: [],
    kind: namedArgument
    selection: 11
''');
  }

  Future<void> test_afterLeftParen_beforeArgument_inInstanceCreation_2() async {
    writeTestPackageConfig(flutter: true);

    await computeSuggestions('''
import 'package:flutter/material.dart';

build() => new Row(
    ^
    key: null,
  );
''');

    printerConfiguration.filter = (suggestion) {
      return suggestion.completion.startsWith('children');
    };

    assertResponse(r'''
suggestions
  children: [],
    kind: namedArgument
    selection: 11
''');
  }

  Future<void>
  test_afterLeftParen_beforeColon_inInstanceCreation_partial() async {
    // Ensure a trailing comma is not added when only replacing the name.
    writeTestPackageConfig(flutter: true);

    await computeSuggestions('''
import 'package:flutter/material.dart';

build() => new Row(
    ke^: null,
  );
''');

    printerConfiguration.filter = (suggestion) {
      return suggestion.completion.startsWith('key');
    };

    assertResponse(r'''
replacement
  left: 2
suggestions
  key
    kind: namedArgument
''');
  }

  Future<void>
  test_afterLeftParen_beforeColon_inInstanceCreation_withExistingValue_partial() async {
    // Ensure we don't include list markers if there's already a value.
    writeTestPackageConfig(flutter: true);

    await computeSuggestions('''
import 'package:flutter/material.dart';

build() => new Row(
    ch^: []
  );
''');
    assertResponse(r'''
replacement
  left: 2
suggestions
  children
    kind: namedArgument
''');
  }

  Future<void>
  test_afterLeftParen_beforeRightParen_inInstanceCreation_0() async {
    writeTestPackageConfig(flutter: true);

    await computeSuggestions('''
import 'package:flutter/widgets.dart';

build() => new Row(
    ^
  );
''');

    printerConfiguration.filter = (suggestion) {
      return suggestion.completion.startsWith('children');
    };

    assertResponse(r'''
suggestions
  children: [],
    kind: namedArgument
    selection: 11
''');
  }

  Future<void>
  test_afterLeftParen_beforeRightParen_inInstanceCreation_01() async {
    writeTestPackageConfig(flutter: true);

    await computeSuggestions('''
import 'package:flutter/material.dart';

build() => new Scaffold(
      appBar: new AppBar(
        ^
      ),
);
''');

    printerConfiguration.filter = (suggestion) {
      return suggestion.completion.startsWith('backgroundColor');
    };

    assertResponse(r'''
suggestions
  backgroundColor: ,
    kind: namedArgument
    selection: 17
''');
  }

  Future<void>
  test_afterLeftParen_beforeRightParen_inInstanceCreation_children_dynamic() async {
    // Ensure we don't generate unneeded <dynamic> param if a future API doesn't
    // type it's children.
    writeTestPackageConfig(flutter: true);

    await computeSuggestions('''
import 'package:flutter/material.dart';

build() => new Container(
    child: new DynamicRow(^);
  );

class DynamicRow extends Widget {
  DynamicRow({List children: null});
}
''');

    assertResponse(r'''
suggestions
  children: [],
    kind: namedArgument
    selection: 11
''');
  }

  Future<void>
  test_afterLeftParen_beforeRightParen_inInstanceCreation_mapValue() async {
    // Ensure we don't generate Map params for a future API
    writeTestPackageConfig(flutter: true);

    await computeSuggestions('''
import 'package:flutter/material.dart';

build() => new Container(
    child: new MapRow(^);
  );

class MapRow extends Widget {
  MapRow({Map<Object, Object> children: null});
}
''');

    assertResponse(r'''
suggestions
  children: ,
    kind: namedArgument
    selection: 10
''');
  }

  Future<void>
  test_afterLeftParen_beforeRightParen_inInstanceCreation_slivers() async {
    writeTestPackageConfig(flutter: true);

    await computeSuggestions('''
import 'package:flutter/material.dart';

build() => new CustomScrollView(
    ^
  );

class CustomScrollView extends Widget {
  CustomScrollView({List<Widget> slivers});
}
''');

    assertResponse(r'''
suggestions
  slivers: [],
    kind: namedArgument
    selection: 10
''');
  }

  Future<void>
  test_afterLeftParen_beforeRightParen_inMethodInvocation_nonFlutter() async {
    // Ensure we don't generate params for a non-flutter method invocation.
    writeTestPackageConfig(flutter: true);

    await computeSuggestions('''
import 'package:flutter/material.dart';

void f() {
  foo(^);
}

foo({String children}) {}
''');

    assertResponse(r'''
suggestions
  |children: |
    kind: namedArgument
''');
  }
}

@reflectiveTest
class NamedArgumentListTest extends AbstractCompletionDriverTest
    with NamedArgumentListTestCases {
  @override
  bool get includeKeywords => false;
}

mixin NamedArgumentListTestCases on AbstractCompletionDriverTest {
  @override
  Future<void> setUp() async {
    await super.setUp();
    allowedIdentifiers = {'foo01', 'foo02', 'foo03', 'foo04', 'foo05'};
  }

  Future<void> test_named_01() async {
    await _tryParametersArguments(
      parameters: '({int? foo01, int? foo02})',
      arguments: '(^)',
      check: (String where) {
        assertResponse(r'''
suggestions
  |foo01: |
    kind: namedArgument
  |foo02: |
    kind: namedArgument
''', where: where);
      },
    );
  }

  Future<void> test_named_02() async {
    await _tryParametersArguments(
      parameters: '({int? foo01, int? foo02})',
      arguments: '(foo0^)',
      check: (String where) {
        assertResponse(r'''
replacement
  left: 4
suggestions
  |foo01: |
    kind: namedArgument
  |foo02: |
    kind: namedArgument
''', where: where);
      },
    );
  }

  Future<void> test_named_03() async {
    await _tryParametersArguments(
      parameters: '({int? foo01, int? foo02})',
      arguments: '(f^ foo02: 2)',
      check: (String where) {
        assertResponse(r'''
replacement
  left: 1
suggestions
  foo01: ,
    kind: namedArgument
    selection: 7
''', where: where);
      },
    );
  }

  Future<void> test_named_04() async {
    await _tryParametersArguments(
      parameters: '({int? foo01, int? foo02})',
      arguments: '(f^, foo02: 2)',
      check: (String where) {
        assertResponse(r'''
replacement
  left: 1
suggestions
  |foo01: |
    kind: namedArgument
''', where: where);
      },
    );
  }

  Future<void> test_named_05() async {
    await _tryParametersArguments(
      parameters: '({int? foo01, int? foo02})',
      arguments: '(f^ , foo02: 2)',
      check: (String where) {
        assertResponse(r'''
replacement
  left: 1
suggestions
  |foo01: |
    kind: namedArgument
''', where: where);
      },
    );
  }

  Future<void> test_named_06() async {
    await _tryParametersArguments(
      parameters: '({int? foo01, int? foo02})',
      arguments: '(^f,)',
      check: (String where) {
        assertResponse(r'''
replacement
  right: 1
suggestions
  |foo01: |
    kind: namedArgument
  |foo02: |
    kind: namedArgument
''', where: where);
      },
    );
  }

  Future<void> test_named_07() async {
    await _tryParametersArguments(
      parameters: '({int? foo01, int? foo02})',
      arguments: '(^ foo02: 2)',
      check: (String where) {
        assertResponse(r'''
suggestions
  foo01: ,
    kind: namedArgument
    selection: 7
''', where: where);
      },
    );
  }

  Future<void> test_named_08() async {
    await _tryParametersArguments(
      parameters: '({int? foo01, int? foo02})',
      arguments: '(^foo02: 2)',
      check: (String where) {
        assertResponse(r'''
replacement
  right: 5
suggestions
  foo01
    kind: namedArgument
  foo02
    kind: namedArgument
''', where: where);
      },
    );
  }

  Future<void> test_named_09() async {
    await _tryParametersArguments(
      parameters: '({int? foo01, int? foo02})',
      arguments: '(^, foo02: 2)',
      check: (String where) {
        assertResponse(r'''
suggestions
  |foo01: |
    kind: namedArgument
''', where: where);
      },
    );
  }

  Future<void> test_named_10() async {
    await _tryParametersArguments(
      parameters: '({int? foo01, int? foo02})',
      arguments: '(^ , foo02: 2)',
      check: (String where) {
        assertResponse(r'''
suggestions
  |foo01: |
    kind: namedArgument
''', where: where);
      },
    );
  }

  Future<void> test_named_11() async {
    await _tryParametersArguments(
      parameters: '(int foo01, {int? foo02, int? foo03})',
      arguments: '(1, ^, foo03: 3)',
      check: (String where) {
        assertResponse(r'''
suggestions
  |foo02: |
    kind: namedArgument
''', where: where);
      },
    );
  }

  Future<void> test_named_12() async {
    await _tryParametersArguments(
      parameters: '(int foo01, {int? foo02, int? foo03})',
      arguments: '(1, ^ foo03: 3)',
      check: (String where) {
        assertResponse(r'''
suggestions
  foo02: ,
    kind: namedArgument
    selection: 7
''', where: where);
      },
    );
  }

  Future<void> test_named_13() async {
    await _tryParametersArguments(
      parameters: '(int foo01, {int? foo02, int? foo03})',
      arguments: '(1, ^foo03: 3)',
      check: (String where) {
        assertResponse(r'''
replacement
  right: 5
suggestions
  foo02
    kind: namedArgument
  foo03
    kind: namedArgument
''', where: where);
      },
    );
  }

  Future<void> test_named_14() async {
    await _tryParametersArguments(
      parameters: '({int? foo01, int? foo02})',
      arguments: '(foo02: 2^)',
      check: (String where) {
        assertResponse(r'''
suggestions
''', where: where);
      },
    );
  }

  @failingTest
  Future<void> test_named_15() async {
    await _tryParametersArguments(
      parameters: '({int? foo01, int? foo02})',
      arguments: '(foo02: 2 ^)',
      check: (String where) {
        assertResponse(r'''
suggestions
  |, foo01: |
    kind: namedArgument
''', where: where);
      },
    );
  }

  Future<void> test_named_16() async {
    await _tryParametersArguments(
      parameters: '({int? foo01, int? foo02})',
      arguments: '(foo02: 2, ^)',
      check: (String where) {
        assertResponse(r'''
suggestions
  |foo01: |
    kind: namedArgument
''', where: where);
      },
    );
  }

  Future<void> test_named_17() async {
    await _tryParametersArguments(
      parameters: '({int? foo01, int? foo02})',
      arguments: '(foo02: 2, f^)',
      check: (String where) {
        assertResponse(r'''
replacement
  left: 1
suggestions
  |foo01: |
    kind: namedArgument
''', where: where);
      },
    );
  }

  Future<void> test_named_18() async {
    await _tryParametersArguments(
      parameters: '({int? foo01, int? foo02})',
      arguments: '(foo02: 2, f^,)',
      check: (String where) {
        assertResponse(r'''
replacement
  left: 1
suggestions
  |foo01: |
    kind: namedArgument
''', where: where);
      },
    );
  }

  Future<void> test_named_19() async {
    await _tryParametersArguments(
      parameters: '(int foo01, int foo02, int foo03, {int? foo04, int? foo05})',
      arguments: '(1, ^, 3)',
      check: (String where) {
        assertResponse(r'''
suggestions
  |foo04: |
    kind: namedArgument
  |foo05: |
    kind: namedArgument
''', where: where);
      },
    );
  }

  Future<void> test_named_20() async {
    await _tryParametersArguments(
      languageVersion: '2.15',
      parameters: '(int foo01, int foo02, int foo03, {int? foo04, int? foo05})',
      arguments: '(1, ^, 3)',
      check: (String where) {
        assertResponse(r'''
suggestions
  |foo04: |
    kind: namedArgument
  |foo05: |
    kind: namedArgument
''', where: where);
      },
    );
  }

  Future<void> test_named_21() async {
    await _tryParametersArguments(
      parameters: '({int? foo01, int? foo02})',
      arguments: '(f^: 0)',
      check: (String where) {
        assertResponse(r'''
replacement
  left: 1
suggestions
  foo01
    kind: namedArgument
  foo02
    kind: namedArgument
''', where: where);
      },
    );
  }

  Future<void> test_named_22() async {
    await _tryParametersArguments(
      parameters: '(bool foo01, {int? foo02, int? foo03})',
      arguments: '(false, ^f: 2)',
      check: (String where) {
        assertResponse(r'''
replacement
  right: 1
suggestions
  foo02
    kind: namedArgument
  foo03
    kind: namedArgument
''', where: where);
      },
    );
  }

  Future<void> test_named_23() async {
    await _tryParametersArguments(
      parameters: '(int foo01, {int? foo02})',
      arguments: '(0, foo^ba: 2)',
      check: (String where) {
        assertResponse(r'''
replacement
  left: 3
  right: 2
suggestions
  foo02
    kind: namedArgument
''', where: where);
      },
    );
  }

  Future<void> test_named_24() async {
    await _tryParametersArguments(
      parameters: '(bool foo01, {int? foo02, int? foo03})',
      arguments: '(0, ^: 2)',
      check: (String where) {
        assertResponse(r'''
suggestions
  foo02
    kind: namedArgument
  foo03
    kind: namedArgument
''', where: where);
      },
    );
  }

  Future<void> test_named_25() async {
    await _tryParametersArguments(
      parameters: '({int? foo01, int? foo02})',
      arguments: '(foo01: ^)',
      check: (String where) {
        assertResponse(r'''
suggestions
''', where: where);
      },
    );
  }

  Future<void> _tryParametersArguments({
    String? languageVersion,
    required String parameters,
    required String arguments,
    required void Function(String) check,
  }) async {
    var languageVersionLine =
        languageVersion != null
            ? '// @dart = $languageVersion'
            : '// no language version override';

    Future<void> computeAndCheck(String code, String where) async {
      await computeSuggestions(code);
      check(where);
    }

    await computeAndCheck('''
$languageVersionLine
class A {
  const A$parameters;
}
@A$arguments
void f() {}
''', ' (annotation, local class)');

    newFile('$testPackageLibPath/a.dart', '''
class A {
  const A$parameters;
}
''');
    await computeAndCheck('''
$languageVersionLine
import 'a.dart';
@A$arguments
void f() {}
''', ' (annotation, imported class)');

    newFile('$testPackageLibPath/a.dart', '''
class A {
  const A$parameters;
}
''');
    await computeAndCheck('''
$languageVersionLine
import 'a.dart' as p;
@p.A$arguments
void f() {}
''', ' (annotation, imported class, prefixed)');

    await computeAndCheck('''
$languageVersionLine
enum E {
  v$arguments;
  const E$parameters;
}
''', ' (enum constant)');

    await computeAndCheck('''
$languageVersionLine
import 'a.dart';
void f$parameters {}
var v = (f)$arguments;
''', ' (function expression invocation)');

    await computeAndCheck('''
$languageVersionLine
class A {
  A$parameters;
}
var v = A$arguments;
''', ' (instance creation, local class, generative)');

    newFile('$testPackageLibPath/a.dart', '''
class A {
  A$parameters;
}
''');
    await computeAndCheck('''
$languageVersionLine
import 'a.dart';
var v = A$arguments;
''', ' (instance creation, imported class, generative)');

    newFile('$testPackageLibPath/a.dart', '''
class A {
  factory A$parameters => throw 0;
}
''');
    await computeAndCheck('''
$languageVersionLine
import 'a.dart';
var v = A$arguments;
''', ' (instance creation, imported class, factory)');

    await computeAndCheck('''
$languageVersionLine
class A {
  void foo$parameters {}
}
var v = A().foo$arguments;
''', ' (method invocation, local method)');

    await computeAndCheck('''
$languageVersionLine
void f$parameters {}
var v = f$arguments;
''', ' (method invocation, local function)');

    newFile('$testPackageLibPath/a.dart', '''
void f$parameters {}
''');
    await computeAndCheck('''
$languageVersionLine
import 'a.dart';
var v = f$arguments;
''', ' (method invocation, imported function)');

    await computeAndCheck('''
$languageVersionLine
void foo(void Function$parameters f) {
  f$arguments;
}
''', ' (invocation, function typed formal parameter)');

    await computeAndCheck('''
$languageVersionLine
void foo() {
  void Function$parameters f; // not initialized
  f$arguments;
}
''', ' (invocation, function typed local variable)');

    await computeAndCheck('''
$languageVersionLine
void Function$parameters foo() => throw 0;
void f() {
  foo()$arguments;
}
''', ' (invocation, function typed expression)');

    await computeAndCheck('''
$languageVersionLine
class A {
  void Function$parameters get f => throw 0;
  void foo() {
    f$arguments;
  }
}
''', ' (invocation, function typed class getter)');

    await computeAndCheck('''
$languageVersionLine
void Function$parameters get f => throw 0;
void foo() {
  f$arguments;
}
''', ' (invocation, function typed top-level getter)');
  }
}
