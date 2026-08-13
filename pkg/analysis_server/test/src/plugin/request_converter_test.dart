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
  void test_analysisService() {
    var kindMap = {
      plugin.AnalysisService.FOLDING: server.AnalysisService.FOLDING,
      plugin.AnalysisService.HIGHLIGHTS: server.AnalysisService.HIGHLIGHTS,
      plugin.AnalysisService.NAVIGATION: server.AnalysisService.NAVIGATION,
      plugin.AnalysisService.OCCURRENCES: server.AnalysisService.OCCURRENCES,
      plugin.AnalysisService.OUTLINE: server.AnalysisService.OUTLINE,
    };
    kindMap.forEach((pluginKind, serverKind) {
      expect(serverKind.asPluginProtocol, pluginKind);
    });
  }

  void test_analysisSetPriorityFilesParams() {
    var files = ['a', 'b', 'c'];
    var result = server.AnalysisSetPriorityFilesParams(files).asPluginProtocol;
    expect(result.files, files);
  }

  void test_analysisSetSubscriptionsParams() {
    var serverSubscriptions = {
      server.AnalysisService.HIGHLIGHTS: ['a', 'b'],
      server.AnalysisService.OUTLINE: ['c'],
      server.AnalysisService.OVERRIDES: ['d', 'e'],
    };
    var result = server.AnalysisSetSubscriptionsParams(serverSubscriptions)
        .asPluginProtocol;
    var pluginSubscriptions = result.subscriptions;
    expect(pluginSubscriptions, hasLength(2));
    expect(
      pluginSubscriptions[plugin.AnalysisService.HIGHLIGHTS],
      hasLength(2),
    );
    expect(pluginSubscriptions[plugin.AnalysisService.OUTLINE], hasLength(1));
  }

  void test_analysisUpdateContentParams() {
    var serverFiles = {
      'file1': AddContentOverlay('content1'),
      'file2': AddContentOverlay('content2'),
    };
    var result = server.AnalysisUpdateContentParams(serverFiles)
        .asPluginProtocol;
    var pluginFiles = result.files;
    expect(pluginFiles, hasLength(2));
    expect(pluginFiles['file1'], const TypeMatcher<AddContentOverlay>());
    expect(pluginFiles['file2'], const TypeMatcher<AddContentOverlay>());
  }
}
