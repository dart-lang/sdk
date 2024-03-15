// Copyright (c) 2015, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/protocol_server.dart';
import 'package:analysis_server/src/provisional/completion/completion_core.dart';
import 'package:analysis_server/src/provisional/completion/dart/completion_dart.dart';
import 'package:analysis_server/src/services/completion/dart/candidate_suggestion.dart';
import 'package:analysis_server/src/services/completion/dart/completion_state.dart';
import 'package:analysis_server/src/services/completion/dart/enum_constant_constructor_contributor.dart';
import 'package:analysis_server/src/services/completion/dart/extension_member_contributor.dart';
import 'package:analysis_server/src/services/completion/dart/feature_computer.dart';
import 'package:analysis_server/src/services/completion/dart/in_scope_completion_pass.dart';
import 'package:analysis_server/src/services/completion/dart/library_member_contributor.dart';
import 'package:analysis_server/src/services/completion/dart/library_prefix_contributor.dart';
import 'package:analysis_server/src/services/completion/dart/not_imported_contributor.dart';
import 'package:analysis_server/src/services/completion/dart/record_literal_contributor.dart';
import 'package:analysis_server/src/services/completion/dart/suggestion_builder.dart';
import 'package:analysis_server/src/services/completion/dart/suggestion_collector.dart';
import 'package:analysis_server/src/services/completion/dart/uri_contributor.dart';
import 'package:analysis_server/src/utilities/selection.dart';
import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/analysis/session.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/source/source.dart';
import 'package:analyzer/source/source_range.dart';
import 'package:analyzer/src/dart/analysis/driver_based_analysis_context.dart';
import 'package:analyzer/src/dart/analysis/session.dart';
import 'package:analyzer/src/dart/element/inheritance_manager3.dart';
import 'package:analyzer/src/dartdoc/dartdoc_directive_info.dart';
import 'package:analyzer/src/generated/source.dart' show SourceFactory;
import 'package:analyzer/src/util/file_paths.dart' as file_paths;
import 'package:analyzer/src/util/performance/operation_performance.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart' as protocol;
import 'package:analyzer_plugin/src/utilities/completion/completion_target.dart';
import 'package:analyzer_plugin/src/utilities/completion/optype.dart';

/// Class that tracks how much time budget we have left.
class CompletionBudget {
  static const Duration defaultDuration = Duration(milliseconds: 100);

  final Duration _budget;
  final Stopwatch _timer = Stopwatch()..start();

  CompletionBudget(this._budget);

  bool get isEmpty {
    return _timer.elapsed > _budget;
  }

  Duration get left {
    var result = _budget - _timer.elapsed;
    return result.isNegative ? Duration.zero : result;
  }
}

/// [DartCompletionManager] determines if a completion request is Dart specific
/// and forwards those requests to all [DartCompletionContributor]s.
class DartCompletionManager {
  /// Time budget to computing suggestions.
  final CompletionBudget budget;

  /// If not `null`, then instead of using [ImportedReferenceContributor],
  /// fill this set with kinds of elements that are applicable at the
  /// completion location, so should be suggested from available suggestion
  /// sets.
  final Set<protocol.ElementKind>? includedElementKinds;

  /// If [includedElementKinds] is not null, must be also not `null`, and
  /// will be filled with names of all top-level declarations from all
  /// included suggestion sets.
  final Set<String>? includedElementNames;

  /// The listener to be notified at certain points in the process of building
  /// suggestions, or `null` if no notification should occur.
  final SuggestionListener? listener;

  /// If specified, will be filled with suggestions and URIs from libraries
  /// that are not yet imported, but could be imported into the requested
  /// target. It is up to the client to make copies of [CompletionSuggestion]s
  /// with the import index property updated.
  final NotImportedSuggestions? notImportedSuggestions;

  /// Initialize a newly created completion manager. The parameters
  /// [includedElementKinds], [includedElementNames], and
  /// [includedSuggestionRelevanceTags] must either all be `null` or must all be
  /// non-`null`.
  DartCompletionManager({
    required this.budget,
    this.includedElementKinds,
    this.includedElementNames,
    this.listener,
    this.notImportedSuggestions,
  }) : assert((includedElementKinds != null && includedElementNames != null) ||
            (includedElementKinds == null && includedElementNames == null));

