// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/protocol/protocol_generated.dart' as server;
import 'package:analysis_server/src/protocol/protocol_internal.dart' as server;
import 'package:analyzer_plugin/protocol/protocol_generated.dart' as plugin;

/**
 * An object used to convert between similar objects defined by both the plugin
 * protocol and the server protocol.
 */
class RequestConverter {
  plugin.AnalysisService convertAnalysisService(
      server.AnalysisService service) {
    return new plugin.AnalysisService(service.name);
  }

  plugin.AnalysisSetPriorityFilesParams convertAnalysisSetPriorityFilesParams(
      server.AnalysisSetPriorityFilesParams params) {
    return new plugin.AnalysisSetPriorityFilesParams(params.files);
  }

  plugin.AnalysisSetSubscriptionsParams convertAnalysisSetSubscriptionsParams(
      server.AnalysisSetSubscriptionsParams params) {
    Map<server.AnalysisService, List<String>> serverSubscriptions =
        params.subscriptions;
    Map<plugin.AnalysisService, List<String>> pluginSubscriptions =
        <plugin.AnalysisService, List<String>>{};
    for (server.AnalysisService service in serverSubscriptions.keys) {
      try {
        pluginSubscriptions[convertAnalysisService(service)] =
            serverSubscriptions[service];
      } catch (exception) {
        // Ignore the exception. It indicates that the service isn't one that
        // should be passed along to plugins.
      }
    }
    return new plugin.AnalysisSetSubscriptionsParams(pluginSubscriptions);
  }

  plugin.AnalysisUpdateContentParams convertAnalysisUpdateContentParams(
      server.AnalysisUpdateContentParams params) {
    return new plugin.AnalysisUpdateContentParams(params.files);
  }
}
