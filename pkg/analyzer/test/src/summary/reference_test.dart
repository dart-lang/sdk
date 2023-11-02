// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/summary2/reference.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../util/tree_string_sink.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ReferenceTest);
  });
}

@reflectiveTest
class ReferenceTest {
  final _IdMap idMap = _IdMap();

  void assertReferenceText(Reference reference, String expected) {
    final buffer = StringBuffer();
    _ReferenceWriter(
      sink: TreeStringSink(
        sink: buffer,
        indent: '',
      ),
      idMap: idMap,
    ).write(reference);
    final actual = buffer.toString();

    if (actual != expected) {
      print('-------- Actual --------');
      print('$actual------------------------');
      NodeTextExpectationsCollector.add(actual);
    }
    expect(actual, expected);
  }

  void test_addChild() {
    final root = Reference.root();
    assertReferenceText(root, r'''
<root>
  id: r0
''');

    final foo1 = root.addChild('foo');
    expect(foo1.elementName, 'foo');
    expect(idMap[foo1], 'r1');
    assertReferenceText(root, r'''
<root>
  id: r0
  childrenUnion: r1
  children
    foo
      id: r1
''');

    final foo2 = root.addChild('foo');
    expect(foo2.elementName, 'foo');
    expect(idMap[foo1], 'r1');
    expect(idMap[foo2], 'r2');
    assertReferenceText(root, r'''
<root>
  id: r0
  childrenUnion: r3
  children
    foo
      id: r3
      childrenUnion: r4
      children
        @def
          id: r4
          childrenUnion: {0: r1, 1: r2}
          children
            0
              id: r1
            1
              id: r2
''');

    final foo3 = root.addChild('foo');
    expect(foo3.elementName, 'foo');
    expect(idMap[foo1], 'r1');
    expect(idMap[foo2], 'r2');
    expect(idMap[foo3], 'r5');
    assertReferenceText(root, r'''
<root>
  id: r0
  childrenUnion: r3
  children
    foo
      id: r3
      childrenUnion: r4
      children
        @def
          id: r4
          childrenUnion: {0: r1, 1: r2, 2: r5}
          children
            0
              id: r1
            1
              id: r2
            2
              id: r5
''');
  }

  void test_getChild() {
    final root = Reference.root();
    assertReferenceText(root, r'''
<root>
  id: r0
''');

    // 0 -> 1
    {
      final first = root.getChild('foo');
      final second = root.getChild('foo');
      final third = root['foo'];
      expect(second, same(first));
      expect(third, same(first));
      expect(idMap[first], 'r1');
    }
    assertReferenceText(root, r'''
<root>
  id: r0
  childrenUnion: r1
  children
    foo
      id: r1
''');

    // 1 -> 2
    {
      final first = root.getChild('bar');
      final second = root.getChild('bar');
      final third = root['bar'];
      expect(second, same(first));
      expect(third, same(first));
      expect(idMap[first], 'r2');
    }
    assertReferenceText(root, r'''
<root>
  id: r0
  childrenUnion: {foo: r1, bar: r2}
  children
    foo
      id: r1
    bar
      id: r2
''');
  }

  void test_indexRead() {
    final root = Reference.root();
    expect(root['foo'], isNull);
    assertReferenceText(root, r'''
<root>
  id: r0
''');
  }

  void test_remove() {
    final root = Reference.root();
    assertReferenceText(root, r'''
<root>
  id: r0
''');

    final foo = root.getChild('foo');
    final bar = root.getChild('bar');
    final baz = root.getChild('baz');
    assertReferenceText(root, r'''
<root>
  id: r0
  childrenUnion: {foo: r1, bar: r2, baz: r3}
  children
    foo
      id: r1
    bar
      id: r2
    baz
      id: r3
''');

    // 3 -> 2
    final bar2 = root.removeChild('bar');
    expect(bar2, same(bar));
    assertReferenceText(root, r'''
<root>
  id: r0
  childrenUnion: {foo: r1, baz: r3}
  children
    foo
      id: r1
    baz
      id: r3
''');

    // 2 -> 1
    final baz2 = root.removeChild('baz');
    expect(baz2, same(baz));
    assertReferenceText(root, r'''
<root>
  id: r0
  childrenUnion: r1
  children
    foo
      id: r1
''');

    // 1 -> 0
    final foo2 = root.removeChild('foo');
    expect(foo2, same(foo));
    assertReferenceText(root, r'''
<root>
  id: r0
''');

    final foo3 = root.removeChild('foo');
    expect(foo3, isNull);
  }
}

class _IdMap {
  final Map<Reference, String> map = Map.identity();

  String operator [](Reference reference) {
    return map[reference] ??= 'r${map.length}';
  }
}

class _ReferenceWriter {
  final TreeStringSink sink;
  final _IdMap idMap;

  _ReferenceWriter({
    required this.sink,
    required this.idMap,
  });

  void write(Reference reference) {
    if (reference.isRoot) {
      sink.writelnWithIndent('<root>');
    } else {
      sink.writelnWithIndent(reference.name);
    }

    sink.withIndent(() {
      sink.writelnWithIndent('id: ${idMap[reference]}');

      final union = reference.childrenUnionForTesting;
      if (union != null) {
        sink.writeIndentedLine(() {
          sink.write('childrenUnion: ');
          switch (union) {
            case Reference child:
              expect(reference.children, hasLength(1));
              sink.write(idMap[child]);
            case Map<String, Reference> map:
              expect(reference.children, hasLength(greaterThanOrEqualTo(2)));
              final entriesStr = map.entries.map((e) {
                return '${e.key}: ${idMap[e.value]}';
              }).join(', ');
              sink.write('{$entriesStr}');
            default:
              throw UnimplementedError('(${union.runtimeType}) $union');
          }
        });
      }

      // Sanity check.
      for (final child in reference.children) {
        expect(child.parent, same(reference));
      }

      sink.writeElements('children', reference.children.toList(), write);
    });
  }
}
