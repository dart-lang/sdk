// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/src/domain_abstract.dart';
import 'package:analysis_server/src/plugin/plugin_manager.dart';
import 'package:analysis_server/src/protocol_server.dart' hide Element;
import 'package:analyzer_plugin/protocol/protocol.dart' as plugin;
import 'package:analyzer_plugin/protocol/protocol_constants.dart' as plugin;
import 'package:analyzer_plugin/protocol/protocol_generated.dart' as plugin;
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../analysis_abstract.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AbstractRequestHandlerTest);
  });
}

@reflectiveTest
class AbstractRequestHandlerTest extends AbstractAnalysisTest {
  test_waitForResponses_empty_noTimeout() async {
    AbstractRequestHandler handler = new TestAbstractRequestHandler(server);
    Map<PluginInfo, Future<plugin.Response>> futures =
        <PluginInfo, Future<plugin.Response>>{};
    List<plugin.Response> responses = await handler.waitForResponses(futures);
    expect(responses, isEmpty);
  }

  test_waitForResponses_empty_timeout() async {
    AbstractRequestHandler handler = new TestAbstractRequestHandler(server);
    Map<PluginInfo, Future<plugin.Response>> futures =
        <PluginInfo, Future<plugin.Response>>{};
    List<plugin.Response> responses =
        await handler.waitForResponses(futures, timeout: 250);
    expect(responses, isEmpty);
  }

  test_waitForResponses_nonEmpty_noTimeout_immediate() async {
    AbstractRequestHandler handler = new TestAbstractRequestHandler(server);
    PluginInfo plugin1 = new DiscoveredPluginInfo('p1', '', '', null, null);
    PluginInfo plugin2 = new DiscoveredPluginInfo('p2', '', '', null, null);
    plugin.Response response1 = new plugin.Response('1', 1);
    plugin.Response response2 = new plugin.Response('2', 2);
    Map<PluginInfo, Future<plugin.Response>> futures =
        <PluginInfo, Future<plugin.Response>>{
      plugin1: new Future.value(response1),
      plugin2: new Future.value(response2),
    };
    List<plugin.Response> responses = await handler.waitForResponses(futures);
    expect(responses, unorderedEquals([response1, response2]));
  }

  test_waitForResponses_nonEmpty_noTimeout_withError() async {
    AbstractRequestHandler handler = new TestAbstractRequestHandler(server);
    PluginInfo plugin1 = new DiscoveredPluginInfo('p1', '', '', null, null);
    PluginInfo plugin2 = new DiscoveredPluginInfo('p2', '', '', null, null);
    plugin.Response response1 = new plugin.Response('1', 1);
    plugin.Response response2 = new plugin.Response('2', 2,
        error: new plugin.RequestError(
            plugin.RequestErrorCode.PLUGIN_ERROR, 'message'));
    Map<PluginInfo, Future<plugin.Response>> futures =
        <PluginInfo, Future<plugin.Response>>{
      plugin1: new Future.value(response1),
      plugin2: new Future.value(response2),
    };
    List<plugin.Response> responses = await handler.waitForResponses(futures);
    expect(responses, unorderedEquals([response1]));
  }

  test_waitForResponses_nonEmpty_timeout_someDelayed() async {
    AbstractRequestHandler handler = new TestAbstractRequestHandler(server);
    PluginInfo plugin1 = new DiscoveredPluginInfo('p1', '', '', null, null);
    PluginInfo plugin2 = new DiscoveredPluginInfo('p2', '', '', null, null);
    PluginInfo plugin3 = new DiscoveredPluginInfo('p3', '', '', null, null);
    plugin.Response response1 = new plugin.Response('1', 1);
    plugin.Response response2 = new plugin.Response('2', 2);
    plugin.Response response3 = new plugin.Response('3', 3);
    Map<PluginInfo, Future<plugin.Response>> futures =
        <PluginInfo, Future<plugin.Response>>{
      plugin1:
          new Future.delayed(new Duration(milliseconds: 500), () => response1),
      plugin2: new Future.value(response2),
      plugin3:
          new Future.delayed(new Duration(milliseconds: 500), () => response3)
    };
    List<plugin.Response> responses =
        await handler.waitForResponses(futures, timeout: 50);
    expect(responses, unorderedEquals([response2]));
  }
}

class TestAbstractRequestHandler extends AbstractRequestHandler {
  TestAbstractRequestHandler(server) : super(server);

  @override
  Response handleRequest(Request request) {
    fail('Unexpected invocation of handleRequest');
    return null;
  }
}
