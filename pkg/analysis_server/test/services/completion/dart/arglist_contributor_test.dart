// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// This file contains tests written in a deprecated way. Please do not add any
/// tests to this file. Instead, add tests to the files in `declaration`,
/// `location`, or `relevance`.
library;

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../client/completion_driver_test.dart';
import 'completion_printer.dart' as printer;

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ArgListContributorTest);
    defineReflectiveTests(ArgumentListContributorNamedTest);
  });
}

@reflectiveTest
class ArgListContributorTest extends AbstractCompletionDriverTest {
  @override
  TestingCompletionProtocol get protocol => TestingCompletionProtocol.version2;

  @override
  Future<void> setUp() async {
    await super.setUp();

    printerConfiguration = printer.Configuration(
      filter: (suggestion) {
        return true;
      },
    );
  }

  Future<void> test_fieldFormal_documentation() async {
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

  Future<void> test_fieldFormal_noDocumentation() async {
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

  Future<void> test_flutter_InstanceCreationExpression_0() async {
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

  Future<void> test_flutter_InstanceCreationExpression_01() async {
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

  Future<void> test_flutter_InstanceCreationExpression_1() async {
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

  Future<void> test_flutter_InstanceCreationExpression_2() async {
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

  Future<void> test_flutter_InstanceCreationExpression_3() async {
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
      test_flutter_InstanceCreationExpression_children_dynamic() async {
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
      test_flutter_InstanceCreationExpression_children_existingValue() async {
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

  Future<void> test_flutter_InstanceCreationExpression_children_Map() async {
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

  Future<void> test_flutter_InstanceCreationExpression_slivers() async {
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

  Future<void> test_flutter_MethodExpression_children() async {
    // Ensure we don't generate params for a method call
    // TODO(brianwilkerson) This test has been changed so that it no longer has
    // anything to do with Flutter (by moving the declaration of `foo` out of
    // the 'material' library). Determine whether the test is still valid.
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
class ArgumentListContributorNamedTest extends AbstractCompletionDriverTest {
  @override
  TestingCompletionProtocol get protocol => TestingCompletionProtocol.version2;

  @override
  Future<void> setUp() async {
    await super.setUp();

    printerConfiguration = printer.Configuration(
      filter: (suggestion) {
        return suggestion.completion.startsWith('foo0');
      },
      withKind: false,
    );
  }

  Future<void> test_named_01() async {
    await _tryParametersArguments(
      parameters: '({int? foo01, int? foo02})',
      arguments: '(^)',
      check: () {
        assertResponse(r'''
suggestions
  |foo01: |
  |foo02: |
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
  |foo02: |
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
  |foo02: |
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
  |foo05: |
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
  foo02
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
    selection: 7
  foo03: ,
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
  foo03
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
