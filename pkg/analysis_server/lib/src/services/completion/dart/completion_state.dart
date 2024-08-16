// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/completion/dart/completion_manager.dart';
import 'package:analysis_server/src/services/completion/dart/utilities.dart';
import 'package:analysis_server_plugin/src/utilities/selection.dart';
import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/utilities/completion_matcher.dart';

/// The information used to compute the suggestions for a completion request.
class CompletionState {
  /// The completion request being processed.
  final DartCompletionRequest request;

  /// The selection at the time completion was requested.
  ///
  /// The selection is required to have a length of zero.
  final Selection selection;

  /// The budget controlling how much time can be spent computing completion
  /// suggestions.
  final CompletionBudget budget;

  /// The matcher used to compute the score of a completion suggestion.
  final CompletionMatcher matcher;

  /// Initialize a newly created completion state.
  CompletionState(this.request, this.selection, this.budget, this.matcher)
      : assert(selection.length == 0);

  /// The type of value required by the context in which completion was
  /// requested.
  DartType? get contextType => request.contextType;

  /// The [ClassMember] that encloses the completion location, or `null` if the
  /// completion location isn't in a class member.
  ClassMember? get enclosingMember {
    return selection.coveringNode.thisOrAncestorOfType<ClassMember>();
  }

  /// Indicates if types should be specified whenever possible.
  bool get includeTypes =>
      request.fileState.analysisOptions.codeStyleOptions.specifyTypes;

  /// The indentation for the completion text.
  String get indent => getRequestLineIndent(request);

  /// Whether the completion location is inside an instance member, and hence
  /// whether there is a binding for `this`.
  bool get inInstanceScope {
    var member = enclosingMember;
    return member != null && !member.isStatic;
  }

  /// The element of the library containing the completion location.
  LibraryElement get libraryElement => request.libraryElement;

  /// The type of `this` at the completion location, or `null` if the completion
  /// location doesn't allow `this` to be used.
  DartType? get thisType {
    AstNode? node = selection.coveringNode;
    while (node != null) {
      switch (node) {
        case ClassDeclaration():
          var element = node.declaredElement;
          if (element != null) {
            return element.thisType;
          }
        case EnumDeclaration():
          var element = node.declaredElement;
          if (element != null) {
            return element.thisType;
          }
        case ExtensionDeclaration():
          return node.onClause?.extendedType.type;
        case MixinDeclaration():
          var element = node.declaredElement;
          if (element != null) {
            return element.thisType;
          }
      }
      node = node.parent;
    }
    return null;
  }

  /// Whether the given `feature` is enabled in the library containing the
  /// selection.
  bool isFeatureEnabled(Feature feature) {
    return libraryElement.featureSet.isEnabled(feature);
  }
}

// TODO(brianwilkerson): Move to 'package:analysis_server/src/utilities/extensions/ast.dart'
extension on ClassMember {
  /// Whether this member is a static member.
  bool get isStatic {
    var self = this;
    if (self is MethodDeclaration) {
      return self.isStatic;
    } else if (self is FieldDeclaration) {
      return self.isStatic;
    }
    return false;
  }
}
