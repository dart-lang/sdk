// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library services.completion.computer.dart.local;

import 'dart:async';

import 'package:analysis_server/src/protocol.dart' as protocol show Element,
    ElementKind;
import 'package:analysis_server/src/protocol.dart' hide Element, ElementKind;
import 'package:analysis_server/src/services/completion/dart_completion_manager.dart';
import 'package:analysis_server/src/services/completion/local_declaration_visitor.dart';
import 'package:analysis_server/src/services/completion/optype.dart';
import 'package:analyzer/src/generated/ast.dart';
import 'package:analyzer/src/generated/scanner.dart';
import 'package:analyzer/src/generated/utilities_dart.dart';

/**
 * A computer for calculating `completion.getSuggestions` request results
 * for the local library in which the completion is requested.
 */
class LocalComputer extends DartCompletionComputer {

  @override
  bool computeFast(DartCompletionRequest request) {
    OpType optype = request.optype;
    if (optype.includeTopLevelSuggestions) {
      _LocalVisitor localVisitor = new _LocalVisitor(
          request,
          request.offset,
          optype.includeOnlyTypeNameSuggestions,
          !optype.includeVoidReturnSuggestions);

      // Collect suggestions from the specific child [AstNode] that contains
      // the completion offset and all of its parents recursively.
      localVisitor.visit(request.node);
    }
    if (optype.includeStatementLabelSuggestions ||
        optype.includeCaseLabelSuggestions) {
      _LabelVisitor labelVisitor = new _LabelVisitor(
          request,
          optype.includeStatementLabelSuggestions,
          optype.includeCaseLabelSuggestions);
      labelVisitor.visit(request.node);
    }

    // If the unit is not a part and does not reference any parts
    // then work is complete
    return !request.unit.directives.any(
        (Directive directive) =>
            directive is PartOfDirective || directive is PartDirective);
  }

  @override
  Future<bool> computeFull(DartCompletionRequest request) {
    // TODO: implement computeFull
    // include results from part files that are included in the library
    return new Future.value(false);
  }
}

/**
 * A visitor for collecting suggestions for break and continue labels.
 */
class _LabelVisitor extends LocalDeclarationVisitor {
  final DartCompletionRequest request;

  /**
   * True if statement labels should be included as suggestions.
   */
  final bool includeStatementLabels;

  /**
   * True if case labels should be included as suggestions.
   */
  final bool includeCaseLabels;

  _LabelVisitor(DartCompletionRequest request, this.includeStatementLabels,
      this.includeCaseLabels)
      : super(request.offset),
        request = request;

  @override
  void declaredClass(ClassDeclaration declaration) {
    // ignored
  }

  @override
  void declaredClassTypeAlias(ClassTypeAlias declaration) {
    // ignored
  }

  @override
  void declaredField(FieldDeclaration fieldDecl, VariableDeclaration varDecl) {
    // ignored
  }

  @override
  void declaredFunction(FunctionDeclaration declaration) {
    // ignored
  }

  @override
  void declaredFunctionTypeAlias(FunctionTypeAlias declaration) {
    // ignored
  }

  @override
  void declaredLabel(Label label, bool isCaseLabel) {
    if (isCaseLabel ? includeCaseLabels : includeStatementLabels) {
      CompletionSuggestion suggestion = _addSuggestion(label.label);
      if (suggestion != null) {
        suggestion.element =
            _createElement(protocol.ElementKind.LABEL, label.label);
      }
    }
  }

  @override
  void declaredLocalVar(SimpleIdentifier name, TypeName type) {
    // ignored
  }

  @override
  void declaredMethod(MethodDeclaration declaration) {
    // ignored
  }

  @override
  void declaredParam(SimpleIdentifier name, TypeName type) {
    // ignored
  }

  @override
  void declaredTopLevelVar(VariableDeclarationList varList,
      VariableDeclaration varDecl) {
    // ignored
  }

