// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/lsp/snippets.dart' as lsp;
import 'package:analysis_server/src/lsp/snippets.dart';
import 'package:analysis_server/src/protocol_server.dart' as server;
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(SnippetsTest);
    defineReflectiveTests(SnippetBuilderTest);
  });
}

@reflectiveTest
class SnippetBuilderTest {
  Future<void> test_appendChoice() async {
    final builder = SnippetBuilder()
      ..appendChoice({r'a'})
      ..appendChoice({r'a', r'b'})
      ..appendChoice({}, placeholderNumber: 6)
      ..appendChoice({r'aaa', r'bbb'}, placeholderNumber: 12)
      ..appendChoice({r'aaa', r'bbb \ bbb $ bbb | bbb , bbb } bbb'});

    expect(
      builder.value,
      r'${1:a}'
      r'${2|a,b|}'
      r'$6'
      r'${12|aaa,bbb|}'
      // Only pipes (delimiter), comma (separator) and backslashes (the escape
      // character) are escaped in choices. Not dollars or braces.
      // https://github.com/microsoft/vscode/issues/201059
      r'${13|aaa,bbb \\ bbb $ bbb \| bbb \, bbb } bbb|}',
    );
  }

  Future<void> test_appendPlaceholder() async {
    final builder = SnippetBuilder()
      ..appendPlaceholder(r'placeholder $ 1')
      ..appendPlaceholder(r'')
      ..appendPlaceholder(r'placeholder } 3', placeholderNumber: 6);

    expect(
      builder.value,
      r'${1:placeholder \$ 1}'
      r'$2'
      r'${6:placeholder \} 3}',
    );
  }

  Future<void> test_appendTabStop() async {
    final builder = SnippetBuilder()
      ..appendTabStop()
      ..appendTabStop(placeholderNumber: 10)
      ..appendTabStop();

    expect(
      builder.value,
      r'$1'
      r'$10'
      r'$11',
    );
  }

  Future<void> test_appendText() async {
    final builder = SnippetBuilder()
      ..appendText(r'text 1')
      ..appendText(r'text ${that needs} escaping $0')
      ..appendText(r'text 2');

    expect(
      builder.value,
      r'text 1'
      r'text \${that needs} escaping \$0'
      r'text 2',
    );
  }

  Future<void> test_extension_appendPlaceholders() async {
    final code = r'''
012345678
012345678
012345678
012345678
012345678
''';

    final placeholders = [
      lsp.SnippetPlaceholder(2, 2),
      lsp.SnippetPlaceholder(32, 2, linkedGroupId: 123),
      lsp.SnippetPlaceholder(12, 2, isFinal: true),
      lsp.SnippetPlaceholder(42, 2, linkedGroupId: 123),
      lsp.SnippetPlaceholder(22, 2, suggestions: ['aaa', 'bbb']),
    ];

    final builder = SnippetBuilder()
      ..appendPlaceholders(code, placeholders, isPreSorted: false);

    expect(builder.value, r'''
01${1:23}45678
01${0:23}45678
01${2|23,aaa,bbb|}45678
01${3:23}45678
01${3:23}45678
''');
  }

  Future<void> test_mixed() async {
    final builder = SnippetBuilder()
      ..appendText('text1')
      ..appendPlaceholder('placeholder')
      ..appendText('text2')
      ..appendChoice({'aaa', 'bbb'})
      ..appendText('text3')
      ..appendTabStop()
      ..appendText('text4');

    expect(
      builder.value,
      r'text1'
      r'${1:placeholder}'
      r'text2'
      r'${2|aaa,bbb|}'
      r'text3'
      r'$3'
      r'text4',
    );
  }
}

@reflectiveTest
class SnippetsTest {
  /// Paths aren't used for anything except filtering edit groups positions
  /// so the specific values are not important.
  final mainPath = '/home/test.dart';
  final otherPath = '/home/other.dart';

  Future<void> test_editGroups_choices() async {
    var result = lsp.buildSnippetStringForEditGroups(
      r'''
var a = 1;
''',
      filePath: mainPath,
      editOffset: 0,
      editGroups: [
        server.LinkedEditGroup(
          [_pos(4)],
          1,
          [
            _suggestion('aaa'),
            _suggestion(r'bbb${},|'), // test for escaping
            _suggestion('ccc'),
          ],
        ),
      ],
    );
    // Choices are never 0th placeholders, so this is `$1`.
    expect(result, equals(r'''
var ${1|a,aaa,bbb${}\,\|,ccc|} = 1;
'''));
  }

