// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart';
import 'package:kernel/core_types.dart';
import 'package:vm/transformations/type_flow/native_code.dart';
import 'package:vm/transformations/type_flow/utils.dart';

// Since we don't run the constants transformation in this test, we can't
// recognize all pragma annotations precisely. Instead, we pattern match on
// annotations which look like a pragma and assume that their options field
// evaluates to true.
class ExpressionPragmaAnnotationParser extends PragmaAnnotationParser {
  final CoreTypes coreTypes;

  ExpressionPragmaAnnotationParser(this.coreTypes);

  ParsedPragma parsePragma(Expression annotation) {
    assertx(annotation is! ConstantExpression);

    String pragmaName;
    Expression options;

    if (annotation is ConstructorInvocation) {
      if (annotation.constructedType.classNode != coreTypes.pragmaClass) {
        return null;
      }

      if (annotation.arguments.types.length != 0 ||
          (annotation.arguments.positional.length != 1 &&
              annotation.arguments.positional.length != 2) ||
          annotation.arguments.named.length != 0) {
        throw "Cannot evaluate pragma annotation $annotation";
      }

      var arguments = annotation.arguments.positional;
      var nameArg = arguments[0];
      if (nameArg is StringLiteral) {
        pragmaName = nameArg.value;
      } else {
        return null;
      }

      options = arguments.length > 1 ? arguments[1] : new NullLiteral();
    }

    switch (pragmaName) {
      case kEntryPointPragmaName:
        // We ignore the option because we can't properly evaluate it, assume
        // it's true.
        return new ParsedEntryPointPragma(PragmaEntryPointType.Always);
      case kExactResultTypePragmaName:
        if (options is TypeLiteral) {
          return new ParsedResultTypeByTypePragma(options.type);
        } else if (options is StringLiteral) {
          return new ParsedResultTypeByPathPragma(options.value);
        }
        throw "Could not recognize option to $kExactResultTypePragmaName";
      default:
        return null;
    }
  }
}
