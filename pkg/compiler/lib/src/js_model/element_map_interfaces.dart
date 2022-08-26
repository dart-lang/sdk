// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:compiler/src/js_model/element_map_migrated.dart';
import 'package:kernel/ast.dart' as ir;

import '../elements/entities.dart';
import '../elements/types.dart';

// TODO(48820): Remove this interface when nnbd migration is done.
abstract class JsToElementMap {
  DartType getDartType(ir.DartType type);

  MemberDefinition getMemberDefinition(MemberEntity member);
}
