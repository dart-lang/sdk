// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:cli_util/cli_logging.dart';
import 'package:nnbd_migration/src/edit_plan.dart';
import 'package:nnbd_migration/src/utilities/source_edit_diff_formatter.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(SourceEditDiffFormatterTest);
  });
}

@reflectiveTest
class SourceEditDiffFormatterTest {
  DiffStyle get compactStyle => DiffStyle.forTesting(true);

  DiffStyle get traditionalStyle => DiffStyle.forTesting(false);

  test_ansi_supported() {
    var ansi = Ansi(true);
    expect(
        DiffStyle(ansi).formatDiff('ab', {
          0: [AtomicEdit.delete(1)],
          2: [AtomicEdit.insert('c')]
        }),
        [
          'line 1   • ${ansi.red}${ansi.reversed}a${ansi.none}'
              'b${ansi.green}${ansi.reversed}c${ansi.none}'
        ]);
  }

  test_ansi_unsupported() {
    var ansi = Ansi(false);
    expect(
        DiffStyle(ansi).formatDiff('ab', {
          0: [AtomicEdit.delete(1)],
          2: [AtomicEdit.insert('c')]
        }),
        ['line 1   -ab', '         +bc']);
  }

  test_compact_consecutiveEdits() {
    expect(
        compactStyle.formatDiff('a', {
          1: [AtomicEdit.insert('b'), AtomicEdit.insert('c')]
        }),
        ['line 1   * a{+b+}{+c+}']);
  }

  test_compact_deletion() {
    expect(
        compactStyle.formatDiff('abc', {
          1: [AtomicEdit.delete(1)]
        }),
        ['line 1   * a{-b-}c']);
  }

  test_compact_deletion_ending_in_newline_at_line_start() {
    expect(
        compactStyle.formatDiff('abc\ndef', {
          0: [AtomicEdit.delete(4)]
        }),
        ['line 1   * {-abc-}']);
  }

  test_compact_deletion_ending_in_newline_not_at_line_start() {
    expect(
        compactStyle.formatDiff('abc\ndef', {
          1: [AtomicEdit.delete(3)]
        }),
        ['line 1   * a{-bc-}']);
  }

  test_compact_deletion_multiline() {
    expect(
        compactStyle.formatDiff('abc\ndef', {
          1: [AtomicEdit.delete(5)]
        }),
        ['line 1   * a{-bc-}', 'line 2   * {-de-}f']);
  }

  test_compact_initialText() {
    expect(
        compactStyle.formatDiff('abc', {
          3: [AtomicEdit.insert('d')]
        }),
        ['line 1   * abc{+d+}']);
  }

  test_compact_insertion() {
    expect(
        compactStyle.formatDiff('ac', {
          1: [AtomicEdit.insert('b')]
        }),
        ['line 1   * a{+b+}c']);
  }

  test_compact_insertion_ending_in_newline() {
    expect(
        compactStyle.formatDiff('def', {
          0: [AtomicEdit.insert('abc\n')]
        }),
        ['line 1   * {+abc+}']);
  }

  test_compact_insertion_multiline() {
    expect(
        compactStyle.formatDiff('af', {
          1: [AtomicEdit.insert('bc\nde')]
        }),
        ['line 1   * a{+bc+}', '         * {+de+}f']);
  }

  test_compact_sort() {
    expect(
        compactStyle.formatDiff('b', {
          1: [AtomicEdit.insert('c')],
          0: [AtomicEdit.insert('a')]
        }),
        ['line 1   * {+a+}b{+c+}']);
  }

  test_compact_startsWithUnchangedLine() {
    expect(
        compactStyle.formatDiff('a\nb', {
          3: [AtomicEdit.insert('c')]
        }),
        ['line 2   * b{+c+}']);
  }

  test_compact_trailingTextOnEditedLine_withFinalNewline() {
    expect(
        compactStyle.formatDiff('ac\n', {
          1: [AtomicEdit.insert('b')]
        }),
        ['line 1   * a{+b+}c']);
  }

  test_compact_trailingTextOnEditedLine_withoutFinalNewline() {
    expect(
        compactStyle.formatDiff('ac', {
          1: [AtomicEdit.insert('b')]
        }),
        ['line 1   * a{+b+}c']);
  }

  test_traditional_consecutiveEdits() {
    expect(
        traditionalStyle.formatDiff('a', {
          1: [AtomicEdit.insert('b'), AtomicEdit.insert('c')]
        }),
        ['line 1   -a', '         +a{+b+}{+c+}']);
  }

  test_traditional_deletion() {
    expect(
        traditionalStyle.formatDiff('abc', {
          1: [AtomicEdit.delete(1)]
        }),
        ['line 1   -a{-b-}c', '         +ac']);
  }

  test_traditional_deletion_ending_in_newline_at_line_start() {
    expect(
        traditionalStyle.formatDiff('abc\ndef', {
          0: [AtomicEdit.delete(4)]
        }),
        ['line 1   -{-abc-}']);
  }

  test_traditional_deletion_ending_in_newline_not_at_line_start() {
    expect(
        traditionalStyle.formatDiff('abc\ndef', {
          1: [AtomicEdit.delete(3)]
        }),
        ['line 1   -a{-bc-}', 'line 2   -def', '         +adef']);
  }

  test_traditional_deletion_multiline() {
    expect(
        traditionalStyle.formatDiff('abc\ndef', {
          1: [AtomicEdit.delete(5)]
        }),
        ['line 1   -a{-bc-}', 'line 2   -{-de-}f', '         +af']);
  }

  test_traditional_initialText() {
    expect(
        traditionalStyle.formatDiff('abc', {
          3: [AtomicEdit.insert('d')]
        }),
        ['line 1   -abc', '         +abc{+d+}']);
  }

  test_traditional_insertion() {
    expect(
        traditionalStyle.formatDiff('ac', {
          1: [AtomicEdit.insert('b')]
        }),
        ['line 1   -ac', '         +a{+b+}c']);
  }

  test_traditional_insertion_ending_in_newline() {
    expect(
        traditionalStyle.formatDiff('def', {
          0: [AtomicEdit.insert('abc\n')]
        }),
        ['line 1   +{+abc+}']);
  }

  test_traditional_insertion_multiline() {
    expect(
        traditionalStyle.formatDiff('af', {
          1: [AtomicEdit.insert('bc\nde')]
        }),
        ['line 1   -af', '         +a{+bc+}', '         +{+de+}f']);
  }

  test_traditional_sort() {
    expect(
        traditionalStyle.formatDiff('b', {
          1: [AtomicEdit.insert('c')],
          0: [AtomicEdit.insert('a')]
        }),
        ['line 1   -b', '         +{+a+}b{+c+}']);
  }

  test_traditional_startsWithUnchangedLine() {
    expect(
        traditionalStyle.formatDiff('a\nb', {
          3: [AtomicEdit.insert('c')]
        }),
        ['line 2   -b', '         +b{+c+}']);
  }

  test_traditional_trailingTextOnEditedLine_withFinalNewline() {
    expect(
        traditionalStyle.formatDiff('ac\n', {
          1: [AtomicEdit.insert('b')]
        }),
        ['line 1   -ac', '         +a{+b+}c']);
  }

  test_traditional_trailingTextOnEditedLine_withoutFinalNewline() {
    expect(
        traditionalStyle.formatDiff('ac', {
          1: [AtomicEdit.insert('b')]
        }),
        ['line 1   -ac', '         +a{+b+}c']);
  }
}
