// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

main() {
  const n = 1 << 16;
  // TODO(https://github.com/dart-lang/sdk/issues/61310): n = 1 << 20
  const m = 1 << 10;

  print("class Box { final int value; const Box(this.value); }");

  print("int sum = 0;");
  print("@pragma('vm:never-inline')");
  print("@pragma('dart2js:noInline')");
  print("add(Box x) { sum += x.value; }");

  for (var i = 0; i < m; i++) {
    print("chunk${i}() {");
    for (var j = 0; j < n / m; j++) {
      print("  add(const Box(${n ~/ m * i + j}));");
    }
    print("}");
  }

  print("main() {");
  for (var i = 0; i < m; i++) {
    print("  chunk${i}();");
  }
  print("  if (sum != ${n * (n - 1) ~/ 2}) throw 'Wrong!';");
  print("}");
}
