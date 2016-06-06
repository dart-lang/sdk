// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library services.completion.contributor.dart.local_ref;

import 'dart:async';

import 'package:analysis_server/plugin/protocol/protocol.dart' as protocol
    show Element, ElementKind;
import 'package:analysis_server/src/provisional/completion/dart/completion_dart.dart';
import 'package:analysis_server/src/services/completion/dart/completion_manager.dart'
    show DartCompletionRequestImpl;
import 'package:analysis_server/src/services/completion/dart/local_declaration_visitor.dart'
    show LocalDeclarationVisitor;
import 'package:analysis_server/src/services/completion/dart/optype.dart';
import 'package:analysis_server/src/services/correction/strings.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/ast/token.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/generated/utilities_dart.dart' show ParameterKind;

import '../../../protocol_server.dart'
    show CompletionSuggestion, CompletionSuggestionKind, Location;

const DYNAMIC = 'dynamic';

final TypeName NO_RETURN_TYPE = new TypeName(
    new SimpleIdentifier(new StringToken(TokenType.IDENTIFIER, '', 0)), null);

/**
* Create a new protocol Element for inclusion in a completion suggestion.
*/
protocol.Element _createLocalElement(
    Source source, protocol.ElementKind kind, SimpleIdentifier id,
    {String parameters,
    TypeName returnType,
    bool isAbstract: false,
    bool isDeprecated: false}) {
  String name;
  Location location;
  if (id != null) {
    name = id.name;
    // TODO(danrubel) use lineInfo to determine startLine and startColumn
    location = new Location(source.fullName, id.offset, id.length, 0, 0);
  } else {
    name = '';
    location = new Location(source.fullName, -1, 0, 1, 0);
  }
  int flags = protocol.Element.makeFlags(
      isAbstract: isAbstract,
      isDeprecated: isDeprecated,
      isPrivate: Identifier.isPrivateName(name));
  return new protocol.Element(kind, name, flags,
      location: location,
      parameters: parameters,
      returnType: _nameForType(returnType));
}

