// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:cfg/front_end/recognized_methods.dart';
import 'package:cfg/ir/flow_graph_builder.dart';
import 'package:cfg/ir/functions.dart';
import 'package:cfg/ir/global_context.dart';
import 'package:kernel/external_name.dart' show getExternalName;

class BuildNativeMethodIR(
  final FunctionRegistry functionRegistry,
  final CFunction function,
) {
  void buildIR(FlowGraphBuilder builder) {
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
}

/// VM-specific recognized methods.
final class VmRecognizedMethods(final FunctionRegistry functionRegistry)
    extends CommonRecognizedMethods {
  final coreTypes = GlobalContext.instance.coreTypes;

  @override
  BuildIR? getRecognizedFunctionBody(CFunction function) {
    final member = function.member;
    if (member.isExternal) {
      if (getExternalName(coreTypes, member) != null) {
        return BuildNativeMethodIR(functionRegistry, function).buildIR;
      }
    }
    return super.getRecognizedFunctionBody(function);
  }
}
