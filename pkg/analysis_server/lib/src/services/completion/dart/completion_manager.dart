// Copyright (c) 2015, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/protocol_server.dart';
import 'package:analysis_server/src/provisional/completion/completion_core.dart'
    show AbortCompletion, CompletionRequest;
import 'package:analysis_server/src/provisional/completion/dart/completion_dart.dart';
import 'package:analysis_server/src/services/completion/completion_core.dart';
import 'package:analysis_server/src/services/completion/completion_performance.dart';
import 'package:analysis_server/src/services/completion/dart/arglist_contributor.dart';
import 'package:analysis_server/src/services/completion/dart/combinator_contributor.dart';
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
import 'package:analysis_server/src/services/completion/dart/override_contributor.dart';
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
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dartdoc/dartdoc_directive_info.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/util/performance/operation_performance.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart' as protocol;
import 'package:analyzer_plugin/src/utilities/completion/completion_target.dart';
import 'package:analyzer_plugin/src/utilities/completion/optype.dart';

/// [DartCompletionManager] determines if a completion request is Dart specific
/// and forwards those requests to all [DartCompletionContributor]s.
class DartCompletionManager {
  /// The object used to resolve macros in Dartdoc comments.
  final DartdocDirectiveInfo dartdocDirectiveInfo;

  /// If not `null`, then instead of using [ImportedReferenceContributor],
  /// fill this set with kinds of elements that are applicable at the
  /// completion location, so should be suggested from available suggestion
  /// sets.
  final Set<protocol.ElementKind> includedElementKinds;

  /// If [includedElementKinds] is not null, must be also not `null`, and
  /// will be filled with names of all top-level declarations from all
  /// included suggestion sets.
  final Set<String> includedElementNames;

  /// If [includedElementKinds] is not null, must be also not `null`, and
  /// will be filled with tags for suggestions that should be given higher
  /// relevance than other included suggestions.
  final List<IncludedSuggestionRelevanceTag> includedSuggestionRelevanceTags;

  /// The listener to be notified at certain points in the process of building
  /// suggestions, or `null` if no notification should occur.
  final SuggestionListener listener;

  /// Initialize a newly created completion manager. The parameters
  /// [includedElementKinds], [includedElementNames], and
  /// [includedSuggestionRelevanceTags] must either all be `null` or must all be
  /// non-`null`.
  DartCompletionManager(
      {this.dartdocDirectiveInfo,
      this.includedElementKinds,
      this.includedElementNames,
      this.includedSuggestionRelevanceTags,
      this.listener})
      : assert((includedElementKinds != null &&
                includedElementNames != null &&
                includedSuggestionRelevanceTags != null) ||
            (includedElementKinds == null &&
                includedElementNames == null &&
                includedSuggestionRelevanceTags == null));

