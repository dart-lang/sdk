// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

main() {
  const n = 512;

  print("@pragma('vm:never-inline')");
  print("@pragma('vm:entry-point') // Stop TFA");
  print("@pragma('dart2js:noInline')");
  print("dynamic check(List<int> x, int y) {");
  print("  return x[0] == y");
  for (var i = 1; i < n; i++) {
    print("    && x[$i] == y");
  }
  print("    ;");
  print("}");

  print("""
main() {
  var x = new List<int>.filled($n, 42);
  if (!check(x, 42)) throw "Wrong!";
}
""");
}
