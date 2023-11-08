// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Source information system mapping that attempts a semantic mapping between
/// offsets of JavaScript code points to offsets of Dart code points.

library dart2js.source_information.kernel;

import 'package:kernel/ast.dart' as ir;
import '../elements/entities.dart';
import '../js_model/element_map.dart';
import '../universe/call_structure.dart';
import 'source_information.dart';
import 'position_information.dart';

class KernelSourceInformationStrategy
    extends AbstractPositionSourceInformationStrategy {
  late final JsToElementMap _elementMap;

  @override
  void onElementMapAvailable(JsToElementMap elementMap) {
    _elementMap = elementMap;
  }

  @override
  SourceInformationBuilder createBuilderForContext(MemberEntity member) {
    return KernelSourceInformationBuilder(_elementMap, member);
  }
}

/// Compute the source map name for kernel based [member]. If [callStructure]
/// is non-null it is used to name the parameter stub for [element].
///
/// [elementMap] is used to compute names for closure call methods.
// TODO(johnniwinther): Make the closure call names available to
// `sourcemap_helper.dart`.
String? computeKernelElementNameForSourceMaps(
    JsToElementMap elementMap, MemberEntity member,
    [CallStructure? callStructure]) {
  MemberDefinition definition = elementMap.getMemberDefinition(member);
  switch (definition.kind) {
    case MemberKind.regular:
      final node = definition.node as ir.Member;
      if (node.isExtensionMember) return _findExtensionMemberName(node);
      return computeElementNameForSourceMaps(member, callStructure);

    case MemberKind.closureCall:
      var node = definition.node as ir.TreeNode;
      String? name;
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
        node = node.parent!;
      }
      MemberEntity enclosingMember = elementMap.getMember(node);
      String enclosingMemberName =
          computeElementNameForSourceMaps(enclosingMember, callStructure)!;
      return '$enclosingMemberName.$name';
    default:
      return computeElementNameForSourceMaps(member, callStructure);
  }
}

/// Extract a simple readable name for an extension member.
String _findExtensionMemberName(ir.Member member) {
  assert(member.isExtensionMember);
  for (ir.Extension extension in member.enclosingLibrary.extensions) {
    for (ir.ExtensionMemberDescriptor descriptor in extension.members) {
      if (descriptor.member == member.reference ||
          descriptor.tearOff == member.reference) {
        String extensionName;
        // Anonymous extensions contain a # on their synthetic name.
        if (extension.name.contains('#')) {
          ir.DartType type = extension.onType;
          if (type is ir.InterfaceType) {
            extensionName = "${type.classNode.name}.<anonymous extension>";
          } else {
            extensionName = "<anonymous extension>";
          }
        } else {
          extensionName = extension.name;
        }
        String memberName = descriptor.name.text;
        return '$extensionName.$memberName';
      }
    }
  }
  throw StateError('No original name found for extension member $member.');
}

/// [SourceInformationBuilder] that generates [PositionSourceInformation] from
/// Kernel nodes.
class KernelSourceInformationBuilder implements SourceInformationBuilder {
  final JsToElementMap _elementMap;
  final MemberEntity _member;
  final String? _name;

  /// Inlining context or null when no inlining has taken place.
  ///
  /// A new builder is created every time the backend inlines a method. This
  /// field contains the location of every call site that has been inlined. The
  /// last entry on the list is always a call to [_member].
  final List<FrameContext>? inliningContext;

  KernelSourceInformationBuilder(this._elementMap, this._member)
      : _name = computeKernelElementNameForSourceMaps(_elementMap, _member),
        inliningContext = null;

  KernelSourceInformationBuilder.withContext(
      this._elementMap, this._member, this.inliningContext, this._name);

  /// Returns the [SourceLocation] for the [offset] within [node] using [name]
  /// as the name of the source location.
  ///
  /// If [offset] is `null`, the first `fileOffset` of [node] or its parents is
  /// used.
  SourceLocation _getSourceLocation(String? name, ir.TreeNode node,
      [int? offset]) {
    ir.Location location;
    if (offset != null) {
      location = node.location!;
      location = node.enclosingComponent!.getLocation(location.file, offset)!;
    } else {
      while (node.fileOffset == ir.TreeNode.noOffset) {
        node = node.parent!;
      }
      location = node.location!;
      offset = node.fileOffset;
    }
    return KernelSourceLocation(location, offset, name);
  }

