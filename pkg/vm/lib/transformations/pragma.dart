// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library vm.transformations.pragma;

import 'package:kernel/ast.dart';
import 'package:kernel/core_types.dart' show CoreTypes;

const kEntryPointPragmaName = "vm:entry-point";
const kExactResultTypePragmaName = "vm:exact-result-type";
const kNonNullableResultType = "vm:non-nullable-result-type";

abstract class ParsedPragma {}

enum PragmaEntryPointType { Default, GetterOnly, SetterOnly, CallOnly }

class ParsedEntryPointPragma extends ParsedPragma {
  final PragmaEntryPointType type;
  ParsedEntryPointPragma(this.type);
}

class ParsedResultTypeByTypePragma extends ParsedPragma {
  final DartType type;
  ParsedResultTypeByTypePragma(this.type);
}

class ParsedResultTypeByPathPragma extends ParsedPragma {
  final String path;
  ParsedResultTypeByPathPragma(this.path);
}

class ParsedNonNullableResultType extends ParsedPragma {
  ParsedNonNullableResultType();
}

abstract class PragmaAnnotationParser {
  /// May return 'null' if the annotation does not represent a recognized
  /// @pragma.
  ParsedPragma parsePragma(Expression annotation);
}

class ConstantPragmaAnnotationParser extends PragmaAnnotationParser {
  final CoreTypes coreTypes;

  ConstantPragmaAnnotationParser(this.coreTypes);

  ParsedPragma parsePragma(Expression annotation) {
    InstanceConstant pragmaConstant;
    if (annotation is ConstantExpression) {
      Constant constant = annotation.constant;
      if (constant is InstanceConstant) {
        if (constant.classNode == coreTypes.pragmaClass) {
          pragmaConstant = constant;
        }
      } else if (constant is UnevaluatedConstant) {
        throw 'Error: unevaluated constant $constant';
      }
    } else {
      throw 'Error: non-constant annotation $annotation';
    }
    if (pragmaConstant == null) return null;

    String pragmaName;
    Constant name = pragmaConstant.fieldValues[coreTypes.pragmaName.reference];
    if (name is StringConstant) {
      pragmaName = name.value;
    } else {
      return null;
    }

    Constant options =
        pragmaConstant.fieldValues[coreTypes.pragmaOptions.reference];
    assert(options != null);

    switch (pragmaName) {
      case kEntryPointPragmaName:
        PragmaEntryPointType type;
        if (options is NullConstant) {
          type = PragmaEntryPointType.Default;
        } else if (options is BoolConstant && options.value == true) {
          type = PragmaEntryPointType.Default;
        } else if (options is StringConstant) {
          if (options.value == "get") {
            type = PragmaEntryPointType.GetterOnly;
          } else if (options.value == "set") {
            type = PragmaEntryPointType.SetterOnly;
          } else if (options.value == "call") {
            type = PragmaEntryPointType.CallOnly;
          } else {
            throw "Error: string directive to @pragma('$kEntryPointPragmaName', ...) "
                "must be either 'get' or 'set' for fields "
                "or 'get' or 'call' for procedures.";
          }
        }
        return type != null ? new ParsedEntryPointPragma(type) : null;
      case kExactResultTypePragmaName:
        if (options == null) return null;
        if (options is TypeLiteralConstant) {
          return new ParsedResultTypeByTypePragma(options.type);
        } else if (options is StringConstant) {
          return new ParsedResultTypeByPathPragma(options.value);
        }
        throw "ERROR: Unsupported option to '$kExactResultTypePragmaName' "
            "pragma: $options";
      case kNonNullableResultType:
        return new ParsedNonNullableResultType();
      default:
        return null;
    }
  }
}
