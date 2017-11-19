// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/src/protocol_server.dart'
    hide Element, ElementKind;
import 'package:analysis_server/src/provisional/completion/dart/completion_dart.dart';
import 'package:analysis_server/src/services/completion/dart/utilities.dart';
import 'package:analysis_server/src/utilities/documentation.dart';
import 'package:analysis_server/src/utilities/flutter.dart' as flutter;
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/generated/utilities_dart.dart';

/**
 * Determine the number of arguments.
 */
int _argCount(DartCompletionRequest request) {
  AstNode node = request.target.containingNode;
  if (node is ArgumentList) {
    if (request.target.entity == node.rightParenthesis) {
      // Parser ignores trailing commas
      if (node.rightParenthesis.previous?.lexeme == ',') {
        return node.arguments.length + 1;
      }
    }
    return node.arguments.length;
  }
  return 0;
}

/**
 * If the containing [node] is an argument list
 * or named expression in an argument list
 * then return the simple identifier for the method, constructor, or annotation
 * to which the argument list is associated
 */
SimpleIdentifier _getTargetId(AstNode node) {
  if (node is NamedExpression) {
    return _getTargetId(node.parent);
  }
  if (node is ArgumentList) {
    AstNode parent = node.parent;
    if (parent is MethodInvocation) {
      return parent.methodName;
    }
    if (parent is InstanceCreationExpression) {
      ConstructorName constructorName = parent.constructorName;
      if (constructorName != null) {
        if (constructorName.name != null) {
          return constructorName.name;
        }
        Identifier typeName = constructorName.type.name;
        if (typeName is SimpleIdentifier) {
          return typeName;
        }
        if (typeName is PrefixedIdentifier) {
          return typeName.identifier;
        }
      }
    }
    if (parent is Annotation) {
      return parent.constructorName ?? parent.name;
    }
  }
  return null;
}

/**
 * Determine if the completion target is at the end of the list of arguments.
 */
bool _isAppendingToArgList(DartCompletionRequest request) {
  AstNode node = request.target.containingNode;
  if (node is ArgumentList) {
    var entity = request.target.entity;
    if (entity == node.rightParenthesis) {
      return true;
    }
    if (node.arguments.length > 0 && node.arguments.last == entity) {
      return entity is SimpleIdentifier;
    }
  }
  return false;
}

/**
 * Determine if the completion target is the label for a named argument.
 */
bool _isEditingNamedArgLabel(DartCompletionRequest request) {
  AstNode node = request.target.containingNode;
  if (node is ArgumentList) {
    var entity = request.target.entity;
    if (entity is NamedExpression) {
      int offset = request.offset;
      if (entity.offset < offset && offset < entity.end) {
        return true;
      }
    }
  }
  return false;
}

/**
 * Return `true` if the [request] is inside of a [NamedExpression] name.
 */
bool _isInNamedExpression(DartCompletionRequest request) {
  Object entity = request.target.entity;
  if (entity is NamedExpression) {
    Label name = entity.name;
    return name.offset < request.offset && request.offset < name.end;
  }
  return false;
}

/**
 * Determine if the completion target is in the middle or beginning of the list
 * of named parameters and is not preceded by a comma. This method assumes that
 * _isAppendingToArgList has been called and is false.
 */
bool _isInsertingToArgListWithNoSynthetic(DartCompletionRequest request) {
  AstNode node = request.target.containingNode;
  if (node is ArgumentList) {
    var entity = request.target.entity;
    return entity is NamedExpression;
  }
  return false;
}

/**
 * Determine if the completion target is in the middle or beginning of the list
 * of named parameters and is preceded by a comma. This method assumes that
 * _isAppendingToArgList and _isInsertingToArgListWithNoSynthetic have been
 * called and both return false.
 */
bool _isInsertingToArgListWithSynthetic(DartCompletionRequest request) {
  AstNode node = request.target.containingNode;
  if (node is ArgumentList) {
    var entity = request.target.entity;
    if (entity is SimpleIdentifier) {
      int argIndex = request.target.argIndex;
      // if the next argument is a NamedExpression, then we are in the named
      // parameter list, guard first against end of list
      if (node.arguments.length == argIndex + 1 ||
          node.arguments.getRange(argIndex + 1, argIndex + 2).first
              is NamedExpression) {
        return true;
      }
    }
  }
  return false;
}

/**
 * Return a collection of currently specified named arguments
 */
Iterable<String> _namedArgs(DartCompletionRequest request) {
  AstNode node = request.target.containingNode;
  List<String> namedArgs = new List<String>();
  if (node is ArgumentList) {
    for (Expression arg in node.arguments) {
      if (arg is NamedExpression) {
        namedArgs.add(arg.name.label.name);
      }
    }
  }
  return namedArgs;
}

/**
 * A contributor for calculating `completion.getSuggestions` request results
 * when the cursor position is inside the arguments to a method call.
 */
class ArgListContributor extends DartCompletionContributor {
  DartCompletionRequest request;
  List<CompletionSuggestion> suggestions;

