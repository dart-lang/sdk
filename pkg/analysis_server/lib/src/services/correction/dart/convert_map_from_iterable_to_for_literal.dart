// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/assist.dart';
import 'package:analysis_server/src/services/correction/dart/abstract_producer.dart';
import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer_plugin/utilities/assist/assist.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

class ConvertMapFromIterableToForLiteral extends ResolvedCorrectionProducer {
  @override
  AssistKind get assistKind => DartAssistKind.CONVERT_TO_FOR_ELEMENT;

  @override
  bool get canBeAppliedInBulk => true;

  @override
  bool get canBeAppliedToFile => true;

  @override
  FixKind get fixKind => DartFixKind.CONVERT_TO_FOR_ELEMENT;

  @override
  FixKind get multiFixKind => DartFixKind.CONVERT_TO_FOR_ELEMENT_MULTI;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    //
    // Ensure that the selection is inside an invocation of Map.fromIterable.
    //
    var creation = node.thisOrAncestorOfType<InstanceCreationExpression>();
    if (creation == null) {
      return;
    }
    var element = creation.constructorName.staticElement;
    if (element == null ||
        element.name != 'fromIterable' ||
        element.enclosingElement != typeProvider.mapElement) {
      return;
    }
    //
    // Ensure that the arguments have the right form.
    //
    var arguments = creation.argumentList.arguments;
    if (arguments.length != 3) {
      return;
    }
    var iterator = arguments[0].unParenthesized;
    var secondArg = arguments[1];
    var thirdArg = arguments[2];

    var keyClosure =
        _extractClosure('key', secondArg) ?? _extractClosure('key', thirdArg);
    var valueClosure = _extractClosure('value', thirdArg) ??
        _extractClosure('value', secondArg);
    if (keyClosure == null || valueClosure == null) {
      return;
    }
    //
    // Compute the loop variable name and convert the key and value closures if
    // necessary.
    //
    var keyParameter = keyClosure.parameter;
    var keyParameterName = keyClosure.parameterIdentifier.lexeme;
    var valueParameter = valueClosure.parameter;
    var valueParameterName = valueClosure.parameterIdentifier.lexeme;
    var keyExpressionText = utils.getNodeText(keyClosure.body);
    var valueExpressionText = utils.getNodeText(valueClosure.body);

