// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:convert";

import 'package:_fe_analyzer_shared/src/scanner/abstract_scanner.dart'
    show ScannerConfiguration;
import "package:front_end/src/util/textual_outline.dart"
    show TextualOutlineInfoForTesting, textualOutline;

const ScannerConfiguration scannerConfiguration =
    const ScannerConfiguration(enableExtensionMethods: true);

void main() {
  TextualOutlineInfoForTesting infoForTesting;

  // Doesn't sort if not asked to perform modelling.
  infoForTesting = new TextualOutlineInfoForTesting();
  String? result = textualOutline(
    utf8.encode("""
b() { print("hello"); }
a() { print("hello"); }
"""),
    scannerConfiguration,
    throwOnUnexpected: true,
    performModelling: false,
    enablePatterns: true,
    infoForTesting: infoForTesting,
  );
  if (result !=
      """
b() {}

a() {}""") {
    throw "Unexpected result: $result";
  }
  expectNoUnknownChunk(infoForTesting);

  // Sort if asked to perform modelling.
  infoForTesting = new TextualOutlineInfoForTesting();
  result = textualOutline(
    utf8.encode("""
b() { print("hello"); }
a() { print("hello"); }
"""),
    scannerConfiguration,
    throwOnUnexpected: true,
    performModelling: true,
    enablePatterns: true,
    infoForTesting: infoForTesting,
  );
  if (result !=
      """
a() {}

b() {}""") {
    throw "Unexpected result: $result";
  }
  expectNoUnknownChunk(infoForTesting);

  // Content between braces or not doesn't make any difference.
  // Procedure without content.
  infoForTesting = new TextualOutlineInfoForTesting();
  result = textualOutline(
    utf8.encode("""
a() {}
"""),
    scannerConfiguration,
    throwOnUnexpected: true,
    performModelling: true,
    enablePatterns: true,
    infoForTesting: infoForTesting,
  );
  if (result !=
      """
a() {}""") {
    throw "Unexpected result: $result";
  }
  expectNoUnknownChunk(infoForTesting);

  // Procedure with content.
  infoForTesting = new TextualOutlineInfoForTesting();
  result = textualOutline(
    utf8.encode("""
a() {
  // Whatever
}
"""),
    scannerConfiguration,
    throwOnUnexpected: true,
    performModelling: true,
    enablePatterns: true,
    infoForTesting: infoForTesting,
  );
  if (result !=
      """
a() {}""") {
    throw "Unexpected result: $result";
  }
  expectNoUnknownChunk(infoForTesting);

  // Class without content.
  infoForTesting = new TextualOutlineInfoForTesting();
  result = textualOutline(
    utf8.encode("""
class B {}
class A {}
"""),
    scannerConfiguration,
    throwOnUnexpected: true,
    performModelling: true,
    enablePatterns: true,
    infoForTesting: infoForTesting,
  );
  if (result !=
      """
class A {}

class B {}""") {
    throw "Unexpected result: $result";
  }
  expectNoUnknownChunk(infoForTesting);

  // Class without real content.
  infoForTesting = new TextualOutlineInfoForTesting();
  result = textualOutline(
    utf8.encode("""
class A {
  // Whatever
}
"""),
    scannerConfiguration,
    throwOnUnexpected: true,
    performModelling: true,
    enablePatterns: true,
    infoForTesting: infoForTesting,
  );
  if (result !=
      """
class A {}""") {
    throw "Unexpected result: $result";
  }
  expectNoUnknownChunk(infoForTesting);

  // Has space between entries.
  infoForTesting = new TextualOutlineInfoForTesting();
  result = textualOutline(
    utf8.encode("""
@a
@A(2)
typedef void F1();

@a
@A(3)
int f1, f2;
"""),
    scannerConfiguration,
    throwOnUnexpected: true,
    performModelling: true,
    enablePatterns: true,
    infoForTesting: infoForTesting,
  );
  if (result !=
      """
@a
@A(3)
int f1, f2;

@a
@A(2)
typedef void F1();""") {
    throw "Unexpected result: $result";
  }
  expectNoUnknownChunk(infoForTesting);

  // Has space between entries.
  infoForTesting = new TextualOutlineInfoForTesting();
  result = textualOutline(
    utf8.encode("""
@a
@A(2)
typedef void F1();
@a
@A(3)
int f1, f2;
"""),
    scannerConfiguration,
    throwOnUnexpected: true,
    performModelling: true,
    enablePatterns: true,
    infoForTesting: infoForTesting,
  );
  if (result !=
      """
@a
@A(3)
int f1, f2;

@a
@A(2)
typedef void F1();""") {
    throw "Unexpected result: $result";
  }
  expectNoUnknownChunk(infoForTesting);

  // Knows about and can sort named mixin applications.
  infoForTesting = new TextualOutlineInfoForTesting();
  result = textualOutline(
    utf8.encode("""
class C<T> = Object with A<Function(T)>;
class B<T> = Object with A<Function(T)>;
class A<T> {}
"""),
    scannerConfiguration,
    throwOnUnexpected: true,
    performModelling: true,
    enablePatterns: true,
    infoForTesting: infoForTesting,
  );
  if (result !=
      """
class A<T> {}

class B<T> = Object with A<Function(T)>;

class C<T> = Object with A<Function(T)>;""") {
    throw "Unexpected result: $result";
  }
  expectNoUnknownChunk(infoForTesting);

  // Knows about and can sort imports, but doesn't mix them with the other
  // content.
  infoForTesting = new TextualOutlineInfoForTesting();
  result = textualOutline(
    utf8.encode("""
import "foo.dart" show B,
  A,
  C;
import "bar.dart";

main() {}

import "baz.dart";
"""),
    scannerConfiguration,
    throwOnUnexpected: true,
    performModelling: true,
    returnNullOnError: false,
    enablePatterns: true,
    infoForTesting: infoForTesting,
  );
  if (result !=
      """
import "bar.dart";
import "foo.dart" show A, B, C;

main() {}

import "baz.dart";""") {
    throw "Unexpected result: $result";
  }
  expectNoUnknownChunk(infoForTesting);

  // Knows about and can sort exports, but doesn't mix them with the other
  // content.
  infoForTesting = new TextualOutlineInfoForTesting();
  result = textualOutline(
    utf8.encode("""
export "foo.dart" show B,
  A,
  C;
export "bar.dart";

main() {}

export "baz.dart";
"""),
    scannerConfiguration,
    throwOnUnexpected: true,
    performModelling: true,
    returnNullOnError: false,
    enablePatterns: true,
    infoForTesting: infoForTesting,
  );
  if (result !=
      """
export "bar.dart";
export "foo.dart" show A, B, C;

main() {}

export "baz.dart";""") {
    throw "Unexpected result: $result";
  }
  expectNoUnknownChunk(infoForTesting);

  // Knows about and can sort imports and exports,
  // but doesn't mix them with the other content.
  infoForTesting = new TextualOutlineInfoForTesting();
  result = textualOutline(
    utf8.encode("""
export "foo.dart" show B,
  A,
  C;
import "foo.dart" show B,
  A,
  C;
export "bar.dart";
import "bar.dart";

main() {}

export "baz.dart";
import "baz.dart";
"""),
    scannerConfiguration,
    throwOnUnexpected: true,
    performModelling: true,
    returnNullOnError: false,
    enablePatterns: true,
    infoForTesting: infoForTesting,
  );
  if (result !=
      """
export "bar.dart";
export "foo.dart" show A, B, C;
import "bar.dart";
import "foo.dart" show A, B, C;

main() {}

export "baz.dart";
import "baz.dart";""") {
    throw "Unexpected result: $result";
  }
  expectNoUnknownChunk(infoForTesting);

  // Knows about library, part and part of but they cannot be sorted.
  infoForTesting = new TextualOutlineInfoForTesting();
  result = textualOutline(
    utf8.encode("""
part "foo.dart";
part of "foo.dart";
library foo;

bar() {
  // whatever
}
"""),
    scannerConfiguration,
    throwOnUnexpected: true,
    performModelling: true,
    returnNullOnError: false,
    enablePatterns: true,
    infoForTesting: infoForTesting,
  );
  if (result !=
      """
part "foo.dart";

part of "foo.dart";

library foo;

bar() {}""") {
    throw "Unexpected result: $result";
  }
  expectNoUnknownChunk(infoForTesting);

  // Ending metadata (not associated with anything) is still present.
  infoForTesting = new TextualOutlineInfoForTesting();
  result = textualOutline(
    utf8.encode("""
@Object2()
foo() {
  // hello
}

@Object1()
"""),
    scannerConfiguration,
    throwOnUnexpected: true,
    performModelling: true,
    returnNullOnError: false,
    enablePatterns: true,
    infoForTesting: infoForTesting,
  );
  if (result !=
      """
@Object2()
foo() {}

@Object1()""") {
    throw "Unexpected result: $result";
  }
  expectNoUnknownChunk(infoForTesting);

  // Sorting of question mark types.
  infoForTesting = new TextualOutlineInfoForTesting();
  result = textualOutline(
    utf8.encode("""
class Class1 {
  Class1? get nullable1 => property1;
  Class2? get property => null;
  Class1 get nonNullable1 => property1;
  Class2 get property1 => new Class1();
}
"""),
    scannerConfiguration,
    throwOnUnexpected: true,
    performModelling: true,
    enablePatterns: true,
    infoForTesting: infoForTesting,
  );
  if (result !=
      """
class Class1 {
  Class1? get nullable1 => property1;
  Class1 get nonNullable1 => property1;
  Class2? get property => null;
  Class2 get property1 => new Class1();
}""") {
    throw "Unexpected result: $result";
  }
  expectNoUnknownChunk(infoForTesting);

  // Sorting of various classes with numbers and less than.
  infoForTesting = new TextualOutlineInfoForTesting();
  result = textualOutline(
    utf8.encode("""
class C2<V> = Super<V> with Mixin<V>;
class C<V> extends Super<V> with Mixin<V> {}
class D extends Super with Mixin {}
class D2 = Super with Mixin;
"""),
    scannerConfiguration,
    throwOnUnexpected: true,
    performModelling: true,
    enablePatterns: true,
    infoForTesting: infoForTesting,
  );
  if (result !=
      """
class C<V> extends Super<V> with Mixin<V> {}

class C2<V> = Super<V> with Mixin<V>;

class D extends Super with Mixin {}

class D2 = Super with Mixin;""") {
    throw "Unexpected result: $result";
  }
  expectNoUnknownChunk(infoForTesting);

  // Metadata on imports / exports.
  infoForTesting = new TextualOutlineInfoForTesting();
  result = textualOutline(
    utf8.encode("""
@Object1
export "a3.dart";
@Object2
import "a2.dart";
@Object3
export "a1.dart";
@Object4
import "a0.dart";
"""),
    scannerConfiguration,
    throwOnUnexpected: true,
    performModelling: true,
    enablePatterns: true,
    infoForTesting: infoForTesting,
  );
  if (result !=
      """
@Object3
export "a1.dart";

@Object1
export "a3.dart";

@Object4
import "a0.dart";

@Object2
import "a2.dart";""") {
    throw "Unexpected result: $result";
  }
  expectNoUnknownChunk(infoForTesting);

  // Doesn't crash on illegal import/export.
  // Note that for now a bad import becomes unknown as it has
  // 'advanced recovery' via "handleRecoverImport" whereas exports enforce the
  // structure more.
  infoForTesting = new TextualOutlineInfoForTesting();
  result = textualOutline(
    utf8.encode("""
// bad line.
import "a0.dart" show
// ok line
import "a1.dart" show foo;
// bad line.
export "a2.dart" show
// ok line
export "a3.dart" show foo;
"""),
    scannerConfiguration,
    throwOnUnexpected: true,
    performModelling: true,
    returnNullOnError: false,
    enablePatterns: true,
    infoForTesting: infoForTesting,
  );
  if (result !=
      """
import "a0.dart" show ;

export "a2.dart" show ;
export "a3.dart" show foo;
import "a1.dart" show foo;""") {
    throw "Unexpected result: $result";
  }
  expectUnknownChunk(infoForTesting);

  // Enums.
  infoForTesting = new TextualOutlineInfoForTesting();
  result = textualOutline(
    utf8.encode("""
library test;

enum E { v1 }
final x = E.v1;

main() {
  x;
}
"""),
    scannerConfiguration,
    throwOnUnexpected: true,
    performModelling: true,
    enablePatterns: true,
    infoForTesting: infoForTesting,
  );
  if (result !=
      """
library test;

enum E { v1 }

final x = E.v1;

main() {}""") {
    throw "Unexpected result: $result";
  }
  expectNoUnknownChunk(infoForTesting);
}

void expectUnknownChunk(TextualOutlineInfoForTesting infoForTesting) {
  if (infoForTesting.hasUnknownChunk != true) {
    throw "Expected output to contain unknown chunk, but didn't.";
  }
}

void expectNoUnknownChunk(TextualOutlineInfoForTesting infoForTesting) {
  if (infoForTesting.hasUnknownChunk != false) {
    throw "Expected output to contain no unknown chunk, but it did.";
  }
}
