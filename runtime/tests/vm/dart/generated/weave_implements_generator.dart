// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Cf. hashing_memoize_instance_test.dart.

main() {
  const n = 8;
  // TODO(https://github.com/dart-lang/sdk/issues/61310): n = 100

  print("class C0A {}");
  print("class C0B {}");
  for (var i = 1; i <= n; i++) {
    print("class C${i}A implements C${i - 1}A, C${i - 1}B {}");
    print("class C${i}B implements C${i - 1}A, C${i - 1}B {}");
  }

  print("main() {");
  print("  if (new C${n}A() is! C0A) throw 'Wrong!';");
  print("  if (new C${n}A() is! C0B) throw 'Wrong!';");
  print("  if (new C${n}B() is! C0A) throw 'Wrong!';");
  print("  if (new C${n}B() is! C0B) throw 'Wrong!';");
  print("}");
}
