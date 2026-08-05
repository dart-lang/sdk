// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/protocol/protocol_generated.dart' as server;
import 'package:analyzer_plugin/protocol/protocol_generated.dart' as plugin;

extension AnalysisServiceExtension on server.AnalysisService {
  plugin.AnalysisService get asPluginProtocol =>
      plugin.AnalysisService.values.byName(name);
}

extension AnalysisSetAnalysisRootsParamsExtension
    on server.AnalysisSetAnalysisRootsParams {
  plugin.AnalysisSetAnalysisRootsParams get asPluginProtocol =>
      plugin.AnalysisSetAnalysisRootsParams(included, excluded);
}

extension AnalysisSetPriorityFilesParamsExtension
    on server.AnalysisSetPriorityFilesParams {
  plugin.AnalysisSetPriorityFilesParams get asPluginProtocol =>
      plugin.AnalysisSetPriorityFilesParams(files);
}

extension AnalysisSetSubscriptionsParamsExtension
    on server.AnalysisSetSubscriptionsParams {
  plugin.AnalysisSetSubscriptionsParams get asPluginProtocol {
    var pluginSubscriptions = <plugin.AnalysisService, List<String>>{};
    for (var entry in subscriptions.entries) {
      var service = entry.key;
      try {
        pluginSubscriptions[service.asPluginProtocol] = entry.value;
      } catch (exception) {
        // Ignore the exception. It indicates that the service isn't one that
        // should be passed along to plugins.
      }
    }
    return plugin.AnalysisSetSubscriptionsParams(pluginSubscriptions);
  }
}

extension AnalysisUpdateContentParamsExtension
    on server.AnalysisUpdateContentParams {
  plugin.AnalysisUpdateContentParams get asPluginProtocol =>
      plugin.AnalysisUpdateContentParams(files);
}
