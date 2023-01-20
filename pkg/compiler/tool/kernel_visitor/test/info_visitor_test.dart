// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.10

import "dart:io";

import "package:expect/expect.dart";
import "package:expect/minitest.dart";
import 'package:front_end/src/compute_platform_binaries_location.dart';
import "package:kernel/kernel.dart";
import "package:path/path.dart" as path;

import "../dart_html_metrics_visitor.dart";

void runTests(MetricsVisitor visitor) {
  test("Class A does not call super", () {
    Expect.equals(visitor.classInfo["A"].invokesSuper, false);
  });

  test("Class B does call super", () {
    Expect.equals(visitor.classInfo["B"].invokesSuper, true);

    var callingMethod = visitor.classInfo["B"].methods
        .where((m) => m.name == "testSuper")
        .toList()[0];
    Expect.equals(callingMethod.invokesSuper, true);
  });

  test("Class C does not call super", () {
    Expect.equals(visitor.classInfo["C"].invokesSuper, false);
  });

  test("Class A inherited by B", () {
    Expect.equals(visitor.classInfo["A"].inheritedBy.contains("B"), true);
    Expect.equals(visitor.classInfo["B"].parent, "A");
  });

  test("Class B inherited by C", () {
    Expect.equals(visitor.classInfo["B"].inheritedBy.contains("C"), true);
    Expect.equals(visitor.classInfo["C"].parent, "B");
  });

  test("Class B inherited by F", () {
    Expect.equals(visitor.classInfo["B"].inheritedBy.contains("F"), true);
    Expect.equals(visitor.classInfo["F"].parent, "B");
  });

  test("Class C inherited by nothing", () {
    Expect.equals(visitor.classInfo["C"].inheritedBy.length, 0);
  });

  test("Class D mixed with Mix1 and Mix2", () {
    Expect.equals(visitor.classInfo["D"].mixed, true);
    Expect.deepEquals(visitor.classInfo["D"].mixins, ["Mix1", "Mix2"]);
  });

  test("Class F mixed with Mix1 and Mix2", () {
    Expect.equals(visitor.classInfo["F"].mixed, true);
    Expect.deepEquals(visitor.classInfo["F"].mixins, ["Mix1", "Mix2"]);
  });

  test("Class E implements A", () {
    Expect.equals(visitor.classInfo["E"].implementedTypes.contains("A"), true);
  });

  test("Class G extends A but fails to override getValue()", () {
    Expect.equals(
        visitor.classInfo["G"].notOverriddenMethods.contains("getValue"), true);
  });
}

void main() async {
  // Compile Dill
  var scriptDirectory = path.dirname(Platform.script.path);
  var pkgDirectory =
      path.dirname(path.dirname(path.dirname(path.dirname(scriptDirectory))));
  var compilePath = path.canonicalize(
      path.join(pkgDirectory, "front_end", "tool", "_fasta", "compile.dart"));
  var testClassesPath =
      path.canonicalize(path.join(scriptDirectory, "test_classes.dart"));
  var ddcOutlinePath = path.canonicalize(path.join(
      computePlatformBinariesLocation().toFilePath(), "ddc_outline.dill"));
  var dillPath =
      path.canonicalize(path.join(scriptDirectory, "test_classes.dill"));

  var result = await Process.run(Platform.resolvedExecutable, [
    compilePath,
    "--target=dartdevc",
    "--nnbd-strong",
    "--platform=${ddcOutlinePath}",
    "-o=${dillPath}",
    testClassesPath
  ]);

  if (result.exitCode != 0) {
    throw Exception('${result.stderr}\n${result.stdout}');
  }

  // Dill compiled from test_classes.dart using ddc.
  var component = loadComponentFromBinary(dillPath);
  var visitor = MetricsVisitor(["file:${testClassesPath}"]);

  component.accept(visitor);

  try {
    runTests(visitor);
  } finally {
    // Cleanup.
    File(dillPath).deleteSync();
  }
}
