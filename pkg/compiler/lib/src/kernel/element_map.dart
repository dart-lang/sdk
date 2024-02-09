// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// TODO(joshualitt): Merge the contents of element_map_impl.dart into this file.
export 'element_map_impl.dart';
import 'package:kernel/ast.dart' as ir;

/// Kinds of foreign functions.
enum ForeignKind {
  JS,
  JS_BUILTIN,
  JS_EMBEDDED_GLOBAL,
  JS_INTERCEPTOR_CONSTANT,
  NONE,
}

// Members which dart2js ignores.
bool memberIsIgnorable(ir.Member node, {ir.Class? cls}) {
  if (node is! ir.Procedure) return false;
  ir.Procedure member = node;
  switch (member.stubKind) {
    case ir.ProcedureStubKind.Regular:
    case ir.ProcedureStubKind.ConcreteForwardingStub:
    case ir.ProcedureStubKind.NoSuchMethodForwarder:
      return false;
    case ir.ProcedureStubKind.AbstractForwardingStub:
    case ir.ProcedureStubKind.MemberSignature:
    case ir.ProcedureStubKind.AbstractMixinStub:
    case ir.ProcedureStubKind.ConcreteMixinStub:
    case ir.ProcedureStubKind.RepresentationField:
      return true;
  }
}
