// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../driver_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ExtensionMethodsTest);
  });
}

@reflectiveTest
class ExtensionMethodsTest extends DriverResolutionTest {
  @override
  AnalysisOptionsImpl get analysisOptions => AnalysisOptionsImpl()
    ..contextFeatures = new FeatureSet.forTesting(
        sdkVersion: '2.3.0', additionalFeatures: [Feature.extension_methods]);

  test_implicit_getter() async {
    await assertNoErrorsInCode('''
class A<T> {}

extension E<T> on A<T> {
  List<T> get foo => <T>[];
}

void f(A<int> a) {
  a.foo;
}
''');
    var prefixedIdentifier = findNode.prefixed('.foo');
    assertMember(
      prefixedIdentifier,
      findElement.getter('foo', of: 'E'),
      {'T': 'int'},
    );
    assertType(prefixedIdentifier, 'List<int>');
  }

  test_implicit_method() async {
    await assertNoErrorsInCode('''
class A<T> {}

extension E<T> on A<T> {
  Map<T, U> foo<U>(U u) => <T, U>{};
}

void f(A<int> a) {
  a.foo(1.0);
}
''');
    // TODO(scheglov) We need to instantiate "foo" fully.
    var invocation = findNode.methodInvocation('foo(1.0)');
    assertMember(
      invocation,
      findElement.method('foo', of: 'E'),
      {'T': 'int'},
    );
//    assertMember(
//      invocation,
//      findElement.method('foo', of: 'E'),
//      {'T': 'int', 'U': 'double'},
//    );
    assertInvokeType(invocation, 'Map<int, double> Function(double)');
    assertType(invocation, 'Map<int, double>');
  }

  test_implicit_method_tearOff() async {
    await assertNoErrorsInCode('''
class A<T> {}

extension E<T> on A<T> {
  Map<T, U> foo<U>(U u) => <T, U>{};
}

void f(A<int> a) {
  a.foo;
}
''');
    var prefixedIdentifier = findNode.prefixed('foo;');
    assertMember(
      prefixedIdentifier,
      findElement.method('foo', of: 'E'),
      {'T': 'int'},
    );
    assertType(prefixedIdentifier, 'Map<int, U> Function<U>(U)');
  }

  test_implicit_setter() async {
    await assertNoErrorsInCode('''
class A<T> {}

extension E<T> on A<T> {
  set foo(T value) {}
}

void f(A<int> a) {
  a.foo = 0;
}
''');
    var propertyAccess = findNode.prefixed('.foo =');
    assertMember(
      propertyAccess,
      findElement.setter('foo', of: 'E'),
      {'T': 'int'},
    );
  }

  test_override_hasTypeArguments_getter() async {
    await assertNoErrorsInCode('''
class A<T> {}

extension E<T> on A<T> {
  List<T> get foo => <T>[];
}

void f(A<int> a) {
  E<num>(a).foo;
}
''');
    var override = findNode.extensionOverride('E<num>(a)');
    assertElement(override, findElement.extension_('E'));
    assertElementTypeStrings(override.typeArgumentTypes, ['num']);
    assertElementTypeString(override.extendedType, 'A<num>');

    var propertyAccess = findNode.propertyAccess('.foo');
    assertMember(
      propertyAccess,
      findElement.getter('foo', of: 'E'),
      {'T': 'num'},
    );
    assertType(propertyAccess, 'List<num>');
  }

  test_override_hasTypeArguments_method() async {
    await assertNoErrorsInCode('''
class A<T> {}

extension E<T> on A<T> {
  Map<T, U> foo<U>(U u) => <T, U>{};
}

void f(A<int> a) {
  E<num>(a).foo(1.0);
}
''');
    var override = findNode.extensionOverride('E<num>(a)');
    assertElement(override, findElement.extension_('E'));
    assertElementTypeStrings(override.typeArgumentTypes, ['num']);
    assertElementTypeString(override.extendedType, 'A<num>');

    // TODO(scheglov) We need to instantiate "foo" fully.
    var invocation = findNode.methodInvocation('foo(1.0)');
    assertMember(
      invocation,
      findElement.method('foo', of: 'E'),
      {'T': 'num'},
    );
//    assertMember(
//      invocation,
//      findElement.method('foo', of: 'E'),
//      {'T': 'int', 'U': 'double'},
//    );
    assertInvokeType(invocation, 'Map<num, double> Function(double)');
  }

