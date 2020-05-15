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
class DefaultTypes<S extends self::Object? = dynamic, T extends self::Object = self::Object, U extends self::List<self::DefaultTypes::S%> = self::List<dynamic>, V extends self::List<self::DefaultTypes::T> = self::List<self::Object>, W extends self::Comparable<self::DefaultTypes::W> = self::Comparable<dynamic>, X extends (self::DefaultTypes::W) → void = (Never) → void, Y extends () → self::DefaultTypes::W = () → self::Comparable<dynamic>> extends self::Object {
}
class Super extends self::Object implements self::Comparable<self::Sub> {
}
class Sub extends self::Super {
}
class FBound<T extends self::FBound<self::FBound::T> = self::FBound<dynamic>> extends self::Object {
}
class MixinApplication = self::Object with self::FBound<self::MixinApplication> {
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

main() {
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

  DartType toType(String text, TypeParserEnvironment environment) {
    return environment.parseType(text);
  }

  IsSubtypeOf isSubtypeImpl(DartType subtype, DartType supertype) {
    return new TypeEnvironment(coreTypes, hierarchy)
        .performNullabilityAwareSubtypeCheck(subtype, supertype);
  }

  TypeParserEnvironment extend(String typeParameters) {
    return environment.extendWithTypeParameters(typeParameters);
  }
}
