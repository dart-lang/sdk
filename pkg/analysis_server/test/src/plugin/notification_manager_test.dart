// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/protocol/protocol.dart' as server;
import 'package:analysis_server/protocol/protocol_generated.dart' as server;
import 'package:analysis_server/src/channel/channel.dart';
import 'package:analysis_server/src/plugin/notification_manager.dart';
import 'package:analyzer/file_system/memory_file_system.dart';
import 'package:analyzer_plugin/protocol/protocol.dart' as plugin;
import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:analyzer_plugin/protocol/protocol_constants.dart' as plugin;
import 'package:analyzer_plugin/protocol/protocol_generated.dart' as plugin;
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'protocol_test_utilities.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(NotificationManagerTest);
  });
}

@reflectiveTest
class NotificationManagerTest extends ProtocolTestUtilities {
  String testDir;
  String fileA;
  String fileB;

  TestChannel channel;

  NotificationManager manager;

  void setUp() {
    MemoryResourceProvider provider = new MemoryResourceProvider();
    testDir = provider.convertPath('/test');
    fileA = provider.convertPath('/test/a.dart');
    fileB = provider.convertPath('/test/b.dart');
    channel = new TestChannel();
    manager = new NotificationManager(channel, provider);
  }

  void test_handlePluginNotification_errors() {
    manager.setAnalysisRoots([testDir], []);
    AnalysisError error1 = analysisError(0, 0, file: fileA);
    AnalysisError error2 = analysisError(3, 4, file: fileA);
    plugin.AnalysisErrorsParams params =
        new plugin.AnalysisErrorsParams(fileA, [error1, error2]);
    manager.handlePluginNotification('a', params.toNotification());
    _verifyErrors(fileA, [error1, error2]);
  }

  void test_handlePluginNotification_folding() {
    manager.setSubscriptions({
      server.AnalysisService.FOLDING: new Set.from([fileA, fileB])
    });
    FoldingRegion region1 = foldingRegion(10, 3);
    FoldingRegion region2 = foldingRegion(20, 6);
    plugin.AnalysisFoldingParams params =
        new plugin.AnalysisFoldingParams(fileA, [region1, region2]);
    manager.handlePluginNotification('a', params.toNotification());
    _verifyFoldingRegions(fileA, [region1, region2]);
  }

  void test_handlePluginNotification_highlights() {
    manager.setSubscriptions({
      server.AnalysisService.HIGHLIGHTS: new Set.from([fileA, fileB])
    });
    HighlightRegion region1 = highlightRegion(10, 3);
    HighlightRegion region2 = highlightRegion(20, 6);
    plugin.AnalysisHighlightsParams params =
        new plugin.AnalysisHighlightsParams(fileA, [region1, region2]);
    manager.handlePluginNotification('a', params.toNotification());
    _verifyHighlightRegions(fileA, [region1, region2]);
  }

  void test_handlePluginNotification_naviation() {
    manager.setSubscriptions({
      server.AnalysisService.NAVIGATION: new Set.from([fileA, fileB])
    });
    plugin.AnalysisNavigationParams pluginParams =
        pluginNavigationParams(0, 0, file: fileA);
    manager.handlePluginNotification('a', pluginParams.toNotification());

    server.AnalysisNavigationParams serverParams =
        serverNavigationParams(0, 0, file: fileA);
    _verifyNavigationParams(serverParams);
  }

  void test_handlePluginNotification_occurences() {
    manager.setSubscriptions({
      server.AnalysisService.OCCURRENCES: new Set.from([fileA, fileB])
    });
    Occurrences occurrences1 = occurrences(0, 0);
    Occurrences occurrences2 = occurrences(5, 7);
    plugin.AnalysisOccurrencesParams params =
        new plugin.AnalysisOccurrencesParams(
            fileA, [occurrences1, occurrences2]);

    manager.handlePluginNotification('a', params.toNotification());
    _verifyOccurrences(fileA, [occurrences1, occurrences2]);
  }

