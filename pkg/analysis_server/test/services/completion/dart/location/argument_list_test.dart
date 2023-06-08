// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../../client/completion_driver_test.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ArgumentListTest1);
    defineReflectiveTests(ArgumentListTest2);
    defineReflectiveTests(FlutterArgumentListTest1);
    defineReflectiveTests(FlutterArgumentListTest2);
    defineReflectiveTests(NamedArgumentListTest1);
    defineReflectiveTests(NamedArgumentListTest2);
  });
}

@reflectiveTest
class ArgumentListTest1 extends AbstractCompletionDriverTest
    with ArgumentListTestCases {
  @override
  TestingCompletionProtocol get protocol => TestingCompletionProtocol.version1;
}

@reflectiveTest
class ArgumentListTest2 extends AbstractCompletionDriverTest
    with ArgumentListTestCases {
  @override
  TestingCompletionProtocol get protocol => TestingCompletionProtocol.version2;
}

mixin ArgumentListTestCases on AbstractCompletionDriverTest {
  Future<void> test_afterColon_beforeRightParen() async {
    await computeSuggestions('''
void f() {foo(bar: ^);}
''');
    assertResponse(r'''
suggestions
  const
    kind: keyword
  false
    kind: keyword
  null
    kind: keyword
  switch
    kind: keyword
  true
    kind: keyword
''');
  }

  Future<void> test_afterColon_beforeRightParen_partial() async {
    await computeSuggestions('''
void f() {foo(bar: n^);}
''');
    if (isProtocolVersion2) {
      assertResponse(r'''
replacement
  left: 1
suggestions
  null
    kind: keyword
''');
    } else {
      assertResponse(r'''
replacement
  left: 1
suggestions
  const
    kind: keyword
  false
    kind: keyword
  null
    kind: keyword
  switch
    kind: keyword
  true
    kind: keyword
''');
    }
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
  false
    kind: keyword
  null
    kind: keyword
  switch
    kind: keyword
  true
    kind: keyword
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
    if (isProtocolVersion2) {
      assertResponse(r'''
replacement
  left: 1
suggestions
  null
    kind: keyword
''');
    } else {
      assertResponse(r'''
replacement
  left: 1
suggestions
  const
    kind: keyword
  false
    kind: keyword
  null
    kind: keyword
  switch
    kind: keyword
  true
    kind: keyword
''');
    }
  }
}

@reflectiveTest
class FlutterArgumentListTest1 extends AbstractCompletionDriverTest
    with FlutterArgumentListTestCases {
  @override
  bool get includeKeywords => false;

  @override
  TestingCompletionProtocol get protocol => TestingCompletionProtocol.version1;
}

