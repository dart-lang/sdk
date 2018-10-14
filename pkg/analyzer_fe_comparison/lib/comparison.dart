// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer_fe_comparison/src/analyzer.dart' as analyzer;
import 'package:analyzer_fe_comparison/src/comparison_node.dart';
import 'package:analyzer_fe_comparison/src/kernel.dart' as kernel;
import 'package:path/path.dart' as path;

/// Compares the analyzer and kernel representations of a package, and prints
/// the resulting diff.
void comparePackages(
    String platformPath, String projectLibPath, String packagesFilePath) async {
  ComparisonNode analyzerNode = await analyzer.analyzePackage(projectLibPath);
  var packagesFileUri = Uri.file(packagesFilePath);
  var inputs = <Uri>[];
  for (var library in analyzerNode.children) {
    inputs.add(Uri.parse(library.text));
  }
  var platformUri = Uri.file(platformPath);
  ComparisonNode kernelNode =
      await kernel.analyzePackage(inputs, packagesFileUri, platformUri);
  print(ComparisonNode.diff(kernelNode, analyzerNode, 'CFE', 'analyzer'));
}

/// Compares the analyzer and kernel representations of a test file, and prints
/// the resulting diff.
///
/// Only libraries reached by a "file:" URI are compared.
void compareTestPrograms(
    String sourcePath, String platformPath, String packagesFilePath) async {
  var packagesFileUri = Uri.file(packagesFilePath);
  var platformUri = Uri.file(platformPath);
  ComparisonNode kernelNode = await kernel.analyzeProgram(
      path.toUri(sourcePath),
      packagesFileUri,
      platformUri,
      (uri) => uri.scheme == 'file');
  if (kernelNode.text == 'Error occurred') {
    // TODO(paulberry): really we should verify that the analyzer detects an
    // error as well.  But that's not easy to do right now because we use the
    // front end to chase imports so that we know which files to pass to the
    // analyzer, and we can't rely on the front end import chasing when an error
    // occurred.
    print('No differences found (skipped due to front end compilation error)');
    return;
  }
  String startingPath;
  var inputs = <String>[];
  for (var library in kernelNode.children) {
    var filePath = path.fromUri(Uri.parse(library.text));
    if (startingPath == null) {
      startingPath = path.dirname(filePath);
    } else {
      while (!path.isWithin(startingPath, filePath)) {
        startingPath = path.dirname(startingPath);
      }
    }
    inputs.add(filePath);
  }
  ComparisonNode analyzerNode =
      await analyzer.analyzeFiles(startingPath, inputs);
  if (kernelNode == analyzerNode) {
    print('No differences found!');
  } else {
    print('Differences found:');
    print(ComparisonNode.diff(kernelNode, analyzerNode, 'CFE', 'analyzer'));
  }
}
