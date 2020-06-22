// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Classes for representing information about the program structure.
library vm.snapshot.program_info;

import 'package:meta/meta.dart';

/// Represents information about compiled program.
class ProgramInfo {
  static const int rootId = 0;
  static const int stubsId = 1;
  static const int unknownId = 2;

  final ProgramInfoNode root;
  final ProgramInfoNode stubs;
  final ProgramInfoNode unknown;
  int _nextId = 3;

  ProgramInfo._(this.root, this.stubs, this.unknown);

  factory ProgramInfo() {
    final ProgramInfoNode root = ProgramInfoNode._(
        id: rootId, name: '@shared', type: NodeType.libraryNode, parent: null);

    final ProgramInfoNode stubs = ProgramInfoNode._(
        id: stubsId, name: '@stubs', type: NodeType.libraryNode, parent: root);
    root.children[stubs.name] = stubs;

    final ProgramInfoNode unknown = ProgramInfoNode._(
        id: unknownId,
        name: '@unknown',
        type: NodeType.libraryNode,
        parent: root);
    root.children[unknown.name] = unknown;

    return ProgramInfo._(root, stubs, unknown);
  }

  ProgramInfoNode makeNode(
      {@required String name,
      @required ProgramInfoNode parent,
      @required NodeType type}) {
    return parent.children.putIfAbsent(name, () {
      final node = ProgramInfoNode._(
          id: _nextId++, name: name, parent: parent ?? root, type: type);
      node.parent.children[name] = node;
      return node;
    });
  }

  /// Recursively visit all function nodes, which have [FunctionInfo.info]
  /// populated.
  void visit(
      void Function(String pkg, String lib, String cls, String fun, int size)
          callback) {
    final context = List<String>(NodeType.values.length);

    void recurse(ProgramInfoNode node) {
      final prevContext = context[node._type];
      if (prevContext != null && node._type == NodeType.functionNode.index) {
        context[node._type] = '${prevContext}.${node.name}';
      } else {
        context[node._type] = node.name;
      }

      if (node.size != null) {
        final String pkg = context[NodeType.packageNode.index];
        final String lib = context[NodeType.libraryNode.index];
        final String cls = context[NodeType.classNode.index];
        final String mem = context[NodeType.functionNode.index];
        callback(pkg, lib, cls, mem, node.size);
      }

      for (var child in node.children.values) {
        recurse(child);
      }

      context[node._type] = prevContext;
    }

    recurse(root);
  }

  int get totalSize {
    var result = 0;
    visit((pkg, lib, cls, fun, size) {
      result += size;
    });
    return result;
  }

  /// Convert this program info to a JSON map using [infoToJson] to convert
  /// data attached to nodes into its JSON representation.
  Map<String, dynamic> toJson() => root.toJson();
}

enum NodeType {
  packageNode,
  libraryNode,
  classNode,
  functionNode,
  other,
}

String _typeToJson(NodeType type) => const {
      NodeType.packageNode: 'package',
      NodeType.libraryNode: 'library',
      NodeType.classNode: 'class',
      NodeType.functionNode: 'function',
    }[type];

class ProgramInfoNode {
  final int id;
  final String name;
  final ProgramInfoNode parent;
  final Map<String, ProgramInfoNode> children = {};
  final int _type;

  int size;

  ProgramInfoNode._(
      {@required this.id,
      @required this.name,
      @required this.parent,
      @required NodeType type})
      : _type = type.index;

  NodeType get type => NodeType.values[_type];

  Map<String, dynamic> toJson() => {
        if (size != null) '#size': size,
        if (_type != NodeType.other.index) '#type': _typeToJson(type),
        if (children.isNotEmpty)
          for (var clo in children.entries) clo.key: clo.value.toJson()
      };
}

/// Computes the size difference between two [ProgramInfo].
ProgramInfo computeDiff(ProgramInfo oldInfo, ProgramInfo newInfo) {
  final programDiff = ProgramInfo();

  var path = <Object>[];
  void recurse(ProgramInfoNode oldNode, ProgramInfoNode newNode) {
    if (oldNode?.size != newNode?.size) {
      var diffNode = programDiff.root;
      for (var i = 0; i < path.length; i += 2) {
        final name = path[i];
        final type = path[i + 1];
        diffNode =
            programDiff.makeNode(name: name, parent: diffNode, type: type);
      }
      diffNode.size ??= 0;
      diffNode.size += (newNode?.size ?? 0) - (oldNode?.size ?? 0);
    }

    for (var key in _allKeys(newNode?.children, oldNode?.children)) {
      final newChildNode = newNode != null ? newNode.children[key] : null;
      final oldChildNode = oldNode != null ? oldNode.children[key] : null;
      path.add(key);
      path.add(oldChildNode?.type ?? newChildNode?.type);
      recurse(oldChildNode, newChildNode);
      path.removeLast();
      path.removeLast();
    }
  }

  recurse(oldInfo.root, newInfo.root);

  return programDiff;
}

