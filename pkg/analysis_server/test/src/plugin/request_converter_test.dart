// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/protocol/protocol_generated.dart' as server;
import 'package:analysis_server/src/plugin/request_converter.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:analyzer_plugin/protocol/protocol_generated.dart' as plugin;
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'protocol_test_utilities.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(RequestConverterTest);
  });
}

@reflectiveTest
class RequestConverterTest extends ProtocolTestUtilities {
  RequestConverter converter = RequestConverter();

  void test_convertAnalysisService() {
    var kindMap = <plugin.AnalysisService, server.AnalysisService>{
      plugin.AnalysisService.FOLDING: server.AnalysisService.FOLDING,
      plugin.AnalysisService.HIGHLIGHTS: server.AnalysisService.HIGHLIGHTS,
      plugin.AnalysisService.NAVIGATION: server.AnalysisService.NAVIGATION,
      plugin.AnalysisService.OCCURRENCES: server.AnalysisService.OCCURRENCES,
      plugin.AnalysisService.OUTLINE: server.AnalysisService.OUTLINE,
    };
    kindMap.forEach(
        (plugin.AnalysisService pluginKind, server.AnalysisService serverKind) {
      expect(converter.convertAnalysisService(serverKind), pluginKind);
    });
  }

  void test_convertAnalysisSetPriorityFilesParams() {
    var files = <String>['a', 'b', 'c'];
    var result = converter.convertAnalysisSetPriorityFilesParams(
        server.AnalysisSetPriorityFilesParams(files));
    expect(result, isNotNull);
    expect(result.files, files);
  }

  void test_convertAnalysisSetSubscriptionsParams() {
    var serverSubscriptions = <server.AnalysisService, List<String>>{
      server.AnalysisService.HIGHLIGHTS: <String>['a', 'b'],
      server.AnalysisService.OUTLINE: <String>['c'],
      server.AnalysisService.OVERRIDES: <String>['d', 'e']
    };
    var result = converter.convertAnalysisSetSubscriptionsParams(
        server.AnalysisSetSubscriptionsParams(serverSubscriptions));
    expect(result, isNotNull);
    var pluginSubscriptions = result.subscriptions;
    expect(pluginSubscriptions, hasLength(2));
    expect(
        pluginSubscriptions[plugin.AnalysisService.HIGHLIGHTS], hasLength(2));
    expect(pluginSubscriptions[plugin.AnalysisService.OUTLINE], hasLength(1));
  }

  void test_convertAnalysisUpdateContentParams() {
    var serverFiles = <String, dynamic>{
      'file1': AddContentOverlay('content1'),
      'file2': AddContentOverlay('content2'),
    };
    var result = converter.convertAnalysisUpdateContentParams(
        server.AnalysisUpdateContentParams(serverFiles));
    expect(result, isNotNull);
    var pluginFiles = result.files;
    expect(pluginFiles, hasLength(2));
    expect(pluginFiles['file1'], const TypeMatcher<AddContentOverlay>());
    expect(pluginFiles['file2'], const TypeMatcher<AddContentOverlay>());
  }
}
