// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart' as ir;

import 'node_indexer.dart';

/// Helper for looking up object library data from an [ir.Component] node.
class ComponentLookup {
  final ir.Component _component;

  /// Cache of [LibraryData] for libraries in [_component].
  late final Map<Uri, LibraryData> _libraryMap = _initializeLibraryMap();

  ComponentLookup(this._component);

  Map<Uri, LibraryData> _initializeLibraryMap() {
    final libraryMap = <Uri, LibraryData>{};
    for (ir.Library library in _component.libraries) {
      libraryMap[library.importUri] = LibraryData(library);
    }
    return libraryMap;
  }

  /// Returns the [LibraryData] object for the library with the [canonicalUri].
  LibraryData getLibraryDataByUri(Uri canonicalUri) {
    return _libraryMap[canonicalUri]!;
  }
}

/// Returns a name uniquely identifying a member within its enclosing library
/// or class.
String computeMemberName(ir.Member member) {
  // This should mostly be empty except when serializing the name of nSM
  // forwarders (see dartbug.com/33732).
  String libraryPrefix = member.name.isPrivate &&
          member.name.libraryReference != member.enclosingLibrary.reference
      ? '${member.name.libraryReference?.canonicalName?.name}:'
      : '';
  String name = member.name.text;
  if (member is ir.Constructor) {
    name = '.$name';
  } else if (member is ir.Procedure) {
    if (member.kind == ir.ProcedureKind.Factory) {
      name = '.$name';
    } else if (member.kind == ir.ProcedureKind.Setter) {
      name += "=";
    }
  }
  return '${libraryPrefix}${name}';
}

/// Helper for looking up classes and members from an [ir.Library] node.
class LibraryData {
  /// The [ir.Library] that defines the library.
  final ir.Library node;

  /// Cache of [ClassData] for classes in this library.
  Map<String, ClassData>? _classesByName;
  Map<ir.Class, ClassData>? _classesByNode;

  /// Cache of [ir.Typedef] nodes for typedefs in this library.
  late final Map<String, ir.Typedef> _typedefs = _initializeTypedefs();

  /// Cache of [ir.InlineClass] nodes for inline classes in this library.
  late final Map<String, ir.InlineClass> _inlineClasses =
      _initializeInlineClasses();

  /// Cache of [MemberData] for members in this library.
  Map<String, MemberData>? _membersByName;
  Map<ir.Member, MemberData>? _membersByNode;

  LibraryData(this.node);

  Map<String, ir.Typedef> _initializeTypedefs() {
    final typedefs = <String, ir.Typedef>{};
    for (ir.Typedef typedef in node.typedefs) {
      assert(
          !typedefs.containsKey(typedef.name),
          "Duplicate typedef '${typedef.name}' in $typedefs "
          "trying to add $typedef.");
      typedefs[typedef.name] = typedef;
    }
    return typedefs;
  }

  Map<String, ir.InlineClass> _initializeInlineClasses() {
    final inlineClasses = <String, ir.InlineClass>{};
    for (ir.InlineClass inlineClass in node.inlineClasses) {
      assert(
          !inlineClasses.containsKey(inlineClass.name),
          "Duplicate inline class '${inlineClass.name}' in $inlineClasses "
          "trying to add $inlineClass.");
      inlineClasses[inlineClass.name] = inlineClass;
    }
    return inlineClasses;
  }

  void _ensureClasses() {
    if (_classesByName == null) {
      final classesByName = _classesByName = {};
      final classesByNode = _classesByNode = {};
      for (ir.Class cls in node.classes) {
        assert(
            !classesByName.containsKey(cls.name),
            "Duplicate class '${cls.name}' in $classesByName "
            "trying to add $cls.");
        assert(
            !classesByNode.containsKey(cls),
            "Duplicate class '${cls.name}' in $classesByNode "
            "trying to add $cls.");
        classesByNode[cls] = classesByName[cls.name] = ClassData(cls);
      }
    }
  }

  /// Returns the [ClassData] for the class [name] in this library.
  ClassData? lookupClassByName(String name) {
    _ensureClasses();
    return _classesByName![name];
  }

  /// Returns the [ClassData] for the class [node] in this library.
  ClassData? lookupClassByNode(ir.Class node) {
    _ensureClasses();
    return _classesByNode![node];
  }

  /// Returns the [InlineClass] for the given [name] in this library.
  ir.InlineClass? lookupInlineClass(String name) {
    return _inlineClasses[name];
  }

  ir.Typedef? lookupTypedef(String name) {
    return _typedefs[name];
  }