  Future<List<CompletionSuggestionBuilder>> computeSuggestions(
    DartCompletionRequest request,
    OperationPerformanceImpl performance, {
    bool enableOverrideContributor = true,
    bool enableUriContributor = true,
    required bool useFilter,
  }) async {
    request.checkAborted();
    var pathContext = request.resourceProvider.pathContext;
    if (!file_paths.isDart(pathContext, request.path)) {
      return const [];
    }

    // Don't suggest in comments.
    if (request.target.isCommentText) {
      return const [];
    }

    request.checkAborted();

    // Compute the list of contributors that will be run.
    var builder =
        SuggestionBuilder(request, useFilter: useFilter, listener: listener);
    var contributors = <DartCompletionContributor>[
      EnumConstantConstructorContributor(request, builder),
      ExtensionMemberContributor(request, builder),
      LibraryMemberContributor(request, builder),
      LibraryPrefixContributor(request, builder),
      RecordLiteralContributor(request, builder),
      if (enableUriContributor) UriContributor(request, builder),
    ];

    if (includedElementKinds != null) {
      _addIncludedElementKinds(request);
    }

    final notImportedSuggestions = this.notImportedSuggestions;
    if (notImportedSuggestions != null) {
      contributors.add(
        NotImportedContributor(
            request, builder, budget, notImportedSuggestions),
      );
    }

    try {
      await performance.runAsync(
        'InScopeCompletionPass',
        (performance) async {
          _runFirstPass(
              request: request,
              builder: builder,
              skipImports: includedElementKinds != null,
              suggestOverrides: enableOverrideContributor);
        },
      );
      for (var contributor in contributors) {
        await performance.runAsync(
          '${contributor.runtimeType}',
          (performance) async {
            await contributor.computeSuggestions(
              performance: performance,
            );
          },
        );
        request.checkAborted();
      }
    } on InconsistentAnalysisException {
      // The state of the code being analyzed has changed, so results are likely
      // to be inconsistent. Just abort the operation.
      throw AbortCompletion();
    }

    return builder.suggestions.toList();
  }

  void _addIncludedElementKinds(DartCompletionRequest request) {
    var opType = request.opType;

    if (!opType.includeIdentifiers) return;

    var kinds = includedElementKinds;
    if (kinds != null) {
      if (opType.includeConstructorSuggestions) {
        kinds.add(protocol.ElementKind.CONSTRUCTOR);
      }
      if (opType.includeTypeNameSuggestions) {
        kinds.add(protocol.ElementKind.CLASS);
        kinds.add(protocol.ElementKind.CLASS_TYPE_ALIAS);
        kinds.add(protocol.ElementKind.ENUM);
        kinds.add(protocol.ElementKind.FUNCTION_TYPE_ALIAS);
        kinds.add(protocol.ElementKind.MIXIN);
        kinds.add(protocol.ElementKind.TYPE_ALIAS);
      }
      if (opType.includeReturnValueSuggestions) {
        kinds.add(protocol.ElementKind.CONSTRUCTOR);
        kinds.add(protocol.ElementKind.ENUM_CONSTANT);
        kinds.add(protocol.ElementKind.EXTENSION);
        kinds.add(protocol.ElementKind.FUNCTION);
        // Top-level properties.
        kinds.add(protocol.ElementKind.GETTER);
        kinds.add(protocol.ElementKind.SETTER);
        kinds.add(protocol.ElementKind.TOP_LEVEL_VARIABLE);
      }
      if (opType.includeAnnotationSuggestions) {
        kinds.add(protocol.ElementKind.CONSTRUCTOR);
        // Top-level properties.
        kinds.add(protocol.ElementKind.GETTER);
        kinds.add(protocol.ElementKind.TOP_LEVEL_VARIABLE);
      }
    }
  }

  // Run the first pass of the code completion algorithm.
  void _runFirstPass(
      {required DartCompletionRequest request,
      required SuggestionBuilder builder,
      required bool skipImports,
      required bool suggestOverrides}) {
    var collector = SuggestionCollector();
    var selection = request.unit.select(offset: request.offset, length: 0);
    if (selection == null) {
      throw AbortCompletion();
    }
    var state = CompletionState(request, selection);
    var pass = InScopeCompletionPass(
        state: state,
        collector: collector,
        skipImports: skipImports,
        suggestOverrides: suggestOverrides);
    pass.computeSuggestions();
    request.collectorLocationName = collector.completionLocation;
    builder.suggestFromCandidates(collector.suggestions);
  }
}

