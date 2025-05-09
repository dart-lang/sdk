// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/src/dart/ast/extensions.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

class ReplaceWithInterpolation extends ResolvedCorrectionProducer {
  ReplaceWithInterpolation({required super.context});

  @override
  CorrectionApplicability get applicability =>
      CorrectionApplicability.automatically;

  @override
  FixKind get fixKind => DartFixKind.REPLACE_WITH_INTERPOLATION;

  @override
  FixKind? get multiFixKind => DartFixKind.REPLACE_WITH_INTERPOLATION_MULTI;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    //
    // Validate the fix.
    //
    var binary = _computeTarget();
    if (binary == null) {
      return;
    }
    //
    // Extract the information needed to build the edit.
    //
    var components = <AstNode>[];
    var style = _extractComponentsInto(binary, components);
    if (style.isInvalid || style.isUnknown || style.isRaw) {
      return;
    }
    var interpolation = _mergeComponents(style, components);
    //
    // Build the edit.
    //
    await builder.addDartFileEdit(file, (builder) {
      builder.addSimpleReplacement(range.node(binary), interpolation);
    });
  }

  BinaryExpression? _computeTarget() {
    BinaryExpression? binary;
    AstNode? candidate = node;
    while (candidate is BinaryExpression && _isStringConcatenation(candidate)) {
      binary = candidate;
      candidate = candidate.parent;
    }
    return binary;
  }

  _StringStyle _extractComponentsInto(
    Expression expression,
    List<AstNode> components,
  ) {
    if (expression is SingleStringLiteral) {
      components.add(expression);
      return _StringStyle(
        multiline: expression.isMultiline,
        raw: expression.isRaw,
        singleQuoted: expression.isSingleQuoted,
      );
    } else if (expression is AdjacentStrings) {
      var style = _StringStyle.unknown;
      for (var string in expression.strings) {
        if (style.isUnknown) {
          style = _extractComponentsInto(string, components);
        } else {
          var currentStyle = _extractComponentsInto(string, components);
          if (style != currentStyle) {
            style = _StringStyle.invalid;
          }
        }
      }
      return style;
    } else if (expression is BinaryExpression &&
        _isStringConcatenation(expression)) {
      var leftStyle = _extractComponentsInto(
        expression.leftOperand,
        components,
      );
      var rightStyle = _extractComponentsInto(
        expression.rightOperand,
        components,
      );
      if (leftStyle.isUnknown) {
        return rightStyle;
      } else if (rightStyle.isUnknown) {
        return leftStyle;
      }
      return leftStyle == rightStyle ? leftStyle : _StringStyle.invalid;
    } else if (expression is MethodInvocation) {
      var target = expression.target;
      if (target != null && expression.methodName.name == 'toString') {
        return _extractComponentsInto(target, components);
      }
    } else if (expression is ParenthesizedExpression) {
      return _extractComponentsInto(expression.expression, components);
    }
    components.add(expression);
    return _StringStyle.unknown;
  }

  bool _isStringConcatenation(BinaryExpression node) =>
      node.operator.type == TokenType.PLUS &&
      node.leftOperand.typeOrThrow.isDartCoreString &&
      node.rightOperand.typeOrThrow.isDartCoreString;

  String _mergeComponents(_StringStyle style, List<AstNode> components) {
    var quotes = style.quotes;
    var buffer = StringBuffer();
    buffer.write(quotes);
    for (var i = 0; i < components.length; i++) {
      var component = components[i];
      if (component is SingleStringLiteral) {
        var contents = utils.getRangeText(
          range.startOffsetEndOffset(
            component.contentsOffset,
            component.contentsEnd,
          ),
        );
        buffer.write(contents);
      } else if (component is SimpleIdentifier) {
        if (_nextStartsWithIdentifierContinuation(components, i)) {
          buffer.write(r'${');
          buffer.write(component.name);
          buffer.write('}');
        } else {
          buffer.write(r'$');
          buffer.write(component.name);
        }
      } else {
        buffer.write(r'${');
        buffer.write(utils.getNodeText(component));
        buffer.write('}');
      }
    }
    buffer.write(quotes);
    return buffer.toString();
  }

  /// Return `true` if the component after [index] in the list of [components]
  /// is one that would begin with a valid identifier continuation character
  /// when written into the resulting string.
  bool _nextStartsWithIdentifierContinuation(
    List<AstNode> components,
    int index,
  ) {
    bool startsWithIdentifierContinuation(String string) =>
        string.startsWith(RegExp(r'[a-zA-Z0-9_$]'));

    if (index + 1 >= components.length) {
      return false;
    }
    var next = components[index + 1];
    if (next is SimpleStringLiteral) {
      return startsWithIdentifierContinuation(next.value);
    } else if (next is StringInterpolation) {
      return startsWithIdentifierContinuation(
        (next.elements[0] as InterpolationString).value,
      );
    }
    return false;
  }
}

class _StringStyle {
  static _StringStyle invalid = _StringStyle._(-2);

  static _StringStyle unknown = _StringStyle._(-1);

  static int multilineBit = 4;
  static int rawBit = 2;
  static int singleQuotedBit = 1;

  final int state;

  factory _StringStyle({
    required bool multiline,
    required bool raw,
    required bool singleQuoted,
  }) {
    return _StringStyle._(
      (multiline ? multilineBit : 0) +
          (raw ? rawBit : 0) +
          (singleQuoted ? singleQuotedBit : 0),
    );
  }

  _StringStyle._(this.state);

  @override
  int get hashCode => state;

  bool get isInvalid => state == -2;

  bool get isRaw => state & rawBit != 0;

  bool get isUnknown => state == -1;

  String get quotes {
    if (state & singleQuotedBit != 0) {
      return (state & multilineBit != 0) ? "'''" : "'";
    }
    return (state & multilineBit != 0) ? '"""' : '"';
  }

  @override
  bool operator ==(Object other) {
    return other is _StringStyle && state == other.state;
  }
}