  void test_handlePluginNotification_outline() {
    manager.setSubscriptions({
      server.AnalysisService.OUTLINE: new Set.from([fileA, fileB])
    });
    Outline outline1 = outline(0, 0);
    plugin.AnalysisOutlineParams params =
        new plugin.AnalysisOutlineParams(fileA, [outline1]);
    manager.handlePluginNotification('a', params.toNotification());

    _verifyOutlines(fileA, outline1);
  }

  void test_handlePluginNotification_pluginError() {
    bool isFatal = false;
    String message = 'message';
    String stackTrace = 'stackTrace';
    plugin.PluginErrorParams params =
        new plugin.PluginErrorParams(isFatal, message, stackTrace);
    manager.handlePluginNotification('a', params.toNotification());
    _verifyPluginError(isFatal, message, stackTrace);
  }

  void test_recordAnalysisErrors_noSubscription() {
    AnalysisError error = analysisError(0, 0, file: fileA);
    manager.recordAnalysisErrors('a', fileA, [error]);
    expect(channel.sentNotification, isNull);
  }

  void test_recordAnalysisErrors_withSubscription() {
    manager.setAnalysisRoots([testDir], []);
    //
    // Errors should be reported when they are recorded.
    //
    AnalysisError error1 = analysisError(0, 0, file: fileA);
    AnalysisError error2 = analysisError(3, 4, file: fileA);
    manager.recordAnalysisErrors('a', fileA, [error1, error2]);
    _verifyErrors(fileA, [error1, error2]);
    //
    // Errors from different plugins should be cumulative.
    //
    AnalysisError error3 = analysisError(6, 8, file: fileA);
    manager.recordAnalysisErrors('b', fileA, [error3]);
    _verifyErrors(fileA, [error1, error2, error3]);
    //
    // Overwriting errors from one plugin should not affect errors from other
    // plugins.
    //
    AnalysisError error4 = analysisError(9, 12, file: fileA);
    manager.recordAnalysisErrors('a', fileA, [error4]);
    _verifyErrors(fileA, [error4, error3]);
    //
    // Recording errors against a file should not affect the errors for other
    // files.
    //
    AnalysisError error5 = analysisError(12, 16, file: fileB);
    manager.recordAnalysisErrors('a', fileB, [error5]);
    _verifyErrors(fileB, [error5]);
  }

  void test_recordFoldingRegions_noSubscription() {
    FoldingRegion region = foldingRegion(10, 5);
    manager.recordFoldingRegions('a', fileA, [region]);
    expect(channel.sentNotification, isNull);
  }

  void test_recordFoldingRegions_withSubscription() {
    manager.setSubscriptions({
      server.AnalysisService.FOLDING: new Set.from([fileA, fileB])
    });
    //
    // Regions should be reported when they are recorded.
    //
    FoldingRegion region1 = foldingRegion(10, 3);
    FoldingRegion region2 = foldingRegion(20, 6);
    manager.recordFoldingRegions('a', fileA, [region1, region2]);
    _verifyFoldingRegions(fileA, [region1, region2]);
    //
    // Regions from different plugins should be cumulative.
    //
    FoldingRegion region3 = foldingRegion(30, 5);
    manager.recordFoldingRegions('b', fileA, [region3]);
    _verifyFoldingRegions(fileA, [region1, region2, region3]);
    //
    // Overwriting regions from one plugin should not affect regions from other
    // plugins.
    //
    FoldingRegion region4 = foldingRegion(40, 2);
    manager.recordFoldingRegions('a', fileA, [region4]);
    _verifyFoldingRegions(fileA, [region4, region3]);
    //
    // Recording regions against a file should not affect the regions for other
    // files.
    //
    FoldingRegion region5 = foldingRegion(50, 7);
    manager.recordFoldingRegions('a', fileB, [region5]);
    _verifyFoldingRegions(fileB, [region5]);
  }

