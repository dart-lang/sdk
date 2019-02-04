// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart" show Expect;

import "package:kernel/ast.dart" show Component, DartType, Library;

import "package:kernel/class_hierarchy.dart" show ClassHierarchy;

import "package:kernel/core_types.dart" show CoreTypes;

import "package:kernel/text/ast_to_text.dart" show Printer;

import "package:kernel/type_environment.dart" show TypeEnvironment;

import "kernel_type_parser.dart"
    show KernelEnvironment, KernelFromParsedType, parseLibrary;

import "shared_type_tests.dart" show SubtypeTest;

import "type_parser.dart" as type_parser show parse, parseTypeVariables;

const String testSdk = """
  class Object;
  class Comparable<T>;
  class num implements Comparable<num>;
  class int extends num;
  class double extends num;
  class Iterable<T>;
  class List<T> extends Iterable<T>;
  class Future<T>;
  class FutureOr<T>;
  class Null;
  class Function;
  typedef Typedef<T> <S>(T) -> S;
  typedef VoidFunction () -> void;
  class DefaultTypes<S, T extends Object, U extends List<S>, V extends List<T>, W extends Comparable<W>, X extends (W) -> void, Y extends () -> W>;
  typedef TestDefaultTypes () -> DefaultTypes;
""";

const String expectedSdk = """
library core;
import self as self;

typedef Typedef<T extends self::Object = dynamic> = <S extends self::Object = dynamic>(T) → S;
typedef VoidFunction = () → void;
typedef TestDefaultTypes = () → self::DefaultTypes<dynamic, self::Object, self::List<dynamic>, self::List<self::Object>, self::Comparable<dynamic>, (<BottomType>) → void, () → self::Comparable<dynamic>>;
class Object {
}
class Comparable<T extends self::Object = dynamic> extends self::Object {
}
class num extends self::Object implements self::Comparable<self::num> {
}
class int extends self::num {
}
class double extends self::num {
}
class Iterable<T extends self::Object = dynamic> extends self::Object {
}
class List<T extends self::Object = dynamic> extends self::Iterable<self::List::T> {
}
class Future<T extends self::Object = dynamic> extends self::Object {
}
class FutureOr<T extends self::Object = dynamic> extends self::Object {
}
class Null extends self::Object {
}
class Function extends self::Object {
}
class DefaultTypes<S extends self::Object = dynamic, T extends self::Object = self::Object, U extends self::List<self::DefaultTypes::S> = self::List<dynamic>, V extends self::List<self::DefaultTypes::T> = self::List<self::Object>, W extends self::Comparable<self::DefaultTypes::W> = self::Comparable<dynamic>, X extends (self::DefaultTypes::W) → void = (<BottomType>) → void, Y extends () → self::DefaultTypes::W = () → self::Comparable<dynamic>> extends self::Object {
}
""";

Component parseSdk(Uri uri, KernelEnvironment environment) {
  Library library = parseLibrary(uri, testSdk, environment: environment);
  StringBuffer sb = new StringBuffer();
  Printer printer = new Printer(sb);
  printer.writeLibraryFile(library);
  Expect.stringEquals(expectedSdk, "$sb");
  return new Component(libraries: <Library>[library]);
}

main() {
  Uri uri = Uri.parse("dart:core");
  KernelEnvironment environment = new KernelEnvironment(uri, uri);
  Component component = parseSdk(uri, environment);
  ClassHierarchy hierarchy = new ClassHierarchy(component);
  CoreTypes coreTypes = new CoreTypes(component);
  new KernelSubtypeTest(coreTypes, hierarchy, environment).run();
}

class KernelSubtypeTest extends SubtypeTest<DartType, KernelEnvironment> {
  final CoreTypes coreTypes;

  final ClassHierarchy hierarchy;

  final KernelEnvironment environment;

  KernelSubtypeTest(this.coreTypes, this.hierarchy, this.environment);

  DartType toType(String text, KernelEnvironment environment) {
    return environment.kernelFromParsedType(type_parser.parse(text).single);
  }

  bool isSubtypeImpl(DartType subtype, DartType supertype) {
    return new TypeEnvironment(coreTypes, hierarchy)
        .isSubtypeOf(subtype, supertype);
  }

  KernelEnvironment extend(String typeParameters) {
    if (typeParameters?.isEmpty ?? true) return environment;
    return const KernelFromParsedType()
        .computeTypeParameterEnvironment(
            type_parser.parseTypeVariables("<$typeParameters>"), environment)
        .environment;
  }
}