  Future<List<CompletionSuggestion>> computeSuggestions(
    OperationPerformanceImpl performance,
    CompletionRequest request, {
    bool enableOverrideContributor = true,
    bool enableUriContributor = true,
  }) async {
    request.checkAborted();
    if (!AnalysisEngine.isDartFileName(request.result.path)) {
      return const <CompletionSuggestion>[];
    }

    var dartRequest = await DartCompletionRequestImpl.from(
      performance,
      request,
      dartdocDirectiveInfo,
    );

    // Don't suggest in comments.
    if (dartRequest.target.isCommentText) {
      return const <CompletionSuggestion>[];
    }

    request.checkAborted();

    var range = dartRequest.target.computeReplacementRange(dartRequest.offset);
    (request as CompletionRequestImpl)
      ..replacementOffset = range.offset
      ..replacementLength = range.length;

    // Request Dart specific completions from each contributor
    var builder = SuggestionBuilder(dartRequest, listener: listener);
    var contributors = <DartCompletionContributor>[
      ArgListContributor(),
      CombinatorContributor(),
      ExtensionMemberContributor(),
      FieldFormalContributor(),
      KeywordContributor(),
      LabelContributor(),
      LibraryMemberContributor(),
      LibraryPrefixContributor(),
      LocalLibraryContributor(),
      LocalReferenceContributor(),
      NamedConstructorContributor(),
      if (enableOverrideContributor) OverrideContributor(),
      StaticMemberContributor(),
      TypeMemberContributor(),
      if (enableUriContributor) UriContributor(),
      VariableNameContributor()
    ];

    if (includedElementKinds != null) {
      _addIncludedElementKinds(dartRequest);
      _addIncludedSuggestionRelevanceTags(dartRequest);
    } else {
      contributors.add(ImportedReferenceContributor());
    }

    try {
      for (var contributor in contributors) {
        await performance.runAsync(
          'DartCompletionManager - ${contributor.runtimeType}',
          (_) async {
            await contributor.computeSuggestions(dartRequest, builder);
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

  void _addIncludedElementKinds(DartCompletionRequestImpl request) {
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

  void _addIncludedSuggestionRelevanceTags(DartCompletionRequestImpl request) {
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
class DartCompletionRequestImpl implements DartCompletionRequest {
  @override
  final ResolvedUnitResult result;

  @override
  final ResourceProvider resourceProvider;

  @override
  final InterfaceType objectType;

  @override
  final Source source;

  @override
  final int offset;

  @override
  Expression dotTarget;

  @override
  final Source librarySource;

  @override
  CompletionTarget target;

  OpType _opType;

  @override
  final FeatureComputer featureComputer;

  @override
  final DartdocDirectiveInfo dartdocDirectiveInfo;

  /// A flag indicating whether the [_contextType] has been computed.
  bool _hasComputedContextType = false;

  /// The context type associated with the target's `containingNode`.
  DartType _contextType;

  final CompletionRequest _originalRequest;

  final CompletionPerformance performance;

  DartCompletionRequestImpl._(
      this.result,
      this.resourceProvider,
      this.objectType,
      this.librarySource,
      this.source,
      this.offset,
      CompilationUnit unit,
      this.dartdocDirectiveInfo,
      this._originalRequest,
      this.performance)
      : featureComputer =
            FeatureComputer(result.typeSystem, result.typeProvider) {
    _updateTargets(unit);
  }

  @override
  DartType get contextType {
    if (!_hasComputedContextType) {
      _contextType = featureComputer.computeContextType(
          target.containingNode, target.offset);
      _hasComputedContextType = true;
    }
    return _contextType;
  }

  @override
  FeatureSet get featureSet => result.libraryElement.featureSet;

  @override
  bool get includeIdentifiers {
    return opType.includeIdentifiers;
  }

  @override
  bool get inConstantContext {
    var entity = target.entity;
    return entity is ExpressionImpl && entity.inConstantContext;
  }

  @override
  LibraryElement get libraryElement => result.libraryElement;

  @override
  OpType get opType {
    _opType ??= OpType.forCompletion(target, offset);
    return _opType;
  }

  @override
  String get sourceContents => result.content;

  @override
  SourceFactory get sourceFactory {
    DriverBasedAnalysisContext context = result.session.analysisContext;
    return context.driver.sourceFactory;
  }

  @override
  String get targetPrefix {
    var entity = target.entity;

    if (entity is Token) {
      var prev = entity.previous;
      if (prev?.end == offset && prev.isKeywordOrIdentifier) {
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
      var children = (entity as AstNode).childEntities;
      entity = children.isEmpty ? null : children.first;
    }
    return '';
  }

  /// Throw [AbortCompletion] if the completion request has been aborted.
  @override
  void checkAborted() {
    _originalRequest.checkAborted();
  }

  /// Update the completion [target] and [dotTarget] based on the given [unit].
  void _updateTargets(CompilationUnit unit) {
    _opType = null;
    dotTarget = null;
    target = CompletionTarget.forOffset(unit, offset);
    var node = target.containingNode;
    if (node is MethodInvocation) {
      if (identical(node.methodName, target.entity)) {
        dotTarget = node.realTarget;
      } else if (node.isCascaded && node.operator.offset + 1 == target.offset) {
        dotTarget = node.realTarget;
      }
    }
    if (node is PropertyAccess) {
      if (identical(node.propertyName, target.entity)) {
        dotTarget = node.realTarget;
      } else if (node.isCascaded && node.operator.offset + 1 == target.offset) {
        dotTarget = node.realTarget;
      }
    }
    if (node is PrefixedIdentifier) {
      if (identical(node.identifier, target.entity)) {
        dotTarget = node.prefix;
      }
    }
  }

  /// Return a [Future] that completes with a newly created completion request
  /// based on the given [request]. This method will throw [AbortCompletion]
  /// if the completion request has been aborted.
  static Future<DartCompletionRequest> from(
      OperationPerformanceImpl performance,
      CompletionRequest request,
      DartdocDirectiveInfo dartdocDirectiveInfo) async {
    request.checkAborted();

    return performance.run(
      'build DartCompletionRequest',
      (_) {
        var unit = request.result.unit;
        var libSource = unit.declaredElement.library.source;
        var objectType = request.result.typeProvider.objectType;

        return DartCompletionRequestImpl._(
          request.result,
          request.resourceProvider,
          objectType,
          libSource,
          request.source,
          request.offset,
          unit,
          dartdocDirectiveInfo,
          request,
          (request as CompletionRequestImpl).performance,
        );
      },
    );
  }
}