  @override
  Future<List<CompletionSuggestion>> computeSuggestions(
      DartCompletionRequest request) async {
    this.request = request;
    this.suggestions = <CompletionSuggestion>[];

    // Determine if the target is in an argument list
    // for a method or a constructor or an annotation
    SimpleIdentifier targetId = _getTargetId(request.target.containingNode);
    if (targetId == null) {
      return EMPTY_LIST;
    }
    Element elem = targetId.bestElement;
    if (elem == null) {
      return EMPTY_LIST;
    }

    // Generate argument list suggestion based upon the type of element
    if (elem is ClassElement) {
      _addSuggestions(elem.unnamedConstructor?.parameters);
      return suggestions;
    }
    if (elem is ConstructorElement) {
      _addSuggestions(elem.parameters);
      return suggestions;
    }
    if (elem is FunctionElement) {
      _addSuggestions(elem.parameters);
      return suggestions;
    }
    if (elem is MethodElement) {
      _addSuggestions(elem.parameters);
      return suggestions;
    }
    return EMPTY_LIST;
  }

  void _addDefaultParamSuggestions(Iterable<ParameterElement> parameters,
      [bool appendComma = false]) {
    bool appendColon = !_isInNamedExpression(request);
    Iterable<String> namedArgs = _namedArgs(request);
    for (ParameterElement parameter in parameters) {
      if (parameter.parameterKind == ParameterKind.NAMED) {
        _addNamedParameterSuggestion(
            namedArgs, parameter, appendColon, appendComma);
      }
    }
  }

  void _addNamedParameterSuggestion(List<String> namedArgs,
      ParameterElement parameter, bool appendColon, bool appendComma) {
    String name = parameter.name;
    String type = parameter.type?.displayName;
    if (name != null && name.length > 0 && !namedArgs.contains(name)) {
      String completion = name;
      if (appendColon) {
        completion += ': ';
      }
      int selectionOffset = completion.length;

      // Optionally add Flutter child widget details.
      Element element = parameter.enclosingElement;
      if (element is ConstructorElement) {
        if (flutter.isWidget(element.enclosingElement)) {
          String value = getDefaultStringParameterValue(parameter);
          if (value == '<Widget>[]') {
            completion += value;
            selectionOffset = completion.length - 1; // before closing ']'
          }
        }
      }

      if (appendComma) {
        completion += ',';
      }

      final int relevance = parameter.isRequired
          ? DART_RELEVANCE_NAMED_PARAMETER_REQUIRED
          : DART_RELEVANCE_NAMED_PARAMETER;

      CompletionSuggestion suggestion = new CompletionSuggestion(
          CompletionSuggestionKind.NAMED_ARGUMENT,
          relevance,
          completion,
          selectionOffset,
          0,
          false,
          false,
          parameterName: name,
          parameterType: type);
      if (parameter is FieldFormalParameterElement) {
        _setDocumentation(suggestion, parameter.field?.documentationComment);
        suggestion.element = convertElement(parameter);
      }

      suggestions.add(suggestion);
    }
  }

  void _addSuggestions(Iterable<ParameterElement> parameters) {
    if (parameters == null || parameters.length == 0) {
      return;
    }
    Iterable<ParameterElement> requiredParam = parameters.where(
        (ParameterElement p) => p.parameterKind == ParameterKind.REQUIRED);
    int requiredCount = requiredParam.length;
    // TODO (jwren) _isAppendingToArgList can be split into two cases (with and
    // without preceded), then _isAppendingToArgList,
    // _isInsertingToArgListWithNoSynthetic and
    // _isInsertingToArgListWithSynthetic could be formatted into a single
    // method which returns some enum with 5+ cases.
    if (_isEditingNamedArgLabel(request) || _isAppendingToArgList(request)) {
      if (requiredCount == 0 || requiredCount < _argCount(request)) {
        bool addTrailingComma =
            !_isFollowedByAComma(request) && _isInFlutterCreation(request);
        _addDefaultParamSuggestions(parameters, addTrailingComma);
      }
    } else if (_isInsertingToArgListWithNoSynthetic(request)) {
      _addDefaultParamSuggestions(parameters, true);
    } else if (_isInsertingToArgListWithSynthetic(request)) {
      _addDefaultParamSuggestions(parameters, !_isFollowedByAComma(request));
    }
  }

  bool _isFollowedByAComma(DartCompletionRequest request) {
    // new A(^); NO
    // new A(one: 1, ^); NO
    // new A(^ , one: 1); YES
    // new A(^), ... NO

    var containingNode = request.target.containingNode;
    var entity = request.target.entity;
    Token token =
        entity is AstNode ? entity.endToken : entity is Token ? entity : null;
    return (token != containingNode?.endToken) &&
        token?.next?.type == TokenType.COMMA;
  }

  bool _isInFlutterCreation(DartCompletionRequest request) {
    AstNode containingNode = request?.target?.containingNode;
    InstanceCreationExpression newExpr = containingNode != null
        ? flutter.identifyNewExpression(containingNode.parent)
        : null;
    return newExpr != null && flutter.isWidgetCreation(newExpr);
  }

  /**
   * If the given [comment] is not `null`, fill the [suggestion] documentation
   * fields.
   */
  static void _setDocumentation(
      CompletionSuggestion suggestion, String comment) {
    if (comment != null) {
      String doc = removeDartDocDelimiters(comment);
      suggestion.docComplete = doc;
      suggestion.docSummary = getDartDocSummary(doc);
    }
  }
}
