// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library glob.list_tree;

import 'dart:io';
import 'dart:async';

import 'package:path/path.dart' as p;

import 'ast.dart';
import 'stream_pool.dart';
import 'utils.dart';

/// The errno for a file or directory not existing on Mac and Linux.
const _ENOENT = 2;

/// Another errno we see on Windows when trying to list a non-existent
/// directory.
const _ENOENT_WIN = 3;

/// A structure built from a glob that efficiently lists filesystem entities
/// that match that glob.
///
/// This structure is designed to list the minimal number of physical
/// directories necessary to find everything that matches the glob. For example,
/// for the glob `foo/{bar,baz}/*`, there's no need to list the working
/// directory or even `foo/`; only `foo/bar` and `foo/baz` should be listed.
///
/// This works by creating a tree of [_ListTreeNode]s, each of which corresponds
/// to a single of directory nesting in the source glob. Each node has child
/// nodes associated with globs ([_ListTreeNode.children]), as well as its own
/// glob ([_ListTreeNode._validator]) that indicates which entities within that
/// node's directory should be returned.
///
/// For example, the glob `foo/{*.dart,b*/*.txt}` creates the following tree:
///
///     .
///     '-- "foo" (validator: "*.dart")
///         '-- "b*" (validator: "*.txt"
///
/// If a node doesn't have a validator, we know we don't have to list it
/// explicitly.
///
/// Nodes can also be marked as "recursive", which means they need to be listed
/// recursively (usually to support `**`). In this case, they will have no
/// children; instead, their validator will just encompass the globs that would
/// otherwise be in their children. For example, the glob
/// `foo/{**.dart,bar/*.txt}` creates a recursive node for `foo` with the
/// validator `**.dart,bar/*.txt`.
///
/// If the glob contains multiple filesystem roots (e.g. `{C:/,D:/}*.dart`),
/// each root will have its own tree of nodes. Relative globs use `.` as their
/// root instead.
class ListTree {
  /// A map from filesystem roots to the list tree for those roots.
  ///
  /// A relative glob will use `.` as its root.
  final _trees = new Map<String, _ListTreeNode>();

  /// Whether paths listed might overlap.
  ///
  /// If they do, we need to filter out overlapping paths.
  bool _canOverlap;

  ListTree(AstNode glob) {
    // The first step in constructing a tree from the glob is to simplify the
    // problem by eliminating options. [glob.flattenOptions] bubbles all options
    // (and certain ranges) up to the top level of the glob so we can deal with
    // them one at a time.
    var options = glob.flattenOptions();

    for (var option in options.options) {
      // Since each option doesn't include its own options, we can safely split
      // it into path components.
      var components = option.split(p.context);
      var firstNode = components.first.nodes.first;
      var root = '.';

      // Determine the root for this option, if it's absolute. If it's not, the
      // root's just ".".
      if (firstNode is LiteralNode) {
        var text = firstNode.text;
        if (Platform.isWindows) text.replaceAll("/", "\\");
        if (p.isAbsolute(text)) {
          // If the path is absolute, the root should be the only thing in the
          // first component.
          assert(components.first.nodes.length == 1);
          root = firstNode.text;
          components.removeAt(0);
        }
      }

      _addGlob(root, components);
    }

    _canOverlap = _computeCanOverlap();
  }

  /// Add the glob represented by [components] to the tree under [root].
  void _addGlob(String root, List<AstNode> components) {
    // The first [parent] represents the root directory itself. It may be null
    // here if this is the first option with this particular [root]. If so,
    // we'll create it below.
    //
    // As we iterate through [components], [parent] will be set to
    // progressively more nested nodes.
    var parent = _trees[root];
    for (var i = 0; i < components.length; i++) {
      var component = components[i];
      var recursive = component.nodes.any((node) => node is DoubleStarNode);
      var complete = i == components.length - 1;

      // If the parent node for this level of nesting already exists, the new
      // option will be added to it as additional validator options and/or
      // additional children.
      //
      // If the parent doesn't exist, we'll create it in one of the else
      // clauses below.
      if (parent != null) {
        if (parent.isRecursive || recursive) {
          // If [component] is recursive, mark [parent] as recursive. This
          // will cause all of its children to be folded into its validator.
          // If [parent] was already recursive, this is a no-op.
          parent.makeRecursive();

          // Add [component] and everything nested beneath it as an option to
          // [parent]. Since [parent] is recursive, it will recursively list
          // everything beneath it and filter them with one big glob.
          parent.addOption(_join(components.sublist(i)));
          return;
        } else if (complete) {
          // If [component] is the last component, add it to [parent]'s
          // validator but not to its children.
          parent.addOption(component);
        } else {
          // On the other hand if there are more components, add [component]
          // to [parent]'s children and not its validator. Since we process
          // each option's components separately, the same component is never
          // both a validator and a child.
          if (!parent.children.containsKey(component)) {
            parent.children[component] = new _ListTreeNode();
          }
          parent = parent.children[component];
        }
      } else if (recursive) {
        _trees[root] = new _ListTreeNode.recursive(
            _join(components.sublist(i)));
        return;
      } else if (complete) {
        _trees[root] = new _ListTreeNode()..addOption(component);
      } else {
        _trees[root] = new _ListTreeNode();
        _trees[root].children[component] = new _ListTreeNode();
        parent = _trees[root].children[component];
      }
    }
  }

