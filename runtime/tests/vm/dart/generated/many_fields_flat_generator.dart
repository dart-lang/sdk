// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

main() {
  const n = 1 << 11;
  // TODO(https://github.com/dart-lang/sdk/issues/61310): n = 1 << 16

  print("class C {");
  for (var i = 0; i < n; i++) {
    print("  dynamic f$i = ${i * 2};");
  }
  print("  @pragma('vm:never-inline') C();");
  print("}");

  print("@pragma('vm:never-inline') setDouble(c) {");
  for (var i = 0; i < n; i++) {
    print("  c.f$i = ${i * 2.0};");
  }
  print("  return c;");
  print("}");

  print("@pragma('vm:never-inline') check(c) {");
  for (var i = 0; i < n; i++) {
    print("  if (c.f$i != ${i * 2}) throw 'Wrong!';");
  }
  print("  return c;");
  print("}");

  print("""
main() {
  var c = new C();  // Initialized to Smi.
  check(c);
  setDouble(c); // Storm of field-guard updates
  check(c);
}
""");
}
