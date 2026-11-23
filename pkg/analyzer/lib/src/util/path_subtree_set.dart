// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:path/path.dart';

/// A set of subtrees of the file system, each given by the path of its root.
///
/// It answers whether a path is in one of the subtrees, the same as checking
/// the path against every root with [Context.equals] and [Context.isWithin].
/// But instead of scanning the roots, it looks up the path and each of its
/// ancestors in a [PathSet], so the cost does not depend on the number of
/// roots.
class PathSubtreeSet {
  final Context _context;

  /// The roots of the subtrees, compared with [Context.equals].
  final PathSet _roots;

  /// The lengths of [_roots].
  ///
  /// Normalized paths that are equal have the same length, so only the
  /// ancestors with one of these lengths are looked up in [_roots].
  final Set<int> _rootLengths = {};

  /// Creates a set of the subtrees at [roots], which must be absolute and
  /// normalized.
  new(this._context, Iterable<String> roots)
    : _roots = PathSet(context: _context) {
    for (var root in roots) {
      _roots.add(root);
      _rootLengths.add(root.length);
    }
  }

  /// Whether [path], or one of its ancestors, is a root of a subtree.
  ///
  /// The [path] must be absolute and normalized.
  bool containsSelfOrAncestor(String path) {
    if (_roots.isEmpty) {
      return false;
    }

    if (_isRoot(path, path.length)) {
      return true;
    }

    // In a normalized path, only the root can end with a separator. So the
    // ancestors are the parts before each separator after the root, and the
    // root itself.
    var separator = _context.separator.codeUnitAt(0);
    var rootLength = _context.rootPrefix(path).length;
    for (var i = path.length - 1; i >= rootLength; i--) {
      if (path.codeUnitAt(i) == separator && _isRoot(path, i)) {
        return true;
      }
    }
    return rootLength > 0 && _isRoot(path, rootLength);
  }

  /// Whether the first [length] code units of [path] are a root.
  bool _isRoot(String path, int length) {
    if (!_rootLengths.contains(length)) {
      return false;
    }
    if (length == path.length) {
      return _roots.contains(path);
    }
    return _roots.contains(path.substring(0, length));
  }
}
