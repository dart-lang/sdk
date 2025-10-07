// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix/data_driven/element_descriptor.dart';
import 'package:analysis_server/src/services/correction/fix/data_driven/element_kind.dart';
import 'package:analysis_server/src/services/correction/fix/data_driven/element_matcher.dart';
import 'package:analyzer/utilities/package_config_file_builder.dart';
import 'package:collection/collection.dart';
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
  /// Assert that there is exactly one [ElementMatcher] for the node described
  /// by [search] that satisfies `expectedXyz` requirements.
  void _assertHasMatcher(
    String search, {
    List<String>? expectedComponents,
    List<ElementKind>? expectedKinds,
    List<String>? expectedUris,
  }) {
    var node = findNode.any(search);
    var matchers = ElementMatcher.matchersForNode(
      node,
      node.beginToken,
      testLibraryElement,
    );
    var matchedMatchers = <ElementMatcher>[];
    for (var matcher in matchers) {
      if (expectedUris != null) {
        if (!const UnorderedIterableEquality<Uri>().equals(
          matcher.importedUris,
          expectedUris.map((uri) => Uri.parse(uri)),
        )) {
          continue;
        }
      }
      if (expectedComponents != null) {
        if (!const ListEquality<String>().equals(
          matcher.components,
          expectedComponents,
        )) {
          continue;
        }
      }
      if (expectedKinds != null) {
        if (!const ListEquality<ElementKind>().equals(
          matcher.validKinds,
          expectedKinds,
        )) {
          continue;
        }
      }
      matchedMatchers.add(matcher);
    }
    expect(matchedMatchers, hasLength(1));
  }

  void _assertMatcher(
    String search, {
    List<String>? expectedComponents,
    List<ElementKind>? expectedKinds,
    List<String>? expectedUris,
  }) {
    var node = findNode.any(search);
    var matchers = ElementMatcher.matchersForNode(
      node,
      node.beginToken,
      testLibraryElement,
    );
    expect(matchers, hasLength(1));
    var matcher = matchers[0];
    if (expectedUris != null) {
      expect(
        matcher.importedUris,
        unorderedEquals(expectedUris.map((uri) => Uri.parse(uri))),
      );
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

  /// The kinds that are expected where a static getter is allowed.
  static List<ElementKind> staticGetterAccessorKinds = [
    ElementKind.constantKind,
    ElementKind.fieldKind,
    ElementKind.getterKind,
    ElementKind.methodKind, // tear-off
  ];

  /// The kinds that are expected where an invocation is allowed.
  static List<ElementKind> invocationKinds = [
    ElementKind.classKind,
    ElementKind.constructorKind,
    ElementKind.enumKind,
    ElementKind.extensionKind,
    ElementKind.extensionTypeKind,
    ElementKind.functionKind,
    ElementKind.getterKind,
    ElementKind.methodKind,
    ElementKind.mixinKind,
    ElementKind.typedefKind,
  ];

  /// The kinds that are expected where a method or constructor is allowed.
  static List<ElementKind> methodKinds = [
    ElementKind.constructorKind,
    ElementKind.methodKind,
  ];

  /// The kinds that are expected where a type is allowed.
  static List<ElementKind> typeKinds = [
    ElementKind.classKind,
    ElementKind.enumKind,
    ElementKind.extensionTypeKind,
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
    _assertMatcher(
      '+',
      expectedComponents: ['+', 'int'],
      expectedKinds: [ElementKind.methodKind],
    );
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
    _assertMatcher(
      '+',
      expectedComponents: ['+', 'C'],
      expectedKinds: [ElementKind.methodKind],
    );
  }

  Future<void> test_dotShorthand_constructor_named() async {
    await resolveTestCode('''
class A {
  final int x;
  A.named(this.x);
}
void f() {
  A a = .named(1);
}
''');
    _assertMatcher(
      'named(1)',
      expectedComponents: ['named', 'A'],
      expectedKinds: [ElementKind.constructorKind],
    );
  }

  Future<void> test_dotShorthand_constructor_named_arguments() async {
    await resolveTestCode('''
class A {
  final int x;
  A.named(this.x);
}
void f() {
  A a = .named(1);
}
''');
    _assertMatcher(
      '(1)',
      expectedComponents: ['named', 'A'],
      expectedKinds: [ElementKind.constructorKind],
    );
  }

  Future<void> test_dotShorthand_constructor_unnamed() async {
    await resolveTestCode('''
class A {}
void f() {
  A a = .new();
}
''');
    _assertMatcher(
      'new()',
      expectedComponents: ['new', 'A'],
      expectedKinds: [ElementKind.constructorKind],
    );
  }

  Future<void> test_dotShorthand_enum() async {
    await resolveTestCode('''
enum E { a, b, c }
E f() {
  return .a;
}
''');
    _assertMatcher(
      'a;',
      expectedComponents: ['a', 'E'],
      expectedKinds: staticGetterAccessorKinds,
    );
  }

  Future<void> test_dotShorthand_field() async {
    await resolveTestCode('''
class C {
  static C? field = null;
}
void f() {
  C? c = .field;
}
''');
    _assertMatcher(
      'field;',
      expectedComponents: ['field', 'C'],
      expectedKinds: staticGetterAccessorKinds,
    );
  }

  Future<void> test_dotShorthand_getter() async {
    await resolveTestCode('''
class C {
  static C get getter => C();
}
void f() {
  C c = .getter;
}
''');
    _assertMatcher(
      'getter;',
      expectedComponents: ['getter', 'C'],
      expectedKinds: staticGetterAccessorKinds,
    );
  }

  Future<void> test_dotShorthand_method() async {
    await resolveTestCode('''
class A {
  static A method() => A();
}
void f() {
  A a = .method();
}
''');
    _assertMatcher(
      'method();',
      expectedComponents: ['method', 'A'],
      expectedKinds: [ElementKind.methodKind, ElementKind.constructorKind],
    );
  }

  Future<void> test_dotShorthand_method_arguments() async {
    await resolveTestCode('''
class A {
  static A method({required int x}) => A();
}
void f() {
  A a = .method(x: 1);
}
''');
    _assertMatcher(
      '(x: 1);',
      expectedComponents: ['method', 'A'],
      expectedKinds: [ElementKind.methodKind],
    );
  }

  Future<void> test_dotShorthand_method_typeArguments() async {
    await resolveTestCode('''
class A {
  static A method<T>(T t) => A();
}
void f() {
  A a = .method<int>(1);
}
''');
    _assertMatcher(
      'method<int>(1);',
      expectedComponents: ['method', 'A'],
      expectedKinds: [ElementKind.methodKind],
    );
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
    _assertMatcher('g;', expectedComponents: ['g', 'C']);
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
    _assertHasMatcher(
      'length',
      expectedComponents: ['length', 'String'],
      expectedKinds: accessorKinds,
    );
  }

  Future<void> test_getter_withTarget_unresolved() async {
    await resolveTestCode('''
void f(String s) {
  s.foo;
}
''');
    _assertHasMatcher(
      'foo',
      expectedComponents: ['foo', 'String'],
      expectedKinds: accessorKinds,
    );
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
      isStatic: false,
    );

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
      isStatic: false,
    );

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
    _assertMatcher(
      'm(0)',
      expectedComponents: ['m', 'C'],
      expectedKinds: invocationKinds,
    );
  }

  Future<void> test_method_withoutTarget_unresolved() async {
    await resolveTestCode('''
class C {
  void m() {
    foo();
  }
}
''');
    _assertMatcher(
      'foo',
      expectedComponents: ['foo'],
      expectedKinds: invocationKinds,
    );
  }

  Future<void> test_method_withTarget_resolved() async {
    await resolveTestCode('''
void f(String s) {
  s.substring(2);
}
''');
    _assertHasMatcher(
      'substring',
      expectedComponents: ['substring', 'String'],
      expectedKinds: methodKinds,
    );
  }

  Future<void> test_method_withTarget_unresolved() async {
    await resolveTestCode('''
void f(String s) {
  s.foo(2);
}
''');
    _assertHasMatcher(
      'foo',
      expectedComponents: ['foo', 'String'],
      expectedKinds: methodKinds,
    );
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
    _assertHasMatcher(
      's =',
      expectedComponents: ['s', 'C'],
      expectedKinds: accessorKinds,
    );
  }

  Future<void> test_setter_withTarget_unresolved() async {
    await resolveTestCode('''
void f(String s) {
  s.foo = '';
}
''');
    _assertHasMatcher(
      'foo',
      expectedComponents: ['foo', 'String'],
      expectedKinds: accessorKinds,
    );
  }

  Future<void> test_type_field_resolved() async {
    await resolveTestCode('''
class C {
  String s = '';
}
''');
    _assertMatcher(
      'String',
      expectedComponents: ['String'],
      expectedKinds: typeKinds,
    );
  }

  Future<void> test_type_field_unresolved() async {
    await resolveTestCode('''
class C {
  Foo s = '';
}
''');
    _assertMatcher(
      'Foo',
      expectedComponents: ['Foo'],
      expectedKinds: typeKinds,
    );
  }

  Future<void> test_type_localVariable_resolved() async {
    await resolveTestCode('''
void f() {
  String s = '';
}
''');
    _assertMatcher(
      'String',
      expectedComponents: ['String'],
      expectedKinds: typeKinds,
    );
  }

  Future<void> test_type_localVariable_unresolved() async {
    await resolveTestCode('''
void f() {
  Foo s = '';
}
''');
    _assertMatcher(
      'Foo',
      expectedComponents: ['Foo'],
      expectedKinds: typeKinds,
    );
  }

  Future<void> test_type_method_resolved() async {
    await resolveTestCode('''
class C {
  String m() => '';
}
''');
    _assertMatcher(
      'String',
      expectedComponents: ['String'],
      expectedKinds: typeKinds,
    );
  }

  Future<void> test_type_method_unresolved() async {
    await resolveTestCode('''
class C {
  Foo m() => '';
}
''');
    _assertMatcher(
      'Foo',
      expectedComponents: ['Foo'],
      expectedKinds: typeKinds,
    );
  }

  Future<void> test_type_parameter_resolved() async {
    await resolveTestCode('''
void f(String s) {}
''');
    _assertMatcher(
      'String',
      expectedComponents: ['String'],
      expectedKinds: typeKinds,
    );
  }

  Future<void> test_type_parameter_unresolved() async {
    await resolveTestCode('''
void f(Foo s) {}
''');
    _assertMatcher(
      'Foo',
      expectedComponents: ['Foo'],
      expectedKinds: typeKinds,
    );
  }

  Future<void> test_type_topLevelFunction_resolved() async {
    await resolveTestCode('''
String f() => '';
''');
    _assertMatcher(
      'String',
      expectedComponents: ['String'],
      expectedKinds: typeKinds,
    );
  }

  Future<void> test_type_topLevelFunction_unresolved() async {
    await resolveTestCode('''
Foo f() => '';
''');
    _assertMatcher(
      'Foo',
      expectedComponents: ['Foo'],
      expectedKinds: typeKinds,
    );
  }

  Future<void> test_type_topLevelVariable_resolved() async {
    await resolveTestCode('''
String s = '';
''');
    _assertMatcher(
      'String',
      expectedComponents: ['String'],
      expectedKinds: typeKinds,
    );
  }

  Future<void> test_type_topLevelVariable_unresolved() async {
    await resolveTestCode('''
Foo s = '';
''');
    _assertMatcher(
      'Foo',
      expectedComponents: ['Foo'],
      expectedKinds: typeKinds,
    );
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
        ..add(name: 'other', rootPath: packageRootPath),
    );

    await resolveTestCode('''
import 'package:other/other.dart';

String s = '';
''');
    _assertMatcher(
      's',
      expectedUris: ['dart:core', 'package:other/other.dart'],
    );
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
