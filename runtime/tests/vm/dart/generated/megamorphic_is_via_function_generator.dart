// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

main() {
  const n = 1 << 12;
  // TODO(https://github.com/dart-lang/sdk/issues/61310): n = 1 << 16

  for (var i = 0; i < n; i++) {
    print("class C${i} {}");
  }

  print("@pragma('vm:never-inline')");
  print("@pragma('vm:entry-point') // Stop TFA");
  print("@pragma('dart2js:noInline')");
  print("check<T>(dynamic c) {");
  print("  if (c is! T) throw 'Wrong!';");
  print("}");

  print("main() {");
  for (var i = 0; i < n; i++) {
    print("  check<C${i}>(new C${i}());");
  }
  print("}");
}
