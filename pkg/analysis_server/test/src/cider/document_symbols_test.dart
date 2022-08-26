// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/lsp_protocol/protocol.dart';
import 'package:analysis_server/src/cider/document_symbols.dart';
import 'package:test/expect.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../utilities/mock_packages.dart';
import 'cider_service.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(CiderDocumentSymbolsComputerTest);
  });
}

@reflectiveTest
class CiderDocumentSymbolsComputerTest extends CiderServiceTest {
  void test_class() async {
    var unitOutline = await _compute('''
abstract class A<K, V> {
  int fa, fb;
  String fc;
  A(int i, String s);
  A.name(num p);
  A._privateName(num p);
  static String ma(int pa) => null;
  _mb(int pb);
  R mc<R, P>(P p) {}
  String get propA => null;
  set propB(int v) {}
}
class B {
  B(int p);
}
String fa(int pa) => null;
R fb<R, P>(P p) {}
''');

    expect(unitOutline, hasLength(4));
    // A
    {
      var outline_A = unitOutline[0];
      _expect(outline_A,
          kind: SymbolKind.Class,
          name: 'A',
          start: Position(line: 0, character: 0),
          end: Position(line: 11, character: 1));
      // A children
      var outlines_A = outline_A.children!;
      expect(outlines_A, hasLength(11));

      _expect(outlines_A[0], kind: SymbolKind.Field, name: 'fa');
      _expect(outlines_A[1], kind: SymbolKind.Field, name: 'fb');
      _expect(outlines_A[2], kind: SymbolKind.Field, name: 'fc');

      _expect(outlines_A[3],
          kind: SymbolKind.Constructor,
          name: 'A',
          detail: '(int i, String s)',
          start: Position(line: 3, character: 2),
          end: Position(line: 3, character: 21));

      _expect(outlines_A[4],
          kind: SymbolKind.Constructor,
          name: 'A.name',
          start: Position(line: 4, character: 2),
          end: Position(line: 4, character: 16),
          detail: '(num p)');

      _expect(outlines_A[5],
          kind: SymbolKind.Constructor,
          name: 'A._privateName',
          start: Position(line: 5, character: 2),
          end: Position(line: 5, character: 24),
          detail: '(num p)');

      _expect(outlines_A[6],
          kind: SymbolKind.Method,
          name: 'ma',
          start: Position(line: 6, character: 2),
          end: Position(line: 6, character: 35),
          detail: '(int pa)');

      _expect(outlines_A[7],
          kind: SymbolKind.Method,
          name: '_mb',
          start: Position(line: 7, character: 2),
          end: Position(line: 7, character: 14),
          detail: '(int pb)');

      _expect(outlines_A[8],
          kind: SymbolKind.Method,
          name: 'mc',
          start: Position(line: 8, character: 2),
          end: Position(line: 8, character: 20),
          detail: '(P p)');

      _expect(outlines_A[9],
          kind: SymbolKind.Property,
          name: 'propA',
          start: Position(line: 9, character: 2),
          end: Position(line: 9, character: 27));

      _expect(outlines_A[10],
          kind: SymbolKind.Property,
          name: 'propB',
          start: Position(line: 10, character: 2),
          end: Position(line: 10, character: 21),
          detail: '(int v)');
      // // B
      var outline_B = unitOutline[1];
      _expect(outline_B,
          kind: SymbolKind.Class,
          name: 'B',
          start: Position(line: 12, character: 0),
          end: Position(line: 14, character: 1));

      // B children
      var outlines_B = outline_B.children!;
      expect(outlines_B, hasLength(1));

      _expect(outlines_B[0],
          kind: SymbolKind.Constructor,
          name: 'B',
          start: Position(line: 13, character: 2),
          end: Position(line: 13, character: 11),
          detail: '(int p)');

      _expect(unitOutline[2],
          kind: SymbolKind.Function,
          name: 'fa',
          start: Position(line: 15, character: 0),
          end: Position(line: 15, character: 26),
          detail: '(int pa)');

      _expect(unitOutline[3],
          kind: SymbolKind.Function,
          name: 'fb',
          start: Position(line: 16, character: 0),
          end: Position(line: 16, character: 18),
          detail: '(P p)');
    }
  }

