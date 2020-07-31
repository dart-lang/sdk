// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:front_end/src/api_unstable/dart2js.dart'
    show $0, $9, $A, $Z, $a, $z;

/// Returns a list of strings that are short valid identifiers based on the
/// corresponding full strings in [strings].
///
/// [strings] must not contain the empty string.
/// [strings] must have no duplicates.
List<String> abbreviateToIdentifiers(Iterable<String> strings,
    {int minLength = 6}) {
  var nodes = [for (final string in strings) _Node(string)];
  _partition(nodes, minLength, [], 0);
  return [for (final node in nodes) node.assignment];
}

class _Node {
  final String string;
  String assignment;
  _Node(this.string);
}

/// Walk the prefix tree or TRIE of [nodes], assigning compressed names built
/// from the distinguishing characters along the path.
///
/// - [index] is the position of the first potentially different character,
///   i.e. the current TRIE depth.
/// - [path] contains the prefix of the compressed name at this depth.
/// - Path compression starts after the first [minLength] characters.
void _partition(
    List<_Node> nodes, int minLength, List<String> path, int index) {
  while (true) {
    // Handle trivial partitions.
    if (nodes.length == 0) return;
    if (nodes.length == 1 && path.length >= minLength) {
      String name = path.join();
      assert(name.isNotEmpty);
      nodes.single.assignment = name;
      return;
    }

    // Partition on the code unit at position [index], setting [terminating] if
    // some string ends at this length;
    Map<int, List<_Node>> partition = {};
    _Node terminating;

    for (final node in nodes) {
      String string = node.string;
      assert(string.length > 0);
      if (index < string.length) {
        int codeUnit = string.codeUnitAt(index);
        (partition[codeUnit] ??= []).add(node);
      } else {
        assert(terminating == null); // i.e. no duplicates.
        terminating = node;
      }
    }

    if (terminating != null) {
      terminating.assignment = path.join();
    }

    if (partition.length == 0) return;

    if (partition.length > 1) {
      var keys = partition.keys.toList();
      var keyEncodings = _discriminators(keys, path.isEmpty);
      for (int key in keys) {
        var children = partition[key];
        var discriminator = keyEncodings[key];
        _partition(children, minLength, [...path, discriminator], index + 1);
      }
      return;
    }

    assert(partition.length == 1);
    // All the strings have the same code unit at [index]. Use iteration to
    // find next partition point to avoid recursing down the whole string
    // length. The path is compressed by omitting to add fragments to [path]
    // unless we are near the start of the string.

    int codeUnit = partition.keys.single;
    // Add some characters to name to distinguish from terminating strings.
    // Add the first few legal identifier characters of the string regardless.
    if (terminating != null || path.length < minLength) {
      path.add(_isIdentifier(codeUnit, path.isEmpty)
          ? String.fromCharCode(codeUnit)
          : '_');
    }
    nodes = partition.values.single;
    index += 1;
  }
}

Map<int, String> _discriminators(List<int> keys, bool atStart) {
  // Assign each partition a distinguishing short string. If the partition key
  // is a valid identifier character, it can be used, otherwise we could use
  // `'_'` or an escaped code like `'x3b'` or `'u12ef'`. If we use an escape
  // like `'x3b'` then we need to be careful with the partition key `x`, as it
  // might be followed by `3b`. We avoid this problem without lookahead by
  // encoding `x` as an escape (i.e. `'x78'`) if there is another `x`-escape.

  const xCode = 0x78;
  const uCode = 0x75;

  bool hasX = false;
  bool hasU = false;

  int xEscapes = 0;
  int uEscapes = 0;
  for (int key in keys) {
    if (_isIdentifier(key, atStart)) {
      if (key == xCode) hasX = true;
      if (key == uCode) hasU = true;
    } else if (key < 256) {
      xEscapes++;
    } else {
      uEscapes++;
    }
  }

  Map<int, String> encoding = {};
  bool escapeToUnderscore = false;

  if (uEscapes + xEscapes <= 1) {
    escapeToUnderscore = true;
    xEscapes = uEscapes = 0;
  }

  if (uEscapes > 0 && hasU) {
    encoding[uCode] = 'x75';
    xEscapes++;
  }
  if (xEscapes > 0 && hasX) {
    encoding[xCode] = 'x78';
  }

  for (int key in keys) {
    if (encoding.containsKey(key)) continue;
    if (_isIdentifier(key, atStart)) {
      encoding[key] = String.fromCharCode(key);
    } else {
      if (escapeToUnderscore) {
        encoding[key] = '_';
      } else if (key < 256) {
        encoding[key] = 'x' + key.toRadixString(16).padLeft(2, '0');
      } else {
        encoding[key] = 'u' + key.toRadixString(16).padLeft(4, '0');
      }
    }
  }

  return encoding;
}

bool _isIdentifier(int codeUnit, bool atStart) {
  return atStart ? _isAsciiAlpha(codeUnit) : _isAsciiAlphanumeric(codeUnit);
}

bool _isAsciiAlphanumeric(int codeUnit) {
  return $0 <= codeUnit && codeUnit <= $9 || _isAsciiAlpha(codeUnit);
}

bool _isAsciiAlpha(int codeUnit) {
  return $A <= codeUnit && codeUnit <= $Z || $a <= codeUnit && codeUnit <= $z;
}
