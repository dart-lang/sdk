// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library services.completion.contributor.dart.arglist;

import 'dart:async';

import 'package:analysis_server/src/protocol_server.dart'
    hide Element, ElementKind;
import 'package:analysis_server/src/provisional/completion/dart/completion_dart.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/generated/utilities_dart.dart';

/**
 * Determine the number of arguments.
 */
int _argCount(DartCompletionRequest request) {
  AstNode node = request.target.containingNode;
  if (node is ArgumentList) {
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
 * Determine if the completion target is an emtpy argument list.
 */
bool _isEmptyArgList(DartCompletionRequest request) {
  AstNode node = request.target.containingNode;
  return node is ArgumentList &&
      node.leftParenthesis.next == node.rightParenthesis;
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
    // and resolve the identifier
    SimpleIdentifier targetId = _getTargetId(request.target.containingNode);
    if (targetId == null) {
      return EMPTY_LIST;
    }

    // Resolve the target expression to determine the arguments
    await request.resolveContainingExpression(targetId);
    // Gracefully degrade if the element could not be resolved
    // e.g. target changed, completion aborted
    targetId = _getTargetId(request.target.containingNode);
    if (targetId == null) {
      return EMPTY_LIST;
    }
    Element elem = targetId.bestElement;
    if (elem == null) {
      return EMPTY_LIST;
    }

    // Generate argument list suggestion based upon the type of element
    if (elem is ClassElement) {
      for (ConstructorElement constructor in elem.constructors) {
        if (!constructor.isFactory) {
          _addSuggestions(constructor.parameters);
          return suggestions;
        }
      }
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

  void _addArgListSuggestion(Iterable<ParameterElement> requiredParam) {
    // DEPRECATED... argument lists are no longer suggested.
    // See https://github.com/dart-lang/sdk/issues/25197

    // String _getParamType(ParameterElement param) {
    //   DartType type = param.type;
    //   if (type != null) {
    //     return type.displayName;
    //   }
    //   return 'dynamic';
    // }

    // StringBuffer completion = new StringBuffer('(');
    // List<String> paramNames = new List<String>();
    // List<String> paramTypes = new List<String>();
    // for (ParameterElement param in requiredParam) {
    //   String name = param.name;
    //   if (name != null && name.length > 0) {
    //     if (completion.length > 1) {
    //       completion.write(', ');
    //     }
    //     completion.write(name);
    //     paramNames.add(name);
    //     paramTypes.add(_getParamType(param));
    //   }
    // }
    // completion.write(')');
    // CompletionSuggestion suggestion = new CompletionSuggestion(
    //     CompletionSuggestionKind.ARGUMENT_LIST,
    //     DART_RELEVANCE_HIGH,
    //     completion.toString(),
    //     completion.length,
    //     0,
    //     false,
    //     false);
    // suggestion.parameterNames = paramNames;
    // suggestion.parameterTypes = paramTypes;
    // suggestions.add(suggestion);
  }

  void _addDefaultParamSuggestions(Iterable<ParameterElement> parameters,
      [bool appendComma = false]) {
    Iterable<String> namedArgs = _namedArgs(request);
    for (ParameterElement param in parameters) {
      if (param.parameterKind == ParameterKind.NAMED) {
        _addNamedParameterSuggestion(request, namedArgs, param.name,
            param.type?.displayName, appendComma);
      }
    }
  }

  void _addNamedParameterSuggestion(DartCompletionRequest request,
      List<String> namedArgs, String name, String paramType, bool appendComma) {
    if (name != null && name.length > 0 && !namedArgs.contains(name)) {
      String completion = '$name: ';
      if (appendComma) {
        completion += ',';
      }
      suggestions.add(new CompletionSuggestion(
          CompletionSuggestionKind.NAMED_ARGUMENT,
          DART_RELEVANCE_NAMED_PARAMETER,
          completion,
          completion.length,
          0,
          false,
          false,
          parameterName: name,
          parameterType: paramType));
    }
  }

  void _addSuggestions(Iterable<ParameterElement> parameters) {
    if (parameters == null || parameters.length == 0) {
      return;
    }
    Iterable<ParameterElement> requiredParam = parameters.where(
        (ParameterElement p) => p.parameterKind == ParameterKind.REQUIRED);
    int requiredCount = requiredParam.length;
    if (requiredCount > 0 && _isEmptyArgList(request)) {
      _addArgListSuggestion(requiredParam);
      return;
    }
    // TODO (jwren) _isAppendingToArgList can be split into two cases (with and
    // without preceded), then _isAppendingToArgList,
    // _isInsertingToArgListWithNoSynthetic and
    // _isInsertingToArgListWithSynthetic could be formatted into a single
    // method which returns some enum with 5+ cases.
    if (_isEditingNamedArgLabel(request) || _isAppendingToArgList(request)) {
      if (requiredCount == 0 || requiredCount < _argCount(request)) {
        _addDefaultParamSuggestions(parameters);
      }
    } else if (_isInsertingToArgListWithNoSynthetic(request)) {
      _addDefaultParamSuggestions(parameters, true);
    } else if (_isInsertingToArgListWithSynthetic(request)) {
      _addDefaultParamSuggestions(parameters);
    }
  }
}