  @override
  void visitFunctionExpression(FunctionExpression node) {
    // Labels are only accessible within the local function, so stop visiting
    // once we reach a function boundary.
    finished();
  }

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    // Labels are only accessible within the local function, so stop visiting
    // once we reach a function boundary.
    finished();
  }

  CompletionSuggestion _addSuggestion(SimpleIdentifier id) {
    if (id != null) {
      String completion = id.name;
      if (completion != null && completion.length > 0 && completion != '_') {
        CompletionSuggestion suggestion = new CompletionSuggestion(
            CompletionSuggestionKind.IDENTIFIER,
            DART_RELEVANCE_DEFAULT,
            completion,
            completion.length,
            0,
            false,
            false);
        request.suggestions.add(suggestion);
        return suggestion;
      }
    }
    return null;
  }

  /**
   * Create a new protocol Element for inclusion in a completion suggestion.
   */
  protocol.Element _createElement(protocol.ElementKind kind,
      SimpleIdentifier id) {
    String name = id.name;
    int flags =
        protocol.Element.makeFlags(isPrivate: Identifier.isPrivateName(name));
    return new protocol.Element(kind, name, flags);
  }
}

/**
 * A visitor for collecting suggestions from the most specific child [AstNode]
 * that contains the completion offset to the [CompilationUnit].
 */
class _LocalVisitor extends LocalDeclarationVisitor {
  static const DYNAMIC = 'dynamic';

  static final TypeName NO_RETURN_TYPE = new TypeName(
      new SimpleIdentifier(new StringToken(TokenType.IDENTIFIER, '', 0)),
      null);

  final DartCompletionRequest request;
  final bool typesOnly;
  final bool excludeVoidReturn;

  _LocalVisitor(this.request, int offset, this.typesOnly,
      this.excludeVoidReturn)
      : super(offset);

  @override
  void declaredClass(ClassDeclaration declaration) {
    bool isDeprecated = _isDeprecated(declaration);
    CompletionSuggestion suggestion = _addSuggestion(
        declaration.name,
        NO_RETURN_TYPE,
        isDeprecated,
        DART_RELEVANCE_DEFAULT);
    if (suggestion != null) {
      suggestion.element = _createElement(
          protocol.ElementKind.CLASS,
          declaration.name,
          returnType: NO_RETURN_TYPE,
          isAbstract: declaration.isAbstract,
          isDeprecated: isDeprecated);
    }
  }

  @override
  void declaredClassTypeAlias(ClassTypeAlias declaration) {
    bool isDeprecated = _isDeprecated(declaration);
    CompletionSuggestion suggestion = _addSuggestion(
        declaration.name,
        NO_RETURN_TYPE,
        isDeprecated,
        DART_RELEVANCE_DEFAULT);
    if (suggestion != null) {
      suggestion.element = _createElement(
          protocol.ElementKind.CLASS_TYPE_ALIAS,
          declaration.name,
          returnType: NO_RETURN_TYPE,
          isAbstract: true,
          isDeprecated: isDeprecated);
    }
  }

  @override
  void declaredField(FieldDeclaration fieldDecl, VariableDeclaration varDecl) {
    if (typesOnly) {
      return;
    }
    bool isDeprecated = _isDeprecated(fieldDecl) || _isDeprecated(varDecl);
    TypeName type = fieldDecl.fields.type;
    CompletionSuggestion suggestion = _addSuggestion(
        varDecl.name,
        type,
        isDeprecated,
        DART_RELEVANCE_LOCAL_FIELD,
        classDecl: fieldDecl.parent);
    if (suggestion != null) {
      suggestion.element = _createElement(
          protocol.ElementKind.FIELD,
          varDecl.name,
          returnType: type,
          isDeprecated: isDeprecated);
    }
  }

  @override
  void declaredFunction(FunctionDeclaration declaration) {
    if (typesOnly) {
      return;
    }
    TypeName returnType = declaration.returnType;
    bool isDeprecated = _isDeprecated(declaration);
    protocol.ElementKind kind;
    int defaultRelevance = DART_RELEVANCE_DEFAULT;
    if (declaration.isGetter) {
      kind = protocol.ElementKind.GETTER;
      defaultRelevance = DART_RELEVANCE_LOCAL_ACCESSOR;
    } else if (declaration.isSetter) {
      if (excludeVoidReturn) {
        return;
      }
      kind = protocol.ElementKind.SETTER;
      returnType = NO_RETURN_TYPE;
      defaultRelevance = DART_RELEVANCE_LOCAL_ACCESSOR;
    } else {
      if (excludeVoidReturn && _isVoid(returnType)) {
        return;
      }
      kind = protocol.ElementKind.FUNCTION;
      defaultRelevance = DART_RELEVANCE_LOCAL_FUNCTION;
    }
    CompletionSuggestion suggestion = _addSuggestion(
        declaration.name,
        returnType,
        isDeprecated,
        defaultRelevance);
    if (suggestion != null) {
      FormalParameterList param = declaration.functionExpression.parameters;
      suggestion.element = _createElement(
          kind,
          declaration.name,
          parameters: param != null ? param.toSource() : null,
          returnType: returnType,
          isDeprecated: isDeprecated);
      if (kind == protocol.ElementKind.FUNCTION) {
        _addParameterInfo(
            suggestion,
            declaration.functionExpression.parameters);
      }
    }
  }