  /// Creates the source information for a function definition defined by the
  /// root [node] and its [functionNode].
  ///
  /// This method handles both methods, constructors, and local functions.
  SourceInformation _buildFunction(
      String? name, ir.TreeNode node, ir.FunctionNode functionNode) {
    if (functionNode.fileEndOffset != ir.TreeNode.noOffset) {
      return PositionSourceInformation(
          _getSourceLocation(name, node),
          _getSourceLocation(name, functionNode, functionNode.fileEndOffset),
          this.inliningContext);
    }
    return _buildTreeNode(node);
  }

  /// Creates the source information for a [base] and end of [member]. If [base]
  /// is not provided, the offset of [member] is used as the start position.
  ///
  /// This is used function declarations and return expressions which both point
  /// to the end of the member as the closing position.
  SourceInformation? _buildFunctionEnd(MemberEntity member,
      [ir.TreeNode? base]) {
    MemberDefinition definition = _elementMap.getMemberDefinition(member);
    String? name = computeKernelElementNameForSourceMaps(_elementMap, member);
    switch (definition.kind) {
      case MemberKind.regular:
        final node = definition.node as ir.Member;
        if (node is ir.Procedure) {
          return _buildFunction(name, base ?? node, node.function);
        }
        break;
      case MemberKind.constructor:
      case MemberKind.constructorBody:
        final node = definition.node as ir.Member;
        return _buildFunction(name, base ?? node, node.function!);
      case MemberKind.closureCall:
        final node = definition.node as ir.LocalFunction;
        return _buildFunction(name, base ?? node, node.function);
      case MemberKind.recordGetter:
        return null;
      // TODO(sra): generatorBody
      default:
    }
    return _buildTreeNode(base ?? definition.node as ir.TreeNode, name: name);
  }

  /// Creates the source information for exiting a function definition defined
  /// by the root [node] and its [functionNode].
  ///
  /// This method handles both methods, constructors, and local functions.
  SourceInformation _buildFunctionExit(
      ir.TreeNode node, ir.FunctionNode functionNode) {
    if (functionNode.fileEndOffset != ir.TreeNode.noOffset) {
      return PositionSourceInformation(
          _getSourceLocation(_name, functionNode, functionNode.fileEndOffset),
          null,
          this.inliningContext);
    }
    return _buildTreeNode(node);
  }

  /// Creates the source information for the [body] of [node].
  ///
  /// This method is used to for code in the beginning of a method, like
  /// variable declarations in the start of a function.
  SourceInformation _buildBody(ir.TreeNode node, ir.TreeNode? body) {
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
    return PositionSourceInformation(location, null, inliningContext);
  }