  void test_isTest_isTestGroup() async {
    BazelMockPackages.instance.addMeta(resourceProvider);

    var outline = await _compute('''
import 'package:meta/meta.dart';

@isTestGroup
void myGroup(name, body()) {}

@isTest
void myTest(name) {}

void f() {
  myGroup('group1', () {
    myGroup('group1_1', () {
      myTest('test1_1_1');
      myTest('test1_1_2');
    });
    myGroup('group1_2', () {
      myTest('test1_2_1');
    });
  });
  myGroup('group2', () {
    myTest('test2_1');
    myTest('test2_2');
  });
}
''');
    // outline
    expect(outline, hasLength(3));
    // f
    var f_outline = outline[2];
    _expect(
      f_outline,
      kind: SymbolKind.Function,
      name: 'f',
      start: Position(line: 8, character: 0),
      end: Position(line: 22, character: 1),
      detail: '()',
    );
    var f_children = f_outline.children!;
    expect(f_children, hasLength(2));
    // group1
    var group1_outline = f_children[0];
    _expect(
      group1_outline,
      kind: SymbolKind.Method,
      name: 'myGroup("group1")',
      start: Position(line: 9, character: 2),
      end: Position(line: 17, character: 4),
    );
    var group1_children = group1_outline.children!;
    expect(group1_children, hasLength(2));
    // group1_1
    var group1_1_outline = group1_children[0];
    _expect(group1_1_outline,
        kind: SymbolKind.Method,
        name: 'myGroup("group1_1")',
        start: Position(line: 10, character: 4),
        end: Position(line: 13, character: 6));
    var group1_1_children = group1_1_outline.children!;
    expect(group1_1_children, hasLength(2));
    // test1_1_1
    var test1_1_1_outline = group1_1_children[0];
    _expect(test1_1_1_outline,
        kind: SymbolKind.Method,
        name: 'myTest("test1_1_1")',
        start: Position(line: 11, character: 6),
        end: Position(line: 11, character: 25));
    // test1_1_1
    var test1_1_2_outline = group1_1_children[1];
    _expect(test1_1_2_outline,
        kind: SymbolKind.Method,
        name: 'myTest("test1_1_2")',
        start: Position(line: 12, character: 6),
        end: Position(line: 12, character: 25));
    // group1_2
    var group1_2_outline = group1_children[1];
    _expect(
      group1_2_outline,
      kind: SymbolKind.Method,
      name: 'myGroup("group1_2")',
      start: Position(line: 14, character: 4),
      end: Position(line: 16, character: 6),
    );
    var group1_2_children = group1_2_outline.children!;
    expect(group1_2_children, hasLength(1));
    // test2_1
    var test1_2_1_outline = group1_2_children[0];
    _expect(test1_2_1_outline,
        kind: SymbolKind.Method,
        name: 'myTest("test1_2_1")',
        start: Position(line: 15, character: 6),
        end: Position(line: 15, character: 25));
    // group2
    var group2_outline = f_children[1];
    _expect(
      group2_outline,
      kind: SymbolKind.Method,
      name: 'myGroup("group2")',
      start: Position(line: 18, character: 2),
      end: Position(line: 21, character: 4),
    );
    var group2_children = group2_outline.children!;
    expect(group2_children, hasLength(2));
    // test2_1
    var test2_1_outline = group2_children[0];
    _expect(test2_1_outline,
        kind: SymbolKind.Method,
        name: 'myTest("test2_1")',
        start: Position(line: 19, character: 4),
        end: Position(line: 19, character: 21));
    // test2_2
    var test2_2_outline = group2_children[1];
    _expect(
      test2_2_outline,
      kind: SymbolKind.Method,
      name: 'myTest("test2_2")',
      start: Position(line: 20, character: 4),
      end: Position(line: 20, character: 21),
    );
  }

  Future<List<DocumentSymbol>> _compute(String content) async {
    newFile(testPath, content);
    return CiderDocumentSymbolsComputer(
      fileResolver,
    ).compute2(convertPath(testPath));
  }

  void _expect(DocumentSymbol outline,
      {SymbolKind? kind,
      String? name,
      Position? start,
      Position? end,
      String? detail}) {
    if (kind != null) {
      expect(outline.kind, kind);
    }
    if (name != null) {
      expect(outline.name, name);
    }
    if (start != null) {
      var range = outline.range;
      expect(range.start, start);
      expect(range.end, end);
    }
    if (detail != null) {
      expect(outline.detail, detail);
    }
  }
}
