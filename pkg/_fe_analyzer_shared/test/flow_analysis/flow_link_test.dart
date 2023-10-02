// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/flow_analysis/flow_link.dart';
import 'package:checks/checks.dart';
import 'package:test/scaffolding.dart';

main() {
  group('get:', () {
    test('handles forward step', () {
      var a = _Link('A', key: 0, previous: null, previousForKey: null);
      var b = _Link('B', key: 0, previous: a, previousForKey: a);
      var c = _Link('C', key: 0, previous: b, previousForKey: b);
      var reader = _FlowLinkReader();
      check(reader.get(null, 0)).identicalTo(null);
      check(reader.get(a, 0)).identicalTo(a);
      check(reader.get(b, 0)).identicalTo(b);
      check(reader.get(c, 0)).identicalTo(c);
    });

    test('handles backward step', () {
      var a = _Link('A', key: 0, previous: null, previousForKey: null);
      var b = _Link('B', key: 0, previous: a, previousForKey: a);
      var c = _Link('C', key: 0, previous: b, previousForKey: b);
      var reader = _FlowLinkReader();
      check(reader.get(c, 0)).identicalTo(c);
      check(reader.get(b, 0)).identicalTo(b);
      check(reader.get(a, 0)).identicalTo(a);
      check(reader.get(null, 0)).identicalTo(null);
    });

    test('handles side step', () {
      // B   C
      //  \ /
      //   A
      var a = _Link('A', key: 0, previous: null, previousForKey: null);
      var b = _Link('B', key: 0, previous: a, previousForKey: a);
      var c = _Link('C', key: 0, previous: a, previousForKey: a);
      var reader = _FlowLinkReader();
      check(reader.get(b, 0)).identicalTo(b);
      check(reader.get(c, 0)).identicalTo(c);
    });

    test('handles multiple cache entries', () {
      var a = _Link('A', key: 0, previous: null, previousForKey: null);
      var b = _Link('B', key: 1, previous: a, previousForKey: null);
      var c = _Link('C', key: 2, previous: b, previousForKey: null);
      var reader = _FlowLinkReader();
      check(reader.get(a, 1)).identicalTo(null);
      check(reader.get(a, 2)).identicalTo(null);
      check(reader.get(c, 1)).identicalTo(b);
      check(reader.get(c, 2)).identicalTo(c);
    });
  });

  group('diff:', () {
    test('trivial null', () {
      var reader = _FlowLinkReader();
      var diff = reader.diff(null, null);
      check(diff.ancestor).identicalTo(null);
      check(diff.entries).isEmpty();
    });

    test('trivial non-null', () {
      var a = _Link('A', key: 0, previous: null, previousForKey: null);
      var reader = _FlowLinkReader();
      var diff = reader.diff(a, a);
      check(diff.ancestor).identicalTo(a);
      check(diff.entries).isEmpty();
    });

    test('finds common ancestor', () {
      // E
      // |
      // D   G
      // |   |
      // C   F
      //  \ /
      //   B
      //   |
      //   A
      var a = _Link('A', key: 0, previous: null, previousForKey: null);
      var b = _Link('B', key: 0, previous: a, previousForKey: a);
      var c = _Link('C', key: 0, previous: b, previousForKey: b);
      var d = _Link('D', key: 0, previous: c, previousForKey: c);
      var e = _Link('E', key: 0, previous: d, previousForKey: d);
      var f = _Link('F', key: 0, previous: b, previousForKey: b);
      var g = _Link('G', key: 0, previous: f, previousForKey: f);
      var reader = _FlowLinkReader();
      check(reader.diff(e, g).ancestor).identicalTo(b);
    });

    test('stepLeft twice for the same key', () {
      var a = _Link('A', key: 0, previous: null, previousForKey: null);
      var b = _Link('B', key: 0, previous: a, previousForKey: a);
      var c = _Link('C', key: 0, previous: b, previousForKey: b);
      var reader = _FlowLinkReader();
      var entries = reader.diff(c, a).entries;
      check(entries).length.equals(1);
      var entry = entries[0];
      check(entry.key).equals(0);
      check(entry.ancestor).identicalTo(a);
      check(entry.left).identicalTo(c);
      check(entry.right).identicalTo(a);
    });

    test('stepLeft handles multiple keys', () {
      var a = _Link('A', key: 0, previous: null, previousForKey: null);
      var b = _Link('B', key: 1, previous: a, previousForKey: null);
      var c = _Link('C', key: 0, previous: b, previousForKey: a);
      var d = _Link('D', key: 1, previous: c, previousForKey: b);
      var reader = _FlowLinkReader();
      var entries = reader.diff(d, b).entries;
      check(entries).length.equals(2);
      var entryMap = entries.toMap();
      check(entryMap[0]!.ancestor).identicalTo(a);
      check(entryMap[0]!.left).identicalTo(c);
      check(entryMap[0]!.right).identicalTo(a);
      check(entryMap[1]!.ancestor).identicalTo(b);
      check(entryMap[1]!.left).identicalTo(d);
      check(entryMap[1]!.right).identicalTo(b);
    });

    test('stepRight twice for the same key', () {
      var a = _Link('A', key: 0, previous: null, previousForKey: null);
      var b = _Link('B', key: 0, previous: a, previousForKey: a);
      var c = _Link('C', key: 0, previous: b, previousForKey: b);
      var reader = _FlowLinkReader();
      var entries = reader.diff(a, c).entries;
      check(entries).length.equals(1);
      var entry = entries[0];
      check(entry.key).equals(0);
      check(entry.ancestor).identicalTo(a);
      check(entry.left).identicalTo(a);
      check(entry.right).identicalTo(c);
    });

    test('stepRight handles multiple keys', () {
      var a = _Link('A', key: 0, previous: null, previousForKey: null);
      var b = _Link('B', key: 1, previous: a, previousForKey: null);
      var c = _Link('C', key: 0, previous: b, previousForKey: a);
      var d = _Link('D', key: 1, previous: c, previousForKey: b);
      var reader = _FlowLinkReader();
      var entries = reader.diff(b, d).entries;
      check(entries).length.equals(2);
      var entryMap = entries.toMap();
      check(entryMap[0]!.ancestor).identicalTo(a);
      check(entryMap[0]!.left).identicalTo(a);
      check(entryMap[0]!.right).identicalTo(c);
      check(entryMap[1]!.ancestor).identicalTo(b);
      check(entryMap[1]!.left).identicalTo(b);
      check(entryMap[1]!.right).identicalTo(d);
    });

    test('multiple keys with stepLeft and stepRight', () {
      // B(0)   D(1)
      // |      |
      // A(1)   C(0)
      //  \    /
      //   null
      var a = _Link('A', key: 1, previous: null, previousForKey: null);
      var b = _Link('B', key: 0, previous: a, previousForKey: null);
      var c = _Link('C', key: 0, previous: null, previousForKey: null);
      var d = _Link('D', key: 1, previous: c, previousForKey: null);
      var reader = _FlowLinkReader();
      var entries = reader.diff(b, d).entries;
      check(entries).length.equals(2);
      var entryMap = entries.toMap();
      check(entryMap[0]!.ancestor).identicalTo(null);
      check(entryMap[0]!.left).identicalTo(b);
      check(entryMap[0]!.right).identicalTo(c);
      check(entryMap[1]!.ancestor).identicalTo(null);
      check(entryMap[1]!.left).identicalTo(a);
      check(entryMap[1]!.right).identicalTo(d);
    });

    test('diffs only on one side', () {
      // A(1)   B(0)
      //  \    /
      //   null
      var a = _Link('A', key: 1, previous: null, previousForKey: null);
      var b = _Link('B', key: 0, previous: null, previousForKey: null);
      var reader = _FlowLinkReader();
      var entries = reader.diff(a, b).entries;
      check(entries).length.equals(2);
      var entryMap = entries.toMap();
      check(entryMap[0]!.ancestor).identicalTo(null);
      check(entryMap[0]!.left).identicalTo(null);
      check(entryMap[0]!.right).identicalTo(b);
      check(entryMap[1]!.ancestor).identicalTo(null);
      check(entryMap[1]!.left).identicalTo(a);
      check(entryMap[1]!.right).identicalTo(null);
    });
  });
}

class _FlowLinkReader extends FlowLinkReader<_Link> {}

base class _Link extends FlowLink<_Link> {
  final String debugName;

  _Link(this.debugName,
      {required super.key,
      required super.previous,
      required super.previousForKey});

  @override
  String toString() => debugName;
}

extension on List<FlowLinkDiffEntry<_Link>> {
  Map<int, FlowLinkDiffEntry<_Link>> toMap() {
    Map<int, FlowLinkDiffEntry<_Link>> result = {};
    for (var entry in this) {
      check(result[entry.key]).isNull();
      result[entry.key] = entry;
    }
    return result;
  }
}
