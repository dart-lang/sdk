// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Will exhibit quadratic complexity if an implementation revisits superclass
// fields when processing each class's fields.

main() {
  const k = 64;
  const n = (1 << 11) ~/ k;
  // TODO(https://github.com/dart-lang/sdk/issues/61310): n = (1 << 16) ~/ k

  for (var i = 0; i < n; i++) {
    if (i == 0)
      print("class C${i} {");
    else
      print("class C${i} extends C${i - 1} {");

    for (var j = 0; j < k; j++) {
      print("  dynamic f${i * k + j} = ${(i * k + j) * 2};");
    }
    print("  @pragma('vm:never-inline') C${i}();");
    print("}");
  }

  print("@pragma('vm:never-inline') setDouble(c) {");
  for (var i = 0; i < (n * k); i++) {
    print("  c.f$i = ${i * 2.0};");
  }
  print("  return c;");
  print("}");

  print("@pragma('vm:never-inline') check(c) {");
  for (var i = 0; i < (n * k); i++) {
    print("  if (c.f$i != ${i * 2}) throw 'Wrong!';");
  }
  print("  return c;");
  print("}");

  print("""
main() {
  var c = new C${n - 1}();  // Initialized to Smi.
  check(c);
  setDouble(c); // Storm of field-guard updates
  check(c);
}
""");
}
