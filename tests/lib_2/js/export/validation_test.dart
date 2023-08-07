// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests uses of `@JSExport` and `createDartExport`.

import 'package:js/js.dart';
import 'package:js/js_util.dart';

// You can either have a @JSExport annotation on the entire class or select
// members only, and they may contain members that are ignored.
@JSExport()
class ExportAll {
  int field = throw '';
  final int finalField = throw '';
  int get getSet => throw '';
  set getSet(int val) => throw '';
  int method() => throw '';
}

class ExportSome {
  ExportSome();
  factory ExportSome.factory() => ExportSome();

  @JSExport()
  int field = throw '';
  final int finalField = throw '';
  @JSExport()
  int get getSet => throw '';
  set getSet(int val) => throw '';
  @JSExport()
  int method() => throw '';

  static int staticField = throw '';
  static void staticMethod() => throw '';
}

extension on ExportSome {
  int extensionMethod() => throw '';

  static int extensionStaticField = throw '';
  static void extensionStaticMethod() => throw '';
}

// We should leave Dart classes with no exports alone unless used in
// `createDartExport`.
class NoAnnotations {
  int field = throw '';
  final int finalField = throw '';
  int get getSet => throw '';
  set getSet(int val) => throw '';
  int method() => throw '';
}

// If there is a `@JSExport` annotation, but no exportable members, it's
// considered an error.
@JSExport()
abstract class ExportNoneQualify {
//             ^
// [web] Class 'ExportNoneQualify' has no exportable members in the class or the inheritance chain.
  factory ExportNoneQualify() => throw '';

  abstract int abstractField;
  void abstractMethod();

  static int staticField = throw '';
  static void staticMethod() => throw '';
}

extension on ExportNoneQualify {
  int method() => throw '';

  static int staticField = throw '';
  static void staticMethod() => throw '';
}

@JSExport()
class ExportEmpty {}
//    ^
// [web] Class 'ExportEmpty' has no exportable members in the class or the inheritance chain.

// These are errors, as there are no exportable members that have the annotation
// on them or on their class.
@JSExport()
class ExportWithNoExportSuperclass extends NoAnnotations {}
//    ^
// [web] Class 'ExportWithNoExportSuperclass' has no exportable members in the class or the inheritance chain.

@JSExport()
class ExportWithEmptyExportSuperclass extends ExportEmpty {}
//    ^
// [web] Class 'ExportWithEmptyExportSuperclass' has no exportable members in the class or the inheritance chain.

// This isn't an error to write, but it will be when you use it as part of
// `createDartExport`.
class NoExportWithExportSuperclass extends ExportAll {}

void testNumberOfExports() {
  createDartExport(ExportAll());
  createDartExport(ExportSome());
  createDartExport(NoAnnotations());
//^
// [web] Class 'NoAnnotations' does not have a `@JSExport` on it or any of its members.
  createDartExport(ExportNoneQualify());
  createDartExport(ExportEmpty());
  createDartExport(ExportWithNoExportSuperclass());
  createDartExport(ExportWithEmptyExportSuperclass());
  createDartExport(NoExportWithExportSuperclass());
//^
// [web] Class 'NoExportWithExportSuperclass' does not have a `@JSExport` on it or any of its members.
}

@JS()
@staticInterop
class StaticInterop {
  external factory StaticInterop();
}

typedef InvalidType = void Function();

void testUseDartInterface() {
  // Needs to be an interface type.
  createDartExport<InvalidType>(() {});
//^
// [web] Type argument 'void Function()' needs to be an interface type.

  // Can't use an interop class.
  createDartExport(StaticInterop());
//^
// [web] Type argument 'StaticInterop' needs to be a non-JS interop type.
}

// Incompatible members can't have the same export name using renaming.
@JSExport()
class RenameCollision {
//    ^
// [web] The following class members collide with the same export 'exportName': RenameCollision.exportName, RenameCollision.finalField, RenameCollision.getSet, RenameCollision.getSet, RenameCollision.method.
  int exportName = throw '';
  @JSExport('exportName')
  final int finalField = throw '';
  @JSExport('exportName')
  int get getSet => throw '';
  @JSExport('exportName')
  set getSet(int val) => throw '';
  @JSExport('exportName')
  void method() => throw '';
}

// Allowed collisions are only between getters and setters.
@JSExport()
class GetSetNoCollision {
  int get getSet => throw '';
  set getSet(int val) => throw '';

  @JSExport('renamedGetSet')
  int get renamedGetter => throw '';
  @JSExport('renamedGetSet')
  set renamedSetter(int val) => throw '';
}

void testCollisions() {
  createDartExport(RenameCollision());
  createDartExport(GetSetNoCollision());
}

// Class annotation values are warnings, not values, so they don't show up in
// static error tests.
@JSExport('Invalid')
class ClassWithValue {
  int get getSet => throw '';
}

@JSExport('Invalid')
mixin MixinWithValue {
  int get getSet => throw '';
}

void testClassExportWithValue() {
  createDartExport(ClassWithValue());
}

// `JSExport` classes can't export methods that define type parameters as those
// type parameters will never be instantiated through interop. Class type
// parameters are okay, however.
@JSExport()
class GenericAll {
//    ^
// [web] Class 'GenericAll' has no exportable members in the class or the inheritance chain.
  void defineTypeParam<T extends int>() {}
  T useTypeParam<T extends Object>(T t) => t;
}

class GenericSome<U> {
  @JSExport()
  void defineTypeParam<T extends int>() {}
  //   ^
  // [web] Member 'defineTypeParam' is not a concrete instance member or declares type parameters, and therefore can't be exported.
  T useTypeParam<T extends Object>(T t) => t;
  @JSExport()
  U useClassParam(U u) => u;
}

void testClassWithGenerics() {
  createDartExport(GenericAll());
  createDartExport(GenericSome());
  createDartExport(GenericSome<int>());
}

void main() {
  testNumberOfExports();
  testUseDartInterface();
  testCollisions();
  testClassExportWithValue();
  testClassWithGenerics();
}
