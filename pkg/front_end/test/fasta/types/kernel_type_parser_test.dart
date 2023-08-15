// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart" show Expect;

import "package:kernel/ast.dart" show Component, DartType, Library;

import "package:kernel/class_hierarchy.dart" show ClassHierarchy;

import "package:kernel/core_types.dart" show CoreTypes;

import "package:kernel/text/ast_to_text.dart" show Printer;

import "package:kernel/type_environment.dart" show IsSubtypeOf, TypeEnvironment;

import 'package:kernel/testing/type_parser_environment.dart'
    show TypeParserEnvironment, parseLibrary;

import 'package:kernel/testing/mock_sdk.dart' show mockSdk;

import 'shared_type_tests.dart' show SubtypeTest;

const String testSdk = """
typedef Typedef<T> <S>(T) -> S;
typedef VoidFunction () -> void;
class DefaultTypes<S, T extends Object, U extends List<S>, V extends List<T>, W extends Comparable<W>, X extends (W) -> void, Y extends () -> W>;
typedef TestDefaultTypes () -> DefaultTypes;
typedef Id<T> T;
typedef TestSorting ({int c, int b, int a}) -> void;
class Super implements Comparable<Sub>;
class Sub extends Super;
class FBound<T extends FBound<T>>;
class MixinApplication extends Object with FBound<MixinApplication>;
class ExtendedClass;
class ExtendedGenericClass<X>;
extension Extension on ExtendedClass;
extension GenericExtension<Y> on ExtendedGenericClass<Y>;
extension TopExtension on dynamic;
extension GenericTopExtension<Z> on dynamic;
class ExtendedSubclass extends ExtendedClass;
extension type NullableExtensionType(Object? it);
extension type NonNullableExtensionType(Object it);
extension type GenericExtensionType<T>(T it);
extension type GenericExtensionSubType<T>(T it) implements GenericExtensionType<T>;
extension type NonNullableGenericExtensionType<T extends Object>(T it);
class GenericClass<T>;
extension type GenericExtensionTypeImplements<T>(GenericClass<T> it) implements GenericClass<T>;
class SubGenericClass<T> extends GenericClass<T>;
extension type GenericSubExtensionTypeImplements<T>(SubGenericClass<T> it) implements GenericExtensionTypeImplements<T>, SubGenericClass<T>;
extension type NestedGenericExtensionType<T>(GenericExtensionType<T> it);
""";

