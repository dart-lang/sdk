// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:cfg/ir/types.dart';
import 'package:kernel/ast.dart' as ast;

/// Instance or static field used in CFG IR.
extension type CField(ast.Field _raw) {
  bool get isStatic => _raw.isStatic;
  bool get isLate => _raw.isLate;
  bool get isFinal => _raw.isFinal;
  bool get hasInitializer => _raw.initializer != null;
  CType get type => CType.fromStaticType(_raw.type);
  ast.Class get enclosingClass => _raw.enclosingClass!;
  ast.Field get astField => _raw;
}
