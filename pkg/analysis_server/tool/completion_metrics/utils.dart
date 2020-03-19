// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/syntactic_entity.dart';
import 'package:analyzer/dart/element/element.dart';

/// Return the element associated with the syntactic [entity], or `null` if
/// there is no such element.
Element getElement(SyntacticEntity entity) {
  if (entity is SimpleIdentifier) {
    return entity.staticElement;
  }
  return null;
}

/// Return `true` if the [element] is an instance member of a class or
/// extension.
bool isInstanceMember(Element element) {
  if (element == null || _isStatic(element)) {
    return false;
  }
  var parent = element.enclosingElement;
  return parent is ClassElement || parent is ExtensionElement;
}

/// Return `true` if the [element] is an static member of a class or extension.
bool isStaticMember(Element element) {
  if (element == null || !_isStatic(element)) {
    return false;
  }
  var parent = element.enclosingElement;
  return parent is ClassElement || parent is ExtensionElement;
}

/// Return `true` if the [element] is static (either top-level or a static
/// member of a class or extension).
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
