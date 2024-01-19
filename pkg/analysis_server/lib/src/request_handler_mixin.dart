// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:analysis_server/src/analysis_server.dart';
import 'package:analysis_server/src/plugin/plugin_manager.dart';
import 'package:analyzer_plugin/protocol/protocol.dart' as plugin;
import 'package:analyzer_plugin/src/protocol/protocol_internal.dart' as plugin;

mixin RequestHandlerMixin<T extends AnalysisServer> {
  /// The analysis server that is using this handler to process requests.
  T get server;

  /// Given a mapping from plugins to futures that will complete when the plugin
  /// has responded to a request, wait for a finite amount of time for each of
  /// the plugins to respond. Return a list of the responses from each of the
  /// plugins. If a plugin fails to return a response, notify the plugin manager
  /// associated with the server so that non-responsive plugins can be killed or
  /// restarted. The [timeout] is the maximum amount of time that will be spent
  /// waiting for plugins to respond.
  Future<List<plugin.Response>> waitForResponses(
    Map<PluginInfo, Future<plugin.Response>> futures, {
    plugin.RequestParams? requestParameters,
    Duration timeout = const Duration(milliseconds: 500),
  }) async {
    // TODO(brianwilkerson): requestParameters might need to be required.
    var timer = Stopwatch()..start();
    var responses = <plugin.Response>[];
    for (var entry in futures.entries) {
      var pluginInfo = entry.key;
      var future = entry.value;
      try {
        var response = await future.timeout(timeout - timer.elapsed);
        var error = response.error;
        if (error != null) {
          // TODO(brianwilkerson): Report the error to the plugin manager.
          server.instrumentationService.logPluginError(
              pluginInfo.data,
              error.code.name,
              error.message,
              error.stackTrace ?? StackTrace.current.toString());
        } else {
          responses.add(response);
        }
      } on TimeoutException {
        // TODO(brianwilkerson): Report the timeout to the plugin manager.
        server.instrumentationService.logPluginTimeout(
            pluginInfo.data,
            JsonEncoder()
                .convert(requestParameters?.toRequest('-').toJson() ?? {}));
      } catch (exception, stackTrace) {
        // TODO(brianwilkerson): Report the exception to the plugin manager.
        server.instrumentationService
            .logPluginException(pluginInfo.data, exception, stackTrace);
      }
    }
    return responses;
  }
}
