// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/plugin/protocol/protocol.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../integration_tests.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(SetAnalysisRootsTest);
    defineReflectiveTests(SetAnalysisRootsTest_Driver);
  });
}

class AbstractSetAnalysisRootsTest
    extends AbstractAnalysisServerIntegrationTest {
  test_package_root() {
    String projPath = sourcePath('project');
    String mainPath = path.join(projPath, 'main.dart');
    String packagesPath = sourcePath('packages');
    String fooBarPath = path.join(packagesPath, 'foo', 'bar.dart');
    String mainText = """
library main;

import 'package:foo/bar.dart'

main() {
  f();
}
""";
    String fooBarText = """
library foo.bar;

f() {}
""";
    writeFile(mainPath, mainText);
    String normalizedFooBarPath = writeFile(fooBarPath, fooBarText);
    sendServerSetSubscriptions([ServerService.STATUS]);
    sendAnalysisSetSubscriptions({
      AnalysisService.NAVIGATION: [mainPath]
    });
    List<NavigationRegion> navigationRegions;
    List<NavigationTarget> navigationTargets;
    List<String> navigationTargetFiles;
    onAnalysisNavigation.listen((AnalysisNavigationParams params) {
      expect(params.file, equals(mainPath));
      navigationRegions = params.regions;
      navigationTargets = params.targets;
      navigationTargetFiles = params.files;
    });
    sendAnalysisSetAnalysisRoots([projPath], [],
        packageRoots: {projPath: packagesPath});
    sendAnalysisSetPriorityFiles([mainPath]);
    return analysisFinished.then((_) {
      // Verify that fooBarPath was properly resolved by checking that f()
      // refers to it.
      bool found = false;
      for (NavigationRegion region in navigationRegions) {
        String navigationSource =
            mainText.substring(region.offset, region.offset + region.length);
        if (navigationSource == 'f') {
          found = true;
          expect(region.targets, hasLength(1));
          int navigationTargetIndex = region.targets[0];
          NavigationTarget navigationTarget =
              navigationTargets[navigationTargetIndex];
          String navigationFile =
              navigationTargetFiles[navigationTarget.fileIndex];
          expect(navigationFile, equals(normalizedFooBarPath));
        }
      }
      expect(found, isTrue);
    });
  }
}

@reflectiveTest
class SetAnalysisRootsTest extends AbstractSetAnalysisRootsTest {}

@reflectiveTest
class SetAnalysisRootsTest_Driver extends AbstractSetAnalysisRootsTest {
  @override
  bool get enableNewAnalysisDriver => true;
}
