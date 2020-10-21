// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/protocol/protocol_generated.dart' as server;
import 'package:analyzer_plugin/protocol/protocol_generated.dart' as plugin;

/// An object used to convert between similar objects defined by both the plugin
/// protocol and the server protocol.
class RequestConverter {
  plugin.AnalysisService convertAnalysisService(
      server.AnalysisService service) {
    return plugin.AnalysisService(service.name);
  }

  plugin.AnalysisSetPriorityFilesParams convertAnalysisSetPriorityFilesParams(
      server.AnalysisSetPriorityFilesParams params) {
    return plugin.AnalysisSetPriorityFilesParams(params.files);
  }

  plugin.AnalysisSetSubscriptionsParams convertAnalysisSetSubscriptionsParams(
      server.AnalysisSetSubscriptionsParams params) {
    var serverSubscriptions = params.subscriptions;
    var pluginSubscriptions = <plugin.AnalysisService, List<String>>{};
    for (var service in serverSubscriptions.keys) {
      try {
        pluginSubscriptions[convertAnalysisService(service)] =
            serverSubscriptions[service];
      } catch (exception) {
        // Ignore the exception. It indicates that the service isn't one that
        // should be passed along to plugins.
      }
    }
    return plugin.AnalysisSetSubscriptionsParams(pluginSubscriptions);
  }

  plugin.AnalysisUpdateContentParams convertAnalysisUpdateContentParams(
      server.AnalysisUpdateContentParams params) {
    return plugin.AnalysisUpdateContentParams(params.files);
  }
}
