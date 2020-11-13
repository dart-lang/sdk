// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/ast/ast.dart';

/// TODO(scheglov) https://github.com/dart-lang/sdk/issues/43608
Element _readElement(AstNode node) {
  var parent = node.parent;

  if (parent is AssignmentExpression && parent.leftHandSide == node) {
    return parent.readElement;
  }
  if (parent is PostfixExpression && parent.operand == node) {
    return parent.readElement;
  }
  if (parent is PrefixExpression && parent.operand == node) {
    return parent.readElement;
  }

  if (parent is PrefixedIdentifier && parent.identifier == node) {
    return _readElement(parent);
  }
  if (parent is PropertyAccess && parent.propertyName == node) {
    return _readElement(parent);
  }
  return null;
}

/// TODO(scheglov) https://github.com/dart-lang/sdk/issues/43608
Element _writeElement(AstNode node) {
  var parent = node.parent;

  if (parent is AssignmentExpression && parent.leftHandSide == node) {
    return parent.writeElement;
  }
  if (parent is PostfixExpression && parent.operand == node) {
    return parent.writeElement;
  }
  if (parent is PrefixExpression && parent.operand == node) {
    return parent.writeElement;
  }

  if (parent is PrefixedIdentifier && parent.identifier == node) {
    return _writeElement(parent);
  }
  if (parent is PropertyAccess && parent.propertyName == node) {
    return _writeElement(parent);
  }
  return null;
}

/// TODO(scheglov) https://github.com/dart-lang/sdk/issues/43608
DartType _writeType(AstNode node) {
  var parent = node.parent;

  if (parent is AssignmentExpression && parent.leftHandSide == node) {
    return parent.writeType;
  }
  if (parent is PostfixExpression && parent.operand == node) {
    return parent.writeType;
  }
  if (parent is PrefixExpression && parent.operand == node) {
    return parent.writeType;
  }

  if (parent is PrefixedIdentifier && parent.identifier == node) {
    return _writeType(parent);
  }
  if (parent is PropertyAccess && parent.propertyName == node) {
    return _writeType(parent);
  }
  return null;
}

extension FormalParameterExtension on FormalParameter {
  FormalParameter get notDefault {
    var self = this;
    if (self is DefaultFormalParameter) {
      return self.parameter;
    }
    return self;
  }

  AstNode get typeOrSelf {
    var self = this;
    if (self is SimpleFormalParameter) {
      return self.type;
    }
    return self;
  }
}

/// TODO(scheglov) https://github.com/dart-lang/sdk/issues/43608
extension IdentifierExtension on Identifier {
  Element get writeElement {
    return _writeElement(this);
  }

  Element get readElement {
    return _readElement(this);
  }

  Element get writeOrReadElement {
    return _writeElement(this) ?? staticElement;
  }

  DartType get writeOrReadType {
    return _writeType(this) ?? staticType;
  }
}

/// TODO(scheglov) https://github.com/dart-lang/sdk/issues/43608
extension IndexExpressionExtension on IndexExpression {
  Element get writeOrReadElement {
    return _writeElement(this) ?? staticElement;
  }
}

extension ListOfFormalParameterExtension on List<FormalParameter> {
  Iterable<FormalParameterImpl> get asImpl {
    return cast<FormalParameterImpl>();
  }
}
