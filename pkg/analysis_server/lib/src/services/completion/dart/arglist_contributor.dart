// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/src/protocol_server.dart'
    hide Element, ElementKind;
import 'package:analysis_server/src/provisional/completion/dart/completion_dart.dart';
import 'package:analysis_server/src/services/completion/dart/utilities.dart';
import 'package:analysis_server/src/utilities/flutter.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/util/comment.dart';
import 'package:meta/meta.dart';

/// A contributor for calculating `completion.getSuggestions` request results
/// when the cursor position is inside the arguments to a method call.
class ArgListContributor extends DartCompletionContributor {
  /// The request that is currently being handled.
  DartCompletionRequest request;

  /// The argument list that is the containing node of the target, or `null` if
  /// the containing node of the target is not an argument list (such as when
  /// it's a named expression).
  ArgumentList argumentList;

  /// The list of suggestions that is currently being built.
  List<CompletionSuggestion> suggestions;

  @override
  Future<List<CompletionSuggestion>> computeSuggestions(
      DartCompletionRequest request) async {
    var executable = request.target.executableElement;
    if (executable == null) {
      return const <CompletionSuggestion>[];
    }
    var node = request.target.containingNode;
    if (node is ArgumentList) {
      argumentList = node;
    }

    this.request = request;
    suggestions = <CompletionSuggestion>[];
    _addSuggestions(executable.parameters);
    return suggestions;
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
    var type = parameter.type?.getDisplayString(withNullability: false);
    if (name != null && name.isNotEmpty && !namedArgs.contains(name)) {
      var completion = name;
      if (appendColon) {
        completion += ': ';
      }
      var selectionOffset = completion.length;

      // Optionally add Flutter child widget details.
      var element = parameter.enclosingElement;
      if (element is ConstructorElement) {
        var flutter = Flutter.of(request.result);
        if (flutter.isWidget(element.enclosingElement)) {
          var defaultValue = getDefaultStringParameterValue(parameter);
          // TODO(devoncarew): Should we remove the check here? We would then
          // suggest values for param types like closures.
          if (defaultValue != null && defaultValue.text == '<Widget>[]') {
            var completionLength = completion.length;
            completion += defaultValue.text;
            if (defaultValue.cursorPosition != null) {
              selectionOffset = completionLength + defaultValue.cursorPosition;
            }
          }
        }
      }

      if (appendComma) {
        completion += ',';
      }

      int relevance;
      if (parameter.isRequiredNamed || parameter.hasRequired) {
        relevance = request.useNewRelevance
            ? Relevance.requiredNamedArgument
            : DART_RELEVANCE_NAMED_PARAMETER_REQUIRED;
      } else {
        relevance = request.useNewRelevance
            ? Relevance.namedArgument
            : DART_RELEVANCE_NAMED_PARAMETER;
      }

      var suggestion = CompletionSuggestion(
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
        bool addTrailingComma =
            !_isFollowedByAComma() && _isInFlutterCreation();
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
    // TODO(brianwilkerson) Consider moving this support so that it can be used
    //  whenever the context type is a FunctionType.
    var type = argument.staticParameterElement?.type;
    if (type is FunctionType) {
      var indent = getRequestLineIndent(request);
      var parametersString = buildClosureParameters(type);

      var blockBuffer = StringBuffer(parametersString);
      blockBuffer.writeln(' {');
      blockBuffer.write('$indent  ');
      var blockSelectionOffset = blockBuffer.length;
      blockBuffer.writeln();
      blockBuffer.write('$indent}');

      var expressionBuffer = StringBuffer(parametersString);
      expressionBuffer.write(' => ');
      var expressionSelectionOffset = expressionBuffer.length;

      if (argument.endToken.next?.type != TokenType.COMMA) {
        blockBuffer.write(',');
        expressionBuffer.write(',');
      }

      CompletionSuggestion createSuggestion({
        @required String completion,
        @required String displayText,
        @required int selectionOffset,
      }) {
        return CompletionSuggestion(
          CompletionSuggestionKind.INVOCATION,
          request.useNewRelevance ? Relevance.closure : DART_RELEVANCE_HIGH,
          completion,
          selectionOffset,
          0,
          false,
          false,
          displayText: displayText,
        );
      }

      suggestions.add(createSuggestion(
        completion: blockBuffer.toString(),
        displayText: '$parametersString {}',
        selectionOffset: blockSelectionOffset,
      ));
      suggestions.add(createSuggestion(
        completion: expressionBuffer.toString(),
        displayText: '$parametersString =>',
        selectionOffset: expressionSelectionOffset,
      ));
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
        int offset = request.offset;
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
    Token token =
        entity is AstNode ? entity.endToken : entity is Token ? entity : null;
    return (token != containingNode?.endToken) &&
        token?.next?.type == TokenType.COMMA &&
        !token.next.isSynthetic;
  }

  bool _isInFlutterCreation() {
    var flutter = Flutter.of(request.result);
    var containingNode = request.target?.containingNode;
    InstanceCreationExpression newExpr = containingNode != null
        ? flutter.identifyNewExpression(containingNode.parent)
        : null;
    return newExpr != null && flutter.isWidgetCreation(newExpr);
  }

  /// Return `true` if the [request] is inside of a [NamedExpression] name.
  bool _isInNamedExpression() {
    var entity = request.target.entity;
    if (entity is NamedExpression) {
      Label name = entity.name;
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
        int argIndex = request.target.argIndex;
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
    List<String> namedArgs = <String>[];
    if (argumentList != null) {
      for (var arg in argumentList.arguments) {
        if (arg is NamedExpression) {
          namedArgs.add(arg.name.label.name);
        }
      }
    }
    return namedArgs;
  }

  /// If the given [comment] is not `null`, fill the [suggestion] documentation
  /// fields.
  static void _setDocumentation(
      CompletionSuggestion suggestion, String comment) {
    if (comment != null) {
      String doc = getDartDocPlainText(comment);
      suggestion.docComplete = doc;
      suggestion.docSummary = getDartDocSummary(doc);
    }
  }
}
