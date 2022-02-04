// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/scanner/token.dart';
import 'package:analysis_server/src/provisional/completion/completion_core.dart';
import 'package:analysis_server/src/provisional/completion/dart/completion_dart.dart';
import 'package:analysis_server/src/services/completion/dart/completion_manager.dart';
import 'package:analysis_server/src/services/completion/dart/suggestion_builder.dart';
import 'package:analysis_server/src/utilities/flutter.dart';
import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';

/// A contributor that produces suggestions for named expression labels that
/// correspond to named parameters when completing in argument lists.
class ArgListContributor extends DartCompletionContributor {
  /// The argument list that is the containing node of the target, or `null` if
  /// the containing node of the target is not an argument list (such as when
  /// it's a named expression).
  ArgumentList? argumentList;

  ArgListContributor(
    DartCompletionRequest request,
    SuggestionBuilder builder,
  ) : super(request, builder);

  @override
  Future<void> computeSuggestions() async {
    var parameters = request.target.executableElement?.parameters ??
        request.target.functionType?.parameters;
    if (parameters == null) {
      return;
    }

    var node = request.target.containingNode;
    if (node is ArgumentList) {
      argumentList = node;
    }

    _addSuggestions(parameters);
  }

  void _addDefaultParamSuggestions(Iterable<ParameterElement> parameters,
      {bool appendComma = false, int? replacementLength}) {
    var appendColon = !_isEditingNamedArgLabel();
    var namedArgs = _namedArgs();
    for (var parameter in parameters) {
      if (parameter.isNamed) {
        _addNamedParameterSuggestion(
            namedArgs, parameter, appendColon, appendComma,
            replacementLength: replacementLength);
      }
    }
  }

  void _addNamedParameterSuggestion(List<String> namedArgs,
      ParameterElement parameter, bool appendColon, bool appendComma,
      {int? replacementLength}) {
    var name = parameter.name;

    // Check whether anything after the caret is being replaced. If so, we will
    // suppress inserting colons/commas. We check only replacing _after_ the
    // caret as some replacements (before) will still want colons, for example:
    //     foo(mySt^'bar');
    var replacementEnd = request.replacementOffset +
        (replacementLength ?? request.replacementLength);
    var willReplace =
        request.completionPreference == CompletionPreference.replace &&
            replacementEnd > request.offset;

    if (name.isNotEmpty && !namedArgs.contains(name)) {
      builder.suggestNamedArgument(parameter,
          // If there's a replacement length and the preference is to replace,
          // we should not include colons/commas.
          appendColon: appendColon && !willReplace,
          appendComma: appendComma && !willReplace,
          replacementLength: replacementLength);
    }
  }

  void _addSuggestions(Iterable<ParameterElement> parameters) {
    if (parameters.isEmpty) {
      return;
    }
    var requiredParam =
        parameters.where((ParameterElement p) => p.isRequiredPositional);
    var requiredCount = requiredParam.length;

    // When inserted named args, if there is a replacement starting at the caret
    // it will be an identifier that should not be replaced if the completion
    // preference is to insert. In this case, override the replacement length
    // to 0.

    // TODO(jwren): _isAppendingToArgList can be split into two cases (with and
    // without preceded), then _isAppendingToArgList,
    // _isInsertingToArgListWithNoSynthetic and
    // _isInsertingToArgListWithSynthetic could be formatted into a single
    // method which returns some enum with 5+ cases.
    if (_isEditingNamedArgLabel() ||
        _isAppendingToArgList() ||
        _isAddingLabelToPositional()) {
      if (request.featureSet.isEnabled(Feature.named_arguments_anywhere) ||
          requiredCount == 0 ||
          requiredCount < _argCount()) {
        // If there's a replacement range that starts at the caret, it will be
        // for an identifier that is not the named label and therefore it should
        // not be replaced.
        var replacementLength =
            request.offset == request.target.entity?.offset &&
                    request.replacementLength != 0
                ? 0
                : null;

        var addTrailingComma =
            !request.target.isFollowedByComma && _isInFlutterCreation();
        _addDefaultParamSuggestions(parameters,
            appendComma: addTrailingComma,
            replacementLength: replacementLength);
      }
    } else if (_isInsertingToArgListWithNoSynthetic()) {
      _addDefaultParamSuggestions(parameters, appendComma: true);
    } else if (_isInsertingToArgListWithSynthetic()) {
      _addDefaultParamSuggestions(parameters,
          appendComma: !request.target.isFollowedByComma);
    }
  }

  /// Return the number of arguments in the argument list.
  int _argCount() {
    final argumentList = this.argumentList;
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

  /// Return `true` if the caret is preceding an arg where a name could be added
  /// (turning a positional arg into a named arg).
  bool _isAddingLabelToPositional() {
    final argumentList = this.argumentList;
    if (argumentList != null) {
      var entity = request.target.entity;
      if (entity is! Expression) {
        return false;
      }
      if (entity is! NamedExpression) {
        // Caret is in front of a value
        //     f(one: 1, ^2);
        if (request.offset <= entity.offset) {
          return true;
        }

        // Caret is in the between two values that are not seperated by a comma.
        //     f(one: 1, tw^'foo');
        // must be at least two and the target not last.
        var args = argumentList.arguments;
        if (args.length >= 2 && entity != args.last) {
          var index = args.indexOf(entity);
          if (index != -1) {
            var next = args[index + 1];
            // Check the two tokens are adjacent without any comma.
            if (entity.end == next.offset) {
              return true;
            }
          }
        }
      }
    }
    return false;
  }

  /// Return `true` if the completion target is at the end of the list of
  /// arguments.
  bool _isAppendingToArgList() {
    final argumentList = this.argumentList;
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
      if (entity is SimpleIdentifier &&
          entity.isSynthetic &&
          entity.token.next?.type == TokenType.COLON) {
        return true;
      }
      if (entity is NamedExpression) {
        var offset = request.offset;
        if (entity.offset < offset && offset < entity.end) {
          return true;
        }
      }
    }
    return false;
  }

  bool _isInFlutterCreation() {
    var flutter = Flutter.instance;
    var containingNode = request.target.containingNode;
    var parent = containingNode.parent;
    var newExpr = parent != null ? flutter.identifyNewExpression(parent) : null;
    return newExpr != null && flutter.isWidgetCreation(newExpr);
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
    final argumentList = this.argumentList;
    if (argumentList != null) {
      var entity = request.target.entity;
      if (entity is SimpleIdentifier) {
        var argIndex = request.target.argIndex!;
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
    final argumentList = this.argumentList;
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