Iterable<T> _allKeys<T>(Map<T, dynamic> a, Map<T, dynamic> b) {
  return <T>{...?a?.keys, ...?b?.keys};
}

/// Histogram of sizes based on a [ProgramInfo] bucketed using one of the
/// [HistogramType] rules.
class SizesHistogram {
  /// Rule used to produce this histogram. Specifies how bucket names
  /// are constructed given (library-uri,class-name,function-name) tuples and
  /// how these bucket names can be deconstructed back into human readable form.
  final Bucketing bucketing;

  /// Histogram buckets.
  final Map<String, int> buckets;

  /// Bucket names sorted by the size of the corresponding bucket in descending
  /// order.
  final List<String> bySize;

  final int totalSize;

  int get length => bySize.length;

  SizesHistogram._(this.bucketing, this.buckets, this.bySize, this.totalSize);

  /// Construct the histogram of specific [type] given a [ProgramInfo].
  static SizesHistogram from(ProgramInfo info, HistogramType type) {
    final buckets = <String, int>{};
    final bucketing = Bucketing._forType[type];

    var totalSize = 0;
    info.visit((pkg, lib, cls, fun, size) {
      final bucket = bucketing.bucketFor(pkg, lib, cls, fun);
      buckets[bucket] = (buckets[bucket] ?? 0) + size;
      totalSize += size;
    });

    final bySize = buckets.keys.toList(growable: false);
    bySize.sort((a, b) => buckets[b] - buckets[a]);

    return SizesHistogram._(bucketing, buckets, bySize, totalSize);
  }
}

enum HistogramType {
  bySymbol,
  byClass,
  byLibrary,
  byPackage,
}

abstract class Bucketing {
  /// Specifies which human readable name components can be extracted from
  /// the bucket name.
  List<String> get nameComponents;

  /// Constructs the bucket name from the given library name [lib], class name
  /// [cls] and function name [fun].
  String bucketFor(String pkg, String lib, String cls, String fun);

  /// Deconstructs bucket name into human readable components (the order matches
  /// one returned by [nameComponents]).
  List<String> namesFromBucket(String bucket);

  const Bucketing();

  static const _forType = {
    HistogramType.bySymbol: _BucketBySymbol(),
    HistogramType.byClass: _BucketByClass(),
    HistogramType.byLibrary: _BucketByLibrary(),
    HistogramType.byPackage: _BucketByPackage(),
  };
}

/// A combination of characters that is unlikely to occur in the symbol name.
const String _nameSeparator = ';;;';

class _BucketBySymbol extends Bucketing {
  @override
  List<String> get nameComponents => const ['Library', 'Symbol'];

  @override
  String bucketFor(String pkg, String lib, String cls, String fun) {
    if (fun == null) {
      return '@other${_nameSeparator}';
    }
    return '$lib${_nameSeparator}${cls}${cls != '' ? '.' : ''}${fun}';
  }

  @override
  List<String> namesFromBucket(String bucket) => bucket.split(_nameSeparator);

  const _BucketBySymbol();
}

class _BucketByClass extends Bucketing {
  @override
  List<String> get nameComponents => ['Library', 'Class'];

  @override
  String bucketFor(String pkg, String lib, String cls, String fun) {
    if (cls == null) {
      return '@other${_nameSeparator}';
    }
    return '$lib${_nameSeparator}${cls}';
  }

  @override
  List<String> namesFromBucket(String bucket) => bucket.split(_nameSeparator);

  const _BucketByClass();
}

class _BucketByLibrary extends Bucketing {
  @override
  List<String> get nameComponents => ['Library'];

  @override
  String bucketFor(String pkg, String lib, String cls, String fun) => '$lib';

  @override
  List<String> namesFromBucket(String bucket) => [bucket];

  const _BucketByLibrary();
}

class _BucketByPackage extends Bucketing {
  @override
  List<String> get nameComponents => ['Package'];

  @override
  String bucketFor(String pkg, String lib, String cls, String fun) =>
      pkg ?? lib;

  @override
  List<String> namesFromBucket(String bucket) => [bucket];

  const _BucketByPackage();
}

String packageOf(String lib) {
  if (lib.startsWith('package:')) {
    final separatorPos = lib.indexOf('/');
    return lib.substring(0, separatorPos);
  } else {
    return lib;
  }
}