  /// Creates source information for the body of the current member.
  // TODO(51310): Remove nullable return type.
  SourceInformation? _buildMemberBody() {
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
        final node = definition.node as ir.LocalFunction;
        return _buildBody(node, node.function.body);
      case MemberKind.generatorBody:
        ir.Node node = definition.node;
        if (node is ir.LocalFunction) {
          return _buildBody(node, node.function.body);
        } else if (node is ir.Member && node.function != null) {
          return _buildBody(node, node.function!.body);
        }
        break;
      case MemberKind.recordGetter:
        // This is a completely synthetic element. Perhaps we can use
        // definition.location, but that is often 'nowhere'.

        // TODO(51310): Perhaps we should not end up in
        // [KernelSourceInformationBuilder] for synthetic elements that are not
        // defined by Kernel ASTs.
        return null;

      default:
    }
    return _buildTreeNode(definition.node as ir.TreeNode);
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
        final node = definition.node as ir.Member;
        return _buildFunctionExit(node, node.function!);
      case MemberKind.closureCall:
        final node = definition.node as ir.LocalFunction;
        return _buildFunctionExit(node, node.function);
      default:
    }
    return _buildTreeNode(definition.node as ir.TreeNode);
  }

  /// Creates source information based on the location of [node].
  SourceInformation _buildTreeNode(ir.TreeNode node,
      {SourceLocation? closingPosition, String? name}) {
    return PositionSourceInformation(_getSourceLocation(name ?? _name, node),
        closingPosition, inliningContext);
  }

  @override
  SourceInformationBuilder forContext(
      MemberEntity member, SourceInformation? context) {
    List<FrameContext>? newContext = inliningContext?.toList() ?? [];
    if (context != null) {
      newContext.add(FrameContext(context, member.name!));
    } else {
      // TODO(sigmund): investigate whether we have any more cases where context
      // is null.
      newContext = inliningContext;
    }

    String? name = computeKernelElementNameForSourceMaps(_elementMap, _member);
    return KernelSourceInformationBuilder.withContext(
        _elementMap, member, newContext, name);
  }

  @override
  SourceInformation? buildSwitchCase(ir.Node node) => null;

  @override
  SourceInformation buildSwitch(ir.TreeNode node) {
    return _buildTreeNode(node);
  }

  @override
  SourceInformation buildAs(ir.TreeNode node) {
    return _buildTreeNode(node);
  }

  @override
  SourceInformation buildIs(ir.TreeNode node) {
    return _buildTreeNode(node);
  }

  @override
  SourceInformation buildTry(ir.TreeNode node) {
    return _buildTreeNode(node);
  }

  @override
  SourceInformation buildCatch(ir.TreeNode node) {
    return _buildTreeNode(node);
  }

  @override
  SourceInformation buildBinary(ir.TreeNode node) {
    return _buildTreeNode(node);
  }

  @override
  SourceInformation buildUnary(ir.TreeNode node) {
    return _buildTreeNode(node);
  }

  @override
  SourceInformation? buildIndexSet(ir.Node node) => null;

  @override
  SourceInformation? buildIndex(ir.Node node) => null;

  @override
  SourceInformation buildForInSet(ir.TreeNode node) {
    return _buildTreeNode(node);
  }

  @override
  SourceInformation buildForInCurrent(ir.TreeNode node) {
    return _buildTreeNode(node);
  }

  @override
  SourceInformation buildForInMoveNext(ir.TreeNode node) {
    return _buildTreeNode(node);
  }

  @override
  SourceInformation buildForInIterator(ir.TreeNode node) {
    return _buildTreeNode(node);
  }

  @override
  SourceInformation? buildStringInterpolation(ir.Node node) => null;

  @override
  SourceInformation? buildForeignCode(ir.Node node) => null;

  @override
  SourceInformation? buildVariableDeclaration() {
    return _buildMemberBody();
  }

  @override
  SourceInformation buildAwait(ir.TreeNode node) {
    return _buildTreeNode(node);
  }

  @override
  SourceInformation buildYield(ir.TreeNode node) {
    return _buildTreeNode(node);
  }

  @override
  SourceInformation buildAsyncBody() {
    return _buildMemberBody()!;
  }

  @override
  SourceInformation buildAsyncExit() {
    return _buildMemberExit();
  }

  @override
  SourceInformation buildAssignment(ir.TreeNode node) {
    return _buildTreeNode(node);
  }

  @override
  SourceInformation buildThrow(ir.TreeNode node) {
    return _buildTreeNode(node);
  }

  @override
  SourceInformation buildAssert(ir.TreeNode node) {
    return _buildTreeNode(node);
  }

  @override
  SourceInformation buildNew(ir.TreeNode node) {
    return _buildTreeNode(node);
  }

  @override
  SourceInformation buildIf(ir.TreeNode node) {
    return _buildTreeNode(node);
  }

  @override
  SourceInformation buildCall(
      covariant ir.TreeNode receiver, covariant ir.TreeNode call) {
    return PositionSourceInformation(_getSourceLocation(_name, receiver),
        _getSourceLocation(_name, call), inliningContext);
  }

  @override
  SourceInformation buildGet(ir.TreeNode node) {
    return _buildTreeNode(node);
  }

  @override
  SourceInformation buildSet(ir.TreeNode node) {
    return _buildTreeNode(node);
  }

  @override
  SourceInformation buildLoop(ir.TreeNode node) {
    return _buildTreeNode(node);
  }

  @override
  SourceInformation? buildImplicitReturn(MemberEntity element) => null;

  @override
  SourceInformation buildReturn(ir.TreeNode node) {
    return _buildFunctionEnd(_member, node)!;
  }

  @override
  SourceInformation buildCreate(ir.TreeNode node) {
    return _buildTreeNode(node);
  }

  @override
  SourceInformation buildListLiteral(ir.TreeNode node) {
    return _buildTreeNode(node);
  }

  @override
  SourceInformation? buildGeneric(ir.Node node) => null;

  @override
  SourceInformation? buildDeclaration(MemberEntity member) {
    return _buildFunctionEnd(member);
  }

  @override
  SourceInformation buildStub(
      FunctionEntity function, CallStructure callStructure) {
    MemberDefinition definition = _elementMap.getMemberDefinition(function);
    String? name = computeKernelElementNameForSourceMaps(
        _elementMap, function, callStructure);
    ir.Node node = definition.node;
    return _buildTreeNode(node as ir.TreeNode, name: name);
  }

  @override
  SourceInformation buildGoto(ir.TreeNode node) {
    return _buildTreeNode(node);
  }
}

class KernelSourceLocation extends SourceLocation {
  @override
  final int offset;
  @override
  final String? sourceName;

  final ir.Location location;

  KernelSourceLocation(this.location, this.offset, this.sourceName);

  @override
  int get column => location.column;

  @override
  int get line => location.line;

  @override
  Uri? get sourceUri => location.file;
}