  /// Computes the value for [_canOverlap].
  bool _computeCanOverlap() {
    // If this can list a relative path and an absolute path, the former may be
    // contained within the latter.
    if (_trees.length > 1 && _trees.containsKey('.')) return true;

    // Otherwise, this can only overlap if the tree beneath any given root could
    // overlap internally.
    return _trees.values.any((node) => node.canOverlap);
  }

  /// List all entities that match this glob beneath [root].
  Stream<FileSystemEntity> list({String root, bool followLinks: true}) {
    if (root == null) root = '.';
    var pool = new StreamPool();
    for (var rootDir in _trees.keys) {
      var dir = rootDir == '.' ? root : rootDir;
      pool.add(_trees[rootDir].list(dir, followLinks: followLinks));
    }
    pool.closeWhenEmpty();

    if (!_canOverlap) return pool.stream;

    // TODO(nweiz): Rather than filtering here, avoid double-listing directories
    // in the first place.
    var seen = new Set();
    return pool.stream.where((entity) {
      if (seen.contains(entity.path)) return false;
      seen.add(entity.path);
      return true;
    });
  }

  /// Synchronosuly list all entities that match this glob beneath [root].
  List<FileSystemEntity> listSync({String root, bool followLinks: true}) {
    if (root == null) root = '.';

    var result = _trees.keys.expand((rootDir) {
      var dir = rootDir == '.' ? root : rootDir;
      return _trees[rootDir].listSync(dir, followLinks: followLinks);
    });

    if (!_canOverlap) return result.toList();

    // TODO(nweiz): Rather than filtering here, avoid double-listing directories
    // in the first place.
    var seen = new Set();
    return result.where((entity) {
      if (seen.contains(entity.path)) return false;
      seen.add(entity.path);
      return true;
    }).toList();
  }
}

/// A single node in a [ListTree].
class _ListTreeNode {
  /// This node's child nodes, by their corresponding globs.
  ///
  /// Each child node will only be listed on directories that match its glob.
  ///
  /// This may be `null`, indicating that this node should be listed
  /// recursively.
  Map<SequenceNode, _ListTreeNode> children;

  /// This node's validator.
  ///
  /// This determines which entities will ultimately be emitted when [list] is
  /// called.
  OptionsNode _validator;

  /// Whether this node is recursive.
  ///
  /// A recursive node has no children and is listed recursively.
  bool get isRecursive => children == null;

  /// Whether this node doesn't itself need to be listed.
  ///
  /// If a node has no validator and all of its children are literal filenames,
  /// there's no need to list its contents. We can just directly traverse into
  /// its children.
  bool get _isIntermediate {
    if (_validator != null) return false;
    return children.keys.every((sequence) =>
        sequence.nodes.length == 1 && sequence.nodes.first is LiteralNode);
  }

  /// Returns whether listing this node might return overlapping results.
  bool get canOverlap {
    // A recusive node can never overlap with itself, because it will only ever
    // involve a single call to [Directory.list] that's then filtered with
    // [_validator].
    if (isRecursive) return false;

    // If there's more than one child node and at least one of the children is
    // dynamic (that is, matches more than just a literal string), there may be
    // overlap.
    if (children.length > 1 && children.keys.any((sequence) =>
          sequence.nodes.length > 1 || sequence.nodes.single is! LiteralNode)) {
      return true;
    }

    return children.values.any((node) => node.canOverlap);
  }

  /// Creates a node with no children and no validator.
  _ListTreeNode()
      : children = new Map<SequenceNode, _ListTreeNode>(),
        _validator = null;

  /// Creates a recursive node the given [validator].
  _ListTreeNode.recursive(SequenceNode validator)
      : children = null,
        _validator = new OptionsNode([validator]);

  /// Transforms this into recursive node, folding all its children into its
  /// validator.
  void makeRecursive() {
    if (isRecursive) return;
    _validator = new OptionsNode(children.keys.map((sequence) {
      var child = children[sequence];
      child.makeRecursive();
      return _join([sequence, child._validator]);
    }));
    children = null;
  }

