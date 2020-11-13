// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer_utilities/package_root.dart' as package_root;
import 'package:analyzer_utilities/verify_tests.dart';
import 'package:analyzer/file_system/physical_file_system.dart';

void main() {
  var provider = PhysicalResourceProvider.INSTANCE;
  var packageRoot = provider.pathContext.normalize(package_root.packageRoot);
  var pathToAnalyze = provider.pathContext.join(packageRoot, 'nnbd_migration');
  var testDirPath = provider.pathContext.join(pathToAnalyze, 'test');
  VerifyTests(testDirPath).build();
}
