// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

main() {
  const n = 1 << 13;
  // TODO(https://github.com/dart-lang/sdk/issues/61310): n = 1 << 16

  for (var i = 0; i < n; i++) {
    print("class I${i} {}");
  }

  print("class C implements I0");
  for (var i = 1; i < n; i++) {
    print("  , I${i}");
  }
  print("{}");

  print("main() {");
  print("  var c = new C();");
  for (var i = 1; i < n; i++) {
    print("  if (c is! I${i}) throw 'Wrong!';");
  }
  print("}");
}
