// Copyright (c) 2015, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/protocol_server.dart';
import 'package:analysis_server/src/provisional/completion/completion_core.dart';
import 'package:analysis_server/src/provisional/completion/dart/completion_dart.dart';
import 'package:analysis_server/src/services/completion/dart/arglist_contributor.dart';
import 'package:analysis_server/src/services/completion/dart/combinator_contributor.dart';
import 'package:analysis_server/src/services/completion/dart/documentation_cache.dart';
import 'package:analysis_server/src/services/completion/dart/extension_member_contributor.dart';
import 'package:analysis_server/src/services/completion/dart/feature_computer.dart';
import 'package:analysis_server/src/services/completion/dart/field_formal_contributor.dart';
import 'package:analysis_server/src/services/completion/dart/imported_reference_contributor.dart';
import 'package:analysis_server/src/services/completion/dart/keyword_contributor.dart';
import 'package:analysis_server/src/services/completion/dart/label_contributor.dart';
import 'package:analysis_server/src/services/completion/dart/library_member_contributor.dart';
import 'package:analysis_server/src/services/completion/dart/library_prefix_contributor.dart';
import 'package:analysis_server/src/services/completion/dart/local_library_contributor.dart';
import 'package:analysis_server/src/services/completion/dart/local_reference_contributor.dart';
import 'package:analysis_server/src/services/completion/dart/named_constructor_contributor.dart';
import 'package:analysis_server/src/services/completion/dart/not_imported_contributor.dart';
import 'package:analysis_server/src/services/completion/dart/override_contributor.dart';
import 'package:analysis_server/src/services/completion/dart/redirecting_contributor.dart';
import 'package:analysis_server/src/services/completion/dart/relevance_tables.g.dart';
import 'package:analysis_server/src/services/completion/dart/static_member_contributor.dart';
import 'package:analysis_server/src/services/completion/dart/suggestion_builder.dart';
import 'package:analysis_server/src/services/completion/dart/type_member_contributor.dart';
import 'package:analysis_server/src/services/completion/dart/uri_contributor.dart';
import 'package:analysis_server/src/services/completion/dart/variable_name_contributor.dart';
import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/analysis/session.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/dart/analysis/driver_based_analysis_context.dart';
import 'package:analyzer/src/dartdoc/dartdoc_directive_info.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/util/file_paths.dart' as file_paths;
import 'package:analyzer/src/util/performance/operation_performance.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart' as protocol;
import 'package:analyzer_plugin/src/utilities/completion/completion_target.dart';
import 'package:analyzer_plugin/src/utilities/completion/optype.dart';

/// Class that tracks how much time budget we have left.
class CompletionBudget {
  final Duration _budget;
  final Stopwatch _timer = Stopwatch()..start();

  CompletionBudget(this._budget);

  Duration get left {
    var result = _budget - _timer.elapsed;
    return result.isNegative ? Duration.zero : result;
  }
}

/// [DartCompletionManager] determines if a completion request is Dart specific
/// and forwards those requests to all [DartCompletionContributor]s.
class DartCompletionManager {
  /// If not `null`, then instead of using [ImportedReferenceContributor],
  /// fill this set with kinds of elements that are applicable at the
  /// completion location, so should be suggested from available suggestion
  /// sets.
  final Set<protocol.ElementKind>? includedElementKinds;

  /// If [includedElementKinds] is not null, must be also not `null`, and
  /// will be filled with names of all top-level declarations from all
  /// included suggestion sets.
  final Set<String>? includedElementNames;

  /// If [includedElementKinds] is not null, must be also not `null`, and
  /// will be filled with tags for suggestions that should be given higher
  /// relevance than other included suggestions.
  final List<IncludedSuggestionRelevanceTag>? includedSuggestionRelevanceTags;

  /// The listener to be notified at certain points in the process of building
  /// suggestions, or `null` if no notification should occur.
  final SuggestionListener? listener;

  /// If specified, will be filled with URIs of libraries that are not yet
  /// imported, but could be imported into the requested target. Corresponding
  /// [CompletionSuggestion] will have the import index into this list.
  final List<Uri>? librariesToImport;

  /// Initialize a newly created completion manager. The parameters
  /// [includedElementKinds], [includedElementNames], and
  /// [includedSuggestionRelevanceTags] must either all be `null` or must all be
  /// non-`null`.
  DartCompletionManager({
    this.includedElementKinds,
    this.includedElementNames,
    this.includedSuggestionRelevanceTags,
    this.listener,
    this.librariesToImport,
  }) : assert((includedElementKinds != null &&
                includedElementNames != null &&
                includedSuggestionRelevanceTags != null) ||
            (includedElementKinds == null &&
                includedElementNames == null &&
                includedSuggestionRelevanceTags == null));

