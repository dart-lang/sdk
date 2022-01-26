// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/protocol_server.dart'
    show CompletionSuggestionKind;
import 'package:analysis_server/src/provisional/completion/dart/completion_dart.dart';
import 'package:analysis_server/src/services/completion/dart/completion_manager.dart';
import 'package:analysis_server/src/services/completion/dart/suggestion_builder.dart'
    show SuggestionBuilder;
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/visitor.dart';
import 'package:analyzer_plugin/src/utilities/completion/optype.dart';

/// A visitor for building suggestions based upon the elements defined by
/// a source file contained in the same library but not the same as
/// the source in which the completions are being requested.
class LibraryElementSuggestionBuilder extends GeneralizingElementVisitor {
  final DartCompletionRequest request;

  final SuggestionBuilder builder;

  final OpType opType;

  CompletionSuggestionKind kind;

  final String? prefix;

  /// The set of libraries that have been, or are currently being, visited.
  final Set<LibraryElement> visitedLibraries = <LibraryElement>{};

  factory LibraryElementSuggestionBuilder(
      DartCompletionRequest request, SuggestionBuilder builder,
      [String? prefix]) {
    var opType = request.opType;
    var kind = request.target.isFunctionalArgument()
        ? CompletionSuggestionKind.IDENTIFIER
        : opType.suggestKind;
    return LibraryElementSuggestionBuilder._(
        request, builder, opType, kind, prefix);
  }

  LibraryElementSuggestionBuilder._(
      this.request, this.builder, this.opType, this.kind, this.prefix);

  @override
  void visitClassElement(ClassElement element) {
    if (opType.includeTypeNameSuggestions) {
      builder.suggestClass(element, prefix: prefix);
    }
    if (opType.includeConstructorSuggestions) {
      _addConstructorSuggestions(element);
    }
    if (opType.includeReturnValueSuggestions) {
      if (element.isEnum) {
        for (var field in element.fields) {
          if (field.isEnumConstant) {
            builder.suggestEnumConstant(field, prefix: prefix);
          }
        }
      }
    }
  }

  @override
  void visitCompilationUnitElement(CompilationUnitElement element) {
    element.visitChildren(this);
  }

  @override
  void visitElement(Element element) {
    // ignored
  }

  @override
  void visitExtensionElement(ExtensionElement element) {
    if (opType.includeReturnValueSuggestions) {
      builder.suggestExtension(element, kind: kind, prefix: prefix);
    }
    element.visitChildren(this);
  }

  @override
  void visitFunctionElement(FunctionElement element) {
    // Do not suggest operators or local functions
    if (element.isOperator) {
      return;
    }
    if (element.enclosingElement is! CompilationUnitElement) {
      return;
    }
    var returnType = element.returnType;
    if (returnType.isVoid) {
      if (opType.includeVoidReturnSuggestions) {
        builder.suggestTopLevelFunction(element, kind: kind, prefix: prefix);
      }
    } else {
      if (opType.includeReturnValueSuggestions) {
        builder.suggestTopLevelFunction(element, kind: kind, prefix: prefix);
      }
    }
  }

  @override
  void visitLibraryElement(LibraryElement element) {
    if (visitedLibraries.add(element)) {
      element.visitChildren(this);
    }
  }

  @override
  void visitPropertyAccessorElement(PropertyAccessorElement element) {
    if (opType.includeReturnValueSuggestions) {
      var parent = element.enclosingElement;
      if (parent is ClassElement || parent is ExtensionElement) {
        builder.suggestAccessor(element, inheritanceDistance: 0.0);
      } else {
        builder.suggestTopLevelPropertyAccessor(element, prefix: prefix);
      }
    }
  }

  @override
  void visitTopLevelVariableElement(TopLevelVariableElement element) {
    if (opType.includeReturnValueSuggestions && !element.isSynthetic) {
      builder.suggestTopLevelVariable(element, prefix: prefix);
    }
  }

  @override
  void visitTypeAliasElement(TypeAliasElement element) {
    if (opType.includeTypeNameSuggestions) {
      builder.suggestTypeAlias(element, prefix: prefix);
    }
  }

  /// Add constructor suggestions for the given class.
  void _addConstructorSuggestions(ClassElement element) {
    if (element.isEnum) {
      return;
    }

    for (var constructor in element.constructors) {
      if (constructor.isPrivate) {
        continue;
      }
      if (element.isAbstract && !constructor.isFactory) {
        continue;
      }
      builder.suggestConstructor(constructor, kind: kind, prefix: prefix);
    }
  }
}

/// A contributor that produces suggestions based on the top level members in
/// the library in which the completion is requested but outside the file in
/// which the completion is requested.
class LocalLibraryContributor extends DartCompletionContributor {
  LocalLibraryContributor(
    DartCompletionRequest request,
    SuggestionBuilder builder,
  ) : super(request, builder);

  @override
  Future<void> computeSuggestions() async {
    if (!request.includeIdentifiers) {
      return;
    }

    var visitor = LibraryElementSuggestionBuilder(request, builder);
    for (var unit in request.libraryElement.units) {
      if (unit.source != request.source) {
        unit.accept(visitor);
      }
    }
  }
}
