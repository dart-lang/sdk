// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

main() {
  const n = 1 << 10;

  print(
    "// VMOptions=--optimization-counter-threshold=100 --no-use-osr --no-background-compilation",
  );

  print("class C <");
  print("  T0");
  for (var i = 1; i < n; i++) {
    print("  ,T${i}");
  }
  print("> {");

  print("  @pragma('vm:never-inline')");
  print("  @pragma('vm:entry-point') // Stop TFA");
  print("  @pragma('dart2js:noInline')");
  print("  static create<T>() {");
  print("    return new C<");
  for (var i = 0; i < (n - 1); i++) {
    print("      double,");
  }
  print("      T>();");
  print("  }");

  print("""
  @pragma('vm:never-inline')
  @pragma('vm:entry-point') // Stop TFA
  @pragma('dart2js:noInline')
  dynamic checkIs(dynamic x) => x is T${n - 1};

  @pragma('vm:never-inline')
  @pragma('vm:entry-point') // Stop TFA
  @pragma('dart2js:noInline')
  dynamic checkAs(dynamic x) => x as T${n - 1};

  @pragma('vm:never-inline')
  @pragma('vm:entry-point') // Stop TFA
  @pragma('dart2js:noInline')
  dynamic checkInstantiate() => new G<G<T${n - 1}>>();
}

class G<T> {}

main() {
  for (var i = 0; i < 101; i++) {
    var c1 = C.create<int>();
    if (c1.checkIs(42) != true) throw "Wrong is";
    if (c1.checkAs(42) != 42) throw "Wrong as";
    if (c1.checkInstantiate() is! G<G<int>>) throw "Wrong instantiate";

    var c2 = C.create<double>();
    if (c2.checkIs(42.0) != true) throw "Wrong is";
    if (c2.checkAs(42.0) != 42.0) throw "Wrong as";
    if (c2.checkInstantiate() is! G<G<double>>) throw "Wrong instantiate";

    var c3 = C.create<String>();
    if (c3.checkIs("42") != true) throw "Wrong is";
    if (c3.checkAs("42") != "42") throw "Wrong as";
    if (c3.checkInstantiate() is! G<G<String>>) throw "Wrong instantiate";
  }
}
""");
}
