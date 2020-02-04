// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/protocol/protocol_generated.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../support/integration_tests.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(SetAnalysisRootsTest);
  });
}

@reflectiveTest
class SetAnalysisRootsTest extends AbstractAnalysisServerIntegrationTest {
  Future<void> xtest_package_root() async {
    // TODO(devoncarew): This test fails intermittently on the bots; #33879.
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
    String fooBarText = '''
library foo.bar;

f() {}
''';
    writeFile(mainPath, mainText);
    String normalizedFooBarPath = writeFile(fooBarPath, fooBarText);
    sendServerSetSubscriptions([ServerService.STATUS]);
    Future<AnalysisNavigationParams> navigationParamsFuture =
        onAnalysisNavigation.first;
    sendAnalysisSetSubscriptions({
      AnalysisService.NAVIGATION: [mainPath]
    });
    List<NavigationRegion> navigationRegions;
    List<NavigationTarget> navigationTargets;
    List<String> navigationTargetFiles;

    sendAnalysisSetAnalysisRoots([projPath], [],
        packageRoots: {projPath: packagesPath});
    sendAnalysisSetPriorityFiles([mainPath]);

    AnalysisNavigationParams params = await navigationParamsFuture;

    expect(params.file, equals(mainPath));
    navigationRegions = params.regions;
    navigationTargets = params.targets;
    navigationTargetFiles = params.files;

    await analysisFinished;

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
  }
}