  @override
  void declaredFunctionTypeAlias(FunctionTypeAlias declaration) {
    bool isDeprecated = _isDeprecated(declaration);
    TypeName returnType = declaration.returnType;
    CompletionSuggestion suggestion = _addSuggestion(
        declaration.name,
        returnType,
        isDeprecated,
        DART_RELEVANCE_DEFAULT);
    if (suggestion != null) {
      // TODO (danrubel) determine parameters and return type
      suggestion.element = _createElement(
          protocol.ElementKind.FUNCTION_TYPE_ALIAS,
          declaration.name,
          returnType: returnType,
          isAbstract: true,
          isDeprecated: isDeprecated);
    }
  }

  @override
  void declaredLabel(Label label, bool isCaseLabel) {
    // ignored
  }

  @override
  void declaredLocalVar(SimpleIdentifier name, TypeName type) {
    if (typesOnly) {
      return;
    }
    CompletionSuggestion suggestion =
        _addSuggestion(name, type, false, DART_RELEVANCE_LOCAL_VARIABLE);
    if (suggestion != null) {
      suggestion.element =
          _createElement(protocol.ElementKind.LOCAL_VARIABLE, name, returnType: type);
    }
  }

  @override
  void declaredMethod(MethodDeclaration declaration) {
    if (typesOnly) {
      return;
    }
    protocol.ElementKind kind;
    String parameters;
    TypeName returnType = declaration.returnType;
    int defaultRelevance = DART_RELEVANCE_DEFAULT;
    if (declaration.isGetter) {
      kind = protocol.ElementKind.GETTER;
      parameters = null;
      defaultRelevance = DART_RELEVANCE_LOCAL_ACCESSOR;
    } else if (declaration.isSetter) {
      if (excludeVoidReturn) {
        return;
      }
      kind = protocol.ElementKind.SETTER;
      returnType = NO_RETURN_TYPE;
      defaultRelevance = DART_RELEVANCE_LOCAL_ACCESSOR;
    } else {
      if (excludeVoidReturn && _isVoid(returnType)) {
        return;
      }
      kind = protocol.ElementKind.METHOD;
      parameters = declaration.parameters.toSource();
      defaultRelevance = DART_RELEVANCE_LOCAL_METHOD;
    }
    bool isDeprecated = _isDeprecated(declaration);
    CompletionSuggestion suggestion = _addSuggestion(
        declaration.name,
        returnType,
        isDeprecated,
        defaultRelevance,
        classDecl: declaration.parent);
    if (suggestion != null) {
      suggestion.element = _createElement(
          kind,
          declaration.name,
          parameters: parameters,
          returnType: returnType,
          isAbstract: declaration.isAbstract,
          isDeprecated: isDeprecated);
      if (kind == protocol.ElementKind.METHOD) {
        _addParameterInfo(suggestion, declaration.parameters);
      }
    }
  }

  @override
  void declaredParam(SimpleIdentifier name, TypeName type) {
    if (typesOnly) {
      return;
    }
    CompletionSuggestion suggestion =
        _addSuggestion(name, type, false, DART_RELEVANCE_PARAMETER);
    if (suggestion != null) {
      suggestion.element =
          _createElement(protocol.ElementKind.PARAMETER, name, returnType: type);
    }
  }