  void test_recordHighlightRegions_noSubscription() {
    HighlightRegion region = highlightRegion(10, 5);
    manager.recordHighlightRegions('a', fileA, [region]);
    expect(channel.sentNotification, isNull);
  }

  void test_recordHighlightRegions_withSubscription() {
    manager.setSubscriptions({
      server.AnalysisService.HIGHLIGHTS: new Set.from([fileA, fileB])
    });
    //
    // Regions should be reported when they are recorded.
    //
    HighlightRegion region1 = highlightRegion(10, 3);
    HighlightRegion region2 = highlightRegion(20, 6);
    manager.recordHighlightRegions('a', fileA, [region1, region2]);
    _verifyHighlightRegions(fileA, [region1, region2]);
    //
    // Regions from different plugins should be cumulative.
    //
    HighlightRegion region3 = highlightRegion(30, 5);
    manager.recordHighlightRegions('b', fileA, [region3]);
    _verifyHighlightRegions(fileA, [region1, region2, region3]);
    //
    // Overwriting regions from one plugin should not affect regions from other
    // plugins.
    //
    HighlightRegion region4 = highlightRegion(40, 2);
    manager.recordHighlightRegions('a', fileA, [region4]);
    _verifyHighlightRegions(fileA, [region4, region3]);
    //
    // Recording regions against a file should not affect the regions for other
    // files.
    //
    HighlightRegion region5 = highlightRegion(50, 7);
    manager.recordHighlightRegions('a', fileB, [region5]);
    _verifyHighlightRegions(fileB, [region5]);
  }

  void test_recordNavigationParams_noSubscription() {
    server.AnalysisNavigationParams params =
        serverNavigationParams(0, 0, file: fileA);
    manager.recordNavigationParams('a', fileA, params);
    expect(channel.sentNotification, isNull);
  }

  void test_recordNavigationParams_withSubscription() {
    manager.setSubscriptions({
      server.AnalysisService.NAVIGATION: new Set.from([fileA, fileB])
    });
    //
    // Parameters should be reported when they are recorded.
    //
    server.AnalysisNavigationParams params1 =
        serverNavigationParams(0, 0, file: fileA);
    manager.recordNavigationParams('a', fileA, params1);
    _verifyNavigationParams(params1);
    //
    // Parameters from different plugins should be cumulative.
    //
    server.AnalysisNavigationParams params2 =
        serverNavigationParams(2, 4, file: fileA);
    manager.recordNavigationParams('b', fileA, params2);
    server.AnalysisNavigationParams params1and2 =
        new server.AnalysisNavigationParams(fileA, <NavigationRegion>[
      new NavigationRegion(0, 2, <int>[0]),
      new NavigationRegion(4, 2, <int>[1])
    ], <NavigationTarget>[
      new NavigationTarget(ElementKind.FIELD, 0, 1, 2, 2, 3),
      new NavigationTarget(ElementKind.FIELD, 2, 5, 2, 6, 7)
    ], <String>[
      'aa',
      'ab',
      'ac',
      'ad'
    ]);
    _verifyNavigationParams(params1and2);
    //
    // Overwriting parameters from one plugin should not affect parameters from
    // other plugins.
    //
    server.AnalysisNavigationParams params3 =
        serverNavigationParams(4, 8, file: fileA);
    manager.recordNavigationParams('a', fileA, params3);
    server.AnalysisNavigationParams params3and2 =
        new server.AnalysisNavigationParams(fileA, <NavigationRegion>[
      new NavigationRegion(8, 2, <int>[0]),
      new NavigationRegion(4, 2, <int>[1])
    ], <NavigationTarget>[
      new NavigationTarget(ElementKind.FIELD, 0, 9, 2, 10, 11),
      new NavigationTarget(ElementKind.FIELD, 2, 5, 2, 6, 7)
    ], <String>[
      'ae',
      'af',
      'ac',
      'ad'
    ]);
    _verifyNavigationParams(params3and2);
    //
    // Recording parameters against a file should not affect the parameters for
    // other files.
    //
    server.AnalysisNavigationParams params4 =
        serverNavigationParams(6, 12, file: fileB);
    manager.recordNavigationParams('a', fileB, params4);
    _verifyNavigationParams(params4);
  }

