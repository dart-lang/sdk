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
const kVmDisableUnboxedParametersPragmaName = "vm:disable-unboxed-parameters";
const kVmKeepNamePragmaName = "vm:keep-name";
const kVmPlatformConstPragmaName = "vm:platform-const";
const kVmPlatformConstIfPragmaName = "vm:platform-const-if";

// Pragmas recognized by dart2wasm
const kWasmEntryPointPragmaName = "wasm:entry-point";
const kWasmExportPragmaName = "wasm:export";

// Dynamic modules pragmas, recognized both by the VM and dart2wasm
const kDynModuleExtendablePragmaName = "dyn-module:extendable";
const kDynModuleCanBeOverriddenPragmaName = "dyn-module:can-be-overridden";
const kDynModuleCallablePragmaName = "dyn-module:callable";
const kDynModuleEntryPointPragmaName = "dyn-module:entry-point";

abstract class ParsedPragma {}

enum PragmaEntryPointType {
  Default,
  Extendable,
  CanBeOverridden,
  GetterOnly,
  SetterOnly,
  CallOnly
}

enum PragmaRecognizedType { AsmIntrinsic, GraphIntrinsic, Other }

class ParsedEntryPointPragma implements ParsedPragma {
  final PragmaEntryPointType type;
  const ParsedEntryPointPragma(this.type);
}

class ParsedResultTypeByTypePragma implements ParsedPragma {
  final DartType type;
  final bool resultTypeUsesPassedTypeArguments;
  const ParsedResultTypeByTypePragma(
      this.type, this.resultTypeUsesPassedTypeArguments);
}

class ParsedResultTypeByPathPragma implements ParsedPragma {
  final String path;
  const ParsedResultTypeByPathPragma(this.path);
}

class ParsedNonNullableResultType implements ParsedPragma {
  const ParsedNonNullableResultType();
}

class ParsedRecognized implements ParsedPragma {
  final PragmaRecognizedType type;
  const ParsedRecognized(this.type);
}

class ParsedDisableUnboxedParameters implements ParsedPragma {
  const ParsedDisableUnboxedParameters();
}

class ParsedKeepNamePragma implements ParsedPragma {
  const ParsedKeepNamePragma();
}

class ParsedPlatformConstPragma implements ParsedPragma {
  const ParsedPlatformConstPragma();
}

class ParsedDynModuleEntryPointPragma implements ParsedPragma {
  const ParsedDynModuleEntryPointPragma();
}

abstract class PragmaAnnotationParser {
  /// May return 'null' if the annotation does not represent a recognized
  /// @pragma.
  ParsedPragma? parsePragma(Expression annotation);

  Iterable<R> parsedPragmas<R extends ParsedPragma>(Iterable<Expression> node);
}

class ConstantPragmaAnnotationParser implements PragmaAnnotationParser {
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
    } else if (annotation is InvalidExpression) {
      return null;
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
        return type != null ? ParsedEntryPointPragma(type) : null;
      case kVmExactResultTypePragmaName:
        if (options is TypeLiteralConstant) {
          return ParsedResultTypeByTypePragma(options.type, false);
        } else if (options is StringConstant) {
          return ParsedResultTypeByPathPragma(options.value);
        } else if (options is ListConstant &&
            options.entries.length == 2 &&
            options.entries[0] is TypeLiteralConstant &&
            options.entries[1] is StringConstant &&
            (options.entries[1] as StringConstant).value ==
                kResultTypeUsesPassedTypeArguments) {
          return ParsedResultTypeByTypePragma(
              (options.entries[0] as TypeLiteralConstant).type, true);
        }
        throw "ERROR: Unsupported option to '$kVmExactResultTypePragmaName' "
            "pragma: $options";
      case kVmNonNullableResultType:
        return const ParsedNonNullableResultType();
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
        return ParsedRecognized(type);
      case kVmDisableUnboxedParametersPragmaName:
        return const ParsedDisableUnboxedParameters();
      case kVmKeepNamePragmaName:
        return const ParsedKeepNamePragma();
      case kVmPlatformConstPragmaName:
        return const ParsedPlatformConstPragma();
      case kVmPlatformConstIfPragmaName:
        if (options is! BoolConstant) {
          throw "ERROR: Non-boolean option to '$kVmPlatformConstIfPragmaName' "
              "pragma: $options";
        }
        return options.value ? const ParsedPlatformConstPragma() : null;
      case kWasmEntryPointPragmaName:
        return const ParsedEntryPointPragma(PragmaEntryPointType.Default);
      case kWasmExportPragmaName:
        // Exports are treated as entry points.
        return const ParsedEntryPointPragma(PragmaEntryPointType.Default);
      case kDynModuleExtendablePragmaName:
        return const ParsedEntryPointPragma(PragmaEntryPointType.Extendable);
      case kDynModuleCanBeOverriddenPragmaName:
        return const ParsedEntryPointPragma(
            PragmaEntryPointType.CanBeOverridden);
      case kDynModuleCallablePragmaName:
        return const ParsedEntryPointPragma(PragmaEntryPointType.Default);
      case kDynModuleEntryPointPragmaName:
        return const ParsedDynModuleEntryPointPragma();
      default:
        return null;
    }
  }

  Iterable<R> parsedPragmas<R extends ParsedPragma>(
          Iterable<Expression> annotations) =>
      annotations.map(parsePragma).whereType<R>();
}
