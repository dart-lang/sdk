// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart';
import 'package:kernel/core_types.dart';

T? getPragma<T>(CoreTypes coreTypes, Annotatable node, String name,
    {T? defaultValue}) {
  for (Expression annotation in node.annotations) {
    if (annotation is ConstantExpression) {
      Constant constant = annotation.constant;
      if (constant is InstanceConstant) {
        if (constant.classNode == coreTypes.pragmaClass) {
          Constant? nameConstant =
              constant.fieldValues[coreTypes.pragmaName.fieldReference];
          if (nameConstant is StringConstant && nameConstant.value == name) {
            Constant? value =
                constant.fieldValues[coreTypes.pragmaOptions.fieldReference];
            if (value == null || value is NullConstant) {
              return defaultValue;
            }
            if (value is PrimitiveConstant<T>) {
              return value.value;
            }
            if (value is! T) {
              throw ArgumentError("$name pragma argument has unexpected type "
                  "${value.runtimeType} (expected $T)");
            }
            return value as T;
          }
        }
      }
    }
  }
  return null;
}
