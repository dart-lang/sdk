// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library polymer.test.refactor_test;

import 'package:unittest/unittest.dart';
import 'package:source_maps/refactor.dart';
import 'package:source_maps/parser.dart' show parse, Mapping;
import 'package:source_span/source_span.dart';

main() {
  group('conflict detection', () {
    var original = "0123456789abcdefghij";
    var file = new SourceFile(original);

    test('no conflict, in order', () {
      var txn = new TextEditTransaction(original, file);
      txn.edit(2, 4, '.');
      txn.edit(5, 5, '|');
      txn.edit(6, 6, '-');
      txn.edit(6, 7, '_');
      expect((txn.commit()..build('')).text, "01.4|5-_789abcdefghij");
    });

    test('no conflict, out of order', () {
      var txn = new TextEditTransaction(original, file);
      txn.edit(2, 4, '.');
      txn.edit(5, 5, '|');

      // Regresion test for issue #404: there is no conflict/overlap for edits
      // that don't remove any of the original code.
      txn.edit(6, 7, '_');
      txn.edit(6, 6, '-');
      expect((txn.commit()..build('')).text, "01.4|5-_789abcdefghij");

    });

    test('conflict', () {
      var txn = new TextEditTransaction(original, file);
      txn.edit(2, 4, '.');
      txn.edit(3, 3, '-');
      expect(() => txn.commit(), throwsA(predicate(
            (e) => e.toString().contains('overlapping edits'))));
    });
  });

  test('generated source maps', () {
    var original =
        "0123456789\n0*23456789\n01*3456789\nabcdefghij\nabcd*fghij\n";
    var file = new SourceFile(original);
    var txn = new TextEditTransaction(original, file);
    txn.edit(27, 29, '__\n    ');
    txn.edit(34, 35, '___');
    var printer = (txn.commit()..build(''));
    var output = printer.text;
    var map = parse(printer.map);
    expect(output,
        "0123456789\n0*23456789\n01*34__\n    789\na___cdefghij\nabcd*fghij\n");

    // Line 1 and 2 are unmodified: mapping any column returns the beginning
    // of the corresponding line:
    expect(_span(1, 1, map, file),
        "line 1, column 1: \n"
        "0123456789\n"
        "^");
    expect(_span(1, 5, map, file),
        "line 1, column 1: \n"
        "0123456789\n"
        "^");
    expect(_span(2, 1, map, file),
        "line 2, column 1: \n"
        "0*23456789\n"
        "^");
    expect(_span(2, 8, map, file),
        "line 2, column 1: \n"
        "0*23456789\n"
        "^");

    // Line 3 is modified part way: mappings before the edits have the right
    // mapping, after the edits the mapping is null.
    expect(_span(3, 1, map, file),
        "line 3, column 1: \n"
        "01*3456789\n"
        "^");
    expect(_span(3, 5, map, file),
        "line 3, column 1: \n"
        "01*3456789\n"
        "^");

    // Start of edits map to beginning of the edit secion:
    expect(_span(3, 6, map, file),
        "line 3, column 6: \n"
        "01*3456789\n"
        "     ^");
    expect(_span(3, 7, map, file),
        "line 3, column 6: \n"
        "01*3456789\n"
        "     ^");

    // Lines added have no mapping (they should inherit the last mapping),
    // but the end of the edit region continues were we left off:
    expect(_span(4, 1, map, file), isNull);
    expect(_span(4, 5, map, file),
        "line 3, column 8: \n"
        "01*3456789\n"
        "       ^");

    // Subsequent lines are still mapped correctly:
    // a (in a___cd...)
    expect(_span(5, 1, map, file),
        "line 4, column 1: \n"
        "abcdefghij\n"
        "^");
    // _ (in a___cd...)
    expect(_span(5, 2, map, file),
        "line 4, column 2: \n"
        "abcdefghij\n"
        " ^");
    // _ (in a___cd...)
    expect(_span(5, 3, map, file),
        "line 4, column 2: \n"
        "abcdefghij\n"
        " ^");
    // _ (in a___cd...)
    expect(_span(5, 4, map, file),
        "line 4, column 2: \n"
        "abcdefghij\n"
        " ^");
    // c (in a___cd...)
    expect(_span(5, 5, map, file),
        "line 4, column 3: \n"
        "abcdefghij\n"
        "  ^");
    expect(_span(6, 1, map, file),
        "line 5, column 1: \n"
        "abcd*fghij\n"
        "^");
    expect(_span(6, 8, map, file),
        "line 5, column 1: \n"
        "abcd*fghij\n"
        "^");
  });
}

String _span(int line, int column, Mapping map, SourceFile file) {
  var span = map.spanFor(line - 1, column - 1, files: {'': file});
  return span == null ? null : span.message('').trim();
}
