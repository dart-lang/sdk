// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

main() {
  const n = 1 << 10;

  print(
    "// VMOptions=--optimization-counter-threshold=100 --no-use-osr --no-background-compilation",
  );

  print("class NotGeneric {");
  for (var i = 0; i < n; i++) {
    print("  dynamic field${i};");
  }
  print("  @pragma('vm:never-inline')");
  print("  @pragma('vm:entry-point') // Stop TFA");
  print("  @pragma('dart2js:noInline')");
  print("  NotGeneric(x) :");
  for (var i = 0; i < (n - 1); i++) {
    print("    field${i} = x,");
  }
  print("    field${n - 1} = x {}");

  print("  @pragma('vm:never-inline')");
  print("  @pragma('vm:entry-point') // Stop TFA");
  print("  @pragma('dart2js:noInline')");
  print("  dynamic checkFields(dynamic x) {");
  for (var i = 0; i < n; i++) {
    print("    if (field${i} != x) return false;");
  }
  print("    return true;");
  print("  }");
  print("}");

  print("""
class C<T> extends NotGeneric {
  C(x) : super(x);

  @pragma('vm:never-inline')
  @pragma('vm:entry-point') // Stop TFA
  @pragma('dart2js:noInline')
  dynamic checkIs(dynamic x) => x is T;

  @pragma('vm:never-inline')
  @pragma('vm:entry-point') // Stop TFA
  @pragma('dart2js:noInline')
  dynamic checkAs(dynamic x) => x as T;

  @pragma('vm:never-inline')
  @pragma('vm:entry-point') // Stop TFA
  @pragma('dart2js:noInline')
  dynamic checkInstantiate() => new G<G<T>>();
}

class G<T> {}

main() {
  for (var i = 0; i < 101; i++) {
    var c1 = new C<int>(10);
    if (c1.checkIs(42) != true) throw "Wrong is";
    if (c1.checkAs(42) != 42) throw "Wrong as";
    if (c1.checkInstantiate() is! G<G<int>>) throw "Wrong instanitate";
    if (!c1.checkFields(10)) throw "Wrong fields";

    var c2 = new C<double>(10);
    if (c2.checkIs(42.0) != true) throw "Wrong is";
    if (c2.checkAs(42.0) != 42.0) throw "Wrong as";
    if (c2.checkInstantiate() is! G<G<double>>) throw "Wrong instanitate";
    if (!c2.checkFields(10)) throw "Wrong fields";

    var c3 = new C<String>(10);
    if (c3.checkIs("42") != true) throw "Wrong is";
    if (c3.checkAs("42") != "42") throw "Wrong as";
    if (c3.checkInstantiate() is! G<G<String>>) throw "Wrong instanitate";
    if (!c3.checkFields(10)) throw "Wrong fields";
  }
}
""");
}
