// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix/data_driven/element_descriptor.dart';
import 'package:analysis_server/src/services/correction/fix/data_driven/element_kind.dart';
import 'package:analysis_server/src/services/correction/fix/data_driven/element_matcher.dart';
import 'package:analyzer/src/test_utilities/package_config_file_builder.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'data_driven_test_support.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ElementMatcherComponentAndKindTest);
    defineReflectiveTests(ElementMatcherImportsTest);
  });
}

abstract class AbstractElementMatcherTest extends DataDrivenFixProcessorTest {
  void _assertMatcher(String search,
      {List<String>? expectedComponents,
      List<ElementKind>? expectedKinds,
      List<String>? expectedUris}) {
    var node = findNode.any(search);
    var matchers = ElementMatcher.matchersForNode(node, node.beginToken);
    expect(matchers, hasLength(1));
    var matcher = matchers[0];
    if (expectedUris != null) {
      expect(matcher.importedUris,
          unorderedEquals(expectedUris.map((uri) => Uri.parse(uri))));
    }
    if (expectedComponents != null) {
      expect(matcher.components, expectedComponents);
    }
    if (expectedKinds != null) {
      expect(matcher.validKinds, expectedKinds);
    }
  }
}

@reflectiveTest
class ElementMatcherComponentAndKindTest extends AbstractElementMatcherTest {
  /// The kinds that are expected where a getter or setter is allowed.
  static List<ElementKind> accessorKinds = [
    ElementKind.constantKind,
    ElementKind.fieldKind,
    ElementKind.functionKind, // tear-off
    ElementKind.getterKind,
    ElementKind.methodKind, // tear-off
    ElementKind.setterKind,
  ];

  /// The kinds that are expected where an invocation is allowed.
  static List<ElementKind> invocationKinds = [
    ElementKind.classKind,
    ElementKind.constructorKind,
    ElementKind.extensionKind,
    ElementKind.functionKind,
    ElementKind.getterKind,
    ElementKind.methodKind,
  ];

  /// The kinds that are expected where a method or constructor is allowed.
  static List<ElementKind> methodKinds = [
    ElementKind.constructorKind,
    ElementKind.methodKind
  ];

  /// The kinds that are expected where a type is allowed.
  static List<ElementKind> typeKinds = [
    ElementKind.classKind,
    ElementKind.enumKind,
    ElementKind.mixinKind,
    ElementKind.typedefKind,
  ];

  @failingTest
  Future<void> test_binaryExpression_resolved() async {
    // This test fails because we don't yet support operators.
    await resolveTestCode('''
void f(int x, int y) {
  x + y;
}
''');
    _assertMatcher('+',
        expectedComponents: ['+', 'int'],
        expectedKinds: [ElementKind.methodKind]);
  }

  @failingTest
  Future<void> test_binaryExpression_unresolved() async {
    // This test fails because we don't yet support operators.
    await resolveTestCode('''
void f(C c1, C c2) {
  c1 + c2;
}
class C {}
''');
    _assertMatcher('+',
        expectedComponents: ['+', 'C'],
        expectedKinds: [ElementKind.methodKind]);
  }

  Future<void> test_getter_withoutTarget_resolved() async {
    await resolveTestCode('''
class C {
  String get g => '';
  void m() {
    g;
  }
}
''');
    _assertMatcher('g;', expectedComponents: ['g']);
  }

  Future<void> test_getter_withoutTarget_unresolved() async {
    await resolveTestCode('''
class C {
  void m() {
    foo;
  }
}
''');
    _assertMatcher('foo', expectedComponents: ['foo']);
  }

  Future<void> test_getter_withTarget_resolved() async {
    await resolveTestCode('''
void f(String s) {
  s.length;
}
''');
    _assertMatcher('length',
        expectedComponents: ['length', 'String'], expectedKinds: accessorKinds);
  }

  Future<void> test_getter_withTarget_unresolved() async {
    await resolveTestCode('''
void f(String s) {
  s.foo;
}
''');
    _assertMatcher('foo',
        expectedComponents: ['foo', 'String'], expectedKinds: accessorKinds);
  }

  Future<void> test_identifier_propertyAccess() async {
    await resolveTestCode('''
void f() {
  s.length;
}
''');
    _assertMatcher('s', expectedComponents: ['s'], expectedKinds: []);
  }

  Future<void> test_matcherHasMoreComponents_differentUris() async {
    var matcher = ElementMatcher(
      importedUris: [Uri.parse('dart:core')],
      components: ['A'],
      kinds: [],
    );

    var element = ElementDescriptor(
        libraryUris: [Uri.parse(importUri)],
        kind: ElementKind.constructorKind,
        components: ['', 'A'],
        isStatic: false);

    expect(matcher.matches(element), isFalse);
  }

  Future<void> test_matcherHasMoreComponents_sameUris() async {
    var matcher = ElementMatcher(
      importedUris: [Uri.parse(importUri)],
      components: ['A'],
      kinds: [],
    );

    var element = ElementDescriptor(
        libraryUris: [Uri.parse(importUri)],
        kind: ElementKind.constructorKind,
        components: ['', 'A'],
        isStatic: false);

    expect(matcher.matches(element), isTrue);
  }

  Future<void> test_method_withoutTarget_resolved() async {
    await resolveTestCode('''
class C {
  void m(int i) {}
  void m2() {
    m(0);
  }
}
''');
    _assertMatcher('m(0)',
        expectedComponents: ['m', 'C'], expectedKinds: invocationKinds);
  }

  Future<void> test_method_withoutTarget_unresolved() async {
    await resolveTestCode('''
class C {
  void m() {
    foo();
  }
}
''');
    _assertMatcher('foo',
        expectedComponents: ['foo'], expectedKinds: invocationKinds);
  }

