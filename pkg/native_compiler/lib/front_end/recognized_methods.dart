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
import 'package:cfg/ir/types.dart';
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
}

/// Build IR for static getters returning constants.
void buildConstantGetter(FlowGraphBuilder builder, ConstantValue value) {
  builder.addConstant(value);
}

/// Build IR for instance field getters.
void buildInstanceGetter(FlowGraphBuilder builder, CField field) {
  builder.addLoadInstanceField(field, checkInitialized: field.isLate);
}

/// Build IR for instance field setters.
void buildInstanceSetter(FlowGraphBuilder builder, CField field) {
  builder.addStoreInstanceField(
    field,
    checkNotInitialized: field.isLate && field.isFinal,
  );
  builder.addNullConstant();
}

/// Build IR for unary int operations
void buildUnaryIntOp(FlowGraphBuilder builder, UnaryIntOpcode op) {
  builder.addUnaryIntOp(op);
}

/// Build IR for comparison operations
void buildComparisonOp(FlowGraphBuilder builder, ComparisonOpcode op) {
  builder.addComparison(op);
}

/// Build IR for indexed load of an array element.
void buildArrayElementGetter(
  FlowGraphBuilder builder,
  ArrayKind kind,
  CField lengthField,
  CType elemType, {
  CField? indirectDataField,
}) {
  final index = builder.pop();
  final array = builder.pop();
  builder.push(array);
  if (indirectDataField != null) {
    builder.addLoadInstanceField(indirectDataField);
  }
  builder.push(index);
  builder.push(array);
  builder.addLoadInstanceField(lengthField);
  builder.addIndexCheck();
  builder.addLoadArrayElement(kind, elemType);
}

/// Build IR for indexed store to an array element.
void buildArrayElementSetter(
  FlowGraphBuilder builder,
  ArrayKind kind,
  CField lengthField, {
  CField? indirectDataField,
}) {
  final value = builder.pop();
  final index = builder.pop();
  final array = builder.pop();
  builder.push(array);
  if (indirectDataField != null) {
    builder.addLoadInstanceField(indirectDataField);
  }
  builder.push(index);
  builder.push(array);
  builder.addLoadInstanceField(lengthField);
  builder.addIndexCheck();
  builder.push(value);
  builder.addStoreArrayElement(kind);
  builder.addNullConstant();
}

/// Build IR for factory constructors of typed data lists and built-in _List.
void buildArrayFactory(
  FlowGraphBuilder builder,
  ArrayKind kind,
  ast.Class cls,
) {
  final hasTypeArguments = kind == .fixedLengthList;
  final coreTypes = GlobalContext.instance.coreTypes;
  final type = StaticType(
    hasTypeArguments
        ? coreTypes.thisInterfaceType(cls, .nonNullable)
        : coreTypes.nonNullableRawType(cls),
  );
  builder.addAllocateArray(kind, type, hasTypeArguments: hasTypeArguments);
}

/// Build IR for _GrowableList._withData factory constructor.
void buildGrowableListWithData(
  FlowGraphBuilder builder,
  ObjectLayout objectLayout,
  ast.Class cls,
) {
  final data = builder.pop();
  final typeArgs = builder.pop();
  final coreTypes = GlobalContext.instance.coreTypes;
  final type = StaticType(coreTypes.thisInterfaceType(cls, .nonNullable));
  final obj = builder.addAllocateObject(type, typeArguments: typeArgs);
  builder.push(obj);
  builder.push(data);
  builder.addStoreInstanceField(objectLayout.GrowableList_data);
  builder.push(obj);
  builder.addIntConstant(0);
  builder.addStoreInstanceField(objectLayout.GrowableList_length);
}

/// Build IR for _GrowableList._capacity getter.
void buildGrowableListCapacity(
  FlowGraphBuilder builder,
  ObjectLayout objectLayout,
) {
  builder.addLoadInstanceField(objectLayout.GrowableList_data);
  builder.addLoadInstanceField(objectLayout.Array_length);
}

