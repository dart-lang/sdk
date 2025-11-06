// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

main() {
  const n = 1 << 8;
  // TODO(https://github.com/dart-lang/sdk/issues/61310): n = 1 << 16

  print("class C<T> {}");

  for (var i = 0; i < n; i++) {
    print("C<");
  }
  print("int");
  for (var i = 0; i < n; i++) {
    print(">");
  }
  print(" c = new");
  for (var i = 0; i < n; i++) {
    print("C<");
  }
  print("int");
  for (var i = 0; i < n; i++) {
    print(">");
  }
  print("();");

  print("@pragma('vm:never-inline')");
  print("@pragma('vm:entry-point') // Stop TFA");
  print("@pragma('dart2js:noInline')");
  print("bool isCheck(dynamic c) {");
  print("  return c is ");
  for (var i = 0; i < n; i++) {
    print("C<");
  }
  print("int");
  for (var i = 0; i < n; i++) {
    print(">");
  }
  print(";");
  print("}");

  print("@pragma('vm:never-inline')");
  print("@pragma('vm:entry-point') // Stop TFA");
  print("@pragma('dart2js:noInline')");
  print("void asCheck(dynamic c) {");
  print("  c as ");
  for (var i = 0; i < n; i++) {
    print("C<");
  }
  print("int");
  for (var i = 0; i < n; i++) {
    print(">");
  }
  print(";");
  print("}");

  print("main() {");
  print("  if (!isCheck(c)) throw 'Wrong!';");
  print("  asCheck(c);");
  print("}");
}
