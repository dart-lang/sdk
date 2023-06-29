// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';

class BuiltValueTransformer {
  static Annotation? findNullableAnnotation(MethodDeclaration node) {
    if (node.isGetter && node.isAbstract) {
      for (var annotation in node.metadata) {
        if (annotation.arguments == null) {
          var element = annotation.element;
          if (element is PropertyAccessorElement &&
              element.name == 'nullable') {
            if (element.enclosingElement2 is CompilationUnitElement) {
              if (element.library.source.uri.toString() ==
                  'package:built_value/built_value.dart') {
                return annotation;
              }
            }
          }
        }
      }
    }
    return null;
  }
}