const String expectedSdk = """
library core;
import self as self;

typedef Typedef<T extends self::Object? = dynamic> = <S extends self::Object? = dynamic>(T%) → S%;
typedef VoidFunction = () → void;
typedef TestDefaultTypes = () → self::DefaultTypes<dynamic, self::Object, self::List<dynamic>, self::List<self::Object>, self::Comparable<dynamic>, (Never) → void, () → self::Comparable<dynamic>>;
typedef Id<T extends self::Object? = dynamic> = T%;
typedef TestSorting = ({a: self::int, b: self::int, c: self::int}) → void;
class Object {
}
class Comparable<T extends self::Object? = dynamic> extends self::Object {
}
class num extends self::Object implements self::Comparable<self::num> {
}
class int extends self::num {
}
class double extends self::num {
}
class Iterable<T extends self::Object? = dynamic> extends self::Object {
}
class List<T extends self::Object? = dynamic> extends self::Iterable<self::List::T%> {
}
class Future<T extends self::Object? = dynamic> extends self::Object {
}
class FutureOr<T extends self::Object? = dynamic> extends self::Object {
}
class Null extends self::Object {
}
class Function extends self::Object {
}
class String extends self::Object {
}
class bool extends self::Object {
}
class Record extends self::Object {
}
class DefaultTypes<S extends self::Object? = dynamic, T extends self::Object, U extends self::List<self::DefaultTypes::S%> = self::List<dynamic>, V extends self::List<self::DefaultTypes::T> = self::List<self::Object>, W extends self::Comparable<self::DefaultTypes::W> = self::Comparable<dynamic>, X extends (self::DefaultTypes::W) → void = (Never) → void, Y extends () → self::DefaultTypes::W = () → self::Comparable<dynamic>> extends self::Object {
}
class Super extends self::Object implements self::Comparable<self::Sub> {
}
class Sub extends self::Super {
}
class FBound<T extends self::FBound<self::FBound::T> = self::FBound<dynamic>> extends self::Object {
}
class MixinApplication = self::Object with self::FBound<self::MixinApplication> {
}
class ExtendedClass extends self::Object {
}
class ExtendedGenericClass<X extends self::Object? = dynamic> extends self::Object {
}
class ExtendedSubclass extends self::ExtendedClass {
}
class GenericClass<T extends self::Object? = dynamic> extends self::Object {
}
class SubGenericClass<T extends self::Object? = dynamic> extends self::GenericClass<self::SubGenericClass::T%> {
}
extension Extension on self::ExtendedClass {
}
extension GenericExtension<Y extends self::Object? = dynamic> on self::ExtendedGenericClass<Y%> {
}
extension TopExtension on dynamic {
}
extension GenericTopExtension<Z extends self::Object? = dynamic> on dynamic {
}
extension type NullableExtensionType(self::Object? it) {
}
extension type NonNullableExtensionType(self::Object it) {
}
extension type GenericExtensionType<T extends self::Object? = dynamic>(T% it) {
}
extension type GenericExtensionSubType<T extends self::Object? = dynamic>(T% it) implements self::GenericExtensionType<T%> /* = T% */ {
}
extension type NonNullableGenericExtensionType<T extends self::Object>(T it) {
}
extension type GenericExtensionTypeImplements<T extends self::Object? = dynamic>(self::GenericClass<T%> it) implements self::GenericClass<T%> {
}
extension type GenericSubExtensionTypeImplements<T extends self::Object? = dynamic>(self::SubGenericClass<T%> it) implements self::GenericExtensionTypeImplements<T%> /* = self::GenericClass<T%> */, self::SubGenericClass<T%> {
}
extension type NestedGenericExtensionType<T extends self::Object? = dynamic>(self::GenericExtensionType<T%> /* = T% */ it) {
}
""";

Component parseSdk(Uri uri, TypeParserEnvironment environment) {
  Library library =
      parseLibrary(uri, mockSdk + testSdk, environment: environment);
  StringBuffer sb = new StringBuffer();
  Printer printer = new Printer(sb);
  printer.writeLibraryFile(library);
  Expect.stringEquals(expectedSdk, "$sb");
  return new Component(libraries: <Library>[library]);
}

void main() {
  Uri uri = Uri.parse("dart:core");
  TypeParserEnvironment environment = new TypeParserEnvironment(uri, uri);
  Component component = parseSdk(uri, environment);
  CoreTypes coreTypes = new CoreTypes(component);
  ClassHierarchy hierarchy = new ClassHierarchy(component, coreTypes);
  new KernelSubtypeTest(coreTypes, hierarchy, environment).run();
}

class KernelSubtypeTest extends SubtypeTest<DartType, TypeParserEnvironment> {
  final CoreTypes coreTypes;

  final ClassHierarchy hierarchy;

  final TypeParserEnvironment environment;

  KernelSubtypeTest(this.coreTypes, this.hierarchy, this.environment);

  @override
  bool get skipFutureOrPromotion => true;

  @override
  DartType toType(String text, TypeParserEnvironment environment) {
    return environment.parseType(text);
  }

  @override
  IsSubtypeOf isSubtypeImpl(DartType subtype, DartType supertype) {
    return new TypeEnvironment(coreTypes, hierarchy)
        .performNullabilityAwareSubtypeCheck(subtype, supertype);
  }

  @override
  TypeParserEnvironment extend(String? typeParameters) {
    return environment.extendWithTypeParameters(typeParameters);
  }
}
