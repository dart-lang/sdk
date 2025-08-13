// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

main() {
  const n = 8;
  // TODO(https://github.com/dart-lang/sdk/issues/61310): n = 100

  for (var j = 1; j <= 2; j++) {
    print("const (Object?, Object?) record${j}_0 = (null, null);");
    for (var i = 1; i <= n; i++) {
      print(
        "const (Object?, Object?) record${j}_${i} = (record${j}_${i - 1}, record${j}_${i - 1});",
      );
    }
  }

  print("@pragma('vm:never-inline')");
  print("@pragma('vm:entry-point')");
  print("@pragma('dart2js:noInline')");
  print("confuse(x) {");
  print("  try {");
  print("    throw x;");
  print("  } catch (e) {");
  print("    return e;");
  print("  }");
  print("}");

  print("main() {");
  print("  if (!identical(confuse(record1_${n}),");
  print("                 confuse(record2_${n}))) throw 'Wrong!';");
  print("}");
}
