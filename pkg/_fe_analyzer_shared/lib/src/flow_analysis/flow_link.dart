// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Abstract base class forming the basis for an efficient immutable map data
/// structure that can track program state.
///
/// Each instance of [FlowLink] represents a key/value pair, where the [key] is
/// a non-negative integer, and the value is stored in the derived class; a map
/// is formed by chaining together multiple [FlowLink] objects through
/// [previous] pointers. In this way, a collection of [FlowLink] objects be used
/// to model program state, with each [FlowLink] representing a change to a
/// single state variable, and the [previous] pointer pointing to the previous
/// state of the program. In this interpretation, `null` represents the initial
/// program state, in which all state variables take on their default values.
///
/// Multiple [FlowLink] objects are allowed to point to the same [previous]
/// object; in this way, all [FlowLink] objects implicitly form a tree, with
/// `null` at the root. In the interpretation where a collection of [FlowLink]
/// objects are used to model program state, and a single [FlowLink] represents
/// a change to a single state variable, the tree corresponds to the dominator
/// tree. There are no "child" pointers, so the tree may only be traversed in
/// the leaf-to-root direction, and once a branch is no longer needed it will be
/// reclaimed by the garbage collector.
///
/// The [FlowLinkReader] class may be used to efficiently look up map entries in
/// a given [FlowLink] object. It makes use of the fact that [key]s are
/// non-negative integers to maintain a current state in a list.
///
/// The generic parameter [Link] should be instantiated with the derived class.
abstract base class FlowLink<Link extends FlowLink<Link>> {
  /// The integer key for this [FlowLink]. In the interpretation where a
  /// collection of [FlowLink] objects are used to model program state, and a
  /// single [FlowLink] represents a change to a single state variable, this key
  /// tells which state variable has changed.
  final int key;

  /// Pointer allowing multiple [FlowLink] objects to be joined into a singly
  /// linked list. In the interpretation where a collection of [FlowLink]
  /// objects are used to model program state, and a single [FlowLink]
  /// represents a change to a single state variable, this pointer points to the
  /// state of the program prior to the change.
  final Link? previous;

  /// Pointer to the nearest [FlowLink] in the [previous] chain whose [key]
  /// matches this one, or `null` if there is no matching [FlowLink]. This is
  /// used by [FlowLinkReader] to quickly update its state representation when
  /// traversing the implicit tree of [FlowLink] objects.
  final Link? previousForKey;

  /// The number of [previous] links that need to be traversed to reach `null`.
  /// This is used by [FlowLinkReader] to quickly find the common ancestor of
  /// two points in the implicit tree of [FlowLink] objects.
  final int _depth;

  /// Creates a new [FlowLink] object. Caller is required to satisfy the
  /// invariant described in [previousForKey].
  FlowLink(
      {required this.key, required this.previous, required this.previousForKey})
      : _depth = previous.depth + 1 {
    assert(key >= 0);
    assert(identical(previousForKey, _computePreviousForKey(key)));
  }

  /// Debug only: computes the correct value for [previousForKey], to check that
  /// the caller supplied the appropriate value to the constructor.
  Link? _computePreviousForKey(int key) {
    Link? link = previous;
    while (link != null) {
      if (link.key == key) break;
      link = link.previous;
    }
    return link;
  }
}

/// Information about a difference between two program states, returned by
/// [FlowLinkReader.diff].
class FlowLinkDiffEntry<Link extends FlowLink<Link>> {
  /// The key that differs between the [FlowLink] maps passed to
  /// [FlowLinkReader.diff].
  final int key;

  /// During a diff operation, the first [FlowLink] associated with [key] that
  /// was found while walking the [FlowLink.previous] chain for the `left`
  /// argument to [FlowLinkReader.diff], or `null` if no such key has been found
  /// yet.
  Link? _firstLeft;

  /// During a diff operation, the first [FlowLink] associated with [key] that
  /// was found while walking the [FlowLink.previous] chain for the `right`
  /// argument to [FlowLinkReader.diff], or `null` if no such key has been found
  /// yet.
  Link? _firstRight;

  /// During a diff operation, the value of [FlowLink.previousForKey] that was
  /// most recently encountered while walking the [FlowLink.previous] chains for
  /// both the `left` and `right` arguments to [FlowLinkReader.diff].
  Link? _previousForKey;

  FlowLinkDiffEntry._(
      {required this.key,
      required Link? firstLeft,
      required Link? firstRight,
      required Link? previousForKey})
      : _firstLeft = firstLeft,
        _firstRight = firstRight,
        _previousForKey = previousForKey;

