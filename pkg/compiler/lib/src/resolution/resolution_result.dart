// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.resolution.result;

import '../constants/expressions.dart';
import '../dart_types.dart';
import '../elements/elements.dart';
import '../tree/tree.dart';
import '../universe/call_structure.dart' show CallStructure;

enum ResultKind {
  NONE,
  ELEMENT,
  TYPE,
  ASSERT,
  CONSTANT,
  PREFIX,
}

/// The result of resolving a node.
abstract class ResolutionResult {
  const ResolutionResult();

  // TODO(johnniwinther): Remove this factory constructor when `null` is never
  // passed as an element result.
  factory ResolutionResult.forElement(Element element) {
    return element != null ? new ElementResult(element) : const NoneResult();
  }

  ResultKind get kind;
  Node get node => null;
  Element get element => null;
  DartType get type => null;
  ConstantExpression get constant => null;
  bool get isConstant => false;
}

/// The prefix of top level or member access, like `prefix.member`,
/// `prefix.Class.member` or `Class.member`.
class PrefixResult extends ResolutionResult {
  final PrefixElement prefix;
  final ClassElement cls;

  PrefixResult(this.prefix, this.cls);

  Element get element => cls != null ? cls : prefix;

  bool get isDeferred => prefix != null && prefix.isDeferred;

  ResultKind get kind => ResultKind.PREFIX;

  String toString() => 'PrefixResult($prefix,$cls)';
}

/// The result for the resolution of a node that points to an [Element].
class ElementResult extends ResolutionResult {
  final Element element;

  ResultKind get kind => ResultKind.ELEMENT;

  ElementResult(this.element) {
    assert(element != null);
  }

  String toString() => 'ElementResult($element)';
}

/// The result for the resolution of a node that points to an [DartType].
class TypeResult extends ResolutionResult {
  final DartType type;

  TypeResult(this.type) {
    assert(type != null);
  }

  ResultKind get kind => ResultKind.TYPE;

  Element get element => type.element;

  String toString() => 'TypeResult($type)';
}

/// The result for resolving a constant expression.
class ConstantResult extends ResolutionResult {
  final Node node;
  final ConstantExpression constant;
  final Element element;

  /// Creates a result for the [constant] expression. [node] is provided for
  /// error reporting on the constant and [element] is provided if the
  /// expression additionally serves an [Element] like [ElementResult].
  ConstantResult(this.node, this.constant, {this.element});

  bool get isConstant => true;

  ResultKind get kind => ResultKind.CONSTANT;

  String toString() => 'ConstantResult(${constant.toDartText()})';
}

class NoneResult extends ResolutionResult {
  const NoneResult();

  ResultKind get kind => ResultKind.NONE;

  String toString() => 'NoneResult()';
}

/// The result of resolving a list of arguments.
class ArgumentsResult {
  /// The call structure of the arguments.
  final CallStructure callStructure;

  /// The resolutions results for each argument.
  final List<ResolutionResult> argumentResults;

  /// `true` if the arguments are valid as arguments to a constructed constant
  /// expression.
  final bool isValidAsConstant;

  ArgumentsResult(this.callStructure, this.argumentResults,
      {this.isValidAsConstant});

  /// Returns the list of [ConstantExpression]s for each of the arguments. If
  /// [isValidAsConstant] is `false`, `null` is returned.
  List<ConstantExpression> get constantArguments {
    if (!isValidAsConstant) return null;
    return argumentResults.map((ResolutionResult result) {
      return result.constant;
    }).toList();
  }
}
