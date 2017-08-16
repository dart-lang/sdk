// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:compiler/src/elements/elements.dart';
import 'package:compiler/src/resolution/access_semantics.dart';
import 'package:compiler/src/resolution/send_structure.dart';
import 'package:compiler/src/resolution/tree_elements.dart';
import 'package:compiler/src/tree/nodes.dart' as ast;
import 'package:kernel/ast.dart' as ir;

enum IdKind {
  element,
  node,
}

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

  String toString() => '$kind:$value';
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
        return null;
    }
  }

  NodeId computeNodeId(ast.Node node, AstElement element) {
    if (element != null && element.isLocal) {
      return new NodeId(node.getBeginToken().charOffset);
    } else if (node is ast.Send) {
      dynamic sendStructure = elements.getSendStructure(node);
      if (sendStructure == null) return null;
      switch (sendStructure.kind) {
        case SendStructureKind.GET:
        case SendStructureKind.INVOKE:
          return computeAccessId(node, sendStructure.semantics);
        default:
      }
    }
    return null;
  }
}

/// Visitor that finds the AST node or element corresponding to an [Id].
class AstIdFinder extends ast.Visitor with AstEnumeratorMixin {
  Id soughtId;
  var /*AstElement|ast.Node*/ found;
  final TreeElements elements;

  AstIdFinder(this.elements);

  /// Visits the subtree of [root] returns the [ast.Node] or [AstElement]
  /// corresponding to [id].
  /*AstElement|ast.Node*/ find(ast.Node root, Id id) {
    soughtId = id;
    root.accept(this);
    var result = found;
    found = null;
    return result;
  }

  visit(ast.Node node) {
    if (found == null) {
      node?.accept(this);
    }
  }

  visitNode(ast.Node node) {
    if (found == null) {
      node.visitChildren(this);
    }
  }

  visitSend(ast.Send node) {
    if (found == null) {
      visitNode(node);
      Id id = computeNodeId(node, null);
      if (id == soughtId) {
        found = node;
      }
    }
  }

  visitVariableDefinitions(ast.VariableDefinitions node) {
    if (found == null) {
      for (ast.Node child in node.definitions) {
        AstElement element = elements[child];
        if (element != null) {
          Id id;
          if (element is FieldElement) {
            id = computeElementId(element);
          } else {
            id = computeNodeId(child, element);
          }
          if (id == soughtId) {
            found = element;
            return;
          }
        }
      }
      visitNode(node);
    }
  }

  visitFunctionExpression(ast.FunctionExpression node) {
    if (found == null) {
      AstElement element = elements.getFunctionDefinition(node);
      if (element != null) {
        Id id;
        if (element is LocalFunctionElement) {
          id = computeNodeId(node, element);
        } else {
          id = computeElementId(element);
        }
        if (id == soughtId) {
          found = element;
          return;
        }
      }
      visitNode(node);
    }
  }
}

abstract class IrEnumeratorMixin {
  Id computeElementId(ir.Member node) {
    String className;
    if (node.enclosingClass != null) {
      className = node.enclosingClass.name;
    }
    String memberName = node.name.name;
    if (node is ir.Procedure && node.kind == ir.ProcedureKind.Setter) {
      memberName += '=';
    }
    return new ElementId.internal(memberName, className);
  }

  Id computeNodeId(ir.TreeNode node) {
    if (node is ir.MethodInvocation) {
      assert(node.fileOffset != ir.TreeNode.noOffset);
      return new NodeId(node.fileOffset);
    } else if (node is ir.PropertyGet) {
      assert(node.fileOffset != ir.TreeNode.noOffset);
      return new NodeId(node.fileOffset);
    } else if (node is ir.VariableDeclaration) {
      assert(node.fileOffset != ir.TreeNode.noOffset);
      return new NodeId(node.fileOffset);
      // TODO(johnniwinther): Enable when function expressions have offsets.
      /*} else if (node is ir.FunctionExpression) {
      assert(node.fileOffset != ir.TreeNode.noOffset);
      return new NodeId(node.fileOffset);*/
    } else if (node is ir.FunctionDeclaration) {
      assert(node.fileOffset != ir.TreeNode.noOffset);
      return new NodeId(node.fileOffset);
    }
    return null;
  }
}

/// Visitor that finds the IR node corresponding to an [Id].
class IrIdFinder extends ir.Visitor with IrEnumeratorMixin {
  Id soughtId;
  ir.Node found;

  /// Visits the subtree of [root] returns the [ir.Node] corresponding to [id].
  ir.Node find(ir.Node root, Id id) {
    soughtId = id;
    root.accept(this);
    var result = found;
    found = null;
    return result;
  }

  defaultTreeNode(ir.TreeNode node) {
    if (found == null) {
      Id id = computeNodeId(node);
      if (id == soughtId) {
        found = node;
        return;
      }
      node.visitChildren(this);
    }
  }

  defaultMember(ir.Member node) {
    if (found == null) {
      Id id = computeElementId(node);
      if (id == soughtId) {
        found = node;
        return;
      }
      defaultTreeNode(node);
    }
  }
}