  void test_recordOccurrences_noSubscription() {
    Occurrences occurrences1 = occurrences(0, 0);
    manager.recordOccurrences('a', fileA, [occurrences1]);
    expect(channel.sentNotification, isNull);
  }

  void test_recordOccurrences_withSubscription() {
    manager.setSubscriptions({
      server.AnalysisService.OCCURRENCES: new Set.from([fileA, fileB])
    });
    //
    // Occurrences should be reported when they are recorded.
    //
    Occurrences occurrences1 = occurrences(0, 0);
    Occurrences occurrences2 = occurrences(5, 7);
    manager.recordOccurrences('a', fileA, [occurrences1, occurrences2]);
    _verifyOccurrences(fileA, [occurrences1, occurrences2]);
    //
    // Occurrences from different plugins should be cumulative.
    //
    Occurrences occurrences3 = occurrences(10, 14);
    manager.recordOccurrences('b', fileA, [occurrences3]);
    _verifyOccurrences(fileA, [occurrences1, occurrences2, occurrences3]);
    //
    // Overwriting occurrences from one plugin should not affect occurrences
    // from other plugins.
    //
    Occurrences occurrences4 = occurrences(15, 21);
    manager.recordOccurrences('a', fileA, [occurrences4]);
    _verifyOccurrences(fileA, [occurrences4, occurrences3]);
    //
    // Recording occurrences against a file should not affect the occurrences
    // for other files.
    //
    Occurrences occurrences5 = occurrences(20, 28);
    manager.recordOccurrences('a', fileB, [occurrences5]);
    _verifyOccurrences(fileB, [occurrences5]);
  }

  void test_recordOutlines_noSubscription() {
    Outline outline1 = outline(0, 0);
    manager.recordOutlines('a', fileA, [outline1]);
    expect(channel.sentNotification, isNull);
  }

  @failingTest
  void test_recordOutlines_withSubscription() {
    fail('The outline handling needs to be re-worked slightly');
    // TODO(brianwilkerson) Figure out outlines. What should we do when merge
    // cannot produce a single outline?
    manager.setSubscriptions({
      server.AnalysisService.OUTLINE: new Set.from([fileA, fileB])
    });
    //
    // Outlines should be reported when they are recorded.
    //
    Outline outline1 = outline(0, 0);
    Outline outline2 = outline(5, 7);
    manager.recordOutlines('a', fileA, [outline1, outline2]);
    // TODO(brianwilkerson) Figure out how to test this.
//    _verifyOutlines(fileA, [outline1, outline2]);
    //
    // Outlines from different plugins should be cumulative.
    //
    Outline outline3 = outline(10, 14);
    manager.recordOutlines('b', fileA, [outline3]);
    // TODO(brianwilkerson) Figure out how to test this.
//    _verifyOutlines(fileA, [outline1, outline2, outline3]);
    //
    // Overwriting outlines from one plugin should not affect outlines from
    // other plugins.
    //
    Outline outline4 = outline(15, 21);
    manager.recordOutlines('a', fileA, [outline4]);
    // TODO(brianwilkerson) Figure out how to test this.
//    _verifyOutlines(fileA, [outline4, outline3]);
    //
    // Recording outlines against a file should not affect the outlines for
    // other files.
    //
    Outline outline5 = outline(20, 28);
    manager.recordOutlines('a', fileB, [outline5]);
    // TODO(brianwilkerson) Figure out how to test this.
//    _verifyOutlines(fileB, [outline5]);
  }

