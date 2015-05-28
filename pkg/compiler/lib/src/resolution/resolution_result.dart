// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of resolution;

/// The result of resolving a node.
abstract class ResolutionResult {
  Element get element;
}

/// The result for the resolution of a node that points to an [Element].
class ElementResult implements ResolutionResult {
  final Element element;

  // TODO(johnniwinther): Remove this factory constructor when `null` is never
  // passed as an element result.
  factory ElementResult(Element element) {
    return element != null ? new ElementResult.internal(element) : null;
  }

  ElementResult.internal(this.element);

  String toString() => 'ElementResult($element)';
}

/// The result for the resolution of a node that points to an [DartType].
class TypeResult implements ResolutionResult {
  final DartType type;

  TypeResult(this.type) {
    assert(type != null);
  }

  Element get element => type.element;

  String toString() => 'TypeResult($type)';
}

/// The result for the resolution of the `assert` method.
class AssertResult implements ResolutionResult {
  const AssertResult();

  Element get element => null;

  String toString() => 'AssertResult()';
}
