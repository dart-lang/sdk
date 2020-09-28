// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/provisional/completion/dart/completion_dart.dart';
import 'package:analysis_server/src/services/completion/dart/suggestion_builder.dart';
import 'package:analysis_server/src/utilities/flutter.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';

/// A contributor that produces suggestions for named expression labels that
/// correspond to named parameters when completing in argument lists.
class ArgListContributor extends DartCompletionContributor {
  /// The request that is currently being handled.
  DartCompletionRequest request;

  /// The suggestion builder used to build suggestions.
  SuggestionBuilder builder;

  /// The argument list that is the containing node of the target, or `null` if
  /// the containing node of the target is not an argument list (such as when
  /// it's a named expression).
  ArgumentList argumentList;

  @override
  Future<void> computeSuggestions(
      DartCompletionRequest request, SuggestionBuilder builder) async {
    var executable = request.target.executableElement;
    if (executable == null) {
      return;
    }
    var node = request.target.containingNode;
    if (node is ArgumentList) {
      argumentList = node;
    }

    this.request = request;
    this.builder = builder;
    _addSuggestions(executable.parameters);
  }

  void _addDefaultParamSuggestions(Iterable<ParameterElement> parameters,
      [bool appendComma = false]) {
    var appendColon = !_isInNamedExpression();
    var namedArgs = _namedArgs();
    for (var parameter in parameters) {
      if (parameter.isNamed) {
        _addNamedParameterSuggestion(
            namedArgs, parameter, appendColon, appendComma);
      }
    }
  }

  void _addNamedParameterSuggestion(List<String> namedArgs,
      ParameterElement parameter, bool appendColon, bool appendComma) {
    var name = parameter.name;
    if (name != null && name.isNotEmpty && !namedArgs.contains(name)) {
      builder.suggestNamedArgument(parameter,
          appendColon: appendColon, appendComma: appendComma);
    }
  }

  void _addSuggestions(Iterable<ParameterElement> parameters) {
    if (parameters == null || parameters.isEmpty) {
      return;
    }
    var requiredParam =
        parameters.where((ParameterElement p) => p.isRequiredPositional);
    var requiredCount = requiredParam.length;
    // TODO(jwren): _isAppendingToArgList can be split into two cases (with and
    // without preceded), then _isAppendingToArgList,
    // _isInsertingToArgListWithNoSynthetic and
    // _isInsertingToArgListWithSynthetic could be formatted into a single
    // method which returns some enum with 5+ cases.
    if (_isEditingNamedArgLabel() || _isAppendingToArgList()) {
      if (requiredCount == 0 || requiredCount < _argCount()) {
        var addTrailingComma = !_isFollowedByAComma() && _isInFlutterCreation();
        _addDefaultParamSuggestions(parameters, addTrailingComma);
      }
    } else if (_isInsertingToArgListWithNoSynthetic()) {
      _addDefaultParamSuggestions(parameters, true);
    } else if (_isInsertingToArgListWithSynthetic()) {
      _addDefaultParamSuggestions(parameters, !_isFollowedByAComma());
    } else {
      var argument = request.target.containingNode;
      if (argument is NamedExpression) {
        _buildClosureSuggestions(argument);
      }
    }
  }

  /// Return the number of arguments in the argument list.
  int _argCount() {
    if (argumentList != null) {
      var paren = argumentList.rightParenthesis;
      if (request.target.entity == paren) {
        // Parser ignores trailing commas
        if (argumentList.findPrevious(paren)?.lexeme == ',') {
          return argumentList.arguments.length + 1;
        }
      }
      return argumentList.arguments.length;
    }
    return 0;
  }

  void _buildClosureSuggestions(NamedExpression argument) {
    var type = argument.staticParameterElement?.type;
    if (type is FunctionType) {
      builder.suggestClosure(type,
          includeTrailingComma:
              argument.endToken.next?.type != TokenType.COMMA);
    }
  }

  /// Return `true` if the completion target is at the end of the list of
  /// arguments.
  bool _isAppendingToArgList() {
    if (argumentList != null) {
      var entity = request.target.entity;
      if (entity == argumentList.rightParenthesis) {
        return true;
      }
      if (argumentList.arguments.isNotEmpty &&
          argumentList.arguments.last == entity) {
        return entity is SimpleIdentifier;
      }
    }
    return false;
  }

  /// Return `true` if the completion target is the label for a named argument.
  bool _isEditingNamedArgLabel() {
    if (argumentList != null) {
      var entity = request.target.entity;
      if (entity is NamedExpression) {
        var offset = request.offset;
        if (entity.offset < offset && offset < entity.end) {
          return true;
        }
      }
    }
    return false;
  }

  bool _isFollowedByAComma() {
    // new A(^); NO
    // new A(one: 1, ^); NO
    // new A(^ , one: 1); YES
    // new A(^), ... NO

    var containingNode = request.target.containingNode;
    var entity = request.target.entity;
    var token =
        entity is AstNode ? entity.endToken : entity is Token ? entity : null;
    return (token != containingNode?.endToken) &&
        token?.next?.type == TokenType.COMMA &&
        !token.next.isSynthetic;
  }

  bool _isInFlutterCreation() {
    var flutter = Flutter.instance;
    var containingNode = request.target?.containingNode;
    var newExpr = containingNode != null
        ? flutter.identifyNewExpression(containingNode.parent)
        : null;
    return newExpr != null && flutter.isWidgetCreation(newExpr);
  }

  /// Return `true` if the [request] is inside of a [NamedExpression] name.
  bool _isInNamedExpression() {
    var entity = request.target.entity;
    if (entity is NamedExpression) {
      var name = entity.name;
      return name.offset < request.offset && request.offset < name.end;
    }
    return false;
  }

  /// Return `true` if the completion target is in the middle or beginning of
  /// the list of named arguments and is not preceded by a comma. This method
  /// assumes that [_isAppendingToArgList] has been called and returned `false`.
  bool _isInsertingToArgListWithNoSynthetic() {
    if (argumentList != null) {
      var entity = request.target.entity;
      return entity is NamedExpression;
    }
    return false;
  }

  /// Return `true` if the completion target is in the middle or beginning of
  /// the list of named parameters and is preceded by a comma. This method
  /// assumes that both [_isAppendingToArgList] and
  /// [_isInsertingToArgListWithNoSynthetic] have been called and both returned
  /// `false`.
  bool _isInsertingToArgListWithSynthetic() {
    if (argumentList != null) {
      var entity = request.target.entity;
      if (entity is SimpleIdentifier) {
        var argIndex = request.target.argIndex;
        // if the next argument is a NamedExpression, then we are in the named
        // parameter list, guard first against end of list
        if (argumentList.arguments.length == argIndex + 1 ||
            argumentList.arguments.getRange(argIndex + 1, argIndex + 2).first
                is NamedExpression) {
          return true;
        }
      }
    }
    return false;
  }

  /// Return a list containing the currently specified named arguments.
  List<String> _namedArgs() {
    var namedArgs = <String>[];
    if (argumentList != null) {
      for (var arg in argumentList.arguments) {
        if (arg is NamedExpression) {
          namedArgs.add(arg.name.label.name);
        }
      }
    }
    return namedArgs;
  }
}
