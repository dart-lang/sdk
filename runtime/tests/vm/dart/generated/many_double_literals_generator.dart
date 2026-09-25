// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

main() {
  const n = 1 << 20;
  const m = 1 << 10;

  print("double sum = 0.0;");
  print("@pragma('vm:never-inline')");
  print("@pragma('dart2js:never-inline')");
  print("add(double x) { sum += x; }");

  final buffer = StringBuffer();
  for (var i = 0; i < m; i++) {
    buffer.clear();
    buffer.writeln("chunk${i}() {");
    for (var j = 0; j < n ~/ m; j++) {
      buffer.writeln("  add(${n ~/ m * i + j}.0);");
    }
    buffer.write("}");
    print(buffer);
  }

  buffer.clear();
  buffer.writeln("main() {");
  for (var i = 0; i < m; i++) {
    buffer.writeln("  chunk${i}();");
  }
  buffer.writeln("  if (sum != ${n * (n - 1) ~/ 2}.0) throw 'Wrong!';");
  buffer.write("}");
  print(buffer);
}
