// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Source information system mapping that attempts a semantic mapping between
/// offsets of JavaScript code points to offsets of Dart code points.

library dart2js.source_information.kernel;

import 'package:kernel/ast.dart' as ir;
import '../elements/entities.dart';
import '../kernel/element_map.dart';
import '../js_model/js_strategy.dart';
import 'source_information.dart';
import 'position_information.dart';

class KernelSourceInformationStrategy
    extends AbstractPositionSourceInformationStrategy<ir.Node> {
  final JsBackendStrategy _backendStrategy;

  const KernelSourceInformationStrategy(this._backendStrategy);

  @override
  SourceInformationBuilder<ir.Node> createBuilderForContext(
      MemberEntity member) {
    return new KernelSourceInformationBuilder(
        _backendStrategy.elementMap, member);
  }
}

/// [SourceInformationBuilder] that generates [PositionSourceInformation] from
/// Kernel nodes.
class KernelSourceInformationBuilder
    implements SourceInformationBuilder<ir.Node> {
  final KernelToElementMapForBuilding _elementMap;
  final MemberEntity _member;
  final String _name;

  KernelSourceInformationBuilder(this._elementMap, this._member)
      : this._name = computeElementNameForSourceMaps(_member);

  /// Returns the [SourceLocation] for the [offset] within [node].
  ///
  /// If [offset] is `null`, the first `fileOffset` of [node] or its parents is
  /// used.
  SourceLocation _getSourceLocation(ir.TreeNode node, [int offset]) {
    ir.Location location;
    if (offset != null) {
      location = node.location;
      location = node.enclosingProgram.getLocation(location.file, offset);
    } else {
      while (node != null && node.fileOffset == ir.TreeNode.noOffset) {
        node = node.parent;
      }
      location = node.location;
      offset = node.fileOffset;
    }
    return new KernelSourceLocation(location, offset, _name);
  }

  /// Creates the source information for a function definition defined by the
  /// root [node] and its [functionNode].
  ///
  /// This method handles both methods, constructors, and local functions.
  SourceInformation _buildFunction(
      ir.TreeNode node, ir.FunctionNode functionNode) {
    if (functionNode.fileEndOffset != ir.TreeNode.noOffset) {
      return new PositionSourceInformation(_getSourceLocation(node),
          _getSourceLocation(functionNode, functionNode.fileEndOffset));
    }
    return _buildTreeNode(node);
  }

  /// Creates the source information for the [body] of [node].
  ///
  /// This method is used to for code in the beginning of a method, like
  /// variable declarations in the start of a function.
  SourceInformation _buildBody(ir.TreeNode node, ir.TreeNode body) {
    SourceLocation location;
    if (body != null) {
      if (body is ir.Block && body.statements.isNotEmpty) {
        location = _getSourceLocation(body.statements.first);
      } else {
        location = _getSourceLocation(body);
      }
    } else {
      location = _getSourceLocation(node);
    }
    return new PositionSourceInformation(location);
  }

  /// Creates source information based on the location of [node].
  SourceInformation _buildTreeNode(ir.TreeNode node) {
    return new PositionSourceInformation(_getSourceLocation(node));
  }

  @override
  SourceInformationBuilder forContext(MemberEntity member) =>
      new KernelSourceInformationBuilder(_elementMap, member);

  @override
  SourceInformation buildSwitchCase(ir.Node node) => null;

  @override
  SourceInformation buildSwitch(ir.Node node) => null;

  @override
  SourceInformation buildAs(ir.Node node) => null;

  @override
  SourceInformation buildIs(ir.Node node) => null;

  @override
  SourceInformation buildCatch(ir.Node node) => null;

  @override
  SourceInformation buildBinary(ir.Node node) => null;

  @override
  SourceInformation buildIndexSet(ir.Node node) => null;

  @override
  SourceInformation buildIndex(ir.Node node) => null;

  @override
  SourceInformation buildForInSet(ir.Node node) => null;

  @override
  SourceInformation buildForInCurrent(ir.Node node) => null;

  @override
  SourceInformation buildForInMoveNext(ir.Node node) => null;

  @override
  SourceInformation buildForInIterator(ir.Node node) => null;

  @override
  SourceInformation buildStringInterpolation(ir.Node node) => null;

  @override
  SourceInformation buildForeignCode(ir.Node node) => null;

  @override
  SourceInformation buildVariableDeclaration() {
    MemberDefinition definition = _elementMap.getMemberDefinition(_member);
    switch (definition.kind) {
      case MemberKind.regular:
        ir.Node node = definition.node;
        if (node is ir.Procedure) {
          return _buildBody(node, node.function.body);
        } else if (node is ir.Field) {
          return _buildBody(node, node.initializer);
        }
        break;
      case MemberKind.constructor:
      case MemberKind.constructorBody:
        ir.Node node = definition.node;
        if (node is ir.Procedure) {
          return _buildBody(node, node.function.body);
        } else if (node is ir.Constructor) {
          return _buildBody(node, node.function.body);
        }
        break;
      case MemberKind.closureCall:
        ir.Node node = definition.node;
        if (node is ir.FunctionDeclaration) {
          return _buildBody(node, node.function.body);
        } else if (node is ir.FunctionExpression) {
          return _buildBody(node, node.function.body);
        }
        break;
      default:
    }
    return _buildTreeNode(definition.node);
  }

  @override
  SourceInformation buildAssignment(ir.Node node) {
    return _buildTreeNode(node);
  }

  @override
  SourceInformation buildThrow(ir.Node node) => null;

  @override
  SourceInformation buildNew(ir.Node node) {
    return _buildTreeNode(node);
  }

  @override
  SourceInformation buildIf(ir.Node node) {
    return _buildTreeNode(node);
  }

  @override
  SourceInformation buildCall(
      covariant ir.TreeNode receiver, covariant ir.TreeNode call) {
    return new PositionSourceInformation(
        _getSourceLocation(receiver), _getSourceLocation(call));
  }

  @override
  SourceInformation buildGet(ir.Node node) {
    return _buildTreeNode(node);
  }

  @override
  SourceInformation buildLoop(ir.Node node) => null;

  @override
  SourceInformation buildImplicitReturn(MemberEntity element) => null;

  @override
  SourceInformation buildReturn(ir.Node node) {
    return _buildTreeNode(node);
  }

  @override
  SourceInformation buildCreate(ir.Node node) {
    return _buildTreeNode(node);
  }

  @override
  SourceInformation buildGeneric(ir.Node node) => null;

  @override
  SourceInformation buildDeclaration(MemberEntity member) {
    MemberDefinition definition = _elementMap.getMemberDefinition(member);
    switch (definition.kind) {
      case MemberKind.regular:
        ir.Node node = definition.node;
        if (node is ir.Procedure) {
          return _buildFunction(node, node.function);
        }
        break;
      case MemberKind.constructor:
      case MemberKind.constructorBody:
        ir.Node node = definition.node;
        if (node is ir.Procedure) {
          return _buildFunction(node, node.function);
        } else if (node is ir.Constructor) {
          return _buildFunction(node, node.function);
        }
        break;
      case MemberKind.closureCall:
        ir.Node node = definition.node;
        if (node is ir.FunctionDeclaration) {
          return _buildFunction(node, node.function);
        } else if (node is ir.FunctionExpression) {
          return _buildFunction(node, node.function);
        }
        break;
      default:
    }
    return _buildTreeNode(definition.node);
  }
}

class KernelSourceLocation extends AbstractSourceLocation {
  final int offset;
  final String sourceName;
  final Uri sourceUri;

  KernelSourceLocation(ir.Location location, this.offset, this.sourceName)
      : sourceUri = Uri.base.resolve(location.file),
        super.fromLocation(location);
}
