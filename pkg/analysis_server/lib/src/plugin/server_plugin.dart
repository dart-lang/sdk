// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analysis_server.src.plugin.server_plugin;

import 'package:analysis_server/plugin/plugin.dart';
import 'package:analysis_server/src/analysis_server.dart';
import 'package:analysis_server/src/domain_analysis.dart';
import 'package:analysis_server/src/domain_completion.dart';
import 'package:analysis_server/src/domain_execution.dart';
import 'package:analysis_server/src/domain_server.dart';
import 'package:analysis_server/src/edit/edit_domain.dart';
import 'package:analysis_server/src/protocol.dart';
import 'package:analysis_server/src/search/search_domain.dart';

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
   * The extension point that allows plugins to register new domains with the
   * server.
   */
  ExtensionPoint domainExtensionPoint;

  /**
   * Initialize a newly created plugin.
   */
  ServerPlugin();

  @override
  String get uniqueIdentifier => UNIQUE_IDENTIFIER;

  /**
   * Use the given [server] to create all of the domains ([RequestHandler]'s)
   * that have been registered and return the newly created domains.
   */
  List<RequestHandler> createDomains(AnalysisServer server) {
    if (domainExtensionPoint == null) {
      return <RequestHandler>[];
    }
    return domainExtensionPoint.extensions
        .map((RequestHandlerFactory factory) => factory(server))
        .toList();
  }

  @override
  void registerExtensionPoints(RegisterExtensionPoint registerExtensionPoint) {
    domainExtensionPoint = registerExtensionPoint(
        DOMAIN_EXTENSION_POINT, _validateDomainExtension);
  }

  @override
  void registerExtensions(RegisterExtension registerExtension) {
    String domainId = Plugin.join(UNIQUE_IDENTIFIER, DOMAIN_EXTENSION_POINT);
    registerExtension(
        domainId, (AnalysisServer server) => new ServerDomainHandler(server));
    registerExtension(
        domainId, (AnalysisServer server) => new AnalysisDomainHandler(server));
    registerExtension(
        domainId, (AnalysisServer server) => new EditDomainHandler(server));
    registerExtension(
        domainId, (AnalysisServer server) => new SearchDomainHandler(server));
    registerExtension(domainId,
        (AnalysisServer server) => new CompletionDomainHandler(server));
    registerExtension(domainId,
        (AnalysisServer server) => new ExecutionDomainHandler(server));
  }

  /**
   * Validate the given extension by throwing an [ExtensionError] if it is not a
   * valid domain.
   */
  void _validateDomainExtension(Object extension) {
    if (extension is! RequestHandlerFactory) {
      String id = domainExtensionPoint.uniqueIdentifier;
      throw new ExtensionError(
          'Extensions to $id must be a RequestHandlerFactory');
    }
  }
}
