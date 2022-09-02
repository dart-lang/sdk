// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart' as ir;

import '../elements/entities.dart';
import '../ir/closure.dart';
import 'closure.dart';
import 'elements.dart';

abstract class JsClosedWorldBuilder {
  JsClosureClassInfo buildClosureClass(
      MemberEntity member,
      ir.FunctionNode originalClosureFunctionNode,
      JLibrary enclosingLibrary,
      Map<ir.VariableDeclaration, JRecordField> boxedVariables,
      KernelScopeInfo info,
      {required bool createSignatureMethod});
}
