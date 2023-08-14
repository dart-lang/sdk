// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/protocol_server.dart'
    show CompletionSuggestionKind;
import 'package:analysis_server/src/provisional/completion/dart/completion_dart.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/util/performance/operation_performance.dart';

/// A contributor that produces suggestions based on the members of a library
/// when the library was imported using a prefix. More concretely, this class
/// produces suggestions for expressions of the form `p.^`, where `p` is a
/// prefix.
class LibraryMemberContributor extends DartCompletionContributor {
  LibraryMemberContributor(super.request, super.builder);

  @override
  Future<void> computeSuggestions({
    required OperationPerformanceImpl performance,
  }) async {
    // Determine if the target looks like a library prefix.
    var targetId = request.target.dotTarget;
    if (targetId is SimpleIdentifier && !request.target.isCascade) {
      var elem = targetId.staticElement;
      if (elem is PrefixElement && !elem.isSynthetic) {
        var imports = request.libraryElement.libraryImports;
        _buildSuggestions(elem, imports);
      }
    }
  }

  void _buildSuggestions(
      PrefixElement elem, List<LibraryImportElement> imports) {
    var containingNode = request.target.containingNode;
    var typesOnly =
        containingNode is NamedType && containingNode.importPrefix != null;
    var isConstructor = containingNode.parent is ConstructorName;
    for (var importElem in imports) {
      if (importElem.prefix?.element.name == elem.name) {
        var library = importElem.importedLibrary;
        if (library != null) {
          builder.libraryUriStr = library.source.uri.toString();
          for (var element in importElem.namespace.definedNames.values) {
            if (typesOnly && isConstructor) {
              // Suggest constructors from the imported libraries.
              if (element is ClassElement) {
                for (var constructor in element.constructors) {
                  if (!constructor.isPrivate) {
                    if (!element.isAbstract || constructor.isFactory) {
                      builder.suggestConstructor(constructor,
                          kind: CompletionSuggestionKind.INVOCATION);
                    }
                  }
                }
              }
            } else {
              if (element is InterfaceElement ||
                  element is ExtensionElement ||
                  element is TypeAliasElement) {
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
          if (!typesOnly && importElem.prefix is DeferredImportElementPrefix) {
            builder.suggestLoadLibraryFunction(library.loadLibraryFunction);
          }
          builder.libraryUriStr = null;
        }
      }
    }
  }
}