  Future<void> test_editGroups_emptyGroup() async {
    var result = lsp.buildSnippetStringForEditGroups(
      r'''
class  {
  ();
}
''',
      filePath: mainPath,
      editOffset: 0,
      editGroups: [
        server.LinkedEditGroup(
          [
            _pos(6),
            _pos(11),
          ],
          0,
          [],
        ),
      ],
    );
    expect(result, equals(r'''
class $0 {
  $0();
}
'''));
  }

  Future<void> test_editGroups_positionsInOtherFiles() async {
    var result = lsp.buildSnippetStringForEditGroups(
      r'''
class A {
  A();
}
''',
      filePath: mainPath,
      editOffset: 0,
      editGroups: [
        server.LinkedEditGroup(
          [
            _pos(6),
            _pos(10, otherPath), // Should not be included.
            _pos(12),
          ],
          1,
          [],
        ),
      ],
    );
    expect(result, equals(r'''
class ${0:A} {
  ${0:A}();
}
'''));
  }

  Future<void> test_editGroups_simpleGroup() async {
    var result = lsp.buildSnippetStringForEditGroups(
      r'''
class A {
  A();
}
''',
      filePath: mainPath,
      editOffset: 0,
      editGroups: [
        server.LinkedEditGroup(
          [
            _pos(6),
            _pos(12),
          ],
          1,
          [],
        ),
      ],
    );
    expect(result, equals(r'''
class ${0:A} {
  ${0:A}();
}
'''));
  }

  Future<void> test_editGroups_withOffset() async {
    var result = lsp.buildSnippetStringForEditGroups(
      r'''
class A {
  A();
}
''',
      filePath: mainPath,
      // This means the edit will be inserted at offset 100, so all linked edit
      // offsets will be 100 more than in the supplied text.
      editOffset: 100,
      editGroups: [
        server.LinkedEditGroup(
          [
            _pos(100 + 6),
            _pos(100 + 12),
          ],
          1,
          [],
        ),
      ],
    );
    expect(result, equals(r'''
class ${0:A} {
  ${0:A}();
}
'''));
  }

  Future<void> test_tabStops_contains() async {
    var result = lsp.buildSnippetStringWithTabStops('a, b, c', [3, 1]);
    expect(result, equals(r'a, ${0:b}, c'));
  }

  Future<void> test_tabStops_empty() async {
    var result = lsp.buildSnippetStringWithTabStops('a, b', []);
    expect(result, equals(r'a, b'));
  }

  Future<void> test_tabStops_endsWith() async {
    var result = lsp.buildSnippetStringWithTabStops('a, b', [3, 1]);
    expect(result, equals(r'a, ${0:b}'));
  }

  Future<void> test_tabStops_escape() async {
    var result = lsp.buildSnippetStringWithTabStops(
        r'te$tstri}ng, te$tstri}ng, te$tstri}ng', [13, 11]);
    expect(result, equals(r'te\$tstri}ng, ${0:te\$tstri\}ng}, te\$tstri}ng'));
  }

  Future<void> test_tabStops_multiple() async {
    var result =
        lsp.buildSnippetStringWithTabStops('a, b, c', [0, 1, 3, 1, 6, 1]);
    expect(result, equals(r'${1:a}, ${2:b}, ${3:c}'));
  }

  Future<void> test_tabStops_null() async {
    var result = lsp.buildSnippetStringWithTabStops('a, b', null);
    expect(result, equals(r'a, b'));
  }

  Future<void> test_tabStops_startsWith() async {
    var result = lsp.buildSnippetStringWithTabStops('a, b', [0, 1]);
    expect(result, equals(r'${0:a}, b'));
  }

  server.Position _pos(int offset, [String? path]) =>
      server.Position(path ?? mainPath, offset);

  server.LinkedEditSuggestion _suggestion(String text) =>
      server.LinkedEditSuggestion(
        text,
        server.LinkedEditSuggestionKind.TYPE, // We don't use type.
      );
}
