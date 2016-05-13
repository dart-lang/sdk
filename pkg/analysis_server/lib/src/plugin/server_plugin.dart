// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analysis_server.src.plugin.server_plugin;

import 'package:analysis_server/plugin/analysis/analysis_domain.dart';
import 'package:analysis_server/plugin/analysis/analyzed_files.dart';
import 'package:analysis_server/plugin/analysis/navigation/navigation.dart';
import 'package:analysis_server/plugin/analysis/navigation/navigation_core.dart';
import 'package:analysis_server/plugin/analysis/occurrences/occurrences.dart';
import 'package:analysis_server/plugin/analysis/occurrences/occurrences_core.dart';
import 'package:analysis_server/plugin/edit/assist/assist.dart';
import 'package:analysis_server/plugin/edit/assist/assist_core.dart';
import 'package:analysis_server/plugin/edit/fix/fix.dart';
import 'package:analysis_server/plugin/edit/fix/fix_core.dart';
import 'package:analysis_server/plugin/protocol/protocol.dart';
import 'package:analysis_server/src/analysis_server.dart';
import 'package:analysis_server/src/domain_analysis.dart';
import 'package:analysis_server/src/domain_completion.dart';
import 'package:analysis_server/src/domain_diagnostic.dart';
import 'package:analysis_server/src/domain_execution.dart';
import 'package:analysis_server/src/domain_server.dart';
import 'package:analysis_server/src/domains/analysis/navigation_dart.dart';
import 'package:analysis_server/src/domains/analysis/occurrences_dart.dart';
import 'package:analysis_server/src/edit/edit_domain.dart';
import 'package:analysis_server/src/provisional/completion/completion_core.dart';
import 'package:analysis_server/src/search/search_domain.dart';
import 'package:analysis_server/src/services/correction/assist_internal.dart';
import 'package:analysis_server/src/services/correction/fix_internal.dart';
import 'package:analyzer/src/generated/engine.dart';
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
   * register file patterns that will cause files to be analyzed.
   */
  static const String ANALYZED_FILE_PATTERNS_EXTENSION_POINT =
      'analyzedFilePatterns';

  /**
   * The simple identifier of the extension point that allows plugins to
   * register assist contributors.
   */
  static const String ASSIST_CONTRIBUTOR_EXTENSION_POINT = 'assistContributor';

  /**
   * The simple identifier of the extension point that allows plugins to
   * register completion contributors.
   */
  static const String COMPLETION_CONTRIBUTOR_EXTENSION_POINT =
      'completionContributor';

  /**
   * The simple identifier of the extension point that allows plugins to
   * register domains.
   */
  static const String DOMAIN_EXTENSION_POINT = 'domain';

  /**
   * The simple identifier of the extension point that allows plugins to
   * register fix contributors.
   */
  static const String FIX_CONTRIBUTOR_EXTENSION_POINT = 'fixContributor';

  /**
   * The simple identifier of the extension point that allows plugins to
   * register index contributors.
   */
  static const String INDEX_CONTRIBUTOR_EXTENSION_POINT = 'indexContributor';

  /**
   * The simple identifier of the extension point that allows plugins to
   * register navigation contributors.
   */
  static const String NAVIGATION_CONTRIBUTOR_EXTENSION_POINT =
      'navigationContributor';

  /**
   * The simple identifier of the extension point that allows plugins to
   * register element occurrences.
   */
  static const String OCCURRENCES_CONTRIBUTOR_EXTENSION_POINT =
      'occurrencesContributor';

  /**
   * The simple identifier of the extension point that allows plugins to
   * register analysis result listeners.
   */
  static const String SET_ANALISYS_DOMAIN_EXTENSION_POINT = 'setAnalysisDomain';

  /**
   * The unique identifier of this plugin.
   */
  static const String UNIQUE_IDENTIFIER = 'analysis_server.core';

  /**
   * The extension point that allows plugins to register file patterns that will
   * cause files to be analyzed.
   */
  ExtensionPoint<List<String>> analyzedFilePatternsExtensionPoint;

  /**
   * The extension point that allows plugins to register assist contributors.
   */
  ExtensionPoint<AssistContributor> assistContributorExtensionPoint;

  /**
   * The extension point that allows plugins to register completion
   * contributors.
   */
  ExtensionPoint<CompletionContributorFactory>
      completionContributorExtensionPoint;

  /**
   * The extension point that allows plugins to register domains with the
   * server.
   */
  ExtensionPoint<RequestHandlerFactory> domainExtensionPoint;

  /**
   * The extension point that allows plugins to register fix contributors with
   * the server.
   */
  ExtensionPoint<FixContributor> fixContributorExtensionPoint;

  /**
   * The extension point that allows plugins to register navigation
   * contributors.
   */
  ExtensionPoint<NavigationContributor> navigationContributorExtensionPoint;

  /**
   * The extension point that allows plugins to register occurrences
   * contributors.
   */
  ExtensionPoint<OccurrencesContributor> occurrencesContributorExtensionPoint;

  /**
   * The extension point that allows plugins to get access to the `analysis`
   * domain.
   */
  ExtensionPoint<SetAnalysisDomain> setAnalysisDomainExtensionPoint;

  /**
   * Initialize a newly created plugin.
   */
  ServerPlugin();

  /**
   * Return a list containing all of the file patterns that can cause files to
   * be analyzed.
   */
  List<String> get analyzedFilePatterns {
    List<String> patterns = <String>[];
    for (List<String> extension
        in analyzedFilePatternsExtensionPoint.extensions) {
      patterns.addAll(extension);
    }
    return patterns;
  }

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
  Iterable<CompletionContributor> get completionContributors =>
      completionContributorExtensionPoint.extensions
          .map((CompletionContributorFactory factory) => factory());

  /**
   * Return a list containing all of the fix contributors that were contributed.
   */
  List<FixContributor> get fixContributors =>
      fixContributorExtensionPoint.extensions;

  /**
   * Return a list containing all of the navigation contributors that were
   * contributed.
   */
  List<NavigationContributor> get navigationContributors =>
      navigationContributorExtensionPoint.extensions;

  /**
   * Return a list containing all of the occurrences contributors that were
   * contributed.
   */
  List<OccurrencesContributor> get occurrencesContributors =>
      occurrencesContributorExtensionPoint.extensions;

  /**
   * Return a list containing all of the receivers of the `analysis` domain
   * instance.
   */
  List<SetAnalysisDomain> get setAnalysisDomainFunctions =>
      setAnalysisDomainExtensionPoint.extensions;

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
    analyzedFilePatternsExtensionPoint = new ExtensionPoint<List<String>>(
        this, ANALYZED_FILE_PATTERNS_EXTENSION_POINT, null);
    registerExtensionPoint(analyzedFilePatternsExtensionPoint);
    assistContributorExtensionPoint = new ExtensionPoint<AssistContributor>(
        this, ASSIST_CONTRIBUTOR_EXTENSION_POINT, null);
    registerExtensionPoint(assistContributorExtensionPoint);
    completionContributorExtensionPoint =
        new ExtensionPoint<CompletionContributorFactory>(
            this, COMPLETION_CONTRIBUTOR_EXTENSION_POINT, null);
    registerExtensionPoint(completionContributorExtensionPoint);
    domainExtensionPoint = new ExtensionPoint<RequestHandlerFactory>(
        this, DOMAIN_EXTENSION_POINT, null);
    registerExtensionPoint(domainExtensionPoint);
    fixContributorExtensionPoint = new ExtensionPoint<FixContributor>(
        this, FIX_CONTRIBUTOR_EXTENSION_POINT, null);
    registerExtensionPoint(fixContributorExtensionPoint);
    navigationContributorExtensionPoint =
        new ExtensionPoint<NavigationContributor>(
            this, NAVIGATION_CONTRIBUTOR_EXTENSION_POINT, null);
    registerExtensionPoint(navigationContributorExtensionPoint);
    occurrencesContributorExtensionPoint =
        new ExtensionPoint<OccurrencesContributor>(
            this, OCCURRENCES_CONTRIBUTOR_EXTENSION_POINT, null);
    registerExtensionPoint(occurrencesContributorExtensionPoint);
    setAnalysisDomainExtensionPoint = new ExtensionPoint<SetAnalysisDomain>(
        this, SET_ANALISYS_DOMAIN_EXTENSION_POINT, null);
    registerExtensionPoint(setAnalysisDomainExtensionPoint);
  }

  @override
  void registerExtensions(RegisterExtension registerExtension) {
    //
    // Register analyzed file patterns.
    //
    List<String> patterns = <String>[
      '**/*.${AnalysisEngine.SUFFIX_DART}',
      '**/*.${AnalysisEngine.SUFFIX_HTML}',
      '**/*.${AnalysisEngine.SUFFIX_HTM}',
      '**/${AnalysisEngine.ANALYSIS_OPTIONS_FILE}',
      '**/${AnalysisEngine.ANALYSIS_OPTIONS_YAML_FILE}'
    ];
    registerExtension(ANALYZED_FILE_PATTERNS_EXTENSION_POINT_ID, patterns);
    //
    // Register assist contributors.
    //
    registerExtension(
        ASSIST_CONTRIBUTOR_EXTENSION_POINT_ID, new DefaultAssistContributor());
    //
    // Register completion contributors.
    //
    // TODO(brianwilkerson) Register the completion contributors.
    //registerExtension(COMPLETION_CONTRIBUTOR_EXTENSION_POINT_ID, ???);
    //
    // Register analysis contributors.
    //
    registerExtension(NAVIGATION_CONTRIBUTOR_EXTENSION_POINT_ID,
        new DartNavigationComputer());
    registerExtension(OCCURRENCES_CONTRIBUTOR_EXTENSION_POINT_ID,
        new DartOccurrencesComputer());
    //
    // Register domains.
    //
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
    registerExtension(domainId,
        (AnalysisServer server) => new DiagnosticDomainHandler(server));
    //
    // Register fix contributors.
    //
    registerExtension(
        FIX_CONTRIBUTOR_EXTENSION_POINT_ID, new DefaultFixContributor());
  }
}