/// Build IR for ThreadLocal._hasValue.
void buildThreadLocalHasValue(
  FlowGraphBuilder builder,
  ObjectLayout objectLayout,
) {
  // if (id >= Thread.threadLocals.length) return false;
  final id = builder.stackTop;
  final array = builder.addLoadExternalField(
    objectLayout.Thread_threadLocals,
    hasObject: false,
  );
  builder.addLoadInstanceField(objectLayout.Array_length);
  builder.addComparison(.intGreaterOrEqual);

  final failBlock = builder.newTargetBlock();
  final continueBlock = builder.newTargetBlock();
  builder.addBranch(failBlock, continueBlock);

  // if (Thread.threadLocals[id] == sentinel) return false;
  builder.startBlock(continueBlock);
  builder.push(array);
  builder.push(id);
  builder.addLoadArrayElement(.fixedLengthList, const LateValueType());
  builder.addSentinelConstant();
  builder.addComparison(.equal);

  final failBlock2 = builder.newTargetBlock();
  final continueBlock2 = builder.newTargetBlock();
  builder.addBranch(failBlock2, continueBlock2);

  // Otherwise return true;
  builder.startBlock(continueBlock2);
  builder.addBoolConstant(true);
  builder.addReturn();

  final returnFalseBlock = builder.newJoinBlock();
  builder.startBlock(failBlock);
  builder.addGoto(returnFalseBlock);
  builder.startBlock(failBlock2);
  builder.addGoto(returnFalseBlock);

  builder.startBlock(returnFalseBlock);
  builder.addBoolConstant(false);
  builder.addReturn();
}

