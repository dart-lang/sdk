// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:compiler/src/js_model/element_map_migrated.dart';
import 'package:kernel/ast.dart' as ir;

import '../common/elements.dart';
import '../constants/values.dart';
import '../elements/entities.dart';
import '../elements/types.dart';
import '../ir/closure.dart';
import '../ir/element_map.dart';
import '../native/behavior.dart';
import '../universe/selector.dart';
import 'closure_migrated.dart';

// TODO(48820): Remove this interface when nnbd migration is done.
abstract class JsToElementMap {
  JCommonElements get commonElements;
  JElementEnvironment get elementEnvironment;
  DartTypes get types;
  ConstantValue? getConstantValue(
      ir.Member memberContext, ir.Expression? expression,
      {bool requireConstant = true, bool implicitNull = false});
  DartType getDartType(ir.DartType type);

  Selector getSelector(ir.Expression node);
  ConstructorEntity getConstructor(ir.Member node);
  FunctionEntity getMethod(ir.Procedure node);
  MemberEntity getMember(ir.Member node);
  MemberDefinition getMemberDefinition(MemberEntity member);
  ConstantValue getRequiredSentinelConstantValue();

  Map<ir.VariableDeclaration, JContextField> makeContextContainer(
      KernelScopeInfo info, MemberEntity member);
  NativeBehavior getNativeBehaviorForJsCall(ir.StaticInvocation node);
}

abstract class JsKernelToElementMap implements JsToElementMap, IrToElementMap {}
