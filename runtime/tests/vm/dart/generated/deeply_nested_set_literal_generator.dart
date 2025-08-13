// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

main() {
  const n = 1 << 8;
  // TODO(https://github.com/dart-lang/sdk/issues/61310): n = 1 << 16

  print("var set =");
  for (var i = 0; i < n; i++) {
    print("{");
  }
  print("null");
  for (var i = 0; i < n; i++) {
    print("}");
  }
  print(";");

  print("""
main() {
  const n = $n;
  dynamic s = set;
  for (var i = 0; i < n; i++) {
     if (s is! Set) throw "wrong";
     s = s.single;
  }
  if (s != null) throw "wrong";
}
""");
}
