// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/dart/element/member.dart'; // ignore: implementation_imports

extension ElementExtension on Element {
  Element get canonicalElement {
    var self = this;
    if (self is PropertyAccessorElement) {
      var variable = self.variable;
      if (variable is FieldMember) {
        // A field element defined in a parameterized type where the values of
        // the type parameters are known.
        //
        // This concept should be invisible when comparing FieldElements, but a
        // bug in the analyzer causes FieldElements to not evaluate as
        // equivalent to equivalent FieldMembers. See
        // https://github.com/dart-lang/sdk/issues/35343.
        return variable.declaration;
      } else {
        return variable;
      }
    } else {
      return self;
    }
  }
}

extension AstNodeExtensions on AstNode? {
  Element? get canonicalElement {
    var self = this;
    if (self is Expression) {
      var node = self.unParenthesized;
      if (node is Identifier) {
        return node.staticElement?.canonicalElement;
      } else if (node is PropertyAccess) {
        return node.propertyName.staticElement?.canonicalElement;
      }
    }
    return null;
  }
}

extension ExpressionExtensions on Expression? {
  bool get isNullLiteral => this?.unParenthesized is NullLiteral;
}