    String loopVariableName;
    if (keyParameterName == valueParameterName) {
      loopVariableName = keyParameterName;
    } else {
      var keyFinder = _ParameterReferenceFinder(keyParameter.declaredElement!);
      keyClosure.body.accept(keyFinder);

      var valueFinder =
          _ParameterReferenceFinder(valueParameter.declaredElement!);
      valueClosure.body.accept(valueFinder);

      String computeUnusedVariableName() {
        var candidate = 'e';
        var index = 1;
        while (keyFinder.referencesName(candidate) ||
            valueFinder.referencesName(candidate)) {
          candidate = 'e${index++}';
        }
        return candidate;
      }

      if (valueFinder.isParameterUnreferenced) {
        if (valueFinder.referencesName(keyParameterName)) {
          // The name of the value parameter is not used, but we can't use the
          // name of the key parameter because doing so would hide a variable
          // referenced in the value expression.
          loopVariableName = computeUnusedVariableName();
          keyExpressionText = keyFinder.replaceName(
              keyExpressionText, loopVariableName, keyClosure.body.offset);
        } else {
          loopVariableName = keyParameterName;
        }
      } else if (keyFinder.isParameterUnreferenced) {
        if (keyFinder.referencesName(valueParameterName)) {
          // The name of the key parameter is not used, but we can't use the
          // name of the value parameter because doing so would hide a variable
          // referenced in the key expression.
          loopVariableName = computeUnusedVariableName();
          valueExpressionText = valueFinder.replaceName(
              valueExpressionText, loopVariableName, valueClosure.body.offset);
        } else {
          loopVariableName = valueParameterName;
        }
      } else {
        // The names are different and both are used. We need to find a name
        // that would not change the resolution of any other identifiers in
        // either the key or value expressions.
        loopVariableName = computeUnusedVariableName();
        keyExpressionText = keyFinder.replaceName(
            keyExpressionText, loopVariableName, keyClosure.body.offset);
        valueExpressionText = valueFinder.replaceName(
            valueExpressionText, loopVariableName, valueClosure.body.offset);
      }
    }
    //
    // Construct the edit.
    //
    await builder.addDartFileEdit(file, (builder) {
      builder.addReplacement(range.node(creation), (builder) {
        builder.write('{ for (var ');
        builder.write(loopVariableName);
        builder.write(' in ');
        builder.write(utils.getNodeText(iterator));
        builder.write(') ');
        builder.write(keyExpressionText);
        builder.write(' : ');
        builder.write(valueExpressionText);
        builder.write(' }');
      });
    });
  }

  static Expression? _extractBody(FunctionExpression expression) {
    var body = expression.body;
    if (body is ExpressionFunctionBody) {
      return body.expression;
    } else if (body is BlockFunctionBody) {
      var statements = body.block.statements;
      if (statements.length == 1) {
        var statement = statements[0];
        if (statement is ReturnStatement) {
          return statement.expression;
        }
      }
    }
    return null;
  }

  static _Closure? _extractClosure(String name, Expression argument) {
    if (argument is NamedExpression && argument.name.label.name == name) {
      var expression = argument.expression.unParenthesized;
      if (expression is FunctionExpression) {
        var parameterList = expression.parameters;
        if (parameterList != null) {
          var parameters = parameterList.parameters;
          if (parameters.length == 1) {
            var parameter = parameters[0];
            if (parameter is SimpleFormalParameter &&
                parameter.isRequiredPositional) {
              var parameterIdentifier = parameter.name;
              if (parameterIdentifier != null) {
                var body = _extractBody(expression);
                if (body != null) {
                  return _Closure(parameter, parameterIdentifier, body);
                }
              }
            }
          }
        }
      }
    }
    return null;
  }
}

class _Closure {
  final SimpleFormalParameter parameter;
  final Token parameterIdentifier;
  final Expression body;

  _Closure(this.parameter, this.parameterIdentifier, this.body);
}

/// A visitor that can be used to find references to a parameter.
class _ParameterReferenceFinder extends RecursiveAstVisitor<void> {
  /// The parameter for which references are being sought, or `null` if we are
  /// just accumulating a list of referenced names.
  final ParameterElement parameter;

  /// A list of the simple identifiers that reference the [parameter].
  final List<SimpleIdentifier> references = <SimpleIdentifier>[];

  /// A collection of the names of other simple identifiers that were found. We
  /// need to know these in order to ensure that the selected loop variable does
  /// not hide a name from an enclosing scope that is already being referenced.
  final Set<String> otherNames = <String>{};

  /// Initialize a newly created finder to find references to the [parameter].
  _ParameterReferenceFinder(this.parameter);

  /// Return `true` if the parameter is unreferenced in the nodes that have been
  /// visited.
  bool get isParameterUnreferenced => references.isEmpty;

  /// Return `true` is the given name (assumed to be different than the name of
  /// the parameter) is references in the nodes that have been visited.
  bool referencesName(String name) => otherNames.contains(name);

  /// Replace all of the references to the parameter in the given [source] with
  /// the [newName]. The [offset] is the offset of the first character of the
  /// [source] relative to the start of the file.
  String replaceName(String source, String newName, int offset) {
    var oldLength = parameter.name.length;
    for (var i = references.length - 1; i >= 0; i--) {
      var oldOffset = references[i].offset - offset;
      source = source.replaceRange(oldOffset, oldOffset + oldLength, newName);
    }
    return source;
  }

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    if (node.staticElement == parameter) {
      references.add(node);
    } else if (!node.isQualified) {
      // Only non-prefixed identifiers can be hidden.
      otherNames.add(node.name);
    }
  }
}
