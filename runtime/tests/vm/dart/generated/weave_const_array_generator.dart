// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

main() {
  const n = 100;

  for (var j = 1; j <= 2; j++) {
    print("const array${j}_0 = const <Object?>[null, null];");
    for (var i = 1; i <= n; i++) {
      print(
        "const array${j}_${i} = const <Object?>[array${j}_${i - 1}, array${j}_${i - 1}];",
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
  print("  if (!identical(confuse(array1_${n}),");
  print("                 confuse(array2_${n}))) throw 'Wrong!';");
  print("}");
}
