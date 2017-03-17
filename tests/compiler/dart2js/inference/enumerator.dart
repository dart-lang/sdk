// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:compiler/src/elements/elements.dart';
import 'package:compiler/src/resolution/access_semantics.dart';
import 'package:compiler/src/resolution/send_structure.dart';
import 'package:compiler/src/resolution/tree_elements.dart';
import 'package:compiler/src/tree/nodes.dart' as ast;

enum IdKind { element, node }

/// Id for a code point or element with type inference information.
abstract class Id {
  IdKind get kind;
}

/// Id for an element with type inference information.
// TODO(johnniwinther): Support local variables, functions and parameters.
class ElementId implements Id {
  final String className;
  final String memberName;

  factory ElementId(String text) {
    int dotPos = text.indexOf('.');
    if (dotPos != -1) {
      return new ElementId.internal(
          text.substring(dotPos + 1), text.substring(0, dotPos));
    } else {
      return new ElementId.internal(text);
    }
  }

  ElementId.internal(this.memberName, [this.className]);

  int get hashCode => className.hashCode * 13 + memberName.hashCode * 17;

  bool operator ==(other) {
    if (identical(this, other)) return true;
    if (other is! ElementId) return false;
    return className == other.className && memberName == other.memberName;
  }

  IdKind get kind => IdKind.element;

  String toString() =>
      className != null ? '$className.$memberName' : memberName;
}

/// Id for a code point with type inference information.
// TODO(johnniwinther): Create an [NodeId]-based equivalence with the kernel IR.
class NodeId implements Id {
  final int value;

  const NodeId(this.value);

  int get hashCode => value.hashCode;

  bool operator ==(other) {
    if (identical(this, other)) return true;
    if (other is! NodeId) return false;
    return value == other.value;
  }

  IdKind get kind => IdKind.node;

  String toString() => value.toString();
}

abstract class AstEnumeratorMixin {
  TreeElements get elements;

  ElementId computeElementId(AstElement element) {
    String memberName = element.name;
    if (element.isSetter) {
      memberName += '=';
    }
    String className = element.enclosingClass?.name;
    return new ElementId.internal(memberName, className);
  }

  NodeId computeAccessId(ast.Send node, AccessSemantics access) {
    switch (access.kind) {
      case AccessKind.DYNAMIC_PROPERTY:
        return new NodeId(node.selector.getBeginToken().charOffset);
      default:
        return new NodeId(node.getBeginToken().charOffset);
    }
  }

  NodeId computeNodeId(ast.Send node) {
    var sendStructure = elements.getSendStructure(node);
    if (sendStructure == null) return null;
    switch (sendStructure.kind) {
      case SendStructureKind.GET:
      case SendStructureKind.INVOKE:
      case SendStructureKind.INCOMPATIBLE_INVOKE:
        return computeAccessId(node, sendStructure.semantics);
      default:
        return new NodeId(node.getBeginToken().charOffset);
    }
  }
}