  @override
  void declaredTopLevelVar(VariableDeclarationList varList,
      VariableDeclaration varDecl) {
    if (typesOnly) {
      return;
    }
    bool isDeprecated = _isDeprecated(varList) || _isDeprecated(varDecl);
    CompletionSuggestion suggestion = _addSuggestion(
        varDecl.name,
        varList.type,
        isDeprecated,
        DART_RELEVANCE_LOCAL_TOP_LEVEL_VARIABLE);
    if (suggestion != null) {
      suggestion.element = _createElement(
          protocol.ElementKind.TOP_LEVEL_VARIABLE,
          varDecl.name,
          returnType: varList.type,
          isDeprecated: isDeprecated);
    }
  }

  void _addParameterInfo(CompletionSuggestion suggestion,
      FormalParameterList parameters) {
    var paramList = parameters.parameters;
    suggestion.parameterNames =
        paramList.map((FormalParameter param) => param.identifier.name).toList();
    suggestion.parameterTypes = paramList.map((FormalParameter param) {
      TypeName type = null;
      if (param is DefaultFormalParameter) {
        NormalFormalParameter child = param.parameter;
        if (child is SimpleFormalParameter) {
          type = child.type;
        } else if (child is FieldFormalParameter) {
          type = child.type;
        }
      }
      if (param is SimpleFormalParameter) {
        type = param.type;
      } else if (param is FieldFormalParameter) {
        type = param.type;
      }
      if (type == null) {
        return 'dynamic';
      }
      Identifier typeId = type.name;
      if (typeId == null) {
        return 'dynamic';
      }
      return typeId.name;
    }).toList();
    suggestion.requiredParameterCount = paramList.where(
        (FormalParameter param) => param is! DefaultFormalParameter).length;
    suggestion.hasNamedParameters =
        paramList.any((FormalParameter param) => param.kind == ParameterKind.NAMED);
  }

  CompletionSuggestion _addSuggestion(SimpleIdentifier id, TypeName returnType,
      bool isDeprecated, int defaultRelevance, {ClassDeclaration classDecl}) {
    if (id != null) {
      String completion = id.name;
      if (completion != null && completion.length > 0 && completion != '_') {
        CompletionSuggestion suggestion = new CompletionSuggestion(
            CompletionSuggestionKind.INVOCATION,
            isDeprecated ? DART_RELEVANCE_LOW : defaultRelevance,
            completion,
            completion.length,
            0,
            isDeprecated,
            false,
            returnType: _nameForType(returnType));
        if (classDecl != null) {
          SimpleIdentifier identifier = classDecl.name;
          if (identifier != null) {
            String name = identifier.name;
            if (name != null && name.length > 0) {
              suggestion.declaringType = name;
            }
          }
        }
        request.suggestions.add(suggestion);
        return suggestion;
      }
    }
    return null;
  }


  /**
   * Create a new protocol Element for inclusion in a completion suggestion.
   */
  protocol.Element _createElement(protocol.ElementKind kind,
      SimpleIdentifier id, {String parameters, TypeName returnType, bool isAbstract:
      false, bool isDeprecated: false}) {
    String name = id.name;
    int flags = protocol.Element.makeFlags(
        isAbstract: isAbstract,
        isDeprecated: isDeprecated,
        isPrivate: Identifier.isPrivateName(name));
    return new protocol.Element(
        kind,
        name,
        flags,
        parameters: parameters,
        returnType: _nameForType(returnType));
  }

  /**
   * Return `true` if the @deprecated annotation is present
   */
  bool _isDeprecated(AnnotatedNode node) {
    if (node != null) {
      NodeList<Annotation> metadata = node.metadata;
      if (metadata != null) {
        return metadata.any((Annotation a) {
          return a.name is SimpleIdentifier && a.name.name == 'deprecated';
        });
      }
    }
    return false;
  }

  bool _isVoid(TypeName returnType) {
    if (returnType != null) {
      Identifier id = returnType.name;
      if (id != null && id.name == 'void') {
        return true;
      }
    }
    return false;
  }

  /**
   * Return the name for the given type.
   */
  String _nameForType(TypeName type) {
    if (type == NO_RETURN_TYPE) {
      return null;
    }
    if (type == null) {
      return DYNAMIC;
    }
    Identifier id = type.name;
    if (id == null) {
      return DYNAMIC;
    }
    String name = id.name;
    if (name == null || name.length <= 0) {
      return DYNAMIC;
    }
    TypeArgumentList typeArgs = type.typeArguments;
    if (typeArgs != null) {
      //TODO (danrubel) include type arguments
    }
    return name;
  }
}
