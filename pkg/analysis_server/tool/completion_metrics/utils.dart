// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';

bool isTypeMember(SimpleIdentifier node) {
  if (node == null || node is! SimpleIdentifier || node.staticElement == null) {
    return false;
  }
  var element = node.staticElement;
  if (_isStatic(element)) {
    return false;
  }
  return element.enclosingElement is ClassElement;
}

bool _isStatic(Element element) {
  if (element is ClassMemberElement) {
    return element.isStatic;
  } else if (element is ExecutableElement) {
    return element.isStatic;
  } else if (element is FieldElement) {
    return element.isStatic;
  } else if (element is VariableElement) {
    return element.isStatic;
  }
  return true;
}
