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
import 'package:analysis_server/src/provisional/index/index.dart';
import 'package:analysis_server/src/provisional/index/index_core.dart';
import 'package:analysis_server/src/search/search_domain.dart';
import 'package:analysis_server/src/services/correction/assist_internal.dart';
import 'package:analysis_server/src/services/correction/fix_internal.dart';
import 'package:analysis_server/src/services/index/index_contributor.dart';
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
  ExtensionPoint analyzedFilePatternsExtensionPoint;

  /**
   * The extension point that allows plugins to register assist contributors.
   */
  ExtensionPoint assistContributorExtensionPoint;

  /**
   * The extension point that allows plugins to register completion
   * contributors.
   */
  ExtensionPoint completionContributorExtensionPoint;

  /**
   * The extension point that allows plugins to register domains with the
   * server.
   */
  ExtensionPoint domainExtensionPoint;

  /**
   * The extension point that allows plugins to register fix contributors with
   * the server.
   */
  ExtensionPoint fixContributorExtensionPoint;

  /**
   * The extension point that allows plugins to register index contributors.
   */
  ExtensionPoint indexContributorExtensionPoint;

  /**
   * The extension point that allows plugins to register navigation
   * contributors.
   */
  ExtensionPoint navigationContributorExtensionPoint;

  /**
   * The extension point that allows plugins to register occurrences
   * contributors.
   */
  ExtensionPoint occurrencesContributorExtensionPoint;

  /**
   * The extension point that allows plugins to get access to the `analysis`
   * domain.
   */
  ExtensionPoint setAnalysisDomainExtensionPoint;

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
   * Return a list containing all of the index contributors that were
   * contributed.
   */
  List<IndexContributor> get indexContributors =>
      indexContributorExtensionPoint.extensions;

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
    setAnalysisDomainExtensionPoint = registerExtensionPoint(
        SET_ANALISYS_DOMAIN_EXTENSION_POINT,
        _validateSetAnalysisDomainFunction);
    analyzedFilePatternsExtensionPoint = registerExtensionPoint(
        ANALYZED_FILE_PATTERNS_EXTENSION_POINT,
        _validateAnalyzedFilePatternsExtension);
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
    navigationContributorExtensionPoint = registerExtensionPoint(
        NAVIGATION_CONTRIBUTOR_EXTENSION_POINT,
        _validateNavigationContributorExtension);
    occurrencesContributorExtensionPoint = registerExtensionPoint(
        OCCURRENCES_CONTRIBUTOR_EXTENSION_POINT,
        _validateOccurrencesContributorExtension);
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
      '**/${AnalysisEngine.ANALYSIS_OPTIONS_FILE}'
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
    //
    // Register index contributors.
    //
    registerExtension(
        INDEX_CONTRIBUTOR_EXTENSION_POINT_ID, new DartIndexContributor());
  }

  /**
   * Return `true` if the list being used as an [extension] contains any
   * elements that are not strings.
   */
  bool _containsNonString(List extension) {
    for (Object element in extension) {
      if (element is! String) {
        return true;
      }
    }
    return false;
  }

  /**
   * Validate the given extension by throwing an [ExtensionError] if it is not a
   * valid list of analyzed file patterns.
   */
  void _validateAnalyzedFilePatternsExtension(Object extension) {
    if (extension is! List || _containsNonString(extension)) {
      String id = analyzedFilePatternsExtensionPoint.uniqueIdentifier;
      throw new ExtensionError('Extensions to $id must be a List of Strings');
    }
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
    if (extension is! CompletionContributorFactory) {
      String id = completionContributorExtensionPoint.uniqueIdentifier;
      throw new ExtensionError(
          'Extensions to $id must be an CompletionContributorFactory');
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

  /**
   * Validate the given extension by throwing an [ExtensionError] if it is not a
   * valid navigation contributor.
   */
  void _validateNavigationContributorExtension(Object extension) {
    if (extension is! NavigationContributor) {
      String id = navigationContributorExtensionPoint.uniqueIdentifier;
      throw new ExtensionError(
          'Extensions to $id must be an NavigationContributor');
    }
  }

  /**
   * Validate the given extension by throwing an [ExtensionError] if it is not a
   * valid occurrences contributor.
   */
  void _validateOccurrencesContributorExtension(Object extension) {
    if (extension is! OccurrencesContributor) {
      String id = occurrencesContributorExtensionPoint.uniqueIdentifier;
      throw new ExtensionError(
          'Extensions to $id must be an OccurrencesContributor');
    }
  }

  /**
   * Validate the given extension by throwing an [ExtensionError] if it is not a
   * valid analysis domain receiver.
   */
  void _validateSetAnalysisDomainFunction(Object extension) {
    if (extension is! SetAnalysisDomain) {
      String id = setAnalysisDomainExtensionPoint.uniqueIdentifier;
      throw new ExtensionError(
          'Extensions to $id must be a SetAnalysisDomain function');
    }
  }
}
