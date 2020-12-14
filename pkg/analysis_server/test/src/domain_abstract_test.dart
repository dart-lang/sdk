// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/domain_abstract.dart';
import 'package:analysis_server/src/plugin/plugin_manager.dart';
import 'package:analysis_server/src/protocol_server.dart' hide Element;
import 'package:analyzer_plugin/protocol/protocol.dart' as plugin;
import 'package:analyzer_plugin/protocol/protocol_generated.dart' as plugin;
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../analysis_abstract.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AbstractRequestHandlerTest);
  });
}

@reflectiveTest
class AbstractRequestHandlerTest extends AbstractAnalysisTest {
  Future<void> test_waitForResponses_empty_noTimeout() async {
    AbstractRequestHandler handler = TestAbstractRequestHandler(server);
    var futures = <PluginInfo, Future<plugin.Response>>{};
    var responses = await handler.waitForResponses(futures);
    expect(responses, isEmpty);
  }

  Future<void> test_waitForResponses_empty_timeout() async {
    AbstractRequestHandler handler = TestAbstractRequestHandler(server);
    var futures = <PluginInfo, Future<plugin.Response>>{};
    var responses = await handler.waitForResponses(futures, timeout: 250);
    expect(responses, isEmpty);
  }

  Future<void> test_waitForResponses_nonEmpty_noTimeout_immediate() async {
    AbstractRequestHandler handler = TestAbstractRequestHandler(server);
    PluginInfo plugin1 = DiscoveredPluginInfo('p1', '', '', null, null);
    PluginInfo plugin2 = DiscoveredPluginInfo('p2', '', '', null, null);
    var response1 = plugin.Response('1', 1);
    var response2 = plugin.Response('2', 2);
    var futures = <PluginInfo, Future<plugin.Response>>{
      plugin1: Future.value(response1),
      plugin2: Future.value(response2),
    };
    var responses = await handler.waitForResponses(futures);
    expect(responses, unorderedEquals([response1, response2]));
  }

  Future<void> test_waitForResponses_nonEmpty_noTimeout_withError() async {
    AbstractRequestHandler handler = TestAbstractRequestHandler(server);
    PluginInfo plugin1 = DiscoveredPluginInfo('p1', '', '', null, null);
    PluginInfo plugin2 = DiscoveredPluginInfo('p2', '', '', null, null);
    var response1 = plugin.Response('1', 1);
    var response2 = plugin.Response('2', 2,
        error: plugin.RequestError(
            plugin.RequestErrorCode.PLUGIN_ERROR, 'message'));
    var futures = <PluginInfo, Future<plugin.Response>>{
      plugin1: Future.value(response1),
      plugin2: Future.value(response2),
    };
    var responses = await handler.waitForResponses(futures);
    expect(responses, unorderedEquals([response1]));
  }

  Future<void> test_waitForResponses_nonEmpty_timeout_someDelayed() async {
    AbstractRequestHandler handler = TestAbstractRequestHandler(server);
    PluginInfo plugin1 = DiscoveredPluginInfo('p1', '', '', null, null);
    PluginInfo plugin2 = DiscoveredPluginInfo('p2', '', '', null, null);
    PluginInfo plugin3 = DiscoveredPluginInfo('p3', '', '', null, null);
    var response1 = plugin.Response('1', 1);
    var response2 = plugin.Response('2', 2);
    var response3 = plugin.Response('3', 3);
    var futures = <PluginInfo, Future<plugin.Response>>{
      plugin1: Future.delayed(Duration(milliseconds: 500), () => response1),
      plugin2: Future.value(response2),
      plugin3: Future.delayed(Duration(milliseconds: 500), () => response3)
    };
    var responses = await handler.waitForResponses(futures, timeout: 50);
    expect(responses, unorderedEquals([response2]));
  }
}

class TestAbstractRequestHandler extends AbstractRequestHandler {
  TestAbstractRequestHandler(server) : super(server);

  @override
  Response handleRequest(Request request) {
    fail('Unexpected invocation of handleRequest');
  }
}
