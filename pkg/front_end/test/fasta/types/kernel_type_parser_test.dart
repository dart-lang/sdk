// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart" show Expect;

import "package:kernel/ast.dart" show Component, DartType, Library;

import "package:kernel/class_hierarchy.dart" show ClassHierarchy;

import "package:kernel/core_types.dart" show CoreTypes;

import "package:kernel/text/ast_to_text.dart" show Printer;

import "package:kernel/type_environment.dart" show TypeEnvironment;

import "kernel_type_parser.dart" show KernelEnvironment, parseLibrary;

import "shared_type_tests.dart" show SubtypeTest;

import "type_parser.dart" as type_parser show parse;

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
""";

const String expectedSdk = """
library;
import self as self;

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
""";

main() {
  Uri uri = Uri.parse("dart:core");
  KernelEnvironment environment = new KernelEnvironment(uri, uri);
  Library library = parseLibrary(uri, testSdk, environment: environment);
  StringBuffer sb = new StringBuffer();
  Printer printer = new Printer(sb);
  printer.writeLibraryFile(library);
  Expect.stringEquals(expectedSdk, "$sb");
  Component component = new Component(libraries: <Library>[library]);
  ClassHierarchy hierarchy = new ClassHierarchy(component);
  CoreTypes coreTypes = new CoreTypes(component);
  new KernelSubtypeTest(coreTypes, hierarchy, environment).run();
}

class KernelSubtypeTest extends SubtypeTest<DartType> {
  final CoreTypes coreTypes;

  final ClassHierarchy hierarchy;

  final KernelEnvironment environment;

  KernelSubtypeTest(this.coreTypes, this.hierarchy, this.environment);

  DartType toType(String text) {
    return environment.kernelFromParsedType(type_parser.parse(text).single);
  }

  bool isSubtypeImpl(DartType subtype, DartType supertype, bool legacyMode) {
    return new TypeEnvironment(coreTypes, hierarchy, legacyMode: legacyMode)
        .isSubtypeOf(subtype, supertype);
  }
}
