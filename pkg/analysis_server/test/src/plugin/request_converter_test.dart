// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/protocol/protocol_generated.dart' as server;
import 'package:analysis_server/src/plugin/request_converter.dart';
import 'package:analysis_server/src/protocol/protocol_internal.dart' as server;
import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:analyzer_plugin/protocol/protocol_generated.dart' as plugin;
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'protocol_test_utilities.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(RequestConverterTest);
  });
}

@reflectiveTest
class RequestConverterTest extends ProtocolTestUtilities {
  RequestConverter converter = new RequestConverter();

  void test_convertAnalysisService() {
    Map<plugin.AnalysisService, server.AnalysisService> kindMap =
        <plugin.AnalysisService, server.AnalysisService>{
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
    List<String> files = <String>['a', 'b', 'c'];
    plugin.AnalysisSetPriorityFilesParams result =
        converter.convertAnalysisSetPriorityFilesParams(
            new server.AnalysisSetPriorityFilesParams(files));
    expect(result, isNotNull);
    expect(result.files, files);
  }

  void test_convertAnalysisSetSubscriptionsParams() {
    Map<server.AnalysisService, List<String>> serverSubscriptions =
        <server.AnalysisService, List<String>>{
      server.AnalysisService.HIGHLIGHTS: <String>['a', 'b'],
      server.AnalysisService.OUTLINE: <String>['c'],
      server.AnalysisService.OVERRIDES: <String>['d', 'e']
    };
    plugin.AnalysisSetSubscriptionsParams result =
        converter.convertAnalysisSetSubscriptionsParams(
            new server.AnalysisSetSubscriptionsParams(serverSubscriptions));
    expect(result, isNotNull);
    Map<plugin.AnalysisService, List<String>> pluginSubscriptions =
        result.subscriptions;
    expect(pluginSubscriptions, hasLength(2));
    expect(
        pluginSubscriptions[plugin.AnalysisService.HIGHLIGHTS], hasLength(2));
    expect(pluginSubscriptions[plugin.AnalysisService.OUTLINE], hasLength(1));
  }

  void test_convertAnalysisUpdateContentParams() {
    Map<String, dynamic> serverFiles = <String, dynamic>{
      'file1': new AddContentOverlay('content1'),
      'file2': new AddContentOverlay('content2'),
    };
    plugin.AnalysisUpdateContentParams result =
        converter.convertAnalysisUpdateContentParams(
            new server.AnalysisUpdateContentParams(serverFiles));
    expect(result, isNotNull);
    Map<String, dynamic> pluginFiles = result.files;
    expect(pluginFiles, hasLength(2));
    expect(pluginFiles['file1'], new isInstanceOf<AddContentOverlay>());
    expect(pluginFiles['file2'], new isInstanceOf<AddContentOverlay>());
  }
}
