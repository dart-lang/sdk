// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:typed_data';

import 'package:front_end/src/base/flat_buffers.dart' as fb;
import 'package:front_end/src/incremental/format.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(FormatTest);
  });
}

@reflectiveTest
class FormatTest {
  void test_UnlinkedCombinator_hides() {
    Uint8List bytes;
    {
      fb.Builder fbBuilder = new fb.Builder();
      fb.Offset offset =
          new UnlinkedCombinatorBuilder(hides: ['a', 'bb', 'ccc'])
              .finish(fbBuilder);
      bytes = fbBuilder.finish(offset);
    }

    var combinator = new UnlinkedCombinator(bytes);
    expect(combinator.shows, isEmpty);
    expect(combinator.hides, ['a', 'bb', 'ccc']);
  }

  void test_UnlinkedCombinator_shows() {
    Uint8List bytes;
    {
      fb.Builder fbBuilder = new fb.Builder();
      fb.Offset offset =
          new UnlinkedCombinatorBuilder(shows: ['a', 'bb', 'ccc'])
              .finish(fbBuilder);
      bytes = fbBuilder.finish(offset);
    }

    var combinator = new UnlinkedCombinator(bytes);
    expect(combinator.shows, ['a', 'bb', 'ccc']);
    expect(combinator.hides, isEmpty);
  }

  void test_UnlinkedNamespaceDirective() {
    Uint8List bytes;
    {
      fb.Builder fbBuilder = new fb.Builder();
      fb.Offset offset = new UnlinkedNamespaceDirectiveBuilder(
          uri: 'package:foo/foo.dart',
          combinators: [
            new UnlinkedCombinatorBuilder(shows: ['aaa']),
            new UnlinkedCombinatorBuilder(hides: ['bbb', 'ccc'])
          ]).finish(fbBuilder);
      bytes = fbBuilder.finish(offset);
    }

    var directive = new UnlinkedNamespaceDirective(bytes);
    expect(directive.uri, 'package:foo/foo.dart');
    expect(directive.combinators, hasLength(2));
    expect(directive.combinators[0].shows, ['aaa']);
    expect(directive.combinators[0].hides, isEmpty);
    expect(directive.combinators[1].shows, isEmpty);
    expect(directive.combinators[1].hides, ['bbb', 'ccc']);
  }

  void test_UnlinkedUnit() {
    Uint8List bytes;
    {
      fb.Builder fbBuilder = new fb.Builder();
      fb.Offset offset = new UnlinkedUnitBuilder(apiSignature: [
        0,
        1,
        2,
        3,
        4
      ], imports: [
        new UnlinkedNamespaceDirectiveBuilder(uri: 'a.dart')
      ], exports: [
        new UnlinkedNamespaceDirectiveBuilder(uri: 'b.dart')
      ], parts: [
        new UnlinkedNamespaceDirectiveBuilder(uri: 'p1.dart'),
        new UnlinkedNamespaceDirectiveBuilder(uri: 'p2.dart'),
      ]).finish(fbBuilder);
      bytes = fbBuilder.finish(offset);
    }

    var directive = new UnlinkedUnit(bytes);
    expect(directive.apiSignature, [0, 1, 2, 3, 4]);

    expect(directive.imports, hasLength(1));
    expect(directive.imports[0].uri, 'a.dart');

    expect(directive.exports, hasLength(1));
    expect(directive.exports[0].uri, 'b.dart');

    expect(directive.parts, hasLength(2));
    expect(directive.parts[0].uri, 'p1.dart');
    expect(directive.parts[1].uri, 'p2.dart');
  }
}
