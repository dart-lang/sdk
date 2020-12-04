// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test for b/162922506: verify that compiler does not use signed
// 16-bit integers to store class ids for slots.

import 'dart:io';

import 'package:expect/expect.dart';
import 'package:path/path.dart' as p;

void main() async {
  Directory tmp = await Directory.systemTemp.createTemp("b162922506");
  File testBody = File(p.join(tmp.path, 'test.dart'));
  try {
    generateTestBody(testBody);
    final result = await Process.run(Platform.executable, [
      ...Platform.executableArguments,
      '--deterministic',
      '--optimization-counter-threshold=10',
      '--no-use-osr',
      testBody.path
    ]);
    if (result.exitCode != 0) {
      print('''
Subprocess output:
${result.stdout}
${result.stderr}
''');
    }
    Expect.equals(0, result.exitCode);
    Expect.equals("OK", (result.stdout as String).trim());
  } finally {
    await tmp.delete(recursive: true);
  }
}

void generateTestBody(File testBody) {
  final sb = StringBuffer();

  sb.write("""
import 'package:expect/expect.dart';
""");
  final n = 0x8010;
  for (var i = 0; i < n; i++) {
    sb.write("""
class C$i {
  final f;
  C$i(this.f);

""");
    if (i == (n - 1)) {
      sb.write("""
  test({bool rareCase: false}) {
    final v = this.f;
    if (rareCase) {
      return v.f;
    }
    return null;
  }
""");
    }
    sb.write("""

}
""");
  }
  sb.write("""
void main() {
  final obj = C${n - 1}(C${n - 2}(C${n - 3}(null)));
  for (var i = 0; i < 100; i++) obj.test();
  Expect.isTrue(obj.test(rareCase: true) is C${n - 3});
  print("OK");
}
  """);

  testBody.writeAsStringSync(sb.toString());
}
