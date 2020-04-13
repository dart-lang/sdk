// Copyright (c) 2015, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/src/provisional/completion/completion_core.dart';
import 'package:analysis_server/src/services/completion/dart/feature_computer.dart';
import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dartdoc/dartdoc_directive_info.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:analyzer_plugin/src/utilities/completion/completion_target.dart';
import 'package:analyzer_plugin/src/utilities/completion/optype.dart';

export 'package:analyzer_plugin/utilities/completion/relevance.dart';

/// An object that contributes results for the `completion.getSuggestions`
/// request results.
abstract class DartCompletionContributor {
  /// Return a [Future] that completes with a list of suggestions
  /// for the given completion [request].
  Future<List<CompletionSuggestion>> computeSuggestions(
      DartCompletionRequest request);
}

/// The information about a requested list of completions within a Dart file.
///
/// Clients may not extend, implement or mix-in this class.
abstract class DartCompletionRequest extends CompletionRequest {
  /// Return the type imposed on the target's `containingNode` based on its
  /// context, or `null` if the context does not impose any type.
  DartType get contextType;

  /// Return the object used to resolve macros in Dartdoc comments.
  DartdocDirectiveInfo get dartdocDirectiveInfo;

  /// Return the expression to the right of the "dot" or "dot dot",
  /// or `null` if this is not a "dot" completion (e.g. `foo.b`).
  Expression get dotTarget;

  /// Return the object used to compute the values of the features used to
  /// compute relevance scores for suggestions.
  FeatureComputer get featureComputer;

  /// Return the feature set that was used to analyze the compilation unit in
  /// which suggestions are being made.
  FeatureSet get featureSet;

  /// Return `true` if free standing identifiers should be suggested
  bool get includeIdentifiers;

  /// Return the library element which contains the unit in which the completion
  /// is occurring. This may return `null` if the library cannot be determined
  /// (e.g. unlinked part file).
  LibraryElement get libraryElement;

  /// The source for the library containing the completion request.
  /// This may be different from the source in which the completion is requested
  /// if the completion is being requested in a part file.
  /// This may be `null` if the library for a part file cannot be determined.
  Source get librarySource;

  /// Answer the [DartType] for Object in dart:core
  DartType get objectType;

  /// The [OpType] which describes which types of suggestions would fit the
  /// request.
  OpType get opType;

  /// Return the [SourceFactory] of the request.
  SourceFactory get sourceFactory;

  /// Return the completion target.  This determines what part of the parse tree
  /// will receive the newly inserted text.
  /// At a minimum, all declarations in the completion scope in [target.unit]
  /// will be resolved if they can be resolved.
  CompletionTarget get target;
}
