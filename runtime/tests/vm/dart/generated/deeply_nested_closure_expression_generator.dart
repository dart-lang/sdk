// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

main() {
  const n = 64;
  // TODO(https://github.com/dart-lang/sdk/issues/61310): n = 256

  print("class C {");
  print("  String field;");
  print("  C(this.field);");

  print("  createClosure() {");
  print("     return");
  for (var i = 0; i < n; i++) {
    print("    () =>");
  }
  print("    field;");
  print("  }");
  print("}");

  print("""
main() {
  const n = $n;
  dynamic c = C("42").createClosure();
  for (var i = 0; i < n; i++) {
     if (c is! Function) throw "Wrong!";
     c = c.call();
  }
  if (c != "42") throw "Wrong!";
}
""");
}