  /// The [FlowLink] associated with [key] in the common ancestor of the two
  /// [FlowLink] maps passed to [FlowLinkReader.diff], or `null` if the common
  /// ancestor doesn't associate any [FlowLink] with [key].
  Link? get ancestor {
    // This is called by a client after the `diff` operation has completed.
    // Therefore, `_previousForKey` comes from the `FlowLink` that the `diff`
    // operation visited last; i.e. the one closest to the common ancestor node.
    // So it *is* the common ancestor for the given key.
    return _previousForKey;
  }

  /// The [FlowLink] associated with [key] in the `left` [FlowLink] map passed
  /// to [FlowLinkReader.diff], or `null` if the `left` [FlowLink] map doesn't
  /// associate any [FlowLink] with [key].
  Link? get left {
    // This is called by a client after the `diff` operation has completed.
    // Therefore, `_firstLeft` is either the first [FlowLink] encountered while
    // traversing the linked list for the `left` side of the diff, or it's
    // `null` and *no* [FlowLink] was encountered on the left side of the diff
    // with the given key; in the latter situation, we may safely return
    // `_previousForKey`, which is the common ancestor for the key.
    return _firstLeft ?? _previousForKey;
  }

  /// The [FlowLink] associated with [key] in the `right` [FlowLink] map passed
  /// to [FlowLinkReader.diff], or `null` if the `right` [FlowLink] map doesn't
  /// associate any [FlowLink] with [key].
  Link? get right {
    // This is called by a client after the `diff` operation has completed.
    // Therefore, `_firstRight` is either the first [FlowLink] encountered while
    // traversing the linked list for the `right` side of the diff, or it's
    // `null` and *no* [FlowLink] was encountered on the right side of the diff
    // with the given key; in the latter situation, we may safely return
    // `_previousForKey`, which is the common ancestor for the key.
    return _firstRight ?? _previousForKey;
  }
}

/// Efficient mechanism for looking up entries in the map formed implicitly by
/// a linked list of [FlowLink] objects, and for finding the difference between
/// two such maps.
///
/// This class works by maintaining a "current" pointer recording the [FlowLink]
/// that was most recently passed to [get], and a cache of the state of all
/// state variables implied by that [FlowLink] object. The cache can be updated
/// in O(n) time, where n is the number of tree edges between one state and
/// another. Accordingly, for maximum efficiency, the caller should try not to
/// jump around the tree too much in successive calls to [get].
class FlowLinkReader<Link extends FlowLink<Link>> {
  /// The [FlowLink] pointer most recently passed to [_setCurrent].
  Link? _current;

  /// A cache of the lookup results that should be returned by [get] for each
  /// possible integer key, for the [_current] link.
  List<Link?> _cache = [];

  /// Temporary scratch area used by [_diffCore]. Each non-null entry represents
  /// an index into the list of entries that [_diffCore] will return; that entry
  /// has the same integer key as the corresponding index into this list.
  List<int?> _diffIndices = [];

  /// Computes the difference between [FlowLink] states represented by [left]
  /// and [right].
  ///
  /// Two values are returned: the common ancestor of [left] and [right], and
  /// a list of [FlowLinkDiffEntry] objects representing the difference among
  /// [left], [right], and their common ancestor.
  ///
  /// If [left] and [right] are identical, this method has time complexity
  /// `O(1)`.
  ///
  /// Otherwise, this method has time complexity `O(n)`, where `n` is the number
  /// of edges between [left] and [right] in the implicit [FlowLink] tree.
  ({Link? ancestor, List<FlowLinkDiffEntry<Link>> entries}) diff(
      Link? left, Link? right) {
    if (identical(left, right)) {
      return (ancestor: left, entries: const []);
    }
    List<FlowLinkDiffEntry<Link>> entries = [];
    Link? ancestor = _diffCore(left, right, entries);
    return (ancestor: ancestor, entries: entries);
  }

  /// Looks up the first entry in the linked list formed by [FlowLink.previous],
  /// starting at [link], whose key matches [key]. If there is no such entry,
  /// `null` is returned.
  ///
  /// If [link] is `null` or matches [_current], this method has time
  /// complexity `O(1). In this circumstance, [_current] is unchanged.
  ///
  /// Otherwise, this method has time complexity `O(n)`, where `n` is the number
  /// of edges between [_current] and [link] in the implicit [FlowLink] tree. In
  /// this circumstance, [_current] is set to [link].
  Link? get(Link? link, int key) {
    if (link == null) {
      return null;
    }
    _setCurrent(link);
    return _cache.get(key);
  }