/// The information about a requested list of completions within a Dart file.
class DartCompletionRequest {
  /// The analysis session that produced the elements of the request.
  final AnalysisSessionImpl analysisSession;

  final CompletionPreference completionPreference;

  /// The content of the file in which completion is requested.
  final String content;

  /// Return the type imposed on the target's `containingNode` based on its
  /// context, or `null` if the context does not impose any type.
  final DartType? contextType;

  /// Return the object used to resolve macros in Dartdoc comments.
  final DartdocDirectiveInfo dartdocDirectiveInfo;

  /// Return the object used to compute the values of the features used to
  /// compute relevance scores for suggestions.
  final FeatureComputer featureComputer;

  /// The library element of the file in which completion is requested.
  final LibraryElement libraryElement;

  /// Return the offset within the source at which the completion is being
  /// requested.
  final int offset;

  /// The [OpType] which describes which types of suggestions would fit the
  /// request.
  final OpType opType;

  /// The absolute path of the file where completion is requested.
  final String path;

  /// The source range that represents the region of text that should be
  /// replaced when a suggestion is selected.
  final SourceRange replacementRange;

  /// Return the source in which the completion is being requested.
  final Source source;

  /// Return the completion target.  This determines what part of the parse tree
  /// will receive the newly inserted text.
  /// At a minimum, all declarations in the completion scope in [target.unit]
  /// will be resolved if they can be resolved.
  final CompletionTarget target;

  /// The compilation unit in which completion is being requested.
  final CompilationUnit unit;

  /// The location name from [SuggestionCollector].
  String? collectorLocationName;

  bool _aborted = false;

  /// Return `true` if the completion is occurring in a constant context.
  late final bool inConstantContext = () {
    var entity = target.entity;
    return entity is Expression && entity.inConstantContext;
  }();

  factory DartCompletionRequest({
    required AnalysisSession analysisSession,
    required String filePath,
    required String fileContent,
    required CompilationUnitElement unitElement,
    required AstNode enclosingNode,
    required int offset,
    required CompilationUnit unit,
    DartdocDirectiveInfo? dartdocDirectiveInfo,
    CompletionPreference completionPreference = CompletionPreference.insert,
  }) {
    var target = CompletionTarget.forOffset(enclosingNode, offset);

    var libraryElement = unitElement.library;
    var featureComputer = FeatureComputer(
      libraryElement.typeSystem,
      libraryElement.typeProvider,
    );

    var contextType = featureComputer.computeContextType(
      target.containingNode,
      offset,
    );

    var opType = OpType.forCompletion(target, offset);
    if (contextType is VoidType) {
      opType.includeVoidReturnSuggestions = true;
    }

    return DartCompletionRequest._(
      analysisSession: analysisSession as AnalysisSessionImpl,
      completionPreference: completionPreference,
      content: fileContent,
      contextType: contextType,
      dartdocDirectiveInfo: dartdocDirectiveInfo ?? DartdocDirectiveInfo(),
      featureComputer: featureComputer,
      libraryElement: libraryElement,
      offset: offset,
      opType: opType,
      path: filePath,
      replacementRange: target.computeReplacementRange(offset),
      source: unitElement.source,
      target: target,
      unit: unit,
    );
  }

  factory DartCompletionRequest.forResolvedUnit({
    required ResolvedUnitResult resolvedUnit,
    required int offset,
    DartdocDirectiveInfo? dartdocDirectiveInfo,
    CompletionPreference completionPreference = CompletionPreference.insert,
  }) {
    return DartCompletionRequest(
      analysisSession: resolvedUnit.session,
      filePath: resolvedUnit.path,
      fileContent: resolvedUnit.content,
      unitElement: resolvedUnit.unit.declaredElement!,
      enclosingNode: resolvedUnit.unit,
      offset: offset,
      unit: resolvedUnit.unit,
      dartdocDirectiveInfo: dartdocDirectiveInfo,
      completionPreference: completionPreference,
    );
  }