@reflectiveTest
class FlutterArgumentListTest2 extends AbstractCompletionDriverTest
    with FlutterArgumentListTestCases {
  @override
  bool get includeKeywords => false;

  @override
  TestingCompletionProtocol get protocol => TestingCompletionProtocol.version2;
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
    if (isProtocolVersion2) {
      assertResponse(r'''
replacement
  left: 2
suggestions
  children
    kind: namedArgument
''');
    } else {
      assertResponse(r'''
replacement
  left: 2
suggestions
  children
    kind: namedArgument
  crossAxisAlignment
    kind: namedArgument
  key
    kind: namedArgument
  mainAxisAlignment
    kind: namedArgument
  mainAxisSize
    kind: namedArgument
  textBaseline
    kind: namedArgument
  textDirection
    kind: namedArgument
  verticalDirection
    kind: namedArgument
''');
    }
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
class NamedArgumentListTest1 extends AbstractCompletionDriverTest
    with NamedArgumentListTestCases {
  @override
  bool get includeKeywords => false;

  @override
  TestingCompletionProtocol get protocol => TestingCompletionProtocol.version1;
}

@reflectiveTest
class NamedArgumentListTest2 extends AbstractCompletionDriverTest
    with NamedArgumentListTestCases {
  @override
  bool get includeKeywords => false;

  @override
  TestingCompletionProtocol get protocol => TestingCompletionProtocol.version2;
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
      check: () {
        assertResponse(r'''
suggestions
  |foo01: |
    kind: namedArgument
  |foo02: |
    kind: namedArgument
''');
      },
    );
  }

  Future<void> test_named_02() async {
    await _tryParametersArguments(
      parameters: '({int? foo01, int? foo02})',
      arguments: '(foo0^)',
      check: () {
        assertResponse(r'''
replacement
  left: 4
suggestions
  |foo01: |
    kind: namedArgument
  |foo02: |
    kind: namedArgument
''');
      },
    );
  }

  Future<void> test_named_03() async {
    await _tryParametersArguments(
      parameters: '({int? foo01, int? foo02})',
      arguments: '(f^ foo02: 2)',
      check: () {
        assertResponse(r'''
replacement
  left: 1
suggestions
  foo01: ,
    kind: namedArgument
    selection: 7
''');
      },
    );
  }

  Future<void> test_named_04() async {
    await _tryParametersArguments(
      parameters: '({int? foo01, int? foo02})',
      arguments: '(f^, foo02: 2)',
      check: () {
        assertResponse(r'''
replacement
  left: 1
suggestions
  |foo01: |
    kind: namedArgument
''');
      },
    );
  }

  Future<void> test_named_05() async {
    await _tryParametersArguments(
      parameters: '({int? foo01, int? foo02})',
      arguments: '(f^ , foo02: 2)',
      check: () {
        assertResponse(r'''
replacement
  left: 1
suggestions
  |foo01: |
    kind: namedArgument
''');
      },
    );
  }

  Future<void> test_named_06() async {
    await _tryParametersArguments(
      parameters: '({int? foo01, int? foo02})',
      arguments: '(^f,)',
      check: () {
        assertResponse(r'''
replacement
  right: 1
suggestions
  |foo01: |
    kind: namedArgument
  |foo02: |
    kind: namedArgument
''');
      },
    );
  }

  Future<void> test_named_07() async {
    await _tryParametersArguments(
      parameters: '({int? foo01, int? foo02})',
      arguments: '(^ foo02: 2)',
      check: () {
        assertResponse(r'''
suggestions
  foo01: ,
    kind: namedArgument
    selection: 7
''');
      },
    );
  }

  Future<void> test_named_08() async {
    await _tryParametersArguments(
      parameters: '({int? foo01, int? foo02})',
      arguments: '(^foo02: 2)',
      check: () {
        assertResponse(r'''
replacement
  right: 5
suggestions
  foo01: ,
    kind: namedArgument
    selection: 7
''');
      },
    );
  }

  Future<void> test_named_09() async {
    await _tryParametersArguments(
      parameters: '({int? foo01, int? foo02})',
      arguments: '(^, foo02: 2)',
      check: () {
        assertResponse(r'''
suggestions
  |foo01: |
    kind: namedArgument
''');
      },
    );
  }

  Future<void> test_named_10() async {
    await _tryParametersArguments(
      parameters: '({int? foo01, int? foo02})',
      arguments: '(^ , foo02: 2)',
      check: () {
        assertResponse(r'''
suggestions
  |foo01: |
    kind: namedArgument
''');
      },
    );
  }

  Future<void> test_named_11() async {
    await _tryParametersArguments(
      parameters: '(int foo01, {int? foo02, int? foo03})',
      arguments: '(1, ^, foo03: 3)',
      check: () {
        assertResponse(r'''
suggestions
  |foo02: |
    kind: namedArgument
''');
      },
    );
  }

  Future<void> test_named_12() async {
    await _tryParametersArguments(
      parameters: '(int foo01, {int? foo02, int? foo03})',
      arguments: '(1, ^ foo03: 3)',
      check: () {
        assertResponse(r'''
suggestions
  foo02: ,
    kind: namedArgument
    selection: 7
''');
      },
    );
  }

  Future<void> test_named_13() async {
    await _tryParametersArguments(
      parameters: '(int foo01, {int? foo02, int? foo03})',
      arguments: '(1, ^foo03: 3)',
      check: () {
        assertResponse(r'''
replacement
  right: 5
suggestions
  foo02: ,
    kind: namedArgument
    selection: 7
''');
      },
    );
  }

  @failingTest
  Future<void> test_named_14() async {
    await _tryParametersArguments(
      parameters: '({int? foo01, int? foo02})',
      arguments: '(foo02: 2^)',
      check: () {
        assertResponse(r'''
suggestions
''');
      },
    );
  }

  @failingTest
  Future<void> test_named_15() async {
    await _tryParametersArguments(
      parameters: '({int? foo01, int? foo02})',
      arguments: '(foo02: 2 ^)',
      check: () {
        assertResponse(r'''
suggestions
  |, foo01: |
    kind: namedArgument
''');
      },
    );
  }

  Future<void> test_named_16() async {
    await _tryParametersArguments(
      parameters: '({int? foo01, int? foo02})',
      arguments: '(foo02: 2, ^)',
      check: () {
        assertResponse(r'''
suggestions
  |foo01: |
    kind: namedArgument
''');
      },
    );
  }

  Future<void> test_named_17() async {
    await _tryParametersArguments(
      parameters: '({int? foo01, int? foo02})',
      arguments: '(foo02: 2, f^)',
      check: () {
        assertResponse(r'''
replacement
  left: 1
suggestions
  |foo01: |
    kind: namedArgument
''');
      },
    );
  }

  Future<void> test_named_18() async {
    await _tryParametersArguments(
      parameters: '({int? foo01, int? foo02})',
      arguments: '(foo02: 2, f^,)',
      check: () {
        assertResponse(r'''
replacement
  left: 1
suggestions
  |foo01: |
    kind: namedArgument
''');
      },
    );
  }

  Future<void> test_named_19() async {
    await _tryParametersArguments(
      parameters: '(int foo01, int foo02, int foo03, {int? foo04, int? foo05})',
      arguments: '(1, ^, 3)',
      check: () {
        assertResponse(r'''
suggestions
  |foo04: |
    kind: namedArgument
  |foo05: |
    kind: namedArgument
''');
      },
    );
  }

  Future<void> test_named_20() async {
    await _tryParametersArguments(
      languageVersion: '2.15',
      parameters: '(int foo01, int foo02, int foo03, {int? foo04, int? foo05})',
      arguments: '(1, ^, 3)',
      check: () {
        assertResponse(r'''
suggestions
''');
      },
    );
  }

  Future<void> test_named_21() async {
    await _tryParametersArguments(
      parameters: '({int? foo01, int? foo02})',
      arguments: '(f^: 0)',
      check: () {
        assertResponse(r'''
replacement
  left: 1
suggestions
  foo01
    kind: namedArgument
  foo02
    kind: namedArgument
''');
      },
    );
  }

  Future<void> test_named_22() async {
    await _tryParametersArguments(
      parameters: '(bool foo01, {int? foo02, int? foo03})',
      arguments: '(false, ^f: 2)',
      check: () {
        assertResponse(r'''
replacement
  right: 1
suggestions
  foo02: ,
    kind: namedArgument
    selection: 7
  foo03: ,
    kind: namedArgument
    selection: 7
''');
      },
    );
  }

  Future<void> test_named_23() async {
    await _tryParametersArguments(
      parameters: '(int foo01, {int? foo02})',
      arguments: '(0, foo^ba: 2)',
      check: () {
        assertResponse(r'''
replacement
  left: 3
  right: 2
suggestions
  foo02
    kind: namedArgument
''');
      },
    );
  }

  Future<void> test_named_24() async {
    await _tryParametersArguments(
      parameters: '(bool foo01, {int? foo02, int? foo03})',
      arguments: '(0, ^: 2)',
      check: () {
        assertResponse(r'''
suggestions
  foo02
    kind: namedArgument
  foo03
    kind: namedArgument
''');
      },
    );
  }

  Future<void> test_named_25() async {
    await _tryParametersArguments(
      parameters: '({int? foo01, int? foo02})',
      arguments: '(foo01: ^)',
      check: () {
        assertResponse(r'''
suggestions
''');
      },
    );
  }

  Future<void> _tryParametersArguments({
    String? languageVersion,
    required String parameters,
    required String arguments,
    required void Function() check,
  }) async {
    var languageVersionLine = languageVersion != null
        ? '// @dart = $languageVersion'
        : '// no language version override';

    Future<void> computeAndCheck(String code) async {
      await computeSuggestions(code);
      check();
    }

    // Annotation, local class.
    await computeAndCheck('''
$languageVersionLine
class A {
  const A$parameters;
}
@A$arguments
void f() {}
''');

    // Annotation, imported class.
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
''');

    // Annotation, imported class, prefixed.
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
''');

    // Enum constant.
    await computeAndCheck('''
$languageVersionLine
enum E {
  v$arguments;
  const E$parameters;
}
''');

    // Function expression invocation.
    await computeAndCheck('''
$languageVersionLine
import 'a.dart';
void f$parameters {}
var v = (f)$arguments;
''');

    // Instance creation, local class, generative.
    await computeAndCheck('''
$languageVersionLine
class A {
  A$parameters;
}
var v = A$arguments;
''');

    // Instance creation, imported class, generative.
    newFile('$testPackageLibPath/a.dart', '''
class A {
  A$parameters;
}
''');
    await computeAndCheck('''
$languageVersionLine
import 'a.dart';
var v = A$arguments;
''');

    // Instance creation, imported class, factory.
    newFile('$testPackageLibPath/a.dart', '''
class A {
  factory A$parameters => throw 0;
}
''');
    await computeAndCheck('''
$languageVersionLine
import 'a.dart';
var v = A$arguments;
''');

    // Method invocation, local method.
    await computeAndCheck('''
$languageVersionLine
class A {
  void foo$parameters {}
}
var v = A().foo$arguments;
''');

    // Method invocation, local function.
    await computeAndCheck('''
$languageVersionLine
void f$parameters {}
var v = f$arguments;
''');

    // Method invocation, imported function.
    newFile('$testPackageLibPath/a.dart', '''
void f$parameters {}
''');
    await computeAndCheck('''
$languageVersionLine
import 'a.dart';
var v = f$arguments;
''');

    // Super constructor invocation.
    await computeAndCheck('''
$languageVersionLine
class A {
  A$parameters;
}
class B extends A {
  B() : super$arguments;
}
''');

    // This constructor invocation.
    await computeAndCheck('''
$languageVersionLine
class A {
  A$parameters;
  A.named() : this$arguments;
}
''');
  }
}