/**
* Create a new suggestion based upon the given information.
* Return the new suggestion or `null` if it could not be created.
*/
CompletionSuggestion _createLocalSuggestion(
    SimpleIdentifier id,
    CompletionSuggestionKind kind,
    bool isDeprecated,
    int defaultRelevance,
    TypeName returnType,
    {ClassDeclaration classDecl,
    protocol.Element element}) {
  if (id == null) {
    return null;
  }
  String completion = id.name;
  if (completion == null || completion.length <= 0 || completion == '_') {
    return null;
  }
  CompletionSuggestion suggestion = new CompletionSuggestion(
      kind,
      isDeprecated ? DART_RELEVANCE_LOW : defaultRelevance,
      completion,
      completion.length,
      0,
      isDeprecated,
      false,
      returnType: _nameForType(returnType),
      element: element);
  if (classDecl != null) {
    SimpleIdentifier classId = classDecl.name;
    if (classId != null) {
      String className = classId.name;
      if (className != null && className.length > 0) {
        suggestion.declaringType = className;
      }
    }
  }
  return suggestion;
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

/**
 * A contributor for calculating suggestions for declarations in the local
 * file and containing library.
 */
class LocalReferenceContributor extends DartCompletionContributor {
  @override
  Future<List<CompletionSuggestion>> computeSuggestions(
      DartCompletionRequest request) async {
    OpType optype = (request as DartCompletionRequestImpl).opType;

    // Collect suggestions from the specific child [AstNode] that contains
    // the completion offset and all of its parents recursively.
    if (!optype.isPrefixed) {
      if (optype.includeReturnValueSuggestions ||
          optype.includeTypeNameSuggestions ||
          optype.includeVoidReturnSuggestions) {
        // If the target is in an expression
        // then resolve the outermost/entire expression
        AstNode node = request.target.containingNode;

        if (node is Expression) {
          await request.resolveContainingExpression(node);

          // Discard any cached target information
          // because it may have changed as a result of the resolution
          node = request.target.containingNode;
        }

        // Do not suggest local vars within the current expression
        while (node is Expression) {
          node = node.parent;
        }

        // Do not suggest loop variable of a ForEachStatement
        // when completing the expression of the ForEachStatement
        if (node is ForEachStatement) {
          node = node.parent;
        }

        _LocalVisitor visitor =
            new _LocalVisitor(request, request.offset, optype);
        visitor.visit(node);
        return visitor.suggestions;
      }
    }
    return EMPTY_LIST;
  }
}

/**
 * A visitor for collecting suggestions from the most specific child [AstNode]
 * that contains the completion offset to the [CompilationUnit].
 */
class _LocalVisitor extends LocalDeclarationVisitor {
  final DartCompletionRequest request;
  final OpType optype;
  final Map<String, CompletionSuggestion> suggestionMap =
      <String, CompletionSuggestion>{};
  int privateMemberRelevance = DART_RELEVANCE_DEFAULT;
  bool targetIsFunctionalArgument;

  _LocalVisitor(this.request, int offset, this.optype) : super(offset) {
    // Suggestions for inherited members provided by InheritedReferenceContributor
    targetIsFunctionalArgument = request.target.isFunctionalArgument();

    // If user typed identifier starting with '_'
    // then do not suppress the relevance of private members
    var contents = request.context.getContents(request.source);
    if (contents != null) {
      String data = contents.data;
      int offset = request.offset;
      if (data != null && 0 < offset && offset <= data.length) {
        bool isIdentifierChar(int index) {
          int code = data.codeUnitAt(index);
          return isLetterOrDigit(code) || code == CHAR_UNDERSCORE;
        }
        if (isIdentifierChar(offset - 1)) {
          while (offset > 0 && isIdentifierChar(offset - 1)) {
            --offset;
          }
          if (data.codeUnitAt(offset) == CHAR_UNDERSCORE) {
            privateMemberRelevance = null;
          }
        }
      }
    }
  }

  List<CompletionSuggestion> get suggestions => suggestionMap.values.toList();

  @override
  void declaredClass(ClassDeclaration declaration) {
    if (optype.includeTypeNameSuggestions) {
      _addLocalSuggestion_includeTypeNameSuggestions(
          declaration.name, NO_RETURN_TYPE, protocol.ElementKind.CLASS,
          isAbstract: declaration.isAbstract,
          isDeprecated: _isDeprecated(declaration));
    }
  }

  @override
  void declaredClassTypeAlias(ClassTypeAlias declaration) {
    if (optype.includeTypeNameSuggestions) {
      _addLocalSuggestion_includeTypeNameSuggestions(declaration.name,
          NO_RETURN_TYPE, protocol.ElementKind.CLASS_TYPE_ALIAS,
          isAbstract: true, isDeprecated: _isDeprecated(declaration));
    }
  }

  @override
  void declaredEnum(EnumDeclaration declaration) {
    if (optype.includeTypeNameSuggestions) {
      _addLocalSuggestion_includeTypeNameSuggestions(
          declaration.name, NO_RETURN_TYPE, protocol.ElementKind.ENUM,
          isDeprecated: _isDeprecated(declaration));
      for (EnumConstantDeclaration enumConstant in declaration.constants) {
        if (!enumConstant.isSynthetic) {
          _addLocalSuggestion_includeReturnValueSuggestions_enumConstant(
              enumConstant, declaration,
              isDeprecated: _isDeprecated(declaration));
        }
      }
    }
  }

  @override
  void declaredField(FieldDeclaration fieldDecl, VariableDeclaration varDecl) {
    if (optype.includeReturnValueSuggestions &&
        (!optype.inStaticMethodBody || fieldDecl.isStatic)) {
      bool deprecated = _isDeprecated(fieldDecl) || _isDeprecated(varDecl);
      TypeName typeName = fieldDecl.fields.type;
      _addLocalSuggestion_includeReturnValueSuggestions(
          varDecl.name, typeName, protocol.ElementKind.FIELD,
          isDeprecated: deprecated,
          relevance: DART_RELEVANCE_LOCAL_FIELD,
          classDecl: fieldDecl.parent);
    }
  }

  @override
  void declaredFunction(FunctionDeclaration declaration) {
    if (optype.includeReturnValueSuggestions ||
        optype.includeVoidReturnSuggestions) {
      TypeName typeName = declaration.returnType;
      protocol.ElementKind elemKind;
      int relevance = DART_RELEVANCE_DEFAULT;
      if (declaration.isGetter) {
        elemKind = protocol.ElementKind.GETTER;
        relevance = DART_RELEVANCE_LOCAL_ACCESSOR;
      } else if (declaration.isSetter) {
        if (!optype.includeVoidReturnSuggestions) {
          return;
        }
        elemKind = protocol.ElementKind.SETTER;
        typeName = NO_RETURN_TYPE;
        relevance = DART_RELEVANCE_LOCAL_ACCESSOR;
      } else {
        if (!optype.includeVoidReturnSuggestions && _isVoid(typeName)) {
          return;
        }
        elemKind = protocol.ElementKind.FUNCTION;
        relevance = DART_RELEVANCE_LOCAL_FUNCTION;
      }
      _addLocalSuggestion_includeReturnValueSuggestions(
          declaration.name, typeName, elemKind,
          isDeprecated: _isDeprecated(declaration),
          param: declaration.functionExpression.parameters,
          relevance: relevance);
    }
  }

  @override
  void declaredFunctionTypeAlias(FunctionTypeAlias declaration) {
    if (optype.includeTypeNameSuggestions) {
      // TODO (danrubel) determine parameters and return type
      _addLocalSuggestion_includeTypeNameSuggestions(declaration.name,
          declaration.returnType, protocol.ElementKind.FUNCTION_TYPE_ALIAS,
          isAbstract: true, isDeprecated: _isDeprecated(declaration));
    }
  }

  @override
  void declaredLabel(Label label, bool isCaseLabel) {
    // ignored
  }

  @override
  void declaredLocalVar(SimpleIdentifier id, TypeName typeName) {
    if (optype.includeReturnValueSuggestions) {
      _addLocalSuggestion_includeReturnValueSuggestions(
          id, typeName, protocol.ElementKind.LOCAL_VARIABLE,
          relevance: DART_RELEVANCE_LOCAL_VARIABLE);
    }
  }

  @override
  void declaredMethod(MethodDeclaration declaration) {
    if ((optype.includeReturnValueSuggestions ||
            optype.includeVoidReturnSuggestions) &&
        (!optype.inStaticMethodBody || declaration.isStatic)) {
      protocol.ElementKind elemKind;
      FormalParameterList param;
      TypeName typeName = declaration.returnType;
      int relevance = DART_RELEVANCE_DEFAULT;
      if (declaration.isGetter) {
        elemKind = protocol.ElementKind.GETTER;
        param = null;
        relevance = DART_RELEVANCE_LOCAL_ACCESSOR;
      } else if (declaration.isSetter) {
        if (!optype.includeVoidReturnSuggestions) {
          return;
        }
        elemKind = protocol.ElementKind.SETTER;
        typeName = NO_RETURN_TYPE;
        relevance = DART_RELEVANCE_LOCAL_ACCESSOR;
      } else {
        if (!optype.includeVoidReturnSuggestions && _isVoid(typeName)) {
          return;
        }
        elemKind = protocol.ElementKind.METHOD;
        param = declaration.parameters;
        relevance = DART_RELEVANCE_LOCAL_METHOD;
      }
      _addLocalSuggestion_includeReturnValueSuggestions(
          declaration.name, typeName, elemKind,
          isAbstract: declaration.isAbstract,
          isDeprecated: _isDeprecated(declaration),
          classDecl: declaration.parent,
          param: param,
          relevance: relevance);
    }
  }

  @override
  void declaredParam(SimpleIdentifier id, TypeName typeName) {
    if (optype.includeReturnValueSuggestions) {
      _addLocalSuggestion_includeReturnValueSuggestions(
          id, typeName, protocol.ElementKind.PARAMETER,
          relevance: DART_RELEVANCE_PARAMETER);
    }
  }

  @override
  void declaredTopLevelVar(
      VariableDeclarationList varList, VariableDeclaration varDecl) {
    if (optype.includeReturnValueSuggestions) {
      _addLocalSuggestion_includeReturnValueSuggestions(
          varDecl.name, varList.type, protocol.ElementKind.TOP_LEVEL_VARIABLE,
          isDeprecated: _isDeprecated(varList) || _isDeprecated(varDecl),
          relevance: DART_RELEVANCE_LOCAL_TOP_LEVEL_VARIABLE);
    }
  }

  void _addLocalSuggestion(
      SimpleIdentifier id, TypeName typeName, protocol.ElementKind elemKind,
      {bool isAbstract: false,
      bool isDeprecated: false,
      ClassDeclaration classDecl,
      FormalParameterList param,
      int relevance: DART_RELEVANCE_DEFAULT}) {
    CompletionSuggestionKind kind = targetIsFunctionalArgument
        ? CompletionSuggestionKind.IDENTIFIER
        : optype.suggestKind;
    CompletionSuggestion suggestion = _createLocalSuggestion(
        id, kind, isDeprecated, relevance, typeName,
        classDecl: classDecl);
    if (suggestion != null) {
      if (privateMemberRelevance != null &&
          suggestion.completion.startsWith('_')) {
        suggestion.relevance = privateMemberRelevance;
      }
      suggestionMap.putIfAbsent(suggestion.completion, () => suggestion);
      suggestion.element = _createLocalElement(request.source, elemKind, id,
          isAbstract: isAbstract,
          isDeprecated: isDeprecated,
          parameters: param?.toSource(),
          returnType: typeName);
      if ((elemKind == protocol.ElementKind.METHOD ||
              elemKind == protocol.ElementKind.FUNCTION) &&
          param != null) {
        _addParameterInfo(suggestion, param);
      }
    }
  }

  void _addLocalSuggestion_enumConstant(
      EnumConstantDeclaration constantDeclaration,
      EnumDeclaration enumDeclaration,
      {bool isAbstract: false,
      bool isDeprecated: false,
      ClassDeclaration classDecl,
      int relevance: DART_RELEVANCE_DEFAULT}) {
    String completion =
        '${enumDeclaration.name.name}.${constantDeclaration.name.name}';
    CompletionSuggestion suggestion = new CompletionSuggestion(
        CompletionSuggestionKind.INVOCATION,
        isDeprecated ? DART_RELEVANCE_LOW : relevance,
        completion,
        completion.length,
        0,
        isDeprecated,
        false,
        returnType: enumDeclaration.name.name);

    suggestionMap.putIfAbsent(suggestion.completion, () => suggestion);
    int flags = protocol.Element.makeFlags(
        isAbstract: isAbstract,
        isDeprecated: isDeprecated,
        isPrivate: Identifier.isPrivateName(constantDeclaration.name.name));
    suggestion.element = new protocol.Element(
        protocol.ElementKind.ENUM_CONSTANT,
        constantDeclaration.name.name,
        flags,
        location: new Location(
            request.source.fullName,
            constantDeclaration.name.offset,
            constantDeclaration.name.length,
            0,
            0));
  }

  void _addLocalSuggestion_includeReturnValueSuggestions(
      SimpleIdentifier id, TypeName typeName, protocol.ElementKind elemKind,
      {bool isAbstract: false,
      bool isDeprecated: false,
      ClassDeclaration classDecl,
      FormalParameterList param,
      int relevance: DART_RELEVANCE_DEFAULT}) {
    relevance = optype.returnValueSuggestionsFilter(
        _staticTypeOfIdentifier(id), relevance);
    if (relevance != null) {
      _addLocalSuggestion(id, typeName, elemKind,
          isAbstract: isAbstract,
          isDeprecated: isDeprecated,
          classDecl: classDecl,
          param: param,
          relevance: relevance);
    }
  }

  void _addLocalSuggestion_includeReturnValueSuggestions_enumConstant(
      EnumConstantDeclaration constantDeclaration,
      EnumDeclaration enumDeclaration,
      {bool isAbstract: false,
      bool isDeprecated: false,
      int relevance: DART_RELEVANCE_DEFAULT}) {
    relevance = optype.returnValueSuggestionsFilter(
        enumDeclaration.element.type, relevance);
    if (relevance != null) {
      _addLocalSuggestion_enumConstant(constantDeclaration, enumDeclaration,
          isAbstract: isAbstract,
          isDeprecated: isDeprecated,
          relevance: relevance);
    }
  }

  void _addLocalSuggestion_includeTypeNameSuggestions(
      SimpleIdentifier id, TypeName typeName, protocol.ElementKind elemKind,
      {bool isAbstract: false,
      bool isDeprecated: false,
      ClassDeclaration classDecl,
      FormalParameterList param,
      int relevance: DART_RELEVANCE_DEFAULT}) {
    relevance = optype.typeNameSuggestionsFilter(
        _staticTypeOfIdentifier(id), relevance);
    if (relevance != null) {
      _addLocalSuggestion(id, typeName, elemKind,
          isAbstract: isAbstract,
          isDeprecated: isDeprecated,
          classDecl: classDecl,
          param: param,
          relevance: relevance);
    }
  }

  void _addParameterInfo(
      CompletionSuggestion suggestion, FormalParameterList parameters) {
    var paramList = parameters.parameters;
    suggestion.parameterNames = paramList
        .map((FormalParameter param) => param.identifier.name)
        .toList();
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
    suggestion.requiredParameterCount = paramList
        .where((FormalParameter param) => param is! DefaultFormalParameter)
        .length;
    suggestion.hasNamedParameters = paramList
        .any((FormalParameter param) => param.kind == ParameterKind.NAMED);
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

  DartType _staticTypeOfIdentifier(Identifier id) {
    if (id.staticElement is ClassElement) {
      return (id.staticElement as ClassElement).type;
    } else {
      return id.staticType;
    }
  }
}
