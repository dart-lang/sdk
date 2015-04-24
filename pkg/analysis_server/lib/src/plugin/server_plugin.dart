// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analysis_server.src.plugin.server_plugin;

import 'package:analysis_server/analysis/index/index_core.dart';
import 'package:analysis_server/completion/completion_core.dart';
import 'package:analysis_server/edit/assist/assist_core.dart';
import 'package:analysis_server/edit/fix/fix_core.dart';
import 'package:analysis_server/plugin/assist.dart';
//import 'package:analysis_server/plugin/completion.dart';
import 'package:analysis_server/plugin/fix.dart';
import 'package:analysis_server/src/analysis_server.dart';
import 'package:analysis_server/src/domain_analysis.dart';
import 'package:analysis_server/src/domain_completion.dart';
import 'package:analysis_server/src/domain_execution.dart';
import 'package:analysis_server/src/domain_server.dart';
import 'package:analysis_server/src/edit/edit_domain.dart';
import 'package:analysis_server/src/protocol.dart';
import 'package:analysis_server/src/search/search_domain.dart';
import 'package:analysis_server/src/services/correction/assist_internal.dart';
import 'package:analysis_server/src/services/correction/fix_internal.dart';
import 'package:plugin/plugin.dart';

/**
 * A function that will create a request handler that can be used by the given
 * [server].
 */
typedef RequestHandler RequestHandlerFactory(AnalysisServer server);

/**
 * A plugin that defines the extension points and extensions that are inherently
 * defined by the analysis server.
 */
class ServerPlugin implements Plugin {
  /**
   * The simple identifier of the extension point that allows plugins to
   * register new assist contributors with the server.
   */
  static const String ASSIST_CONTRIBUTOR_EXTENSION_POINT = 'assistContributor';

  /**
   * The simple identifier of the extension point that allows plugins to
   * register new completion contributors with the server.
   */
  static const String COMPLETION_CONTRIBUTOR_EXTENSION_POINT =
      'completionContributor';

  /**
   * The simple identifier of the extension point that allows plugins to
   * register new domains with the server.
   */
  static const String DOMAIN_EXTENSION_POINT = 'domain';

  /**
   * The simple identifier of the extension point that allows plugins to
   * register new fix contributors with the server.
   */
  static const String FIX_CONTRIBUTOR_EXTENSION_POINT = 'fixContributor';

  /**
   * The simple identifier of the extension point that allows plugins to
   * register new index contributors with the server.
   */
  static const String INDEX_CONTRIBUTOR_EXTENSION_POINT = 'indexContributor';

  /**
   * The unique identifier of this plugin.
   */
  static const String UNIQUE_IDENTIFIER = 'analysis_server.core';

  /**
   * The extension point that allows plugins to register new assist contributors
   * with the server.
   */
  ExtensionPoint assistContributorExtensionPoint;

  /**
   * The extension point that allows plugins to register new completion
   * contributors with the server.
   */
  ExtensionPoint completionContributorExtensionPoint;

  /**
   * The extension point that allows plugins to register new domains with the
   * server.
   */
  ExtensionPoint domainExtensionPoint;

  /**
   * The extension point that allows plugins to register new fix contributors
   * with the server.
   */
  ExtensionPoint fixContributorExtensionPoint;

  /**
   * The extension point that allows plugins to register new index contributors
   * with the server.
   */
  ExtensionPoint indexContributorExtensionPoint;

  /**
   * Initialize a newly created plugin.
   */
  ServerPlugin();

  /**
   * Return a list containing all of the assist contributors that were
   * contributed.
   */
  List<AssistContributor> get assistContributors =>
      assistContributorExtensionPoint.extensions;

  /**
   * Return a list containing all of the completion contributors that were
   * contributed.
   */
  List<CompletionContributor> get completionContributors =>
      completionContributorExtensionPoint.extensions;

  /**
   * Return a list containing all of the fix contributors that were contributed.
   */
  List<FixContributor> get fixContributors =>
      fixContributorExtensionPoint.extensions;

