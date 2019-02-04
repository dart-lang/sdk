// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of 'serialization.dart';

/// Helper for looking up object library data from an [ir.Component] node.
class ComponentLookup {
  final ir.Component _component;

  /// Cache of [_LibraryData] for libraries in [_component].
  Map<Uri, _LibraryData> _libraryMap;

  ComponentLookup(this._component);

  /// Returns the [_LibraryData] object for the library with the [canonicalUri].
  _LibraryData getLibraryDataByUri(Uri canonicalUri) {
    if (_libraryMap == null) {
      _libraryMap = {};
      for (ir.Library library in _component.libraries) {
        _libraryMap[library.importUri] = new _LibraryData(library);
      }
    }
    _LibraryData data = _libraryMap[canonicalUri];
    assert(data != null, "No library found for $canonicalUri.");
    return data;
  }
}

/// Returns a name uniquely identifying a member within its enclosing library
/// or class.
String _computeMemberName(ir.Member member) {
  if (member.name.isPrivate &&
      member.name.libraryName != member.enclosingLibrary.reference) {
    // TODO(33732): Handle noSuchMethod forwarders for private members from
    // other libraries.
    return null;
  }
  String name = member.name.name;
  if (member is ir.Constructor) {
    name = '.$name';
  } else if (member is ir.Procedure) {
    if (member.kind == ir.ProcedureKind.Factory) {
      name = '.$name';
    } else if (member.kind == ir.ProcedureKind.Setter) {
      name += "=";
    }
  }
  return name;
}

/// Helper for looking up classes and members from an [ir.Library] node.
class _LibraryData {
  /// The [ir.Library] that defines the library.
  final ir.Library node;

  /// Cache of [_ClassData] for classes in this library.
  Map<String, _ClassData> _classes;

  /// Cache of [ir.Typedef] nodes for typedefs in this library.
  Map<String, ir.Typedef> _typedefs;

  /// Cache of [_MemberData] for members in this library.
  Map<String, _MemberData> _members;

  _LibraryData(this.node);

  /// Returns the [_ClassData] for the class [name] in this library.
  _ClassData lookupClass(String name) {
    if (_classes == null) {
      _classes = {};
      for (ir.Class cls in node.classes) {
        assert(!_classes.containsKey(cls.name),
            "Duplicate class '${cls.name}' in $_classes trying to add $cls.");
        _classes[cls.name] = new _ClassData(cls);
      }
    }
    return _classes[name];
  }

  ir.Typedef lookupTypedef(String name) {
    if (_typedefs == null) {
      _typedefs = {};
      for (ir.Typedef typedef in node.typedefs) {
        assert(
            !_typedefs.containsKey(typedef.name),
            "Duplicate typedef '${typedef.name}' in $_typedefs "
            "trying to add $typedef.");
        _typedefs[typedef.name] = typedef;
      }
    }
    return _typedefs[name];
  }

  /// Returns the [_MemberData] for the member uniquely identified by [name] in
  /// this library.
  _MemberData lookupMember(String name) {
    if (_members == null) {
      _members = {};
      for (ir.Member member in node.members) {
        String name = _computeMemberName(member);
        if (name == null) continue;
        assert(!_members.containsKey(name),
            "Duplicate member '$name' in $_members trying to add $member.");
        _members[name] = new _MemberData(member);
      }
    }
    return _members[name];
  }

  String toString() => '_LibraryData($node(${identityHashCode(node)}))';
}

/// Helper for looking up members from an [ir.Class] node.
class _ClassData {
  /// The [ir.Class] that defines the class.
  final ir.Class node;

  /// Cache of [_MemberData] for members in this class.
  Map<String, _MemberData> _members;

  _ClassData(this.node);

  /// Returns the [_MemberData] for the member uniquely identified by [name] in
  /// this class.
  _MemberData lookupMember(String name) {
    if (_members == null) {
      _members = {};
      for (ir.Member member in node.members) {
        String name = _computeMemberName(member);
        if (name == null) continue;
        assert(!_members.containsKey(name),
            "Duplicate member '$name' in $_members trying to add $member.");
        _members[name] = new _MemberData(member);
      }
    }
    return _members[name];
  }

  String toString() => '_ClassData($node(${identityHashCode(node)}))';
}

/// Helper for looking up child [ir.TreeNode]s of a [ir.Member] node.
class _MemberData {
  /// The [ir.Member] that defines the member.
  final ir.Member node;

  /// Cached index to [ir.TreeNode] map used for deserialization of
  /// [ir.TreeNode]s.
  Map<int, ir.TreeNode> _indexToNodeMap;

  /// Cached [ir.TreeNode] to index map used for serialization of
  /// [ir.TreeNode]s.
  Map<ir.TreeNode, int> _nodeToIndexMap;

  _MemberData(this.node);

  void _ensureMaps() {
    if (_indexToNodeMap == null) {
      _indexToNodeMap = {};
      _nodeToIndexMap = {};
      node.accept(
          new _TreeNodeIndexerVisitor(_indexToNodeMap, _nodeToIndexMap));
    }
  }

  /// Returns the [ir.TreeNode] corresponding to [index] in this member.
  ir.TreeNode getTreeNodeByIndex(int index) {
    _ensureMaps();
    ir.TreeNode treeNode = _indexToNodeMap[index];
    assert(treeNode != null, "No TreeNode found for index $index in $node.");
    return treeNode;
  }

  /// Returns the index corresponding to [ir.TreeNode] in this member.
  int getIndexByTreeNode(ir.TreeNode node) {
    _ensureMaps();
    int index = _nodeToIndexMap[node];
    assert(index != null, "No index found for ${node.runtimeType}.");
    return index;
  }

  String toString() => '_MemberData($node(${identityHashCode(node)}))';
}
