// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

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
    var projPath = sourcePath('project');
    var mainPath = path.join(projPath, 'main.dart');
    var packagesPath = sourcePath('packages');
    var fooBarPath = path.join(packagesPath, 'foo', 'bar.dart');
    var mainText = """
library main;

import 'package:foo/bar.dart'

main() {
  f();
}
""";
    var fooBarText = '''
library foo.bar;

f() {}
''';
    writeFile(mainPath, mainText);
    var normalizedFooBarPath = writeFile(fooBarPath, fooBarText);
    sendServerSetSubscriptions([ServerService.STATUS]);
    var navigationParamsFuture = onAnalysisNavigation.first;
    sendAnalysisSetSubscriptions({
      AnalysisService.NAVIGATION: [mainPath]
    });
    List<NavigationRegion> navigationRegions;
    List<NavigationTarget> navigationTargets;
    List<String> navigationTargetFiles;

    sendAnalysisSetAnalysisRoots([projPath], [],
        packageRoots: {projPath: packagesPath});
    sendAnalysisSetPriorityFiles([mainPath]);

    var params = await navigationParamsFuture;

    expect(params.file, equals(mainPath));
    navigationRegions = params.regions;
    navigationTargets = params.targets;
    navigationTargetFiles = params.files;

    await analysisFinished;

    // Verify that fooBarPath was properly resolved by checking that f()
    // refers to it.
    var found = false;
    for (var region in navigationRegions) {
      var navigationSource =
          mainText.substring(region.offset, region.offset + region.length);
      if (navigationSource == 'f') {
        found = true;
        expect(region.targets, hasLength(1));
        var navigationTargetIndex = region.targets[0];
        var navigationTarget = navigationTargets[navigationTargetIndex];
        var navigationFile = navigationTargetFiles[navigationTarget.fileIndex];
        expect(navigationFile, equals(normalizedFooBarPath));
      }
    }

    expect(found, isTrue);
  }
}
