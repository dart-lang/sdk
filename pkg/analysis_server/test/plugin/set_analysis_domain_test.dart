// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.plugin.analysis_contributor;

import 'dart:async';

import 'package:analysis_server/plugin/analysis/analysis_domain.dart';
import 'package:analysis_server/plugin/analysis/navigation/navigation.dart';
import 'package:analysis_server/plugin/analysis/navigation/navigation_core.dart';
import 'package:analysis_server/plugin/analysis/occurrences/occurrences.dart';
import 'package:analysis_server/plugin/analysis/occurrences/occurrences_core.dart';
import 'package:analysis_server/plugin/protocol/protocol.dart';
import 'package:analysis_server/src/constants.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/task/dart.dart';
import 'package:plugin/plugin.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../analysis_abstract.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(SetAnalysisDomainTest);
  });
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

  AnalysisNavigationParams navigationParams;
  AnalysisOccurrencesParams occurrencesParams;

  @override
  void addServerPlugins(List<Plugin> plugins) {
    var plugin = new TestSetAnalysisDomainPlugin(this);
    plugins.add(plugin);
  }

  @override
  void processNotification(Notification notification) {
    if (notification.event == ANALYSIS_NAVIGATION) {
      var params = new AnalysisNavigationParams.fromNotification(notification);
      if (params.file == testFile) {
        navigationParams = params;
      }
    }
    if (notification.event == ANALYSIS_OCCURRENCES) {
      var params = new AnalysisOccurrencesParams.fromNotification(notification);
      if (params.file == testFile) {
        occurrencesParams = params;
      }
    }
  }

  Future test_contributorIsInvoked() async {
    createProject();
    addAnalysisSubscription(AnalysisService.NAVIGATION, testFile);
    addAnalysisSubscription(AnalysisService.OCCURRENCES, testFile);
    addTestFile('// usually no navigation');
    await server.onAnalysisComplete;
    // we have PARSED_UNIT
    expect(parsedUnitFiles, contains(testFile));
    // we have an additional navigation region/target
    {
      expect(navigationParams.regions, hasLength(1));
      {
        NavigationRegion region = navigationParams.regions.single;
        expect(region.offset, 1);
        expect(region.length, 5);
        expect(region.targets.single, 0);
      }
      {
        NavigationTarget target = navigationParams.targets.single;
        expect(target.fileIndex, 0);
        expect(target.offset, 1);
        expect(target.length, 2);
        expect(target.startLine, 3);
        expect(target.startColumn, 4);
      }
      expect(navigationParams.files.single, '/testLocation.dart');
    }
    // we have additional occurrences
    {
      expect(occurrencesParams.occurrences, hasLength(1));
      Occurrences occurrences = occurrencesParams.occurrences.single;
      expect(occurrences.element.name, 'TestElement');
      expect(occurrences.length, 5);
      expect(occurrences.offsets, unorderedEquals([1, 2, 3]));
    }
  }
}

class TestNavigationContributor implements NavigationContributor {
  final SetAnalysisDomainTest test;

  TestNavigationContributor(this.test);

  @override
  void computeNavigation(NavigationCollector collector, AnalysisContext context,
      Source source, int offset, int length) {
    collector.addRegion(1, 5, ElementKind.CLASS,
        new Location('/testLocation.dart', 1, 2, 3, 4));
  }
}

class TestOccurrencesContributor implements OccurrencesContributor {
  final SetAnalysisDomainTest test;

  TestOccurrencesContributor(this.test);

  @override
  void computeOccurrences(
      OccurrencesCollector collector, AnalysisContext context, Source source) {
    Element element = new Element(ElementKind.UNKNOWN, 'TestElement', 0);
    collector.addOccurrences(new Occurrences(element, <int>[1, 2], 5));
    collector.addOccurrences(new Occurrences(element, <int>[3], 5));
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
    register(OCCURRENCES_CONTRIBUTOR_EXTENSION_POINT_ID,
        new TestOccurrencesContributor(test));
  }

  void _setAnalysisDomain(AnalysisDomain domain) {
    domain.onResultChanged(PARSED_UNIT).listen((result) {
      expect(result.context, isNotNull);
      expect(result.target, isNotNull);
      expect(result.value, isNotNull);
      Source source = result.target.source;
      test.parsedUnitFiles.add(source.fullName);
      domain.scheduleNotification(
          result.context, source, AnalysisService.NAVIGATION);
      domain.scheduleNotification(
          result.context, source, AnalysisService.OCCURRENCES);
    });
  }
}