  void _ensureMembers() {
    if (_membersByName == null) {
      final membersByName = _membersByName = {};
      final membersByNode = _membersByNode = {};
      for (ir.Member member in node.members) {
        String name = computeMemberName(member);
        assert(
            !membersByName.containsKey(name),
            "Duplicate member '$name' in $membersByName "
            "trying to add $member.");
        assert(
            !membersByNode.containsKey(member),
            "Duplicate member '$name' in $membersByNode "
            "trying to add $member.");
        membersByNode[member] = membersByName[name] = MemberData(member);
      }
    }
  }

  /// Returns the [MemberData] for the member uniquely identified by [name] in
  /// this library.
  MemberData? lookupMemberDataByName(String name) {
    _ensureMembers();
    return _membersByName![name];
  }

  /// Returns the [MemberData] for the member [node] in this library.
  MemberData? lookupMemberDataByNode(ir.Member node) {
    _ensureMembers();
    return _membersByNode![node];
  }

  @override
  String toString() => 'LibraryData($node(${identityHashCode(node)}))';
}

/// Helper for looking up members from an [ir.Class] node.
class ClassData {
  /// The [ir.Class] that defines the class.
  final ir.Class node;

  /// Cache of [MemberData] for members in this class.
  Map<String, MemberData>? _membersByName;
  Map<ir.Member, MemberData>? _membersByNode;

  ClassData(this.node);

  void _ensureMembers() {
    if (_membersByName == null) {
      final membersByName = _membersByName = {};
      final membersByNode = _membersByNode = {};
      for (ir.Member member in node.members) {
        String name = computeMemberName(member);
        assert(
            !membersByName.containsKey(name),
            "Duplicate member '$name' in $membersByName "
            "trying to add $member.");
        assert(
            !membersByNode.containsKey(member),
            "Duplicate member '$name' in $membersByNode "
            "trying to add $member.");
        membersByNode[member] = membersByName[name] = MemberData(member);
      }
    }
  }

  /// Returns the [MemberData] for the member uniquely identified by [name] in
  /// this class.
  MemberData? lookupMemberDataByName(String name) {
    _ensureMembers();
    return _membersByName![name];
  }

  /// Returns the [MemberData] for the member [node] in this class.
  MemberData? lookupMemberDataByNode(ir.Member node) {
    _ensureMembers();
    return _membersByNode![node];
  }

  @override
  String toString() => 'ClassData($node(${identityHashCode(node)}))';
}

/// Helper for looking up child [ir.TreeNode]s of a [ir.Member] node.
class MemberData {
  /// The [ir.Member] that defines the member.
  final ir.Member node;

  /// Cached index to [ir.TreeNode] map used for deserialization of
  /// [ir.TreeNode]s.
  Map<int, ir.TreeNode>? _indexToNodeMap;

  /// Cached [ir.TreeNode] to index map used for serialization of
  /// [ir.TreeNode]s.
  Map<ir.TreeNode, int>? _nodeToIndexMap;

  /// Cached [ir.ConstantExpression] to [ConstantNodeIndexerVisitor] map used
  /// for fast serialization/deserialization of constant references.
  late final Map<ir.ConstantExpression, ConstantNodeIndexerVisitor>
      _constantIndexMap = {};

  MemberData(this.node);

  void _ensureMaps() {
    if (_indexToNodeMap == null) {
      _indexToNodeMap = {};
      _nodeToIndexMap = {};
      node.accept(TreeNodeIndexerVisitor(_indexToNodeMap!, _nodeToIndexMap!));
    }
  }

  ConstantNodeIndexerVisitor _createConstantIndexer(
      ir.ConstantExpression node) {
    ConstantNodeIndexerVisitor indexer = ConstantNodeIndexerVisitor();
    node.constant.accept(indexer);
    return indexer;
  }

  ir.Constant getConstantByIndex(ir.ConstantExpression node, int index) {
    ConstantNodeIndexerVisitor indexer =
        _constantIndexMap[node] ??= _createConstantIndexer(node);
    return indexer.getConstant(index);
  }

  int getIndexByConstant(ir.ConstantExpression node, ir.Constant constant) {
    ConstantNodeIndexerVisitor indexer =
        _constantIndexMap[node] ??= _createConstantIndexer(node);
    return indexer.getIndex(constant);
  }

  /// Returns the [ir.TreeNode] corresponding to [index] in this member.
  ir.TreeNode getTreeNodeByIndex(int index) {
    _ensureMaps();
    return _indexToNodeMap![index]!;
  }

  /// Returns the index corresponding to [ir.TreeNode] in this member.
  int getIndexByTreeNode(ir.TreeNode node) {
    _ensureMaps();
    return _nodeToIndexMap![node] ??
        (throw StateError(
            'getIndexByTreeNode ${node.runtimeType} in member ${this.node}'));
  }

  @override
  String toString() => 'MemberData($node(${identityHashCode(node)}))';
}
