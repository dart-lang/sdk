// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart';
import 'package:kernel/core_types.dart' show CoreTypes;
import 'package:kernel/target/targets.dart' show Target;

// Pragmas recognized by the VM
const kVmEntryPointPragmaName = "vm:entry-point";
const kVmExactResultTypePragmaName = "vm:exact-result-type";
const kVmNonNullableResultType = "vm:non-nullable-result-type";
const kResultTypeUsesPassedTypeArguments =
    "result-type-uses-passed-type-arguments";
const kVmRecognizedPragmaName = "vm:recognized";
const kVmDisableUnboxedParametetersPragmaName = "vm:disable-unboxed-parameters";

// Pragmas recognized by dart2wasm
const kWasmEntryPointPragmaName = "wasm:entry-point";
const kWasmExportPragmaName = "wasm:export";

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

class ParsedDisableUnboxedParameters extends ParsedPragma {
  ParsedDisableUnboxedParameters();
}

abstract class PragmaAnnotationParser {
  /// May return 'null' if the annotation does not represent a recognized
  /// @pragma.
  ParsedPragma? parsePragma(Expression annotation);
}

class ConstantPragmaAnnotationParser extends PragmaAnnotationParser {
  final CoreTypes coreTypes;
  final Target target;

  ConstantPragmaAnnotationParser(this.coreTypes, this.target);

  ParsedPragma? parsePragma(Expression annotation) {
    InstanceConstant? pragmaConstant;
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
    Constant? name =
        pragmaConstant.fieldValues[coreTypes.pragmaName.fieldReference];
    if (name is StringConstant) {
      pragmaName = name.value;
    } else {
      return null;
    }

    if (!target.isSupportedPragma(pragmaName)) return null;

    Constant options =
        pragmaConstant.fieldValues[coreTypes.pragmaOptions.fieldReference]!;

    switch (pragmaName) {
      case kVmEntryPointPragmaName:
        PragmaEntryPointType? type;
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
            throw "Error: string directive to "
                "@pragma('$kVmEntryPointPragmaName', ...) "
                "must be either 'get' or 'set' for fields "
                "or 'get' or 'call' for procedures.";
          }
        }
        return type != null ? new ParsedEntryPointPragma(type) : null;
      case kVmExactResultTypePragmaName:
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
        throw "ERROR: Unsupported option to '$kVmExactResultTypePragmaName' "
            "pragma: $options";
      case kVmNonNullableResultType:
        return new ParsedNonNullableResultType();
      case kVmRecognizedPragmaName:
        PragmaRecognizedType? type;
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
          throw "ERROR: Unsupported option to '$kVmRecognizedPragmaName' "
              "pragma: $options";
        }
        return new ParsedRecognized(type);
      case kVmDisableUnboxedParametetersPragmaName:
        return new ParsedDisableUnboxedParameters();
      case kWasmEntryPointPragmaName:
        return ParsedEntryPointPragma(PragmaEntryPointType.Default);
      case kWasmExportPragmaName:
        // Exports are treated as called entry points.
        return ParsedEntryPointPragma(PragmaEntryPointType.CallOnly);
      default:
        return null;
    }
  }
}