  /**
   * Return a list containing all of the index contributors that were
   * contributed.
   */
  List<IndexContributor> get indexContributor =>
      indexContributorExtensionPoint.extensions;

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
    assistContributorExtensionPoint = registerExtensionPoint(
        ASSIST_CONTRIBUTOR_EXTENSION_POINT,
        _validateAssistContributorExtension);
    completionContributorExtensionPoint = registerExtensionPoint(
        COMPLETION_CONTRIBUTOR_EXTENSION_POINT,
        _validateCompletionContributorExtension);
    domainExtensionPoint = registerExtensionPoint(
        DOMAIN_EXTENSION_POINT, _validateDomainExtension);
    fixContributorExtensionPoint = registerExtensionPoint(
        FIX_CONTRIBUTOR_EXTENSION_POINT, _validateFixContributorExtension);
    indexContributorExtensionPoint = registerExtensionPoint(
        INDEX_CONTRIBUTOR_EXTENSION_POINT, _validateIndexContributorExtension);
  }

  @override
  void registerExtensions(RegisterExtension registerExtension) {
    //
    // Register assist contributors.
    //
    registerExtension(
        ASSIST_CONTRIBUTOR_EXTENSION_POINT_ID, new DefaultAssistContributor());
    //
    // Register completion contributors.
    //
    // TODO(brianwilkerson) Register the completion contributors.
//    registerExtension(COMPLETION_CONTRIBUTOR_EXTENSION_POINT_ID, ???);
    //
    // Register domains.
    //
    String domainId = Plugin.join(UNIQUE_IDENTIFIER, DOMAIN_EXTENSION_POINT);
    registerExtension(
        domainId, (AnalysisServer server) => new ServerDomainHandler(server));
    registerExtension(
        domainId, (AnalysisServer server) => new AnalysisDomainHandler(server));
    registerExtension(domainId,
        (AnalysisServer server) => new EditDomainHandler(server, this));
    registerExtension(
        domainId, (AnalysisServer server) => new SearchDomainHandler(server));
    registerExtension(domainId,
        (AnalysisServer server) => new CompletionDomainHandler(server));
    registerExtension(domainId,
        (AnalysisServer server) => new ExecutionDomainHandler(server));
    //
    // Register fix contributors.
    //
    registerExtension(
        FIX_CONTRIBUTOR_EXTENSION_POINT_ID, new DefaultFixContributor());
    //
    // Register index contributors.
    //
    // TODO(brianwilkerson) Register the index contributors.
//    registerExtension(INDEX_CONTRIBUTOR_EXTENSION_POINT, ???);
  }

  /**
   * Validate the given extension by throwing an [ExtensionError] if it is not a
   * valid assist contributor.
   */
  void _validateAssistContributorExtension(Object extension) {
    if (extension is! AssistContributor) {
      String id = assistContributorExtensionPoint.uniqueIdentifier;
      throw new ExtensionError(
          'Extensions to $id must be an AssistContributor');
    }
  }

  /**
   * Validate the given extension by throwing an [ExtensionError] if it is not a
   * valid completion contributor.
   */
  void _validateCompletionContributorExtension(Object extension) {
    if (extension is! CompletionContributor) {
      String id = completionContributorExtensionPoint.uniqueIdentifier;
      throw new ExtensionError(
          'Extensions to $id must be an CompletionContributor');
    }
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

  /**
   * Validate the given extension by throwing an [ExtensionError] if it is not a
   * valid fix contributor.
   */
  void _validateFixContributorExtension(Object extension) {
    if (extension is! FixContributor) {
      String id = fixContributorExtensionPoint.uniqueIdentifier;
      throw new ExtensionError('Extensions to $id must be a FixContributor');
    }
  }

  /**
   * Validate the given extension by throwing an [ExtensionError] if it is not a
   * valid index contributor.
   */
  void _validateIndexContributorExtension(Object extension) {
    if (extension is! IndexContributor) {
      String id = indexContributorExtensionPoint.uniqueIdentifier;
      throw new ExtensionError('Extensions to $id must be an IndexContributor');
    }
  }
}
