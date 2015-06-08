// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of resolution;

enum ResultKind {
  NONE,
  ELEMENT,
  TYPE,
  ASSERT,
  CONSTANT,
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
  Element get element => null;
  DartType get type => null;
  ConstantExpression get constant => null;
  bool get isConstant => false;
}

/// The result for the resolution of a node that points to an [Element].
class ElementResult extends ResolutionResult {
  final Element element;

  ResultKind get kind => ResultKind.ELEMENT;

  ElementResult(this.element);

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

/// The result for the resolution of the `assert` method.
class AssertResult extends ResolutionResult {
  const AssertResult();

  ResultKind get kind => ResultKind.ASSERT;

  String toString() => 'AssertResult()';
}

class ConstantResult extends ResolutionResult {
  final Node node;
  final ConstantExpression constant;

  ConstantResult(this.node, this.constant);

  bool get isConstant => true;

  ResultKind get kind => ResultKind.CONSTANT;

  String toString() => 'ConstantResult(${constant.getText()})';
}

class NoneResult extends ResolutionResult {
  const NoneResult();

  ResultKind get kind => ResultKind.NONE;

  String toString() => 'NoneResult()';
}