  /// Adds [validator] to this node's existing validator.
  void addOption(SequenceNode validator) {
    if (_validator == null) {
      _validator = new OptionsNode([validator]);
    } else {
      _validator.options.add(validator);
    }
  }

  /// Lists all entities within [dir] matching this node or its children.
  ///
  /// This may return duplicate entities. These will be filtered out in
  /// [ListTree.list].
  Stream<FileSystemEntity> list(String dir, {bool followLinks: true}) {
    if (isRecursive) {
      return new Directory(dir).list(recursive: true, followLinks: followLinks)
          .where((entity) => _matches(entity.path.substring(dir.length + 1)));
    }

    var resultPool = new StreamPool();

    // Don't spawn extra [Directory.list] calls when we already know exactly
    // which subdirectories we're interested in.
    if (_isIntermediate) {
      children.forEach((sequence, child) {
        resultPool.add(child.list(p.join(dir, sequence.nodes.single.text),
            followLinks: followLinks));
      });
      resultPool.closeWhenEmpty();
      return resultPool.stream;
    }

    var resultController = new StreamController(sync: true);
    resultPool.add(resultController.stream);
    new Directory(dir).list(followLinks: followLinks).listen((entity) {
      var basename = entity.path.substring(dir.length + 1);
      if (_matches(basename)) resultController.add(entity);

      children.forEach((sequence, child) {
        if (entity is! Directory) return;
        if (!sequence.matches(basename)) return;
        var stream = child.list(p.join(dir, basename), followLinks: followLinks)
            .handleError((_) {}, test: (error) {
          // Ignore errors from directories not existing. We do this here so
          // that we only ignore warnings below wild cards. For example, the
          // glob "foo/bar/*/baz" should fail if "foo/bar" doesn't exist but
          // succeed if "foo/bar/qux/baz" doesn't exist.
          return error is FileSystemException &&
              (error.osError.errorCode == _ENOENT ||
              error.osError.errorCode == _ENOENT_WIN);
        });
        resultPool.add(stream);
      });
    },
        onError: resultController.addError,
        onDone: resultController.close);

    resultPool.closeWhenEmpty();
    return resultPool.stream;
  }

  /// Synchronously lists all entities within [dir] matching this node or its
  /// children.
  ///
  /// This may return duplicate entities. These will be filtered out in
  /// [ListTree.listSync].
  Iterable<FileSystemEntity> listSync(String dir, {bool followLinks: true}) {
    if (isRecursive) {
      return new Directory(dir)
          .listSync(recursive: true, followLinks: followLinks)
          .where((entity) => _matches(entity.path.substring(dir.length + 1)));
    }

    // Don't spawn extra [Directory.listSync] calls when we already know exactly
    // which subdirectories we're interested in.
    if (_isIntermediate) {
      return children.keys.expand((sequence) {
        return children[sequence].listSync(
            p.join(dir, sequence.nodes.single.text), followLinks: followLinks);
      });
    }

    return new Directory(dir).listSync(followLinks: followLinks)
        .expand((entity) {
      var entities = [];
      var basename = entity.path.substring(dir.length + 1);
      if (_matches(basename)) entities.add(entity);
      if (entity is! Directory) return entities;

      entities.addAll(children.keys
          .where((sequence) => sequence.matches(basename))
          .expand((sequence) {
        try {
          return children[sequence].listSync(
              p.join(dir, basename), followLinks: followLinks).toList();
        } on FileSystemException catch (error) {
          // Ignore errors from directories not existing. We do this here so
          // that we only ignore warnings below wild cards. For example, the
          // glob "foo/bar/*/baz" should fail if "foo/bar" doesn't exist but
          // succeed if "foo/bar/qux/baz" doesn't exist.
          if (error.osError.errorCode == _ENOENT ||
              error.osError.errorCode == _ENOENT_WIN) {
            return const [];
          } else {
            rethrow;
          }
        }
      }));

      return entities;
    });
  }

  /// Returns whether the native [path] matches [_validator].
  bool _matches(String path) {
    if (_validator == null) return false;
    return _validator.matches(toPosixPath(p.context, path));
  }

  String toString() => "($_validator) $children";
}

/// Joins each [components] into a new glob where each component is separated by
/// a path separator.
SequenceNode _join(Iterable<AstNode> components) {
  var componentsList = components.toList();
  var nodes = [componentsList.removeAt(0)];
  for (var component in componentsList) {
    nodes.add(new LiteralNode('/'));
    nodes.add(component);
  }
  return new SequenceNode(nodes);
}
