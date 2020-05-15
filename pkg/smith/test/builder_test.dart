// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'package:expect/minitest.dart';

import 'package:smith/smith.dart';

import 'test_helpers.dart';

final configurations = Configuration.expandTemplate(
    "foo-(ia32|x64|arm)-(none|dart2js|dartk)-(debug|release)-(d8|vm)-"
    "(linux|mac|win)",
    {});

void main() {
  group("Step", () {
    test("non-test step", () {
      var step = Step.parse({
        "script": "foo.py",
        "name": "foo",
      }, {}, configurations);
      expect(step.isTestStep, isFalse);
      expect(step.testedConfiguration, null);
    });
    test("explicit test step", () {
      var step = Step.parse({
        "name": "foo",
        "script": "tools/test.py",
        "arguments": ["-nfoo-x64-none-debug-d8-linux"]
      }, {}, configurations);
      expect(step.isTestStep, isTrue);
      expect(step.testedConfiguration.name, "foo-x64-none-debug-d8-linux");
    });
    test("custom test runner step", () {
      var step = Step.parse({
        "name": "foo",
        "script": "foo.py",
        "testRunner": true,
        "arguments": ["-nfoo-x64-none-debug-d8-linux"]
      }, {}, configurations);
      expect(step.isTestStep, isTrue);
      expect(step.testedConfiguration.name, "foo-x64-none-debug-d8-linux");
    });
    test("implicit test step", () {
      var step = Step.parse({
        "name": "foo",
        "arguments": ["-nfoo-x64-none-debug-d8-linux"]
      }, {}, configurations);
      expect(step.isTestStep, isTrue);
      expect(step.testedConfiguration.name, "foo-x64-none-debug-d8-linux");
    });
    test("a step can only test one configuration", () {
      expectFormatError(
          "Step tests multiple configurations: "
          "[-nfoo-x64-none-debug-d8-linux, -nfoo-x64-none-release-d8-linux]",
          () {
        Step.parse({
          "name": "foo",
          "arguments": [
            "-nfoo-x64-none-debug-d8-linux",
            "-nfoo-x64-none-release-d8-linux"
          ]
        }, {}, configurations);
      });
    });
    test("a test step using the long option name", () {
      var step = Step.parse({
        "name": "foo",
        "arguments": ["--named_configuration foo-x64-none-debug-d8-linux"]
      }, {}, configurations);
      expect(step.isTestStep, isTrue);
      expect(step.testedConfiguration.name, "foo-x64-none-debug-d8-linux");
    });
    test("a test step using multiple values for the argument", () {
      expectFormatError(
          "Step tests multiple configurations: [-n foo-x64-none-debug-d8-linux,"
          "foo-x64-none-release-d8-linux]", () {
        Step.parse({
          "name": "foo",
          "arguments": [
            "-n foo-x64-none-debug-d8-linux,foo-x64-none-release-d8-linux"
          ]
        }, {}, configurations);
      });
    });
    test("step arguments can contain arbitrary options and flags", () {
      var step = Step.parse({
        "name": "foo",
        "arguments": ["-nfoo-x64-none-debug-d8-linux", "--bar", "-b=az"]
      }, {}, configurations);
      expect(step.isTestStep, isTrue);
      expect(step.testedConfiguration.name, "foo-x64-none-debug-d8-linux");
    });
    test("in non-test steps, argument -n can have arbitrary values", () {
      var step = Step.parse({
        "script": "foo.py",
        "name": "foo",
        "arguments": ["-n not-a-configuration"]
      }, {}, configurations);
      expect(step.isTestStep, isFalse);
    });
  });
  group("Builder", () {
    test("'system' is parsed from builder name", () {
      expectTestedConfigurations({
        "builders": ["foo-linux", "foo-mac", "foo-win"],
        "steps": [
          {
            "name": "foo",
            "arguments": [r"-nfoo-x64-none-debug-d8-${system}"]
          }
        ],
      }, [
        "foo-x64-none-debug-d8-linux",
        "foo-x64-none-debug-d8-mac",
        "foo-x64-none-debug-d8-win"
      ]);
    });
  });
  test("'mode' is parsed from builder name", () {
    expectTestedConfigurations({
      "builders": ["foo-debug", "foo-release"],
      "steps": [
        {
          "name": "foo",
          "arguments": [r"-nfoo-x64-none-${mode}-d8-linux"]
        }
      ],
    }, [
      "foo-x64-none-debug-d8-linux",
      "foo-x64-none-release-d8-linux"
    ]);
  });
  test("'arch' is parsed from builder name", () {
    expectTestedConfigurations({
      "builders": ["foo-ia32", "foo-x64", "foo-arm"],
      "steps": [
        {
          "name": "foo",
          "arguments": [r"-nfoo-${arch}-none-debug-d8-linux"]
        }
      ],
    }, [
      "foo-ia32-none-debug-d8-linux",
      "foo-x64-none-debug-d8-linux",
      "foo-arm-none-debug-d8-linux"
    ]);
  });
  test("'runtime' is parsed from builder name", () {
    expectTestedConfigurations({
      "builders": ["foo-d8", "foo-vm"],
      "steps": [
        {
          "name": "foo",
          "arguments": [r"-nfoo-x64-none-debug-${runtime}-linux"]
        }
      ],
    }, [
      "foo-x64-none-debug-d8-linux",
      "foo-x64-none-debug-vm-linux"
    ]);
  });
  test("'system' is not implied by builder name", () {
    expectFormatError(
        r"Undefined value for 'system' in "
        r"'-nfoo-x64-none-debug-d8-${system}'", () {
      parseBuilders([
        {
          "builders": ["foo"],
          "steps": [
            {
              "name": "foo",
              "arguments": [r"-nfoo-x64-none-debug-d8-${system}"]
            }
          ],
        }
      ], configurations);
    });
  });
  test("'mode' is not implied by builder name", () {
    expectFormatError(
        r"Undefined value for 'mode' in "
        r"'-nfoo-x64-none-${mode}-d8-linux'", () {
      parseBuilders([
        {
          "builders": ["foo"],
          "steps": [
            {
              "name": "foo",
              "arguments": [r"-nfoo-x64-none-${mode}-d8-linux"]
            }
          ],
        }
      ], configurations);
    });
  });
  test("'arch' is not implied by builder name", () {
    expectFormatError(
        r"Undefined value for 'arch' in "
        r"'-nfoo-${arch}-none-debug-d8-linux'", () {
      parseBuilders([
        {
          "builders": ["foo"],
          "steps": [
            {
              "name": "foo",
              "arguments": [r"-nfoo-${arch}-none-debug-d8-linux"]
            }
          ],
        }
      ], configurations);
    });
  });
  test("'runtime' is not implied by builder name", () {
    expectFormatError(
        r"Undefined value for 'runtime' in "
        r"'-nfoo-x64-none-debug-${runtime}-linux'", () {
      parseBuilders([
        {
          "builders": ["foo"],
          "steps": [
            {
              "name": "foo",
              "arguments": [r"-nfoo-x64-none-debug-${runtime}-linux"]
            }
          ],
        }
      ], configurations);
    });
  });
}

void expectTestedConfigurations(
    Map builderConfiguration, List<String> expectedConfigurations) {
  var builders = parseBuilders([builderConfiguration], configurations);
  int numberOfConfigurations = expectedConfigurations.length;
  expect(builders.length, numberOfConfigurations);
  for (var builderId = 0; builderId < numberOfConfigurations; builderId++) {
    var builder = builders[builderId];
    expect(builder.steps.length, 1);
    var step = builder.steps[0];
    expect(step.isTestStep, isTrue);
  }
  expect(builders.map((b) => b.steps[0].testedConfiguration.name).toList(),
      equals(expectedConfigurations));
}
