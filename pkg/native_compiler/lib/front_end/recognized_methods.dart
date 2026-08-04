// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:cfg/front_end/recognized_methods.dart';
import 'package:cfg/ir/constant_value.dart';
import 'package:cfg/ir/field.dart';
import 'package:cfg/ir/flow_graph_builder.dart';
import 'package:cfg/ir/functions.dart';
import 'package:cfg/ir/global_context.dart';
import 'package:cfg/ir/instructions.dart';
import 'package:kernel/ast.dart' as ast;
import 'package:kernel/external_name.dart' show getExternalName;
import 'package:native_compiler/runtime/constant_objects.dart';
import 'package:native_compiler/runtime/object_layout.dart';
import 'package:native_compiler/runtime/vm_defs.dart';
import 'package:vm/modular/transformations/pragma.dart';

/// Build IR for native methods.
void buildNativeMethod(
  FlowGraphBuilder builder,
  FunctionRegistry functionRegistry,
  CFunction function,
) {
  // Reserve extra argument slot for return value.
  builder.addNullConstant();

  final functionNode = function.functionNode!;
  final argsShape = functionRegistry.getArgumentsShape(
    (function.hasReceiverParameter ? 1 : 0) +
        functionNode.positionalParameters.length +
        1,
    types: function.numberOfFunctionTypeParameters,
    named: functionNode.namedParameters.map((p) => p.parameterName).toList(),
  );
  builder.addExternalCall(
    function,
    function.numberOfParameters + 1,
    argsShape,
    function.returnType,
  );
  builder.addReturn();
}

/// Build IR for static getters returning constants.
void buildConstantGetter(FlowGraphBuilder builder, ConstantValue value) {
  builder.addConstant(value);
  builder.addReturn();
}

/// Build IR for instance field getters.
void buildInstanceGetter(FlowGraphBuilder builder, CField field) {
  builder.addLoadInstanceField(field, checkInitialized: field.isLate);
  builder.addReturn();
}

/// Build IR for instance field setters.
void buildInstanceSetter(FlowGraphBuilder builder, CField field) {
  builder.addStoreInstanceField(
    field,
    checkNotInitialized: field.isLate && field.isFinal,
  );
  builder.addNullConstant();
  builder.addReturn();
}

/// Build IR for unary int operations
void buildUnaryIntOp(FlowGraphBuilder builder, UnaryIntOpcode op) {
  builder.addUnaryIntOp(op);
  builder.addReturn();
}

/// Build IR for unimplemented methods marked with 'vm:recognized' pragma.
void buildUnimplementedRecognizedMethod(
  FlowGraphBuilder builder,
  CFunction function,
) {
  // Drop parameters.
  for (var i = 0, n = function.numberOfParameters; i < n; ++i) {
    builder.pop();
  }
  builder.addConstant(
    ConstantValue.fromString('Unimplemented recognized method: $function'),
  );
  builder.addThrow(.exception, 1);
}

