// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.domain.analysis;

import 'package:analysis_server/src/analysis_server.dart';
import 'package:analysis_server/src/domain_analysis.dart';
import 'package:analysis_server/src/protocol.dart';
import 'package:unittest/unittest.dart';

import 'mocks.dart';

main() {
  AnalysisServer server;
  AnalysisDomainHandler handler;

  setUp(() {
    var serverChannel = new MockServerChannel();
    server = new AnalysisServer(serverChannel);
    handler = new AnalysisDomainHandler(server);
  });

  group('AnalysisDomainHandler', () {
    test('getFixes', () {
      var request = new Request('0', AnalysisDomainHandler.GET_FIXES_METHOD);
      request.setParameter(AnalysisDomainHandler.ERRORS_PARAM, []);
      var response = handler.handleRequest(request);
      // TODO(scheglov) implement
      expect(response, isNull);
    });

    test('getMinorRefactorings', () {
      var request = new Request('0', AnalysisDomainHandler.GET_MINOR_REFACTORINGS_METHOD);
      request.setParameter(AnalysisDomainHandler.FILE_PARAM, 'test.dart');
      request.setParameter(AnalysisDomainHandler.OFFSET_PARAM, 10);
      request.setParameter(AnalysisDomainHandler.LENGTH_PARAM, 20);
      var response = handler.handleRequest(request);
      // TODO(scheglov) implement
      expect(response, isNull);
    });

    test('setAnalysisRoots', () {
      var request = new Request('0', AnalysisDomainHandler.SET_ANALYSIS_ROOTS_METHOD);
      request.setParameter(
          AnalysisDomainHandler.INCLUDED_PARAM,
          ['projectA', 'projectB']);
      request.setParameter(
          AnalysisDomainHandler.EXCLUDED_PARAM,
          ['projectA/subAA', 'projectA/subAB', 'projectB/subBA']);
      var response = handler.handleRequest(request);
      // TODO(scheglov) implement
      expect(response, isNull);
    });

    test('setPriorityFiles', () {
      var request = new Request('0', AnalysisDomainHandler.SET_PRIORITY_FILES_METHOD);
      request.setParameter(
          AnalysisDomainHandler.FILES_PARAM,
          ['projectA/aa.dart', 'projectB/ba.dart']);
      var response = handler.handleRequest(request);
      // TODO(scheglov) implement
      expect(response, isNull);
    });

    test('setSubscriptions', () {
      var request = new Request('0', AnalysisDomainHandler.SET_SUBSCRIPTIONS_METHOD);
      request.setParameter(
          AnalysisDomainHandler.SUBSCRIPTIONS_PARAM,
          {
            AnalysisService.HIGHLIGHTS : ['project/a.dart', 'project/b.dart'],
            AnalysisService.NAVIGATION : ['project/c.dart'],
            AnalysisService.OUTLINE : ['project/d.dart', 'project/e.dart']
          });
      var response = handler.handleRequest(request);
      // TODO(scheglov) implement
      expect(response, isNull);
    });

    test('updateContent', () {
      var request = new Request('0', AnalysisDomainHandler.UPDATE_CONTENT_METHOD);
//      request.setParameter(
//          AnalysisDomainHandler.FILES_PARAM,
//          {'project/test.dart' : null});
      var response = handler.handleRequest(request);
      // TODO(scheglov) implement
      expect(response, isNull);
    });

    test('updateOptions', () {
      var request = new Request('0', AnalysisDomainHandler.UPDATE_OPTIONS_METHOD);
      request.setParameter(
          AnalysisDomainHandler.OPTIONS_PARAM,
          {
            'analyzeAngular' : true,
            'enableDeferredLoading': true,
            'enableEnums': false
          });
      var response = handler.handleRequest(request);
      // TODO(scheglov) implement
      expect(response, isNull);
    });

    test('updateSdks', () {
      var request = new Request('0', AnalysisDomainHandler.UPDATE_SDKS_METHOD);
      request.setParameter(
          AnalysisDomainHandler.ADDED_PARAM,
          ['/dart/sdk-1.3', '/dart/sdk-1.4']);
      request.setParameter(
          AnalysisDomainHandler.REMOVED_PARAM,
          ['/dart/sdk-1.2']);
      request.setParameter(AnalysisDomainHandler.DEFAULT_PARAM, '/dart/sdk-1.4');
      var response = handler.handleRequest(request);
      // TODO(scheglov) implement
      expect(response, isNull);
    });
  });
}
