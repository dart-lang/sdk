// Copyright (c) 2015, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/protocol_server.dart' as protocol;
import 'package:analysis_server/src/provisional/completion/dart/completion_dart.dart';
import 'package:analysis_server/src/services/completion/dart/completion_manager.dart';
import 'package:analysis_server/src/services/completion/dart/suggestion_builder.dart';
import 'package:analysis_server/src/utilities/extensions/completion_request.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';

/// A contributor that produces suggestions based on the named constructors
/// defined on a given class. More concretely, this class produces suggestions
/// for expressions of the form `C.^` or `C<E>.^`, where `C` is the name of a
/// class.
class NamedConstructorContributor extends DartCompletionContributor {
  NamedConstructorContributor(
    DartCompletionRequest request,
    SuggestionBuilder builder,
  ) : super(request, builder);

  @override
  Future<void> computeSuggestions() async {
    var node = request.target.containingNode;
    if (node is ConstructorName) {
      if (node.parent is ConstructorReference) {
        var element = node.type2.name.staticElement;
        if (element is ClassElement) {
          _buildSuggestions(element);
        }
      } else {
        var type = node.type2.type;
        if (type is InterfaceType) {
          var element = type.element;
          _buildSuggestions(element);
        }
      }
    } else if (node is PrefixedIdentifier) {
      var element = node.prefix.staticElement;
      if (element is ClassElement) {
        _buildSuggestions(element);
      }
    }
  }

  void _buildSuggestions(ClassElement element) {
    var tearOff = request.shouldSuggestTearOff(element);
    var isLocalClassDecl = element.library == request.libraryElement;
    for (var constructor in element.constructors) {
      if (isLocalClassDecl || !constructor.isPrivate) {
        if (!element.isAbstract || constructor.isFactory) {
          builder.suggestConstructor(
            constructor,
            hasClassName: true,
            kind: tearOff
                ? protocol.CompletionSuggestionKind.IDENTIFIER
                : protocol.CompletionSuggestionKind.INVOCATION,
            tearOff: tearOff,
          );
        }
      }
    }
  }
}
