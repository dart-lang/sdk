// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:typed_data';

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
  void test_UnlinkedCombinator_isShow_false() {
    Uint8List bytes = new UnlinkedCombinatorBuilder(
        isShow: false, names: ['aaa', 'bbb', 'ccc']).toBytes();

    var combinator = new UnlinkedCombinator(bytes);
    expect(combinator.isShow, isFalse);
    expect(combinator.names, ['aaa', 'bbb', 'ccc']);
  }

  void test_UnlinkedCombinator_isShow_true() {
    Uint8List bytes = new UnlinkedCombinatorBuilder(
        isShow: true, names: ['aaa', 'bbb', 'ccc']).toBytes();

    var combinator = new UnlinkedCombinator(bytes);
    expect(combinator.isShow, isTrue);
    expect(combinator.names, ['aaa', 'bbb', 'ccc']);
  }

  void test_UnlinkedNamespaceDirective() {
    Uint8List bytes = new UnlinkedNamespaceDirectiveBuilder(
        uri: 'package:foo/foo.dart',
        combinators: [
          new UnlinkedCombinatorBuilder(isShow: true, names: ['aaa']),
          new UnlinkedCombinatorBuilder(isShow: false, names: ['bbb', 'ccc'])
        ]).toBytes();

    var directive = new UnlinkedNamespaceDirective(bytes);
    expect(directive.uri, 'package:foo/foo.dart');
    expect(directive.combinators, hasLength(2));
    expect(directive.combinators[0].isShow, isTrue);
    expect(directive.combinators[0].names, ['aaa']);
    expect(directive.combinators[1].isShow, isFalse);
    expect(directive.combinators[1].names, ['bbb', 'ccc']);
  }

  void test_UnlinkedUnit() {
    Uint8List bytes = new UnlinkedUnitBuilder(apiSignature: [
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
      'p1.dart',
      'p2.dart',
    ], hasMixinApplication: true)
        .toBytes();

    var unit = new UnlinkedUnit(bytes);
    expect(unit.apiSignature, [0, 1, 2, 3, 4]);

    expect(unit.imports, hasLength(1));
    expect(unit.imports[0].uri, 'a.dart');

    expect(unit.exports, hasLength(1));
    expect(unit.exports[0].uri, 'b.dart');

    expect(unit.parts, ['p1.dart', 'p2.dart']);

    expect(unit.hasMixinApplication, isTrue);
  }

  void test_UnlinkedUnit_hasMixinApplication_false() {
    Uint8List bytes =
        new UnlinkedUnitBuilder(hasMixinApplication: false).toBytes();

    var unit = new UnlinkedUnit(bytes);
    expect(unit.hasMixinApplication, isFalse);
  }
}
