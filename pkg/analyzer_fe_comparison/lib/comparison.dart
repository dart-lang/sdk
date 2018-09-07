// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer_fe_comparison/src/analyzer.dart';
import 'package:analyzer_fe_comparison/src/comparison_node.dart';
import 'package:analyzer_fe_comparison/src/kernel.dart';

/// Compares the analyzer and kernel representations of a project, and prints
/// the resulting diff.
void compare(
    String platformPath, String projectLibPath, String packagesFilePath) async {
  ComparisonNode analyzerNode = await driveAnalyzer(projectLibPath);
  var packagesFileUri = Uri.file(packagesFilePath);
  var inputs = <Uri>[];
  for (var library in analyzerNode.children) {
    inputs.add(Uri.parse(library.text));
  }
  var platformUri = Uri.file(platformPath);
  ComparisonNode kernelNode =
      await driveKernel(inputs, packagesFileUri, platformUri);
  print(ComparisonNode.diff(kernelNode, analyzerNode));
}
