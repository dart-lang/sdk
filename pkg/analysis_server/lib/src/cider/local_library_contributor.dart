// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/protocol_server.dart'
    show CompletionSuggestionKind;
import 'package:analysis_server/src/services/completion/dart/completion_manager.dart';
import 'package:analysis_server/src/services/completion/dart/suggestion_builder.dart'
    show SuggestionBuilder;
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/dart/element/visitor2.dart';
import 'package:analyzer_plugin/src/utilities/completion/optype.dart';

/// A visitor for building suggestions based upon the elements defined by
/// a source file contained in the same library but not the same as
/// the source in which the completions are being requested.
class LibraryElementSuggestionBuilder
    extends GeneralizingElementVisitor2<void> {
  final DartCompletionRequest request;

  final SuggestionBuilder builder;

  final OpType opType;

  CompletionSuggestionKind kind;

  final String? prefix;

  /// The set of libraries that have been, or are currently being, visited.
  final Set<LibraryElement> visitedLibraries = <LibraryElement>{};

  factory LibraryElementSuggestionBuilder(
    DartCompletionRequest request,
    SuggestionBuilder builder, [
    String? prefix,
  ]) {
    var opType = request.opType;
    var kind = request.target.isFunctionalArgument()
        ? CompletionSuggestionKind.IDENTIFIER
        : opType.suggestKind;
    return LibraryElementSuggestionBuilder._(
      request,
      builder,
      opType,
      kind,
      prefix,
    );
  }

  LibraryElementSuggestionBuilder._(
    this.request,
    this.builder,
    this.opType,
    this.kind,
    this.prefix,
  );

  @override
  void visitClassElement(ClassElement element) {
    AstNode node = request.target.containingNode;
    if (node is ExtendsClause) {
      if (element.library != request.libraryElement &&
          !element.isExtendableOutside) {
        return;
      }
    } else if (node is ImplementsClause) {
      if (element.library != request.libraryElement &&
          !element.isImplementableOutside) {
        return;
      }
    } else if (node is WithClause) {
      if (element.library != request.libraryElement &&
          !element.isMixableOutside) {
        return;
      }
    }
    _visitInterfaceElement(element);
  }

  @override
  void visitElement(Element element) {
    // ignored
  }

  @override
  visitEnumElement(EnumElement element) {
    _visitInterfaceElement(element);
  }

  @override
  void visitExtensionElement(ExtensionElement element) {
    if (opType.includeReturnValueSuggestions) {
      if (element.name != null) {
        builder.suggestExtension(element, kind: kind, prefix: prefix);
      }
    }
  }

  @override
  void visitExtensionTypeElement(ExtensionTypeElement element) {
    _visitInterfaceElement(element);
  }

  @override
  void visitGetterElement(GetterElement element) {
    var variable = element.variable;
    if (opType.includeReturnValueSuggestions ||
        (opType.includeAnnotationSuggestions && variable.isConst)) {
      var parent = element.enclosingElement;
      if (parent is InterfaceElement || parent is ExtensionElement) {
        if (element.isSynthetic) {
          if (variable is FieldElement) {
            builder.suggestField(variable, inheritanceDistance: 0.0);
          }
        } else {
          builder.suggestGetter(element, inheritanceDistance: 0.0);
        }
      } else {
        builder.suggestTopLevelGetter(element, prefix: prefix);
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
  visitMixinElement(MixinElement element) {
    AstNode node = request.target.containingNode;
    if (node is ImplementsClause &&
        request.libraryElement != element.library &&
        !element.isImplementableOutside) {
      return;
    }
    _visitInterfaceElement(element);
  }

  @override
  void visitSetterElement(SetterElement element) {
    var variable = element.variable;
    if (opType.includeReturnValueSuggestions ||
        (opType.includeAnnotationSuggestions && variable.isConst)) {
      var parent = element.enclosingElement;
      if (parent is InterfaceElement || parent is ExtensionElement) {
        if (!element.isSynthetic) {
          builder.suggestSetter(element, inheritanceDistance: 0.0);
        }
      } else {
        builder.suggestTopLevelSetter(element, prefix: prefix);
      }
    }
  }

  @override
  void visitTopLevelFunctionElement(TopLevelFunctionElement element) {
    var returnType = element.returnType;
    if (returnType is VoidType) {
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
  ///
  /// If [onlyConst] is `true`, only `const` constructors will be suggested.
  void _addConstructorSuggestions(
    ClassElement element, {
    bool onlyConst = false,
  }) {
    if (element is EnumElement) {
      return;
    }

    for (var constructor in element.constructors) {
      if (constructor.isPrivate) {
        continue;
      }
      if (!element.isConstructable && !constructor.isFactory) {
        continue;
      }
      if (onlyConst && !constructor.isConst) {
        continue;
      }
      builder.suggestConstructor(constructor, kind: kind, prefix: prefix);
    }
  }

  void _visitInterfaceElement(InterfaceElement element) {
    if (opType.includeTypeNameSuggestions) {
      builder.suggestInterface(element, prefix: prefix);
    }
    if (element is ClassElement) {
      if (opType.includeConstructorSuggestions) {
        _addConstructorSuggestions(element);
      } else if (opType.includeAnnotationSuggestions) {
        _addConstructorSuggestions(element, onlyConst: true);
      }
    }
    if (opType.includeReturnValueSuggestions) {
      var typeSystem = request.libraryElement.typeSystem;
      var contextType = request.contextType;
      if (contextType is InterfaceType) {
        // TODO(scheglov): This looks not ideal - we should suggest getters.
        for (var field in element.fields) {
          if (field.isStatic &&
              field.isAccessibleIn(request.libraryElement) &&
              typeSystem.isSubtypeOf(field.type, contextType)) {
            if (field.isSynthetic) {
              var getter = field.getter;
              if (getter != null) {
                builder.suggestGetter(
                  getter,
                  inheritanceDistance: 0.0,
                  withEnclosingName: true,
                );
              }
            } else {
              builder.suggestStaticField(field, prefix: prefix);
            }
          }
        }
      }
    }
  }
}