/// VM-specific recognized methods.
final class VmRecognizedMethods(
  final FunctionRegistry functionRegistry,
  final ObjectLayout objectLayout,
) extends CommonRecognizedMethods {
  final coreTypes = GlobalContext.instance.coreTypes;

  @override
  BuildIR? getRecognizedFunctionBody(CFunction function) {
    final member = function.member;
    if (member.isRecognized(coreTypes)) {
      final builder = _recognizedMembers[member];
      if (builder != null) {
        return builder;
      }
      if (member.isExternal) {
        return (FlowGraphBuilder builder) {
          buildUnimplementedRecognizedMethod(builder, function);
        };
      }
    }
    if (member.isExternal) {
      if (getExternalName(coreTypes, member) != null) {
        return (FlowGraphBuilder builder) {
          buildNativeMethod(builder, functionRegistry, function);
        };
      }
    }
    return super.getRecognizedFunctionBody(function);
  }

  late final _recognizedMembers = <ast.Member, BuildIR>{
    // dart:core
    index.getProcedure(
      'dart:core',
      '_Smi',
      'get:hashCode',
    ): (FlowGraphBuilder builder) {
      buildUnaryIntOp(builder, .hash);
    },
    index.getProcedure(
      'dart:core',
      '_Smi',
      'get:bitLength',
    ): (FlowGraphBuilder builder) {
      buildUnaryIntOp(builder, .bitLength);
    },
    index.getProcedure(
      'dart:core',
      '_Mint',
      'get:hashCode',
    ): (FlowGraphBuilder builder) {
      buildUnaryIntOp(builder, .hash);
    },
    index.getProcedure(
      'dart:core',
      '_Mint',
      'get:bitLength',
    ): (FlowGraphBuilder builder) {
      buildUnaryIntOp(builder, .bitLength);
    },
    index.getProcedure(
      'dart:core',
      '_Array',
      'get:length',
    ): (FlowGraphBuilder builder) {
      buildInstanceGetter(builder, objectLayout.Array_length);
    },

    // dart:_compact_hash
    index.getTopLevelProcedure(
      'dart:_compact_hash',
      'get:_uninitializedIndex',
    ): (FlowGraphBuilder builder) {
      buildConstantGetter(
        builder,
        ConstantValue(RuntimeConstantObject(.uninitializedIndex)),
      );
    },
    index.getTopLevelProcedure(
      'dart:_compact_hash',
      'get:_uninitializedData',
    ): (FlowGraphBuilder builder) {
      buildConstantGetter(
        builder,
        ConstantValue(RuntimeConstantObject(.uninitializedData)),
      );
    },
    index.getProcedure(
      'dart:_compact_hash',
      '_LinkedHashBase',
      'get:_index',
    ): (FlowGraphBuilder builder) {
      buildInstanceGetter(builder, objectLayout.LinkedHashBase_index);
    },
    index.getProcedure(
      'dart:_compact_hash',
      '_LinkedHashBase',
      'set:_index',
    ): (FlowGraphBuilder builder) {
      buildInstanceSetter(builder, objectLayout.LinkedHashBase_index);
    },
    index.getProcedure(
      'dart:_compact_hash',
      '_LinkedHashBase',
      'get:_hashMask',
    ): (FlowGraphBuilder builder) {
      buildInstanceGetter(builder, objectLayout.LinkedHashBase_hashMask);
    },
    index.getProcedure(
      'dart:_compact_hash',
      '_LinkedHashBase',
      'set:_hashMask',
    ): (FlowGraphBuilder builder) {
      buildInstanceSetter(builder, objectLayout.LinkedHashBase_hashMask);
    },
    index.getProcedure(
      'dart:_compact_hash',
      '_LinkedHashBase',
      'get:_data',
    ): (FlowGraphBuilder builder) {
      buildInstanceGetter(builder, objectLayout.LinkedHashBase_data);
    },
    index.getProcedure(
      'dart:_compact_hash',
      '_LinkedHashBase',
      'set:_data',
    ): (FlowGraphBuilder builder) {
      buildInstanceSetter(builder, objectLayout.LinkedHashBase_data);
    },
    index.getProcedure(
      'dart:_compact_hash',
      '_LinkedHashBase',
      'get:_usedData',
    ): (FlowGraphBuilder builder) {
      buildInstanceGetter(builder, objectLayout.LinkedHashBase_usedData);
    },
    index.getProcedure(
      'dart:_compact_hash',
      '_LinkedHashBase',
      'set:_usedData',
    ): (FlowGraphBuilder builder) {
      buildInstanceSetter(builder, objectLayout.LinkedHashBase_usedData);
    },
    index.getProcedure(
      'dart:_compact_hash',
      '_LinkedHashBase',
      'get:_deletedKeys',
    ): (FlowGraphBuilder builder) {
      buildInstanceGetter(builder, objectLayout.LinkedHashBase_deletedKeys);
    },
    index.getProcedure(
      'dart:_compact_hash',
      '_LinkedHashBase',
      'set:_deletedKeys',
    ): (FlowGraphBuilder builder) {
      buildInstanceSetter(builder, objectLayout.LinkedHashBase_deletedKeys);
    },

    // dart:_internal
    index.getTopLevelProcedure(
      'dart:_internal',
      'get:has63BitSmis',
    ): (FlowGraphBuilder builder) {
      final totalSmiBits =
          smiBits(objectLayout.compressedWordSize) + 1; // Including sign bit.
      final has63BitSmis = totalSmiBits >= 63;
      buildConstantGetter(builder, ConstantValue.fromBool(has63BitSmis));
    },
  };
}
