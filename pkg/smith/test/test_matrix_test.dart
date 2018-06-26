// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'package:expect/minitest.dart';

import 'package:smith/smith.dart';

void main() {
  group("TestMatrix.fromJson()", () {
    test("parses configurations", () {
      var testMatrix = TestMatrix.fromJson({
        "configurations": {
          "x64-dart2js-debug-vm-linux": <String, dynamic>{
            "options": <String, dynamic>{"enableAsserts": true},
          },
          "x64-dartdevc-vm-linux": <String, dynamic>{
            "options": <String, dynamic>{
              "mode": "release",
              "enableAsserts": true
            },
          },
        }
      });

      expect(
          testMatrix.configurations[0],
          equals(Configuration("x64-dart2js-debug-vm-linux", Architecture.x64,
              Compiler.dart2js, Mode.debug, Runtime.vm, System.linux,
              enableAsserts: true)));
      expect(
          testMatrix.configurations[1],
          equals(Configuration("x64-dartdevc-vm-linux", Architecture.x64,
              Compiler.dartdevc, Mode.release, Runtime.vm, System.linux,
              enableAsserts: true)));
    });

    test("error if expanded configuration names collide", () {
      expectJsonError(
          'Configuration "none-x64-dart2js-debug-vm-linux" already exists.', {
        "configurations": {
          "none-x64-dart2js-debug-vm-linux": <String, dynamic>{},
          "none-(x64|ia32)-dart2js-debug-vm-linux": <String, dynamic>{},
        }
      });
    });

    test("error if two configurations have same options", () {
      expectJsonError(
          'Configuration "two-x64-dart2js-debug-vm-linux" is identical to '
          '"one-x64-dart2js-debug-vm-linux".',
          {
            "configurations": {
              "one-x64-dart2js-debug-vm-linux": <String, dynamic>{
                "options": <String, dynamic>{"enableAsserts": true}
              },
              "two-x64-dart2js-debug-vm-linux": <String, dynamic>{
                "options": <String, dynamic>{"enableAsserts": true}
              },
            }
          });
    });
  });
}

void expectJsonError(String error, Map<String, dynamic> json) {
  try {
    var testMatrix = TestMatrix.fromJson(json);
    fail("Expected FormatException but got $testMatrix.");
  } on FormatException catch (ex) {
    expect(ex.message, equals(error));
  }
}
