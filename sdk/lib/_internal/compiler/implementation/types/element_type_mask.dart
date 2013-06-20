// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of types;

/**
 * A [TypeMask] specific to an element: the return type for a
 * function, or the type for a field.
 */
class ElementTypeMask extends ForwardingTypeMask {
  final Element element;
  // Callback function to fetch the actual inferred type of the
  // element. It is used when a user wants to know about the type this
  // [ForwardingTypeMask] forwards to.
  final Function fetchForwardTo;
  final bool isNullable;

  ElementTypeMask(
      this.fetchForwardTo, this.element, {this.isNullable: true});

  bool get isElement => true;

  TypeMask get forwardTo {
    TypeMask forward = fetchForwardTo(element);
    return isNullable ? forward.nullable() : forward.nonNullable();
  }

  bool operator==(other) {
    if (other is! ElementTypeMask) return false;
    return element == other.element && isNullable == other.isNullable;
  }

  bool equalsDisregardNull(other) {
    if (other is! ElementTypeMask) return false;
    return element == other.element;
  }

  TypeMask nullable() {
    return isNullable
        ? this
        : new ElementTypeMask(fetchForwardTo, element, isNullable: true);
  }

  TypeMask nonNullable() {
    return isNullable
        ? new ElementTypeMask(fetchForwardTo, element, isNullable: false)
        : this;
  }

  String toString() {
    return 'Type for element $element';
  }
}
