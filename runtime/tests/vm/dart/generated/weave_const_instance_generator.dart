// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

main() {
  const n = 100;

  print("class Box {");
  print("  final Object? content1;");
  print("  final Object? content2;");
  print("  const Box(this.content1, this.content2);");
  print("}");

  for (var j = 1; j <= 2; j++) {
    print("const box${j}_0 = Box(null, null);");
    for (var i = 1; i <= n; i++) {
      print("const box${j}_${i} = Box(box${j}_${i - 1}, box${j}_${i - 1});");
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
  print("  if (!identical(confuse(box1_${n}),");
  print("                 confuse(box2_${n}))) throw 'Wrong!';");
  print("}");
}
