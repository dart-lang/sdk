// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library vm.transformations.pragma;

import 'package:kernel/ast.dart';
import 'package:kernel/core_types.dart' show CoreTypes;

const kEntryPointPragmaName = "vm:entry-point";
const kExactResultTypePragmaName = "vm:exact-result-type";
const kNonNullableResultType = "vm:non-nullable-result-type";
const kResultTypeUsesPassedTypeArguments =
    "result-type-uses-passed-type-arguments";
const kRecognizedPragmaName = "vm:recognized";

abstract class ParsedPragma {}

enum PragmaEntryPointType { Default, GetterOnly, SetterOnly, CallOnly }

enum PragmaRecognizedType { AsmIntrinsic, GraphIntrinsic, Other }

class ParsedEntryPointPragma extends ParsedPragma {
  final PragmaEntryPointType type;
  ParsedEntryPointPragma(this.type);
}

class ParsedResultTypeByTypePragma extends ParsedPragma {
  final DartType type;
  final bool resultTypeUsesPassedTypeArguments;
  ParsedResultTypeByTypePragma(
      this.type, this.resultTypeUsesPassedTypeArguments);
}

class ParsedResultTypeByPathPragma extends ParsedPragma {
  final String path;
  ParsedResultTypeByPathPragma(this.path);
}

class ParsedNonNullableResultType extends ParsedPragma {
  ParsedNonNullableResultType();
}

class ParsedRecognized extends ParsedPragma {
  final PragmaRecognizedType type;
  ParsedRecognized(this.type);
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
    Constant name =
        pragmaConstant.fieldValues[coreTypes.pragmaName.getterReference];
    if (name is StringConstant) {
      pragmaName = name.value;
    } else {
      return null;
    }

    Constant options =
        pragmaConstant.fieldValues[coreTypes.pragmaOptions.getterReference];
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
          return new ParsedResultTypeByTypePragma(options.type, false);
        } else if (options is StringConstant) {
          return new ParsedResultTypeByPathPragma(options.value);
        } else if (options is ListConstant &&
            options.entries.length == 2 &&
            options.entries[0] is TypeLiteralConstant &&
            options.entries[1] is StringConstant &&
            (options.entries[1] as StringConstant).value ==
                kResultTypeUsesPassedTypeArguments) {
          return new ParsedResultTypeByTypePragma(
              (options.entries[0] as TypeLiteralConstant).type, true);
        }
        throw "ERROR: Unsupported option to '$kExactResultTypePragmaName' "
            "pragma: $options";
      case kNonNullableResultType:
        return new ParsedNonNullableResultType();
      case kRecognizedPragmaName:
        PragmaRecognizedType type;
        if (options is StringConstant) {
          if (options.value == "asm-intrinsic") {
            type = PragmaRecognizedType.AsmIntrinsic;
          } else if (options.value == "graph-intrinsic") {
            type = PragmaRecognizedType.GraphIntrinsic;
          } else if (options.value == "other") {
            type = PragmaRecognizedType.Other;
          }
        }
        if (type == null) {
          throw "ERROR: Unsupported option to '$kRecognizedPragmaName' "
              "pragma: $options";
        }
        return new ParsedRecognized(type);
      default:
        return null;
    }
  }
}