  DartCompletionRequest._({
    required this.analysisSession,
    required this.completionPreference,
    required this.content,
    required this.contextType,
    required this.dartdocDirectiveInfo,
    required this.featureComputer,
    required this.libraryElement,
    required this.offset,
    required this.opType,
    required this.path,
    required this.replacementRange,
    required this.source,
    required this.target,
    required this.unit,
  });

  DriverBasedAnalysisContext get analysisContext {
    var analysisContext = analysisSession.analysisContext;
    return analysisContext as DriverBasedAnalysisContext;
  }

  /// Return the feature set that was used to analyze the compilation unit in
  /// which suggestions are being made.
  FeatureSet get featureSet => libraryElement.featureSet;

  /// Return `true` if free standing identifiers should be suggested
  bool get includeIdentifiers {
    return opType.includeIdentifiers;
  }

  InheritanceManager3 get inheritanceManager {
    return analysisSession.inheritanceManager;
  }

  /// Answer the [DartType] for Object in dart:core
  InterfaceType get objectType => libraryElement.typeProvider.objectType;

  /// The length of the text to be replaced if the remainder of the identifier
  /// containing the cursor is to be replaced when the suggestion is applied
  /// (that is, the number of characters in the existing identifier).
  /// This will be different than the [replacementOffset] - [offset]
  /// if the [offset] is in the middle of an existing identifier.
  int get replacementLength => replacementRange.length;

  /// The offset of the start of the text to be replaced.
  /// This will be different than the [offset] used to request the completion
  /// suggestions if there was a portion of an identifier before the original
  /// [offset]. In particular, the [replacementOffset] will be the offset of the
  /// beginning of said identifier.
  int get replacementOffset => replacementRange.offset;

  /// Return the resource provider associated with this request.
  ResourceProvider get resourceProvider => analysisSession.resourceProvider;

  /// Return the [SourceFactory] of the request.
  SourceFactory get sourceFactory {
    return analysisContext.driver.sourceFactory;
  }

  /// Return prefix that already exists in the document for [target] or empty
  /// string if unavailable. This can be used to filter the completion list to
  /// items that already match the text to the left of the caret.
  String get targetPrefix {
    var entity = target.entity;

    if (entity is Token) {
      var prev = entity.previous;
      if (prev != null && prev.end == offset && prev.isKeywordOrIdentifier) {
        return prev.lexeme;
      }
    }

    if (entity is Token &&
        entity.type == TokenType.STRING &&
        entity.offset < offset &&
        offset < entity.end) {
      final uriNode = target.containingNode;
      if (uriNode is SimpleStringLiteral && uriNode.literal == entity) {
        final directive = uriNode.parent;
        if (directive is UriBasedDirective &&
            directive.uri == uriNode &&
            offset >= uriNode.contentsOffset) {
          return uriNode.value.substring(0, offset - uriNode.contentsOffset);
        }
      }
    }

    // TODO(scheglov): Can we make it better?
    String fromToken(Token token) {
      final lexeme = token.lexeme;
      if (offset >= token.offset && offset < token.end) {
        return lexeme.substring(0, offset - token.offset);
      } else if (offset == token.end) {
        return lexeme;
      }
      return '';
    }

    if (entity is Token) {
      if (entity.end == offset && entity.isKeywordOrIdentifier) {
        return fromToken(entity);
      }
    }

    if (entity is DeclaredVariablePattern && entity.name.offset <= offset) {
      return fromToken(entity.name);
    }

    while (entity is AstNode) {
      if (entity is SimpleIdentifier) {
        return fromToken(entity.token);
      }
      var children = entity.childEntities;
      entity = children.isEmpty ? null : children.first;
      if (entity is Token) {
        return fromToken(entity);
      }
    }
    return '';
  }

  /// Abort the current completion request.
  void abort() {
    _aborted = true;
  }

  /// Throw [AbortCompletion] if the completion request has been aborted.
  void checkAborted() {
    if (_aborted) {
      throw AbortCompletion();
    }
  }
}

/// Information provided by [NotImportedContributor] in addition to suggestions.
class NotImportedSuggestions {
  /// This flag is set to `true` if the contributor decided to stop before it
  /// processed all available libraries, e.g. we ran out of budget.
  bool isIncomplete = false;
}
