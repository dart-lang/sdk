// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.integration.analysis.packageRoot;

import 'package:analysis_server/src/protocol.dart';
import 'package:path/path.dart';
import 'package:unittest/unittest.dart';

import '../../reflective_tests.dart';
import '../integration_tests.dart';

main() {
  runReflectiveTests(Test);
}

@ReflectiveTestCase()
class Test extends AbstractAnalysisServerIntegrationTest {
  test_package_root() {
    String projPath = sourcePath('project');
    String mainPath = join(projPath, 'main.dart');
    String packagesPath = sourcePath('packages');
    String fooBarPath = join(packagesPath, 'foo', 'bar.dart');
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
    onAnalysisNavigation.listen((AnalysisNavigationParams params) {
      expect(params.file, equals(mainPath));
      navigationRegions = params.regions;
    });
    sendAnalysisSetAnalysisRoots([projPath], [], packageRoots: {
      projPath: packagesPath
    });
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
          Location location = region.targets[0].location;
          expect(location.file, equals(normalizedFooBarPath));
        }
      }
      expect(found, isTrue);
    });
  }
}