/// Build IR for ThreadLocal._getValue.
void buildThreadLocalGetValue(
  FlowGraphBuilder builder,
  ObjectLayout objectLayout,
) {
  // return Thread.threadLocals[id];
  final id = builder.pop();
  builder.addLoadExternalField(
    objectLayout.Thread_threadLocals,
    hasObject: false,
  );
  builder.push(id);
  builder.addLoadArrayElement(.fixedLengthList, const LateValueType());
  builder.addTypeCast(const TopType(), isChecked: false);
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

extension on ArrayKind {
  String get elementName => switch (this) {
    .int8List => 'Int8',
    .uint8List => 'Uint8',
    .uint8ClampedList => 'Uint8Clamped',
    .int16List => 'Int16',
    .uint16List => 'Uint16',
    .int32List => 'Int32',
    .uint32List => 'Uint32',
    .int64List => 'Int64',
    .uint64List => 'Uint64',
    .fixedLengthList => throw 'ArrayKind.elementName is not defined for $this',
  };
}

/// VM-specific recognized methods.
final class VmRecognizedMethods(
  final FunctionRegistry functionRegistry,
  final ObjectLayout objectLayout,
) extends CommonRecognizedMethods {
  final coreTypes = GlobalContext.instance.coreTypes;

  @override
  BuildIR? getRecognizedFunctionBody(CFunction function) {
    final commonBuilder = super.getRecognizedFunctionBody(function);
    if (commonBuilder != null) {
      return commonBuilder;
    }
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
    return null;
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
    // TODO: implement 'operator ==' instead of '_equalToInteger'
    index.getProcedure(
      'dart:core',
      '_IntegerImplementation',
      '_equalToInteger',
    ): (FlowGraphBuilder builder) {
      buildComparisonOp(builder, .intEqual);
    },
    index.getProcedure(
      'dart:core',
      '_Array',
      'get:length',
    ): (FlowGraphBuilder builder) {
      buildInstanceGetter(builder, objectLayout.Array_length);
    },
    index.getProcedure(
      'dart:core',
      '_Array',
      '[]',
    ): (FlowGraphBuilder builder) {
      buildArrayElementGetter(
        builder,
        .fixedLengthList,
        objectLayout.Array_length,
        StaticType(
          ast.TypeParameterType.withDefaultNullability(
            index.getClass('dart:core', '_Array').typeParameters.single,
          ),
        ),
      );
    },
    index.getProcedure('dart:core', '_List', ''): (FlowGraphBuilder builder) {
      buildArrayFactory(
        builder,
        .fixedLengthList,
        index.getClass('dart:core', '_List'),
      );
    },
    index.getProcedure(
      'dart:core',
      '_List',
      '[]=',
    ): (FlowGraphBuilder builder) {
      buildArrayElementSetter(
        builder,
        .fixedLengthList,
        objectLayout.Array_length,
      );
    },
    index.getProcedure(
      'dart:core',
      '_GrowableList',
      '_withData',
    ): (FlowGraphBuilder builder) {
      buildGrowableListWithData(
        builder,
        objectLayout,
        index.getClass('dart:core', '_GrowableList'),
      );
    },
    index.getProcedure(
      'dart:core',
      '_GrowableList',
      'get:_emptyList',
    ): (FlowGraphBuilder builder) {
      buildConstantGetter(
        builder,
        ConstantValue(RuntimeConstantObject(.mutableEmptyList)),
      );
    },
    index.getProcedure(
      'dart:core',
      '_GrowableList',
      'get:length',
    ): (FlowGraphBuilder builder) {
      buildInstanceGetter(builder, objectLayout.GrowableList_length);
    },
    index.getProcedure(
      'dart:core',
      '_GrowableList',
      '_setLength',
    ): (FlowGraphBuilder builder) {
      buildInstanceSetter(builder, objectLayout.GrowableList_length);
    },
    index.getProcedure(
      'dart:core',
      '_GrowableList',
      'get:_capacity',
    ): (FlowGraphBuilder builder) {
      buildGrowableListCapacity(builder, objectLayout);
    },
    index.getProcedure(
      'dart:core',
      '_GrowableList',
      '_setData',
    ): (FlowGraphBuilder builder) {
      buildInstanceSetter(builder, objectLayout.GrowableList_data);
    },
    index.getProcedure(
      'dart:core',
      '_GrowableList',
      '[]',
    ): (FlowGraphBuilder builder) {
      buildArrayElementGetter(
        builder,
        .fixedLengthList, // Backing store array.
        objectLayout.GrowableList_length,
        StaticType(
          ast.TypeParameterType.withDefaultNullability(
            index.getClass('dart:core', '_GrowableList').typeParameters.single,
          ),
        ),
        indirectDataField: objectLayout.GrowableList_data,
      );
    },
    index.getProcedure(
      'dart:core',
      '_GrowableList',
      '[]=',
    ): (FlowGraphBuilder builder) {
      buildArrayElementSetter(
        builder,
        .fixedLengthList, // Backing store array.
        objectLayout.GrowableList_length,
        indirectDataField: objectLayout.GrowableList_data,
      );
    },
    index.getProcedure(
      'dart:core',
      '_GrowableList',
      '_setIndexed',
    ): (FlowGraphBuilder builder) {
      buildArrayElementSetter(
        builder,
        .fixedLengthList, // Backing store array.
        objectLayout.GrowableList_length,
        indirectDataField: objectLayout.GrowableList_data,
      );
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

    // dart:isolate
    index.getProcedure(
      'dart:isolate',
      '_RawReceivePort',
      'get:_handler',
    ): (FlowGraphBuilder builder) {
      buildInstanceGetter(builder, objectLayout.RawReceivePort_handler);
    },
    index.getProcedure(
      'dart:isolate',
      '_RawReceivePort',
      'set:_handler',
    ): (FlowGraphBuilder builder) {
      buildInstanceSetter(builder, objectLayout.RawReceivePort_handler);
    },
    index.getProcedure(
      'dart:isolate',
      '_RawReceivePort',
      'get:sendPort',
    ): (FlowGraphBuilder builder) {
      buildInstanceGetter(builder, objectLayout.RawReceivePort_sendPort);
    },

    // dart:typed_data
    index.getProcedure(
      'dart:typed_data',
      '_TypedListBase',
      'get:length',
    ): (FlowGraphBuilder builder) {
      buildInstanceGetter(builder, objectLayout.TypedListBase_length);
    },

    for (ArrayKind arrayKind in [
      .int8List,
      .uint8List,
      .uint8ClampedList,
      .int16List,
      .uint16List,
      .int32List,
      .uint32List,
      .int64List,
      .uint64List,
    ])
      index.getProcedure(
        'dart:typed_data',
        '_${arrayKind.elementName}List',
        '[]',
      ): (FlowGraphBuilder builder) {
        buildArrayElementGetter(
          builder,
          arrayKind,
          objectLayout.TypedListBase_length,
          const IntType(),
        );
      },

    for (ArrayKind arrayKind in [
      .int8List,
      .uint8List,
      .uint8ClampedList,
      .int16List,
      .uint16List,
      .int32List,
      .uint32List,
      .int64List,
      .uint64List,
    ])
      index.getProcedure(
        'dart:typed_data',
        '_${arrayKind.elementName}List',
        '[]=',
      ): (FlowGraphBuilder builder) {
        buildArrayElementSetter(
          builder,
          arrayKind,
          objectLayout.TypedListBase_length,
        );
      },

    for (ArrayKind arrayKind in [
      .int8List,
      .uint8List,
      .uint8ClampedList,
      .int16List,
      .uint16List,
      .int32List,
      .uint32List,
      .int64List,
      .uint64List,
    ])
      index.getProcedure(
        'dart:typed_data',
        '${arrayKind.elementName}List',
        '',
      ): (FlowGraphBuilder builder) {
        buildArrayFactory(
          builder,
          arrayKind,
          index.getClass('dart:typed_data', '${arrayKind.elementName}List'),
        );
      },

    // dart:_vm
    index.getProcedure(
      'dart:_vm',
      'ThreadLocal',
      '_hasValue',
    ): (FlowGraphBuilder builder) {
      buildThreadLocalHasValue(builder, objectLayout);
    },

    index.getProcedure(
      'dart:_vm',
      'ThreadLocal',
      '_getValue',
    ): (FlowGraphBuilder builder) {
      buildThreadLocalGetValue(builder, objectLayout);
    },
  };
}
