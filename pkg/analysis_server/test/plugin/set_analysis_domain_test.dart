// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.plugin.analysis_contributor;

import 'dart:async';

import 'package:analysis_server/analysis/analysis_domain.dart';
import 'package:analysis_server/analysis/navigation/navigation_core.dart';
import 'package:analysis_server/plugin/navigation.dart';
import 'package:analysis_server/src/constants.dart';
import 'package:analysis_server/src/protocol.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/task/dart.dart';
import 'package:plugin/plugin.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';
import 'package:unittest/unittest.dart';

import '../analysis_abstract.dart';
import '../utils.dart';

main() {
  initializeTestEnvironment();
  if (AnalysisEngine.instance.useTaskModel) {
    defineReflectiveTests(SetAnalysisDomainTest);
  }
}

/**
 * This test uses [SET_ANALYSIS_DOMAIN_EXTENSION_POINT_ID] and
 * [NAVIGATION_CONTRIBUTOR_EXTENSION_POINT_ID] extension points to validate
 * that plugins can listen for analysis and force sending navigation
 * notifications.
 */
@reflectiveTest
class SetAnalysisDomainTest extends AbstractAnalysisTest {
  final Set<String> parsedUnitFiles = new Set<String>();
  bool contributorMayAddRegion = false;

  List<NavigationRegion> regions;
  List<NavigationTarget> targets;
  List<String> targetFiles;

  @override
  void addServerPlugins(List<Plugin> plugins) {
    var plugin = new TestSetAnalysisDomainPlugin(this);
    plugins.add(plugin);
  }

  @override
  void processNotification(Notification notification) {
    if (notification.event == ANALYSIS_NAVIGATION) {
      var params = new AnalysisNavigationParams.fromNotification(notification);
      // TODO(scheglov) we check for "params.regions.isNotEmpty" because
      // normal, Dart only, navigation notifications are scheduled as
      // operations, but plugins use "notificationSite.scheduleNavigation"
      // which is not scheduled yet. So, it comes *before* the Dart one, and
      // gets lost.
      if (params.file == testFile && params.regions.isNotEmpty) {
        regions = params.regions;
        targets = params.targets;
        targetFiles = params.files;
      }
    }
  }

  Future test_contributorIsInvoked() async {
    createProject();
    addAnalysisSubscription(AnalysisService.NAVIGATION, testFile);
    addTestFile('// usually no navigation');
    await server.onAnalysisComplete;
    // we have PARSED_UNIT
    expect(parsedUnitFiles, contains(testFile));
    // we have an additional navigation region/target
    expect(regions, hasLength(1));
    {
      NavigationRegion region = regions.single;
      expect(region.offset, 1);
      expect(region.length, 5);
      expect(region.targets.single, 0);
    }
    {
      NavigationTarget target = targets.single;
      expect(target.fileIndex, 0);
      expect(target.offset, 1);
      expect(target.length, 2);
      expect(target.startLine, 3);
      expect(target.startColumn, 4);
    }
    expect(targetFiles.single, '/testLocation.dart');
  }
}

class TestNavigationContributor implements NavigationContributor {
  final SetAnalysisDomainTest test;

  TestNavigationContributor(this.test);

  @override
  void computeNavigation(NavigationHolder holder, AnalysisContext context,
      Source source, int offset, int length) {
    if (test.contributorMayAddRegion) {
      holder.addRegion(1, 5, ElementKind.CLASS,
          new Location('/testLocation.dart', 1, 2, 3, 4));
    }
  }
}

class TestSetAnalysisDomainPlugin implements Plugin {
  final SetAnalysisDomainTest test;

  TestSetAnalysisDomainPlugin(this.test);

  @override
  String get uniqueIdentifier => 'test';

  @override
  void registerExtensionPoints(RegisterExtensionPoint register) {}

  @override
  void registerExtensions(RegisterExtension register) {
    register(SET_ANALYSIS_DOMAIN_EXTENSION_POINT_ID, _setAnalysisDomain);
    register(NAVIGATION_CONTRIBUTOR_EXTENSION_POINT_ID,
        new TestNavigationContributor(test));
  }

  void _setAnalysisDomain(AnalysisDomain domain) {
    domain.onResultComputed(PARSED_UNIT).listen((result) {
      expect(result.context, isNotNull);
      expect(result.target, isNotNull);
      expect(result.value, isNotNull);
      Source source = result.target.source;
      test.parsedUnitFiles.add(source.fullName);
      // let the navigation contributor to work
      test.contributorMayAddRegion = true;
      try {
        domain.scheduleNotification(
            result.context, source, AnalysisService.NAVIGATION);
      } finally {
        test.contributorMayAddRegion = false;
      }
    });
  }
}