  test_override_hasTypeArguments_method_tearOff() async {
    await assertNoErrorsInCode('''
class A<T> {}

extension E<T> on A<T> {
  Map<T, U> foo<U>(U u) => <T, U>{};
}

void f(A<int> a) {
  E<num>(a).foo;
}
''');
    var propertyAccess = findNode.propertyAccess('foo;');
    assertMember(
      propertyAccess,
      findElement.method('foo', of: 'E'),
      {'T': 'num'},
    );
    assertType(propertyAccess, 'Map<num, U> Function<U>(U)');
  }

  test_override_hasTypeArguments_setter() async {
    await assertNoErrorsInCode('''
class A<T> {}

extension E<T> on A<T> {
  set foo(T value) {}
}

void f(A<int> a) {
  E<num>(a).foo = 1.2;
}
''');
    var override = findNode.extensionOverride('E<num>(a)');
    assertElement(override, findElement.extension_('E'));
    assertElementTypeStrings(override.typeArgumentTypes, ['num']);
    assertElementTypeString(override.extendedType, 'A<num>');

    var propertyAccess = findNode.propertyAccess('.foo =');
    assertMember(
      propertyAccess,
      findElement.setter('foo', of: 'E'),
      {'T': 'num'},
    );
  }

  test_override_inferTypeArguments_getter() async {
    await assertNoErrorsInCode('''
class A<T> {}

extension E<T> on A<T> {
  List<T> get foo => <T>[];
}

void f(A<int> a) {
  E(a).foo;
}
''');
    var override = findNode.extensionOverride('E(a)');
    assertElement(override, findElement.extension_('E'));
    assertElementTypeStrings(override.typeArgumentTypes, ['int']);
    assertElementTypeString(override.extendedType, 'A<int>');

    var propertyAccess = findNode.propertyAccess('.foo');
    assertMember(
      propertyAccess,
      findElement.getter('foo', of: 'E'),
      {'T': 'int'},
    );
    assertType(propertyAccess, 'List<int>');
  }

  test_override_inferTypeArguments_method() async {
    await assertNoErrorsInCode('''
class A<T> {}

extension E<T> on A<T> {
  Map<T, U> foo<U>(U u) => <T, U>{};
}

void f(A<int> a) {
  E(a).foo(1.0);
}
''');
    var override = findNode.extensionOverride('E(a)');
    assertElement(override, findElement.extension_('E'));
    assertElementTypeStrings(override.typeArgumentTypes, ['int']);
    assertElementTypeString(override.extendedType, 'A<int>');

    // TODO(scheglov) We need to instantiate "foo" fully.
    var invocation = findNode.methodInvocation('foo(1.0)');
    assertMember(
      invocation,
      findElement.method('foo', of: 'E'),
      {'T': 'int'},
    );
//    assertMember(
//      invocation,
//      findElement.method('foo', of: 'E'),
//      {'T': 'int', 'U': 'double'},
//    );
    assertInvokeType(invocation, 'Map<int, double> Function(double)');
  }

  test_override_inferTypeArguments_method_tearOff() async {
    await assertNoErrorsInCode('''
class A<T> {}

extension E<T> on A<T> {
  Map<T, U> foo<U>(U u) => <T, U>{};
}

void f(A<int> a) {
  E(a).foo;
}
''');
    var override = findNode.extensionOverride('E(a)');
    assertElement(override, findElement.extension_('E'));
    assertElementTypeStrings(override.typeArgumentTypes, ['int']);
    assertElementTypeString(override.extendedType, 'A<int>');

    var propertyAccess = findNode.propertyAccess('foo;');
    assertMember(
      propertyAccess,
      findElement.method('foo', of: 'E'),
      {'T': 'int'},
    );
    assertType(propertyAccess, 'Map<int, U> Function<U>(U)');
  }

  test_override_inferTypeArguments_setter() async {
    await assertNoErrorsInCode('''
class A<T> {}

extension E<T> on A<T> {
  set foo(T value) {}
}

void f(A<int> a) {
  E(a).foo = 0;
}
''');
    var override = findNode.extensionOverride('E(a)');
    assertElement(override, findElement.extension_('E'));
    assertElementTypeStrings(override.typeArgumentTypes, ['int']);
    assertElementTypeString(override.extendedType, 'A<int>');

    var propertyAccess = findNode.propertyAccess('.foo =');
    assertMember(
      propertyAccess,
      findElement.setter('foo', of: 'E'),
      {'T': 'int'},
    );
  }
}
