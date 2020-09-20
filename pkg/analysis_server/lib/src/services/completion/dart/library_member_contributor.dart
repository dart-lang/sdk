// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/protocol_server.dart'
    show CompletionSuggestionKind;
import 'package:analysis_server/src/provisional/completion/dart/completion_dart.dart';
import 'package:analysis_server/src/services/completion/dart/suggestion_builder.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';

/// A contributor that produces suggestions based on the members of a library
/// when the library was imported using a prefix. More concretely, this class
/// produces suggestions for expressions of the form `p.^`, where `p` is a
/// prefix.
class LibraryMemberContributor extends DartCompletionContributor {
  @override
  Future<void> computeSuggestions(
      DartCompletionRequest request, SuggestionBuilder builder) async {
    // Determine if the target looks like a library prefix.
    var targetId = request.dotTarget;
    if (targetId is SimpleIdentifier && !request.target.isCascade) {
      var elem = targetId.staticElement;
      if (elem is PrefixElement && !elem.isSynthetic) {
        var containingLibrary = request.libraryElement;
        // Gracefully degrade if the library or directives could not be
        // determined (e.g. detached part file or source change).
        if (containingLibrary != null) {
          var imports = containingLibrary.imports;
          if (imports != null) {
            _buildSuggestions(request, builder, elem, imports);
            return;
          }
        }
      }
    }
  }

  void _buildSuggestions(
      DartCompletionRequest request,
      SuggestionBuilder builder,
      PrefixElement elem,
      List<ImportElement> imports) {
    var parent = request.target.containingNode.parent;
    var typesOnly = parent is TypeName;
    var isConstructor = parent.parent is ConstructorName;
    for (var importElem in imports) {
      if (importElem.prefix?.name == elem.name) {
        var library = importElem.importedLibrary;
        if (library != null) {
          for (var element in importElem.namespace.definedNames.values) {
            if (typesOnly && isConstructor) {
              // Suggest constructors from the imported libraries.
              if (element is ClassElement) {
                for (var constructor in element.constructors) {
                  if (!constructor.isPrivate) {
                    builder.suggestConstructor(constructor,
                        kind: CompletionSuggestionKind.INVOCATION);
                  }
                }
              }
            } else {
              if (element is ClassElement ||
                  element is ExtensionElement ||
                  element is FunctionTypeAliasElement) {
                builder.suggestElement(element,
                    kind: CompletionSuggestionKind.INVOCATION);
              } else if (!typesOnly &&
                  (element is FunctionElement ||
                      element is PropertyAccessorElement)) {
                builder.suggestElement(element,
                    kind: CompletionSuggestionKind.INVOCATION);
              }
            }
          }
          // If the import is `deferred` then suggest `loadLibrary`.
          if (!typesOnly && importElem.isDeferred) {
            builder.suggestLoadLibraryFunction(library.loadLibraryFunction);
          }
        }
      }
    }
  }
}
