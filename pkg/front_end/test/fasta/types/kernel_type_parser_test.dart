// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart" show Expect;

import "package:kernel/ast.dart" show Component, Library;

import "package:kernel/class_hierarchy.dart" show ClassHierarchy;

import "package:kernel/text/ast_to_text.dart" show Printer;

import "kernel_type_parser.dart" show parseLibrary;

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
""";

main() {
  Library library = parseLibrary(Uri.parse("dart:core"), testSdk);
  StringBuffer sb = new StringBuffer();
  Printer printer = new Printer(sb);
  printer.writeLibraryFile(library);
  Expect.stringEquals(expectedSdk, "$sb");
  Component component = new Component(libraries: <Library>[library]);
  new ClassHierarchy(component);
}