  Future<List<CompletionSuggestion>> computeSuggestions(
    DartCompletionRequest request,
    OperationPerformanceImpl performance, {
    bool enableOverrideContributor = true,
    bool enableUriContributor = true,
  }) async {
    request.checkAborted();
    var pathContext = request.resourceProvider.pathContext;
    if (!file_paths.isDart(pathContext, request.result.path)) {
      return const <CompletionSuggestion>[];
    }

    // Don't suggest in comments.
    if (request.target.isCommentText) {
      return const <CompletionSuggestion>[];
    }

    request.checkAborted();

    // Request Dart specific completions from each contributor
    var builder = SuggestionBuilder(request, listener: listener);
    var contributors = <DartCompletionContributor>[
      ArgListContributor(request, builder),
      CombinatorContributor(request, builder),
      ExtensionMemberContributor(request, builder),
      FieldFormalContributor(request, builder),
      KeywordContributor(request, builder),
      LabelContributor(request, builder),
      LibraryMemberContributor(request, builder),
      LibraryPrefixContributor(request, builder),
      LocalLibraryContributor(request, builder),
      LocalReferenceContributor(request, builder),
      NamedConstructorContributor(request, builder),
      if (enableOverrideContributor) OverrideContributor(request, builder),
      RedirectingContributor(request, builder),
      StaticMemberContributor(request, builder),
      TypeMemberContributor(request, builder),
      if (enableUriContributor) UriContributor(request, builder),
      VariableNameContributor(request, builder),
    ];

    if (includedElementKinds != null) {
      _addIncludedElementKinds(request);
      _addIncludedSuggestionRelevanceTags(request);
    } else {
      contributors.add(
        ImportedReferenceContributor(request, builder),
      );
    }

    final librariesToImport = this.librariesToImport;
    if (librariesToImport != null) {
      contributors.add(
        NotImportedContributor(request, builder, librariesToImport),
      );
    }

    try {
      for (var contributor in contributors) {
        await performance.runAsync(
          'DartCompletionManager - ${contributor.runtimeType}',
          (_) async {
            await contributor.computeSuggestions();
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
        // Static fields.
        kinds.add(protocol.ElementKind.FIELD);
        kinds.add(protocol.ElementKind.FUNCTION);
        // Static and top-level properties.
        kinds.add(protocol.ElementKind.GETTER);
        kinds.add(protocol.ElementKind.SETTER);
        kinds.add(protocol.ElementKind.TOP_LEVEL_VARIABLE);
      }
    }
  }

  void _addIncludedSuggestionRelevanceTags(DartCompletionRequest request) {
    final includedSuggestionRelevanceTags =
        this.includedSuggestionRelevanceTags!;
    var location = request.opType.completionLocation;
    if (location != null) {
      var locationTable = elementKindRelevance[location];
      if (locationTable != null) {
        var inConstantContext = request.inConstantContext;
        for (var entry in locationTable.entries) {
          var kind = entry.key.toString();
          var elementBoost = (entry.value.upper * 100).floor();
          includedSuggestionRelevanceTags
              .add(IncludedSuggestionRelevanceTag(kind, elementBoost));
          if (inConstantContext) {
            includedSuggestionRelevanceTags.add(IncludedSuggestionRelevanceTag(
                '$kind+const', elementBoost + 100));
          }
        }
      }
    }

    var type = request.contextType;
    if (type is InterfaceType) {
      var element = type.element;
      var tag = '${element.librarySource.uri}::${element.name}';
      if (element.isEnum) {
        includedSuggestionRelevanceTags.add(
          IncludedSuggestionRelevanceTag(
            tag,
            RelevanceBoost.availableEnumConstant,
          ),
        );
      } else {
        // TODO(brianwilkerson) This was previously used to boost exact type
        //  matches. For example, if the context type was `Foo`, then the class
        //  `Foo` and it's constructors would be given this boost. Now this
        //  boost will almost always be ignored because the element boost will
        //  be bigger. Find a way to use this boost without negating the element
        //  boost, which is how we get constructors to come before classes.
        includedSuggestionRelevanceTags.add(
          IncludedSuggestionRelevanceTag(
            tag,
            RelevanceBoost.availableDeclaration,
          ),
        );
      }
    }
  }
}

/// The information about a requested list of completions within a Dart file.
class DartCompletionRequest {
  final CompletionPreference completionPreference;

  /// Return the type imposed on the target's `containingNode` based on its
  /// context, or `null` if the context does not impose any type.
  final DartType? contextType;

  /// Return the object used to resolve macros in Dartdoc comments.
  final DartdocDirectiveInfo dartdocDirectiveInfo;

  final DocumentationCache? documentationCache;

  /// Return the expression to the right of the "dot" or "dot dot",
  /// or `null` if this is not a "dot" completion (e.g. `foo.b`).
  final Expression? dotTarget;

  /// Return the object used to compute the values of the features used to
  /// compute relevance scores for suggestions.
  final FeatureComputer featureComputer;

  /// Return the offset within the source at which the completion is being
  /// requested.
  final int offset;

  /// The [OpType] which describes which types of suggestions would fit the
  /// request.
  final OpType opType;

  /// The source range that represents the region of text that should be
  /// replaced when a suggestion is selected.
  final SourceRange replacementRange;

  /// The analysis result for the file in which the completion is being
  /// requested.
  final ResolvedUnitResult result;

  /// Return the source in which the completion is being requested.
  final Source source;

  /// Return the completion target.  This determines what part of the parse tree
  /// will receive the newly inserted text.
  /// At a minimum, all declarations in the completion scope in [target.unit]
  /// will be resolved if they can be resolved.
  final CompletionTarget target;

  bool _aborted = false;

  factory DartCompletionRequest({
    required ResolvedUnitResult resolvedUnit,
    required int offset,
    DartdocDirectiveInfo? dartdocDirectiveInfo,
    CompletionPreference completionPreference = CompletionPreference.insert,
    DocumentationCache? documentationCache,
  }) {
    var target = CompletionTarget.forOffset(resolvedUnit.unit, offset);
    var dotTarget = _dotTarget(target);

    var featureComputer = FeatureComputer(
      resolvedUnit.typeSystem,
      resolvedUnit.typeProvider,
    );

    var contextType = featureComputer.computeContextType(
      target.containingNode,
      offset,
    );

    var opType = OpType.forCompletion(target, offset);
    if (contextType != null && contextType.isVoid) {
      opType.includeVoidReturnSuggestions = true;
    }

    return DartCompletionRequest._(
      completionPreference: completionPreference,
      contextType: contextType,
      dartdocDirectiveInfo: dartdocDirectiveInfo ?? DartdocDirectiveInfo(),
      documentationCache: documentationCache,
      dotTarget: dotTarget,
      featureComputer: featureComputer,
      offset: offset,
      opType: opType,
      replacementRange: target.computeReplacementRange(offset),
      result: resolvedUnit,
      source: resolvedUnit.unit.declaredElement!.source,
      target: target,
    );
  }

  DartCompletionRequest._({
    required this.completionPreference,
    required this.contextType,
    required this.dartdocDirectiveInfo,
    required this.documentationCache,
    required this.dotTarget,
    required this.featureComputer,
    required this.offset,
    required this.opType,
    required this.replacementRange,
    required this.result,
    required this.source,
    required this.target,
  });

  /// Return the feature set that was used to analyze the compilation unit in
  /// which suggestions are being made.
  FeatureSet get featureSet => libraryElement.featureSet;

  /// Return `true` if free standing identifiers should be suggested
  bool get includeIdentifiers {
    return opType.includeIdentifiers;
  }

  /// Return `true` if the completion is occurring in a constant context.
  bool get inConstantContext {
    var entity = target.entity;
    return entity is Expression && entity.inConstantContext;
  }

  /// Return the library element which contains the unit in which the completion
  /// is occurring.
  LibraryElement get libraryElement => result.libraryElement;

  /// Answer the [DartType] for Object in dart:core
  DartType get objectType => libraryElement.typeProvider.objectType;

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
  ResourceProvider get resourceProvider => result.session.resourceProvider;

  /// Return the content of the [source] in which the completion is being
  /// requested, or `null` if the content could not be accessed.
  String? get sourceContents => result.content;

  /// Return the [SourceFactory] of the request.
  SourceFactory get sourceFactory {
    var context = result.session.analysisContext as DriverBasedAnalysisContext;
    return context.driver.sourceFactory;
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

    while (entity is AstNode) {
      if (entity is SimpleIdentifier) {
        var identifier = entity.name;
        if (offset >= entity.offset && offset < entity.end) {
          return identifier.substring(0, offset - entity.offset);
        } else if (offset == entity.end) {
          return identifier;
        }
      }
      var children = entity.childEntities;
      entity = children.isEmpty ? null : children.first;
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

  /// TODO(scheglov) Should this be a property of [CompletionTarget]?
  static Expression? _dotTarget(CompletionTarget target) {
    var node = target.containingNode;
    var offset = target.offset;
    if (node is MethodInvocation) {
      if (identical(node.methodName, target.entity)) {
        return node.realTarget;
      } else if (node.isCascaded && node.operator!.offset + 1 == offset) {
        return node.realTarget;
      }
    }
    if (node is PropertyAccess) {
      if (identical(node.propertyName, target.entity)) {
        return node.realTarget;
      } else if (node.isCascaded && node.operator.offset + 1 == offset) {
        return node.realTarget;
      }
    }
    if (node is PrefixedIdentifier) {
      if (identical(node.identifier, target.entity)) {
        return node.prefix;
      }
    }
  }
}