  Future<void> test_method_withTarget_resolved() async {
    await resolveTestCode('''
void f(String s) {
  s.substring(2);
}
''');
    _assertMatcher('substring',
        expectedComponents: ['substring', 'String'],
        expectedKinds: methodKinds);
  }

  Future<void> test_method_withTarget_unresolved() async {
    await resolveTestCode('''
void f(String s) {
  s.foo(2);
}
''');
    _assertMatcher('foo',
        expectedComponents: ['foo', 'String'], expectedKinds: methodKinds);
  }

  Future<void> test_setter_withoutTarget_resolved() async {
    await resolveTestCode('''
class C {
  set s(String s) {}
  void m() {
    s = '';
  }
}
''');
    _assertMatcher('s =', expectedComponents: ['s']);
  }

  Future<void> test_setter_withoutTarget_unresolved() async {
    await resolveTestCode('''
class C {
  void m() {
    foo = '';
  }
}
''');
    _assertMatcher('foo', expectedComponents: ['foo']);
  }

  Future<void> test_setter_withTarget_resolved() async {
    await resolveTestCode('''
void f(C c) {
  c.s = '';
}
class C {
  set s(String s) {}
}
''');
    _assertMatcher('s =',
        expectedComponents: ['s', 'C'], expectedKinds: accessorKinds);
  }

  Future<void> test_setter_withTarget_unresolved() async {
    await resolveTestCode('''
void f(String s) {
  s.foo = '';
}
''');
    _assertMatcher('foo',
        expectedComponents: ['foo', 'String'], expectedKinds: accessorKinds);
  }

  Future<void> test_type_field_resolved() async {
    await resolveTestCode('''
class C {
  String s = '';
}
''');
    _assertMatcher('String',
        expectedComponents: ['String'], expectedKinds: typeKinds);
  }

  Future<void> test_type_field_unresolved() async {
    await resolveTestCode('''
class C {
  Foo s = '';
}
''');
    _assertMatcher('Foo',
        expectedComponents: ['Foo'], expectedKinds: typeKinds);
  }

  Future<void> test_type_localVariable_resolved() async {
    await resolveTestCode('''
void f() {
  String s = '';
}
''');
    _assertMatcher('String',
        expectedComponents: ['String'], expectedKinds: typeKinds);
  }

  Future<void> test_type_localVariable_unresolved() async {
    await resolveTestCode('''
void f() {
  Foo s = '';
}
''');
    _assertMatcher('Foo',
        expectedComponents: ['Foo'], expectedKinds: typeKinds);
  }

  Future<void> test_type_method_resolved() async {
    await resolveTestCode('''
class C {
  String m() => '';
}
''');
    _assertMatcher('String',
        expectedComponents: ['String'], expectedKinds: typeKinds);
  }

  Future<void> test_type_method_unresolved() async {
    await resolveTestCode('''
class C {
  Foo m() => '';
}
''');
    _assertMatcher('Foo',
        expectedComponents: ['Foo'], expectedKinds: typeKinds);
  }

  Future<void> test_type_parameter_resolved() async {
    await resolveTestCode('''
void f(String s) {}
''');
    _assertMatcher('String',
        expectedComponents: ['String'], expectedKinds: typeKinds);
  }

  Future<void> test_type_parameter_unresolved() async {
    await resolveTestCode('''
void f(Foo s) {}
''');
    _assertMatcher('Foo',
        expectedComponents: ['Foo'], expectedKinds: typeKinds);
  }

  Future<void> test_type_topLevelFunction_resolved() async {
    await resolveTestCode('''
String f() => '';
''');
    _assertMatcher('String',
        expectedComponents: ['String'], expectedKinds: typeKinds);
  }

  Future<void> test_type_topLevelFunction_unresolved() async {
    await resolveTestCode('''
Foo f() => '';
''');
    _assertMatcher('Foo',
        expectedComponents: ['Foo'], expectedKinds: typeKinds);
  }

  Future<void> test_type_topLevelVariable_resolved() async {
    await resolveTestCode('''
String s = '';
''');
    _assertMatcher('String',
        expectedComponents: ['String'], expectedKinds: typeKinds);
  }

  Future<void> test_type_topLevelVariable_unresolved() async {
    await resolveTestCode('''
Foo s = '';
''');
    _assertMatcher('Foo',
        expectedComponents: ['Foo'], expectedKinds: typeKinds);
  }
}

@reflectiveTest
class ElementMatcherImportsTest extends AbstractElementMatcherTest {
  Future<void> test_imports_noImports() async {
    await resolveTestCode('''
String s = '';
''');
    _assertMatcher('s', expectedUris: ['dart:core']);
  }

  Future<void> test_imports_package() async {
    var packageRootPath = '$workspaceRootPath/other';
    newFile('$packageRootPath/lib/other.dart', '');
    writeTestPackageConfig(
        config: PackageConfigFileBuilder()
          ..add(name: 'other', rootPath: packageRootPath));

    await resolveTestCode('''
import 'package:other/other.dart';

String s = '';
''');
    _assertMatcher('s',
        expectedUris: ['dart:core', 'package:other/other.dart']);
  }

  Future<void> test_imports_relative() async {
    newFile('$testPackageLibPath/a.dart', '');
    await resolveTestCode('''
import 'a.dart';

String s = '';
''');
    _assertMatcher('s', expectedUris: ['dart:core', 'package:test/a.dart']);
  }

  Future<void> test_imports_sdkLibraries() async {
    await resolveTestCode('''
import 'dart:math';

int f(int x, int y) => max(x, y);
''');
    _assertMatcher('f', expectedUris: ['dart:core', 'dart:math']);
  }
}
