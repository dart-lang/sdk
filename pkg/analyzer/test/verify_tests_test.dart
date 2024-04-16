// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:analyzer/src/utilities/extensions/file_system.dart';
import 'package:analyzer_utilities/package_root.dart' as package_root;
import 'package:analyzer_utilities/verify_tests.dart';
import 'package:path/path.dart' as path;

main() {
  var provider = PhysicalResourceProvider.INSTANCE;
  var packageRoot = provider.pathContext.normalize(package_root.packageRoot);
  var pathToAnalyze = provider.pathContext.join(packageRoot, 'analyzer');
  var testDirPath = provider.pathContext.join(pathToAnalyze, 'test');
  _VerifyTests(testDirPath).build(
    analysisContextPredicate: (analysisContext) {
      var root = analysisContext.contextRoot.root;
      if (root.endsWithNames(['macro', 'single'])) {
        return false;
      }
      return true;
    },
  );
}

class _VerifyTests extends VerifyTests {
  _VerifyTests(super.testDirPath);

  @override
  bool isExpensive(Resource resource) =>
      resource.shortName.endsWith('_integration_test.dart');

  @override
  bool isOkAsAdditionalTestAllImport(Folder folder, String uri) {
    // This is not really a test, but a helper to update expectations.
    if (path.url.basename(uri) == 'node_text_expectations.dart') {
      return true;
    }

    return super.isOkAsAdditionalTestAllImport(folder, uri);
  }

  @override
  bool isOkForTestAllToBeMissing(Folder folder) =>
      folder.shortName == 'id_tests';
}
