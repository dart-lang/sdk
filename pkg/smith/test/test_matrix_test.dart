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
            "options": <String, dynamic>{"enable-asserts": true},
          },
          "x64-dartdevc-vm-linux": <String, dynamic>{
            "options": <String, dynamic>{
              "mode": "release",
              "enable-asserts": true
            },
          },
        },
        "builder_configurations": [],
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
                "options": <String, dynamic>{"enable-asserts": true}
              },
              "two-x64-dart2js-debug-vm-linux": <String, dynamic>{
                "options": <String, dynamic>{"enable-asserts": true}
              },
            }
          });
    });

    test("two builders have same name", () {
      expectJsonError('Duplicate builder name: "front-end-linux-release-x64"', {
        "builder_configurations": [
          {
            "builders": [
              "front-end-linux-release-x64",
              "front-end-linux-release-x64"
            ],
          },
        ]
      });
    });

    test("two builders have same name in different configurations", () {
      expectJsonError('Duplicate builder name: "front-end-linux-release-x64"', {
        "builder_configurations": [
          {
            "builders": ["front-end-linux-release-x64"],
          },
          {
            "builders": ["front-end-linux-release-x64"],
          },
        ]
      });
    });

    test("a builder step refers to existing configuration", () {
      TestMatrix.fromJson({
        "configurations": {"fasta-linux": {}},
        "builder_configurations": [
          {
            "builders": ["front-end-linux-release-x64"],
            "steps": [
              {
                "name": "fasta sdk tests",
                "arguments": [r"-nfasta-${system}"],
              },
            ],
          },
        ]
      });
    });

    test("a builder step refers to non-existing configuration", () {
      expectJsonError('Undefined configuration: fasta-linux', {
        "configurations": {"fasta-win": {}},
        "builder_configurations": [
          {
            "builders": ["front-end-linux-release-x64"],
            "steps": [
              {
                "name": "fasta sdk tests",
                "arguments": [r"-nfasta-${system}"],
              },
            ],
          },
        ]
      });
    });

    test("a configuration is tested on more than one builder", () {
      expectJsonError(
          'Configuration "fasta-linux" is tested on both '
          '"test-fasta-2" and "test-fasta-1"',
          {
            "configurations": {"fasta-linux": {}},
            "builder_configurations": [
              {
                "builders": ["test-fasta-1"],
                "steps": [
                  {
                    "name": "fasta1",
                    "arguments": [r"-nfasta-linux"],
                  },
                ],
              },
              {
                "builders": ["test-fasta-2"],
                "steps": [
                  {
                    "name": "fasta2",
                    "arguments": [r"-nfasta-linux"],
                  },
                ],
              },
            ]
          });
    });
  });

  test("a list of branches is parsed", () {
    var testMatrix = TestMatrix.fromJson({
      "branches": ["master", "stable"]
    });
    expect(testMatrix.branches, unorderedEquals(["master", "stable"]));
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
