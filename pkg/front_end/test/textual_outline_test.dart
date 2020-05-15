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
b() { }

a() { }""") {
    throw "Unexpected result: $result";
  }

  // Sort if asked to perform modelling.
  result = textualOutline(utf8.encode("""
b() { print("hello"); }
a() { print("hello"); }
"""), throwOnUnexpected: true, performModelling: true);
  if (result !=
      """
a() { }

b() { }""") {
    throw "Unexpected result: $result";
  }

  // Content between braces or not doesn't make any difference.
  // Procedure without content.
  result = textualOutline(utf8.encode("""
a() {}
"""), throwOnUnexpected: true, performModelling: true);
  if (result !=
      """
a() { }""") {
    throw "Unexpected result: $result";
  }

  // Procedure with content.
  result = textualOutline(utf8.encode("""
a() {
  // Whatever
}
"""), throwOnUnexpected: true, performModelling: true);
  if (result !=
      """
a() { }""") {
    throw "Unexpected result: $result";
  }

  // Class without content.
  result = textualOutline(utf8.encode("""
class A {}
"""), throwOnUnexpected: true, performModelling: true);
  if (result !=
      """
class A {
}""") {
    throw "Unexpected result: $result";
  }

  // Class without real content.
  result = textualOutline(utf8.encode("""
class A {
  // Whatever
}
"""), throwOnUnexpected: true, performModelling: true);
  if (result !=
      """
class A {
}""") {
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
"""), throwOnUnexpected: true, performModelling: true);
  if (result !=
      """
@a
@A(2)
typedef void F1();

@a
@A(3)
int f1, f2;""") {
    throw "Unexpected result: $result";
  }
}
