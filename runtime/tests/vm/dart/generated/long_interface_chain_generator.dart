// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

main() {
  const n = 16;
  // TODO(https://github.com/dart-lang/sdk/issues/61310): n = 256

  print("class C0 {}");
  for (var i = 1; i < n; i++) {
    print("class C${i} implements C${i - 1} {}");
  }

  print("main() {");
  print("  var c = new C${n - 1}();");
  for (var i = 1; i < n; i++) {
    print("  if (c is! C${i}) throw 'Wrong!';");
  }
  print("}");
}
