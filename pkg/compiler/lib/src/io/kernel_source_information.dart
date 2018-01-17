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
import '../universe/call_structure.dart';
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

/// Compute the source map name for kernel based [member]. If [callStructure]
/// is non-null it is used to name the parameter stub for [element].
///
/// [elementMap] is used to compute names for closure call methods.
// TODO(johnniwinther): Make the closure call names available to
// `sourcemap_helper.dart`.
String computeKernelElementNameForSourceMaps(
    KernelToElementMapForBuilding elementMap, MemberEntity member,
    [CallStructure callStructure]) {
  MemberDefinition definition = elementMap.getMemberDefinition(member);
  switch (definition.kind) {
    case MemberKind.closureCall:
      ir.TreeNode node = definition.node;
      String name;
      while (node is! ir.Member) {
        if (node is ir.FunctionDeclaration) {
          if (name != null) {
            name = '${node.variable.name}.$name';
          } else {
            name = node.variable.name;
          }
        } else if (node is ir.FunctionExpression) {
          if (name != null) {
            name = '<anonymous function>.$name';
          } else {
            name = '<anonymous function>';
          }
        }
        node = node.parent;
      }
      MemberEntity enclosingMember = elementMap.getMember(node);
      String enclosingMemberName =
          computeElementNameForSourceMaps(enclosingMember, callStructure);
      return '$enclosingMemberName.$name';
    default:
      return computeElementNameForSourceMaps(member, callStructure);
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
      : this._name =
            computeKernelElementNameForSourceMaps(_elementMap, _member);

  /// Returns the [SourceLocation] for the [offset] within [node] using [name]
  /// as the name of the source location.
  ///
  /// If [offset] is `null`, the first `fileOffset` of [node] or its parents is
  /// used.
  SourceLocation _getSourceLocation(String name, ir.TreeNode node,
      [int offset]) {
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
    return new KernelSourceLocation(location, offset, name);
  }

  /// Creates the source information for a function definition defined by the
  /// root [node] and its [functionNode].
  ///
  /// This method handles both methods, constructors, and local functions.
  SourceInformation _buildFunction(
      String name, ir.TreeNode node, ir.FunctionNode functionNode) {
    if (functionNode.fileEndOffset != ir.TreeNode.noOffset) {
      return new PositionSourceInformation(_getSourceLocation(name, node),
          _getSourceLocation(name, functionNode, functionNode.fileEndOffset));
    }
    return _buildTreeNode(node);
  }

  /// Creates the source information for a [base] and end of [member]. If [base]
  /// is not provided, the offset of [member] is used as the start position.
  ///
  /// This is used function declarations and return expressions which both point
  /// to the end of the member as the closing position.
  SourceInformation _buildFunctionEnd(MemberEntity member, [ir.TreeNode base]) {
    MemberDefinition definition = _elementMap.getMemberDefinition(member);
    String name = computeKernelElementNameForSourceMaps(_elementMap, member);
    ir.Node node = definition.node;
    switch (definition.kind) {
      case MemberKind.regular:
        if (node is ir.Procedure) {
          return _buildFunction(name, base ?? node, node.function);
        }
        break;
      case MemberKind.constructor:
      case MemberKind.constructorBody:
        if (node is ir.Procedure) {
          return _buildFunction(name, base ?? node, node.function);
        } else if (node is ir.Constructor) {
          return _buildFunction(name, base ?? node, node.function);
        }
        break;
      case MemberKind.closureCall:
        if (node is ir.FunctionDeclaration) {
          return _buildFunction(name, base ?? node, node.function);
        } else if (node is ir.FunctionExpression) {
          return _buildFunction(name, base ?? node, node.function);
        }
        break;
      default:
    }
    return _buildTreeNode(base ?? node, name: name);
  }

  /// Creates the source information for exiting a function definition defined
  /// by the root [node] and its [functionNode].
  ///
  /// This method handles both methods, constructors, and local functions.
  SourceInformation _buildFunctionExit(
      ir.TreeNode node, ir.FunctionNode functionNode) {
    if (functionNode.fileEndOffset != ir.TreeNode.noOffset) {
      return new PositionSourceInformation(
          _getSourceLocation(_name, functionNode, functionNode.fileEndOffset));
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
        location = _getSourceLocation(_name, body.statements.first);
      } else {
        location = _getSourceLocation(_name, body);
      }
    } else {
      location = _getSourceLocation(_name, node);
    }
    return new PositionSourceInformation(location);
  }

  /// Creates source information for the body of the current member.
  SourceInformation _buildMemberBody() {
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

  /// Creates source information for the exit of the current member.
  SourceInformation _buildMemberExit() {
    MemberDefinition definition = _elementMap.getMemberDefinition(_member);
    switch (definition.kind) {
      case MemberKind.regular:
        ir.Node node = definition.node;
        if (node is ir.Procedure) {
          return _buildFunctionExit(node, node.function);
        }
        break;
      case MemberKind.constructor:
      case MemberKind.constructorBody:
        ir.Node node = definition.node;
        if (node is ir.Procedure) {
          return _buildFunctionExit(node, node.function);
        } else if (node is ir.Constructor) {
          return _buildFunctionExit(node, node.function);
        }
        break;
      case MemberKind.closureCall:
        ir.Node node = definition.node;
        if (node is ir.FunctionDeclaration) {
          return _buildFunctionExit(node, node.function);
        } else if (node is ir.FunctionExpression) {
          return _buildFunctionExit(node, node.function);
        }
        break;
      default:
    }
    return _buildTreeNode(definition.node);
  }

  /// Creates source information based on the location of [node].
  SourceInformation _buildTreeNode(ir.TreeNode node,
      {SourceLocation closingPosition, String name}) {
    return new PositionSourceInformation(
        _getSourceLocation(name ?? _name, node), closingPosition);
  }

  @override
  SourceInformationBuilder forContext(MemberEntity member) =>
      new KernelSourceInformationBuilder(_elementMap, member);

  @override
  SourceInformation buildSwitchCase(ir.Node node) => null;

  @override
  SourceInformation buildSwitch(ir.Node node) {
    return _buildTreeNode(node);
  }

  @override
  SourceInformation buildAs(ir.Node node) {
    return _buildTreeNode(node);
  }

  @override
  SourceInformation buildIs(ir.Node node) {
    return _buildTreeNode(node);
  }

  @override
  SourceInformation buildTry(ir.Node node) {
    return _buildTreeNode(node);
  }

  @override
  SourceInformation buildCatch(ir.Node node) {
    return _buildTreeNode(node);
  }

  @override
  SourceInformation buildBinary(ir.Node node) {
    return _buildTreeNode(node);
  }

  @override
  SourceInformation buildUnary(ir.Node node) {
    return _buildTreeNode(node);
  }

  @override
  SourceInformation buildIndexSet(ir.Node node) => null;

  @override
  SourceInformation buildIndex(ir.Node node) => null;

  @override
  SourceInformation buildForInSet(ir.Node node) {
    return _buildTreeNode(node);
  }

  @override
  SourceInformation buildForInCurrent(ir.Node node) {
    return _buildTreeNode(node);
  }

  @override
  SourceInformation buildForInMoveNext(ir.Node node) {
    return _buildTreeNode(node);
  }

  @override
  SourceInformation buildForInIterator(ir.Node node) {
    return _buildTreeNode(node);
  }

  @override
  SourceInformation buildStringInterpolation(ir.Node node) => null;

  @override
  SourceInformation buildForeignCode(ir.Node node) => null;

  @override
  SourceInformation buildVariableDeclaration() {
    return _buildMemberBody();
  }

  @override
  SourceInformation buildAwait(ir.Node node) {
    return _buildTreeNode(node);
  }

  @override
  SourceInformation buildYield(ir.Node node) {
    return _buildTreeNode(node);
  }

  @override
  SourceInformation buildAsyncBody() {
    return _buildMemberBody();
  }

  @override
  SourceInformation buildAsyncExit() {
    return _buildMemberExit();
  }

  @override
  SourceInformation buildAssignment(ir.Node node) {
    return _buildTreeNode(node);
  }

  @override
  SourceInformation buildThrow(ir.Node node) {
    return _buildTreeNode(node);
  }

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
        _getSourceLocation(_name, receiver), _getSourceLocation(_name, call));
  }

  @override
  SourceInformation buildGet(ir.Node node) {
    return _buildTreeNode(node);
  }

  @override
  SourceInformation buildLoop(ir.Node node) {
    return _buildTreeNode(node);
  }

  @override
  SourceInformation buildImplicitReturn(MemberEntity element) => null;

  @override
  SourceInformation buildReturn(ir.Node node) {
    return _buildFunctionEnd(_member, node);
  }

  @override
  SourceInformation buildCreate(ir.Node node) {
    return _buildTreeNode(node);
  }

  @override
  SourceInformation buildListLiteral(ir.Node node) {
    return _buildTreeNode(node);
  }

  @override
  SourceInformation buildGeneric(ir.Node node) => null;

  @override
  SourceInformation buildDeclaration(MemberEntity member) {
    return _buildFunctionEnd(member);
  }

  @override
  SourceInformation buildStub(
      FunctionEntity function, CallStructure callStructure) {
    MemberDefinition definition = _elementMap.getMemberDefinition(function);
    String name = computeKernelElementNameForSourceMaps(
        _elementMap, function, callStructure);
    ir.Node node = definition.node;
    return _buildTreeNode(node, name: name);
  }

  @override
  SourceInformation buildGoto(ir.Node node) {
    return _buildTreeNode(node);
  }
}

class KernelSourceLocation extends AbstractSourceLocation {
  final int offset;
  final String sourceName;
  final Uri sourceUri;

  KernelSourceLocation(ir.Location location, this.offset, this.sourceName)
      : sourceUri = location.file,
        super.fromLocation(location);
}
