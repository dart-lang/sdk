// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:compiler/src/js_model/element_map_migrated.dart';
import 'package:kernel/ast.dart' as ir;

import '../common/elements.dart';
import '../constants/values.dart';
import '../elements/entities.dart';
import '../elements/types.dart';
import '../ir/element_map.dart';

// TODO(48820): Remove this interface when nnbd migration is done.
abstract class JsToElementMap {
  JElementEnvironment get elementEnvironment;
  DartTypes get types;
  ConstantValue getConstantValue(
      ir.Member memberContext, ir.Expression expression,
      {bool requireConstant = true, bool implicitNull = false});
  DartType getDartType(ir.DartType type);

  MemberEntity getMember(ir.Member node);
  MemberDefinition getMemberDefinition(MemberEntity member);
  ConstantValue getRequiredSentinelConstantValue();
}

abstract class JsKernelToElementMap implements JsToElementMap, IrToElementMap {}
