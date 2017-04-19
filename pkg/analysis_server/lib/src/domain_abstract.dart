// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:analysis_server/src/analysis_server.dart';
import 'package:analysis_server/src/plugin/plugin_manager.dart';
import 'package:analysis_server/src/protocol_server.dart' hide Element;
import 'package:analyzer_plugin/protocol/protocol.dart' as plugin;
import 'package:analyzer_plugin/protocol/protocol_constants.dart' as plugin;
import 'package:analyzer_plugin/protocol/protocol_generated.dart' as plugin;
import 'package:analyzer_plugin/src/protocol/protocol_internal.dart' as plugin;

/**
 * An abstract implementation of a request handler.
 */
abstract class AbstractRequestHandler implements RequestHandler {
  /**
   * The analysis server that is using this handler to process requests.
   */
  final AnalysisServer server;

  /**
   * Initialize a newly created request handler to be associated with the given
   * analysis [server].
   */
  AbstractRequestHandler(this.server);

  /**
   * Given a mapping from plugins to futures that will complete when the plugin
   * has responded to a request, wait for a finite amount of time for each of
   * the plugins to respond. Return a list of the responses from each of the
   * plugins. If a plugin fails to return a response, notify the plugin manager
   * associated with the server so that non-responsive plugins can be killed or
   * restarted. The [timeout] is the maximum amount of time that will be spent
   * waiting for plugins to respond.
   */
  Future<List<plugin.Response>> waitForResponses(
      Map<PluginInfo, Future<plugin.Response>> futures,
      {plugin.RequestParams requestParameters,
      int timeout: 500}) async {
    // TODO(brianwilkerson) requestParameters might need to be required.
    int endTime = new DateTime.now().millisecondsSinceEpoch + timeout;
    List<plugin.Response> responses = <plugin.Response>[];
    for (PluginInfo pluginInfo in futures.keys) {
      Future<plugin.Response> future = futures[pluginInfo];
      try {
        int startTime = new DateTime.now().millisecondsSinceEpoch;
        plugin.Response response = await future.timeout(
            new Duration(milliseconds: math.max(endTime - startTime, 0)));
        if (response.error != null) {
          // TODO(brianwilkerson) Report the error to the plugin manager.
          server.instrumentationService.logPluginError(
              pluginInfo.data,
              response.error.code.name,
              response.error.message,
              response.error.stackTrace);
        } else {
          responses.add(response);
        }
      } on TimeoutException {
        // TODO(brianwilkerson) Report the timeout to the plugin manager.
        server.instrumentationService.logPluginTimeout(
            pluginInfo.data,
            new JsonEncoder()
                .convert(requestParameters?.toRequest('-')?.toJson() ?? {}));
      } catch (exception, stackTrace) {
        // TODO(brianwilkerson) Report the exception to the plugin manager.
        server.instrumentationService
            .logPluginException(pluginInfo.data, exception, stackTrace);
      }
    }
    return responses;
  }
}
