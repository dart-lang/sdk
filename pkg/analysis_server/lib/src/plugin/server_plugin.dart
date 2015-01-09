// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analysis_server.src.plugin.plugin_impl;

import 'package:analysis_server/plugin/plugin.dart';
import 'package:analysis_server/src/analysis_server.dart';
import 'package:analysis_server/src/domain_server.dart';
import 'package:analysis_server/src/protocol.dart';

/**
 * A function that will create a request handler that can be used by the given
 * [server].
 *
 * TODO(brianwilkerson) Move this into 'protocol.dart'.
 */
typedef RequestHandler RequestHandlerFactory(AnalysisServer server);

/**
 * A plugin that defines the extension points and extensions that are inherently
 * defined by the analysis server.
 */
class ServerPlugin implements Plugin {
  /**
   * The simple identifier of the extension point that allows plugins to
   * register new domains with the server.
   */
  static const String DOMAIN_EXTENSION_POINT = 'domain';

  /**
   * The unique identifier of this plugin.
   */
  static const String UNIQUE_IDENTIFIER = 'analysis_server.core';

  /**
   * Initialize a newly created plugin.
   */
  ServerPlugin();

  @override
  String get uniqueIdentifier => UNIQUE_IDENTIFIER;

  @override
  void registerExtensionPoints(RegisterExtensionPoint registerExtensionPoint) {
    registerExtensionPoint(
        DOMAIN_EXTENSION_POINT,
        (Object extension) => extension is RequestHandlerFactory);
  }

  @override
  void registerExtensions(RegisterExtension registerExtension) {
    String domainId = Plugin.join(UNIQUE_IDENTIFIER, DOMAIN_EXTENSION_POINT);
    registerExtension(
        domainId,
        (AnalysisServer server) => new ServerDomainHandler(server));
    // TODO(brianwilkerson) Register the other domains.
  }
}