  /// The core algorithm used by [diff] and [_setCurrent]. Computes a difference
  /// between [left] and [right], adding diff entries to [entries]. The return
  /// value is the common ancestor of [left] and [right].
  Link? _diffCore(
      Link? left, Link? right, List<FlowLinkDiffEntry<Link>> entries) {
    // The core strategy is to traverse the implicit [FlowLink] tree, starting
    // at `left` and `right`, and taking single steps through the linked list
    // formed by `FlowLink.previous`, until a common ancestor is found. For each
    // step, an entry is added to the `entries` list for the corresponding key
    // (or a previously made entry is updated), and `_diffIndices` is modified
    // to keep track of which keys have corresponding entries.

    // Takes a single step from `left` through the linked list formed by
    // `FlowLink.previous`, updating `entries` and `_diffIndices` as
    // appropriate.
    Link? stepLeft(Link left) {
      int key = left.key;
      int? index = _diffIndices.get(key);
      if (index == null) {
        // No diff entry has been created for this key yet, so create one.
        _diffIndices.set(key, entries.length);
        entries.add(new FlowLinkDiffEntry<Link>._(
            key: key,
            firstLeft: left,
            firstRight: null,
            previousForKey: left.previousForKey));
      } else {
        // A diff entry for this key has already been created, so update it.
        entries[index]._firstLeft ??= left;
        entries[index]._previousForKey = left.previousForKey;
      }
      return left.previous;
    }

    // Takes a single step from `right` through the linked list formed by
    // `FlowLink.previous`, updating `entries` and `_diffIndices` as
    // appropriate.
    Link? stepRight(Link right) {
      int key = right.key;
      int? index = _diffIndices.get(key);
      if (index == null) {
        _diffIndices.set(key, entries.length);
        entries.add(new FlowLinkDiffEntry<Link>._(
            key: key,
            firstLeft: null,
            firstRight: right,
            previousForKey: right.previousForKey));
      } else {
        entries[index]._firstRight ??= right;
        entries[index]._previousForKey = right.previousForKey;
      }
      return right.previous;
    }

    // Walk `left` and `right` back to their common ancestor.
    int leftDepth = left.depth;
    int rightDepth = right.depth;
    try {
      if (leftDepth > rightDepth) {
        do {
          // `left.depth > right.depth`, therefore `left.depth > 0`, so
          // `left != null`.
          left = stepLeft(left!);
          leftDepth--;
          assert(leftDepth == left.depth);
        } while (leftDepth > rightDepth);
      } else {
        while (rightDepth > leftDepth) {
          // `right.depth > left.depth`, therefore `right.depth > 0`, so
          // `right != null`.
          right = stepRight(right!);
          rightDepth--;
          assert(rightDepth == right.depth);
        }
      }
      while (!identical(left, right)) {
        assert(left.depth == right.depth);
        // The only possible value of type `FlowLink?` with a depth of `0` is
        // `null`. Therefore, since `left.depth == right.depth`, `left`
        // and `right` must either be both `null` or both non-`null`. Since
        // they're not identical to one another, it follows that they're both
        // non-`null`.
        left = stepLeft(left!);
        right = stepRight(right!);
      }
    } finally {
      // Clear `_diffIndices` for the next call to this method. Note that we
      // don't really expect an exception to occur above, but if one were to
      // occur, and we left non-null data in `_diffIndices`, that would produce
      // very confusing behavior on future invocations of this method. So to be
      // on the safe side, we do this clean up logic is in a `finally`
      // clause.
      for (int i = 0; i < entries.length; i++) {
        FlowLinkDiffEntry<Link> entry = entries[i];
        // Since `_diffIndices` was constructed as an index into `entries`, we
        // know that `_diffIndices[entry.key] == i`.
        assert(_diffIndices[entry.key] == i);
        // Therefore, there's no need to use `_diffIndices.set`, since we
        // already know that `entry.key < _diffIndices.length`.
        _diffIndices[entry.key] = null;
      }
    }

    return left;
  }

  /// Sets [_current] to [value], updating [_cache] in the process.
  void _setCurrent(Link? value) {
    if (identical(value, _current)) return;
    List<FlowLinkDiffEntry<Link>> entries = [];
    _diffCore(_current, value, entries);
    for (FlowLinkDiffEntry<Link> entry in entries) {
      _cache.set(entry.key, entry.right);
    }
    _current = value;
  }
}

extension on FlowLink<dynamic>? {
  /// Gets the `_depth` of `this`, or `0` if `this` is `null`.
  int get depth {
    FlowLink<dynamic>? self = this;
    if (self == null) return 0;
    return self._depth;
  }
}

extension<T extends Object> on List<T?> {
  /// Looks up the `index`th entry in `this` in a safe way, returning `null` if
  /// `index` is out of range.
  T? get(int index) => index < length ? this[index] : null;

  /// Stores `value` in the `index`th entry of `this`, increasing the length of
  /// `this` if necessary.
  void set(int index, T? value) {
    while (index >= length) {
      add(null);
    }
    this[index] = value;
  }
}
