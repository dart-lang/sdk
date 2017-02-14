// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:compiler/src/resolution/access_semantics.dart';
import 'package:compiler/src/resolution/send_structure.dart';
import 'package:compiler/src/resolution/tree_elements.dart';
import 'package:compiler/src/tree/nodes.dart' as ast;

/// Id for a code point with type inference information.
// TODO(johnniwinther): Create an [Id]-based equivalence with the kernel IR.
class Id {
  final int value;

  const Id(this.value);

  int get hashCode => value.hashCode;

  bool operator ==(other) {
    if (identical(this, other)) return true;
    if (other is! Id) return false;
    return value == other.value;
  }

  String toString() => value.toString();
}

abstract class AstEnumeratorMixin {
  TreeElements get elements;

  Id computeAccessId(ast.Send node, AccessSemantics access) {
    switch (access.kind) {
      case AccessKind.DYNAMIC_PROPERTY:
        return new Id(node.selector.getBeginToken().charOffset);
      default:
        return new Id(node.getBeginToken().charOffset);
    }
  }

  Id computeId(ast.Send node) {
    var sendStructure = elements.getSendStructure(node);
    if (sendStructure == null) return null;
    switch (sendStructure.kind) {
      case SendStructureKind.GET:
      case SendStructureKind.INVOKE:
      case SendStructureKind.INCOMPATIBLE_INVOKE:
        return computeAccessId(node, sendStructure.semantics);
      default:
        return new Id(node.getBeginToken().charOffset);
    }
  }
}
