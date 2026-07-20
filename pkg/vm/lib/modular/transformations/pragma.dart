// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart';
import 'package:kernel/core_types.dart' show CoreTypes;
import 'package:kernel/target/targets.dart' show Target;

// Pragmas recognized by the VM
const vmEntryPointPragmaName = "vm:entry-point";
const vmExactResultTypePragmaName = "vm:exact-result-type";
const kResultTypeUsesPassedTypeArguments =
    "result-type-uses-passed-type-arguments";
const vmRecognizedPragmaName = "vm:recognized";
const vmDisableUnboxedParametersPragmaName = "vm:disable-unboxed-parameters";
const vmKeepNamePragmaName = "vm:keep-name";
const vmPlatformConstPragmaName = "vm:platform-const";
const vmPlatformConstIfPragmaName = "vm:platform-const-if";
const vmFfiNative = "vm:ffi:native";
const vmSharedPragmaName = "vm:shared";
const vmDeeplyImmutablePragmaName = "vm:deeply-immutable";
const vmInvisiblePragmaName = "vm:invisible";

// Pragmas recognized by dart2wasm
const wasmEntryPointPragmaName = "wasm:entry-point";
const wasmExportPragmaName = "wasm:export";

// Dynamic modules pragmas, recognized both by the VM and dart2wasm
const dynModuleExtendablePragmaName = "dyn-module:extendable";
const dynModuleImplicitlyExtendablePragmaName =
    "dyn-module:implicitly-extendable";
const dynModuleCanBeOverriddenPragmaName = "dyn-module:can-be-overridden";
const dynModuleCanBeOverriddenImplicitlyPragmaName =
    "dyn-module:can-be-overridden-implicitly";
const dynModuleCallablePragmaName = "dyn-module:callable";
const dynModuleImplicitlyCallablePragmaName = "dyn-module:implicitly-callable";
const dynModuleCanBeUsedAsTypePragmaName = "dyn-module:can-be-used-as-type";
const dynModuleEntryPointPragmaName = "dyn-module:entry-point";
const dynModuleDynamicallyCallablePragmaName =
    "dyn-module:dynamically-callable";
const dynModuleImplicitlyDynamicallyCallablePragmaName =
    "dyn-module:implicitly-dynamically-callable";

abstract class ParsedPragma {}

enum PragmaEntryPointType {
  Default,
  Extendable,
  ImplicitlyExtendable,
  CanBeOverridden,
  GetterOnly,
  SetterOnly,
  CallOnly,
  CanBeUsedAsType,
  DynamicallyCallable,
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
    this.type,
    this.resultTypeUsesPassedTypeArguments,
  );
}

class ParsedResultTypeByPathPragma implements ParsedPragma {
  final String path;
  const ParsedResultTypeByPathPragma(this.path);
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

class ParsedFfiNativePragma implements ParsedPragma {
  const ParsedFfiNativePragma();
}

class ParsedDynModuleEntryPointPragma implements ParsedPragma {
  const ParsedDynModuleEntryPointPragma();
}

class ParsedVmSharedPragma implements ParsedPragma {
  const ParsedVmSharedPragma();
}

class ParsedVmDeeplyImmutablePragma implements ParsedPragma {
  const ParsedVmDeeplyImmutablePragma();
}

class ParsedVmInvisiblePragma implements ParsedPragma {
  const ParsedVmInvisiblePragma();
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