  void _verifyErrors(String fileName, List<AnalysisError> expectedErrors) {
    server.Notification notification = channel.sentNotification;
    expect(notification, isNotNull);
    expect(notification.event, 'analysis.errors');
    server.AnalysisErrorsParams params =
        new server.AnalysisErrorsParams.fromNotification(notification);
    expect(params, isNotNull);
    expect(params.file, fileName);
    expect(params.errors, equals(expectedErrors));
    channel.sentNotification = null;
  }

  void _verifyFoldingRegions(
      String fileName, List<FoldingRegion> expectedRegions) {
    server.Notification notification = channel.sentNotification;
    expect(notification, isNotNull);
    expect(notification.event, 'analysis.folding');
    server.AnalysisFoldingParams params =
        new server.AnalysisFoldingParams.fromNotification(notification);
    expect(params, isNotNull);
    expect(params.file, fileName);
    expect(params.regions, equals(expectedRegions));
    channel.sentNotification = null;
  }

  void _verifyHighlightRegions(
      String fileName, List<HighlightRegion> expectedRegions) {
    server.Notification notification = channel.sentNotification;
    expect(notification, isNotNull);
    expect(notification.event, 'analysis.highlights');
    server.AnalysisHighlightsParams params =
        new server.AnalysisHighlightsParams.fromNotification(notification);
    expect(params, isNotNull);
    expect(params.file, fileName);
    expect(params.regions, equals(expectedRegions));
    channel.sentNotification = null;
  }

  void _verifyNavigationParams(server.AnalysisNavigationParams expectedParams) {
    server.Notification notification = channel.sentNotification;
    expect(notification, isNotNull);
    expect(notification.event, 'analysis.navigation');
    server.AnalysisNavigationParams params =
        new server.AnalysisNavigationParams.fromNotification(notification);
    expect(params, isNotNull);
    expect(params.file, expectedParams.file);
    expect(params.files, equals(expectedParams.files));
    expect(params.regions, equals(expectedParams.regions));
    expect(params.targets, equals(expectedParams.targets));
    channel.sentNotification = null;
  }

  void _verifyOccurrences(
      String fileName, List<Occurrences> expectedOccurrences) {
    server.Notification notification = channel.sentNotification;
    expect(notification, isNotNull);
    expect(notification.event, 'analysis.occurrences');
    server.AnalysisOccurrencesParams params =
        new server.AnalysisOccurrencesParams.fromNotification(notification);
    expect(params, isNotNull);
    expect(params.file, fileName);
    expect(params.occurrences, equals(expectedOccurrences));
    channel.sentNotification = null;
  }

  void _verifyOutlines(String fileName, Outline expectedOutline) {
    server.Notification notification = channel.sentNotification;
    expect(notification, isNotNull);
    expect(notification.event, 'analysis.outline');
    server.AnalysisOutlineParams params =
        new server.AnalysisOutlineParams.fromNotification(notification);
    expect(params, isNotNull);
    expect(params.file, fileName);
    expect(params.outline, equals(expectedOutline));
    channel.sentNotification = null;
  }

  void _verifyPluginError(bool isFatal, String message, String stackTrace) {
    server.Notification notification = channel.sentNotification;
    expect(notification, isNotNull);
    expect(notification.event, 'server.error');
    server.ServerErrorParams params =
        new server.ServerErrorParams.fromNotification(notification);
    expect(params, isNotNull);
    expect(params.isFatal, isFatal);
    expect(params.message, message);
    expect(params.stackTrace, stackTrace);
    channel.sentNotification = null;
  }
}

class TestChannel implements ServerCommunicationChannel {
  server.Notification sentNotification;

  @override
  void close() {
    fail('Unexpected invocation of close');
  }

  @override
  void listen(void onRequest(server.Request request),
      {Function onError, void onDone()}) {
    fail('Unexpected invocation of listen');
  }

  @override
  void sendNotification(server.Notification notification) {
    sentNotification = notification;
  }

  @override
  void sendResponse(server.Response response) {
    fail('Unexpected invocation of sendResponse');
  }
}
