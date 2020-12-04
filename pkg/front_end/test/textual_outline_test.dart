import "dart:convert";
import "package:front_end/src/fasta/util/textual_outline.dart";

main() {
  // Doesn't sort if not asked to perform modelling.
  String result = textualOutline(utf8.encode("""
b() { print("hello"); }
a() { print("hello"); }
"""), throwOnUnexpected: true, performModelling: false);
  if (result !=
      """
b() {}

a() {}""") {
    throw "Unexpected result: $result";
  }

  // Sort if asked to perform modelling.
  result = textualOutline(utf8.encode("""
b() { print("hello"); }
a() { print("hello"); }
"""),
      throwOnUnexpected: true,
      performModelling: true,
      addMarkerForUnknownForTest: true);
  if (result !=
      """
a() {}

b() {}""") {
    throw "Unexpected result: $result";
  }

  // Content between braces or not doesn't make any difference.
  // Procedure without content.
  result = textualOutline(utf8.encode("""
a() {}
"""),
      throwOnUnexpected: true,
      performModelling: true,
      addMarkerForUnknownForTest: true);
  if (result !=
      """
a() {}""") {
    throw "Unexpected result: $result";
  }

  // Procedure with content.
  result = textualOutline(utf8.encode("""
a() {
  // Whatever
}
"""),
      throwOnUnexpected: true,
      performModelling: true,
      addMarkerForUnknownForTest: true);
  if (result !=
      """
a() {}""") {
    throw "Unexpected result: $result";
  }

  // Class without content.
  result = textualOutline(utf8.encode("""
class B {}
class A {}
"""),
      throwOnUnexpected: true,
      performModelling: true,
      addMarkerForUnknownForTest: true);
  if (result !=
      """
class A {}

class B {}""") {
    throw "Unexpected result: $result";
  }

  // Class without real content.
  result = textualOutline(utf8.encode("""
class A {
  // Whatever
}
"""),
      throwOnUnexpected: true,
      performModelling: true,
      addMarkerForUnknownForTest: true);
  if (result !=
      """
class A {}""") {
    throw "Unexpected result: $result";
  }

  // Has space between entries.
  result = textualOutline(utf8.encode("""
@a
@A(2)
typedef void F1();

@a
@A(3)
int f1, f2;
"""),
      throwOnUnexpected: true,
      performModelling: true,
      addMarkerForUnknownForTest: true);
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

  // Has space between entries.
  result = textualOutline(utf8.encode("""
@a
@A(2)
typedef void F1();
@a
@A(3)
int f1, f2;
"""),
      throwOnUnexpected: true,
      performModelling: true,
      addMarkerForUnknownForTest: true);
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

  // Knows about and can sort named mixin applications.
  result = textualOutline(utf8.encode("""
class C<T> = Object with A<Function(T)>;
class B<T> = Object with A<Function(T)>;
class A<T> {}
"""),
      throwOnUnexpected: true,
      performModelling: true,
      addMarkerForUnknownForTest: true);
  if (result !=
      """
class A<T> {}

class B<T> = Object with A<Function(T)>;

class C<T> = Object with A<Function(T)>;""") {
    throw "Unexpected result: $result";
  }

  // Knows about and can sort imports, but doesn't mix them with the other
  // content.
  result = textualOutline(utf8.encode("""
import "foo.dart" show B,
  A,
  C;
import "bar.dart";

main() {}

import "baz.dart";
"""),
      throwOnUnexpected: true,
      performModelling: true,
      addMarkerForUnknownForTest: true);
  if (result !=
      """
import "bar.dart";
import "foo.dart" show A, B, C;

main() {}

import "baz.dart";""") {
    throw "Unexpected result: $result";
  }

  // Knows about and can sort exports, but doesn't mix them with the other
  // content.
  result = textualOutline(utf8.encode("""
export "foo.dart" show B,
  A,
  C;
export "bar.dart";

main() {}

export "baz.dart";
"""),
      throwOnUnexpected: true,
      performModelling: true,
      addMarkerForUnknownForTest: true);
  if (result !=
      """
export "bar.dart";
export "foo.dart" show A, B, C;

main() {}

export "baz.dart";""") {
    throw "Unexpected result: $result";
  }

  // Knows about and can sort imports and exports,
  // but doesn't mix them with the other content.
  result = textualOutline(utf8.encode("""
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
      throwOnUnexpected: true,
      performModelling: true,
      addMarkerForUnknownForTest: true);
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

  // Knows about library, part and part of but they cannot be sorted.
  result = textualOutline(utf8.encode("""
part "foo.dart";
part of "foo.dart";
library foo;

bar() {
  // whatever
}
"""),
      throwOnUnexpected: true,
      performModelling: true,
      addMarkerForUnknownForTest: true);
  if (result !=
      """
part "foo.dart";

part of "foo.dart";

library foo;

bar() {}""") {
    throw "Unexpected result: $result";
  }

  // Ending metadata (not associated with anything) is still present.
  result = textualOutline(utf8.encode("""
@Object2()
foo() {
  // hello
}

@Object1()
"""),
      throwOnUnexpected: true,
      performModelling: true,
      addMarkerForUnknownForTest: true);
  if (result !=
      """
@Object2()
foo() {}

@Object1()""") {
    throw "Unexpected result: $result";
  }

  // Sorting of question mark types.
  result = textualOutline(utf8.encode("""
class Class1 {
  Class1? get nullable1 => property1;
  Class2? get property => null;
  Class1 get nonNullable1 => property1;
  Class2 get property1 => new Class1();
}
"""),
      throwOnUnexpected: true,
      performModelling: true,
      addMarkerForUnknownForTest: true);
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

  // Sorting of various classes with numbers and less than.
  result = textualOutline(utf8.encode("""
class C2<V> = Super<V> with Mixin<V>;
class C<V> extends Super<V> with Mixin<V> {}
class D extends Super with Mixin {}
class D2 = Super with Mixin;
"""),
      throwOnUnexpected: true,
      performModelling: true,
      addMarkerForUnknownForTest: true);
  if (result !=
      """
class C<V> extends Super<V> with Mixin<V> {}

class C2<V> = Super<V> with Mixin<V>;

class D extends Super with Mixin {}

class D2 = Super with Mixin;""") {
    throw "Unexpected result: $result";
  }

  // Metadata on imports / exports.
  result = textualOutline(utf8.encode("""
@Object1
export "a3.dart";
@Object2
import "a2.dart";
@Object3
export "a1.dart";
@Object4
import "a0.dart";
"""),
      throwOnUnexpected: true,
      performModelling: true,
      addMarkerForUnknownForTest: true);
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

  // Doesn't crash on illegal import/export.
  // Note that for now a bad import becomes unknown as it has
  // 'advanced recovery' via "handleRecoverImport" whereas exports enforce the
  // structure more.
  result = textualOutline(utf8.encode("""
// bad line.
import "a0.dart" show
// ok line
import "a1.dart" show foo;
// bad line.
export "a2.dart" show
// ok line
export "a3.dart" show foo;
"""),
      throwOnUnexpected: true,
      performModelling: true,
      addMarkerForUnknownForTest: true);
  if (result !=
      """
---- unknown chunk starts ----
import "a0.dart" show ;
---- unknown chunk ends ----

export "a2.dart" show ;
export "a3.dart" show foo;
import "a1.dart" show foo;""") {
    throw "Unexpected result: $result";
  }

  // Enums.
  result = textualOutline(utf8.encode("""
library test;

enum E { v1 }
final x = E.v1;

main() {
  x;
}
"""),
      throwOnUnexpected: true,
      performModelling: true,
      addMarkerForUnknownForTest: true);
  if (result !=
      """
library test;

enum E { v1 }

final x = E.v1;

main() {}""") {
    throw "Unexpected result: $result";
  }
}