  ParsedEntryPointPragma? getEntryPointTypeFromOptions(
    Constant options,
    String pragmaName,
  ) {
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
            "@pragma('$pragmaName', ...) "
            "must be either 'get' or 'set' for fields "
            "or 'get' or 'call' for procedures.";
      }
    }
    return type != null ? ParsedEntryPointPragma(type) : null;
  }

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
      case vmEntryPointPragmaName:
        return getEntryPointTypeFromOptions(options, pragmaName);
      case vmExactResultTypePragmaName:
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
            (options.entries[0] as TypeLiteralConstant).type,
            true,
          );
        }
        throw "ERROR: Unsupported option to '$vmExactResultTypePragmaName' "
            "pragma: $options";
      case vmRecognizedPragmaName:
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
          throw "ERROR: Unsupported option to '$vmRecognizedPragmaName' "
              "pragma: $options";
        }
        return ParsedRecognized(type);
      case vmDisableUnboxedParametersPragmaName:
        return const ParsedDisableUnboxedParameters();
      case vmKeepNamePragmaName:
        return const ParsedKeepNamePragma();
      case vmPlatformConstPragmaName:
        return const ParsedPlatformConstPragma();
      case vmPlatformConstIfPragmaName:
        if (options is! BoolConstant) {
          throw "ERROR: Non-boolean option to '$vmPlatformConstIfPragmaName' "
              "pragma: $options";
        }
        return options.value ? const ParsedPlatformConstPragma() : null;
      case vmFfiNative:
        return const ParsedFfiNativePragma();
      case wasmEntryPointPragmaName:
        return const ParsedEntryPointPragma(PragmaEntryPointType.Default);
      case wasmExportPragmaName:
        // Exports are treated as entry points.
        return const ParsedEntryPointPragma(PragmaEntryPointType.Default);
      case dynModuleExtendablePragmaName:
        return const ParsedEntryPointPragma(PragmaEntryPointType.Extendable);
      case dynModuleImplicitlyExtendablePragmaName:
        return const ParsedEntryPointPragma(
          PragmaEntryPointType.ImplicitlyExtendable,
        );
      case dynModuleCanBeOverriddenPragmaName:
        return const ParsedEntryPointPragma(
          PragmaEntryPointType.CanBeOverridden,
        );
      case dynModuleCanBeUsedAsTypePragmaName:
        return const ParsedEntryPointPragma(
          PragmaEntryPointType.CanBeUsedAsType,
        );
      case dynModuleCallablePragmaName:
      case dynModuleImplicitlyCallablePragmaName:
        return getEntryPointTypeFromOptions(options, pragmaName);
      case dynModuleDynamicallyCallablePragmaName:
      case dynModuleImplicitlyDynamicallyCallablePragmaName:
        return const ParsedEntryPointPragma(
          PragmaEntryPointType.DynamicallyCallable,
        );
      case dynModuleEntryPointPragmaName:
        return const ParsedDynModuleEntryPointPragma();
      case vmSharedPragmaName:
        return const ParsedVmSharedPragma();
      case vmDeeplyImmutablePragmaName:
        return const ParsedVmDeeplyImmutablePragma();
      case vmInvisiblePragmaName:
        return const ParsedVmInvisiblePragma();
      default:
        return null;
    }
  }

  Iterable<R> parsedPragmas<R extends ParsedPragma>(
    Iterable<Expression> annotations,
  ) => annotations.map(parsePragma).whereType<R>();
}

/// Helper methods for accessing pragmas.
/// Should be used on kernel AST nodes only after all constants are evaluated.
extension AnnotatblePragmaHelpers on Annotatable {
  /// Returns true if this node is annotated with pragma [pragmaName].
  bool hasPragma(String pragmaName, CoreTypes coreTypes) {
    for (final annotation in annotations) {
      switch (annotation) {
        case ConstantExpression(:InstanceConstant constant)
            when constant.classNode == coreTypes.pragmaClass &&
                (constant.fieldValues[coreTypes.pragmaName.fieldReference]
                            as StringConstant)
                        .value ==
                    pragmaName:
          return true;
        case ConstantExpression(constant: UnevaluatedConstant()):
          throw 'Error: unevaluated constant $annotation';
        case ConstantExpression():
        case InvalidExpression():
          break;
        default:
          throw 'Error: non-constant annotation $annotation';
      }
    }
    return false;
  }
}

extension ClassPragmaHelpers on Class {
  /// Returns true if this class is annotated with 'vm:deeply-immutable' pragma.
  bool isDeeplyImmutable(CoreTypes coreTypes) =>
      hasPragma(vmDeeplyImmutablePragmaName, coreTypes);
}

extension FieldPragmaHelpers on Field {
  /// Returns true if this field is annotated with 'vm:shared' pragma.
  bool isShared(CoreTypes coreTypes) =>
      hasPragma(vmSharedPragmaName, coreTypes);
}

extension MemberPragmaHelpers on Member {
  /// Returns true if this member is annotated with 'vm:ffi:native' pragma.
  bool isFfiNative(CoreTypes coreTypes) => hasPragma(vmFfiNative, coreTypes);

  /// Returns true if this member is annotated with 'vm:invisible' pragma.
  bool isInvisible(CoreTypes coreTypes) =>
      hasPragma(vmInvisiblePragmaName, coreTypes);

  /// Returns true if this member is annotated with 'dyn-module:entry-point' pragma.
  bool isDynModuleEntryPoint(CoreTypes coreTypes) =>
      hasPragma(dynModuleEntryPointPragmaName, coreTypes);
}

extension FunctionDeclarationPragmaHelpers on FunctionDeclaration {
  /// Returns true if this local function is annotated with 'vm:invisible' pragma.
  bool isInvisible(CoreTypes coreTypes) =>
      variable.hasPragma(vmInvisiblePragmaName, coreTypes);
}
