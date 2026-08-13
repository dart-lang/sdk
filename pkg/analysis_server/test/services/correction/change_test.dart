// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/protocol_server.dart';
import 'package:analyzer/source/source_range.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../constants.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ChangeTest);
    defineReflectiveTests(EditTest);
    defineReflectiveTests(FileEditTest);
    defineReflectiveTests(LinkedEditGroupTest);
    defineReflectiveTests(LinkedEditSuggestionTest);
    defineReflectiveTests(PositionTest);
  });
}

@reflectiveTest
class ChangeTest {
  void test_addEdit() {
    var change = SourceChange('msg');
    var edit1 = SourceEdit(1, 2, 'a');
    var edit2 = SourceEdit(4, 2, 'b');
    expect(change.edits, hasLength(0));
    change.addEdit('/a.dart', 0, edit1);
    expect(change.edits, hasLength(1));
    change.addEdit('/a.dart', 0, edit2);
    expect(change.edits, hasLength(1));
    {
      var fileEdit = change.getFileEdit('/a.dart')!;
      expect(fileEdit.edits, unorderedEquals([edit1, edit2]));
    }
  }

  void test_getFileEdit() {
    var change = SourceChange('msg');
    var fileEdit = SourceFileEdit('/a.dart', 0);
    change.addFileEdit(fileEdit);
    expect(change.getFileEdit('/a.dart'), fileEdit);
  }

  void test_getFileEdit_empty() {
    var change = SourceChange('msg');
    expect(change.getFileEdit('/some.dart'), isNull);
  }

  void test_toJson() {
    var change = SourceChange('msg');
    change.addFileEdit(
      SourceFileEdit('/a.dart', 1)
        ..add(SourceEdit(1, 2, 'aaa'))
        ..add(SourceEdit(10, 20, 'bbb')),
    );
    change.addFileEdit(
      SourceFileEdit('/b.dart', 2)
        ..add(SourceEdit(21, 22, 'xxx'))
        ..add(SourceEdit(210, 220, 'yyy')),
    );
    {
      var group = LinkedEditGroup.empty();
      change.addLinkedEditGroup(
        group
          ..addPosition(Position('/ga.dart', 1), 2)
          ..addPosition(Position('/ga.dart', 10), 2),
      );
      group.addSuggestion(
        LinkedEditSuggestion('AA', LinkedEditSuggestionKind.TYPE),
      );
      group.addSuggestion(
        LinkedEditSuggestion('BB', LinkedEditSuggestionKind.TYPE),
      );
    }
    change.addLinkedEditGroup(
      LinkedEditGroup.empty()
        ..addPosition(Position('/gb.dart', 10), 5)
        ..addPosition(Position('/gb.dart', 100), 5),
    );
    change.selection = Position('/selection.dart', 42);
    var expectedJson = {
      'message': 'msg',
      'edits': [
        {
          'file': '/a.dart',
          'fileStamp': 1,
          'edits': [
            {'offset': 10, 'length': 20, 'replacement': 'bbb'},
            {'offset': 1, 'length': 2, 'replacement': 'aaa'},
          ],
        },
        {
          'file': '/b.dart',
          'fileStamp': 2,
          'edits': [
            {'offset': 210, 'length': 220, 'replacement': 'yyy'},
            {'offset': 21, 'length': 22, 'replacement': 'xxx'},
          ],
        },
      ],
      'linkedEditGroups': [
        {
          'length': 2,
          'positions': [
            {'file': '/ga.dart', 'offset': 1},
            {'file': '/ga.dart', 'offset': 10},
          ],
          'suggestions': [
            {'kind': 'TYPE', 'value': 'AA'},
            {'kind': 'TYPE', 'value': 'BB'},
          ],
        },
        {
          'length': 5,
          'positions': [
            {'file': '/gb.dart', 'offset': 10},
            {'file': '/gb.dart', 'offset': 100},
          ],
          'suggestions': [],
        },
      ],
      'selection': {'file': '/selection.dart', 'offset': 42},
    };
    expect(change.toJson(), expectedJson);
    // some toString()
    change.toString();
  }
}

@reflectiveTest
class EditTest {
  /// There is no ambiguity in edits sorted last-to-first and the implementation
  /// may optimize this case.
  void test_applySequence_lastToFirst() {
    var edit1 = SourceEdit(5, 2, 'abc');
    var edit2 = SourceEdit(1, 0, '!');
    expect(
      SourceEdit.applySequence('0123456789', [edit1, edit2]),
      '0!1234abc789',
    );
  }

  void test_applySequence_lastToFirst_invalidLength_negative() {
    var edit1 = SourceEdit(1, 0, 'a');
    var edit2 = SourceEdit(0, -1, '');
    expect(
      () => SourceEdit.applySequence('', [edit1, edit2]),
      throwsRangeError('The edit length is negative.'),
    );
  }

  void test_applySequence_lastToFirst_invalidLength_pastEndOfString() {
    var edit1 = SourceEdit(1, 100, 'a');
    var edit2 = SourceEdit(0, 0, '');
    expect(
      () => SourceEdit.applySequence('aa', [edit1, edit2]),
      throwsRangeError('The edit extends past the end of the code.'),
    );
  }

  void test_applySequence_lastToFirst_invalidOffset_negative() {
    var edit1 = SourceEdit(1, 0, 'a');
    var edit2 = SourceEdit(-1, 0, '');
    expect(
      () => SourceEdit.applySequence('', [edit1, edit2]),
      throwsRangeError('The edit offset is negative.'),
    );
  }

  void test_applySequence_lastToFirst_invalidOffset_pastEndOfString() {
    var edit1 = SourceEdit(1, 0, 'a');
    var edit2 = SourceEdit(0, 0, 'b');
    expect(
      () => SourceEdit.applySequence('', [edit1, edit2]),
      throwsRangeError('The edit starts past the end of the code.'),
    );
  }

  /// Last-to-first offsets may have overlaps if edit `n+1` replaces text
  /// inserted by edit `n`. The result should be as if they were applied
  /// sequentially.
  ///
  /// Although sorted last-to-first, this case will fall back to sequential
  /// processing.
  void test_applySequence_lastToFirstOffsets_overlap() {
    var edit1 = SourceEdit(3, 0, '1111');
    var edit2 = SourceEdit(1, 4, '2222'); // replaces aa11
    expect(SourceEdit.applySequence('aaaa', [edit1, edit2]), 'a222211a');
  }

  /// Last-to-first offsets may have overlaps if edit `n+1` replaces text
  /// inserted by edit `n`. The result should be as if they were applied
  /// sequentially.
  ///
  /// Although sorted last-to-first, this case will fall back to sequential
  /// processing.
  void test_applySequence_lastToFirstOffsets_touching() {
    var edit1 = SourceEdit(3, 0, '1111');
    var edit2 = SourceEdit(1, 2, '2222'); // replaces aa
    expect(SourceEdit.applySequence('aaaa', [edit1, edit2]), 'a22221111a');
  }

  /// Edits are described sequentially, so the offsets in edit `n` assume edit
  /// `n-1` has been applied.
  void test_applySequence_sequential() {
    var edit1 = SourceEdit(0, 0, '1111');
    var edit2 = SourceEdit(2, 0, '2222');
    expect(SourceEdit.applySequence('', [edit1, edit2]), '11222211');
  }

  void test_applySequence_sequential_invalidLength_negative() {
    var edit1 = SourceEdit(0, -1, '');
    var edit2 = SourceEdit(0, 0, '');
    expect(
      () => SourceEdit.applySequence('', [edit1, edit2]),
      throwsRangeError('The edit length is negative.'),
    );
  }

  void test_applySequence_sequential_invalidLength_pastEndOfString() {
    var edit1 = SourceEdit(0, 0, '');
    var edit2 = SourceEdit(0, 100, '');
    expect(
      () => SourceEdit.applySequence('', [edit1, edit2]),
      throwsRangeError('The edit extends past the end of the code.'),
    );
  }

  void test_applySequence_sequential_invalidOffset_negative() {
    var edit1 = SourceEdit(-1, 0, '');
    var edit2 = SourceEdit(0, 0, '');
    expect(
      () => SourceEdit.applySequence('', [edit1, edit2]),
      throwsRangeError('The edit offset is negative.'),
    );
  }

  void test_applySequence_sequential_invalidOffset_pastEndOfString() {
    var edit1 = SourceEdit(0, 0, '');
    var edit2 = SourceEdit(100, 0, '');
    expect(
      () => SourceEdit.applySequence('', [edit1, edit2]),
      throwsRangeError('The edit starts past the end of the code.'),
    );
  }

  /// Edits are described sequentially, so repeated offsets in inserts
  /// result in the second insert ending up in front of the first.
  void test_applySequence_sequential_sameOffsets() {
    var edit1 = SourceEdit(0, 0, '1111');
    var edit2 = SourceEdit(0, 0, '2222');
    expect(SourceEdit.applySequence('', [edit1, edit2]), '22221111');
  }

  void test_applySequence_sequential_validLength_assumesPriorEdit() {
    var edit1 = SourceEdit(0, 0, '1111');
    var edit2 = SourceEdit(0, 4, ''); // Valid because it deletes 1111.
    expect(SourceEdit.applySequence('', [edit1, edit2]), '');
  }

  void test_editFromRange() {
    var range = SourceRange(1, 2);
    var edit = newSourceEdit_range(range, 'foo');
    expect(edit.offset, 1);
    expect(edit.length, 2);
    expect(edit.replacement, 'foo');
  }

  void test_eqEq() {
    var a = SourceEdit(1, 2, 'aaa');
    expect(a == a, isTrue);
    expect(a == SourceEdit(1, 2, 'aaa'), isTrue);
    // ignore: unrelated_type_equality_checks
    expect(a == this, isFalse);
    expect(a == SourceEdit(1, 2, 'bbb'), isFalse);
    expect(a == SourceEdit(10, 2, 'aaa'), isFalse);
  }

  void test_new() {
    var edit = SourceEdit(1, 2, 'foo', id: 'my-id');
    expect(edit.offset, 1);
    expect(edit.length, 2);
    expect(edit.replacement, 'foo');
    expect(edit.toJson(), {
      'offset': 1,
      'length': 2,
      'replacement': 'foo',
      'id': 'my-id',
    });
  }

  void test_toJson() {
    var edit = SourceEdit(1, 2, 'foo');
    var expectedJson = {offsetKey: 1, lengthKey: 2, replacementKey: 'foo'};
    expect(edit.toJson(), expectedJson);
  }

  Matcher throwsRangeError(String message) => throwsA(
    const TypeMatcher<RangeError>().having(
      (e) => e.message,
      'message',
      message,
    ),
  );
}

@reflectiveTest
class FileEditTest {
  void test_add_sorts() {
    var edit1a = SourceEdit(1, 0, 'a1');
    var edit1b = SourceEdit(1, 0, 'a2');
    var edit10 = SourceEdit(10, 1, 'b');
    var edit100 = SourceEdit(100, 2, 'c');
    var fileEdit = SourceFileEdit('/test.dart', 0);
    fileEdit.add(edit100);
    fileEdit.add(edit1a);
    fileEdit.add(edit1b);
    fileEdit.add(edit10);
    expect(fileEdit.edits, [edit100, edit10, edit1b, edit1a]);
  }

  void test_addAll() {
    var edit1a = SourceEdit(1, 0, 'a1');
    var edit1b = SourceEdit(1, 0, 'a2');
    var edit10 = SourceEdit(10, 1, 'b');
    var edit100 = SourceEdit(100, 2, 'c');
    var fileEdit = SourceFileEdit('/test.dart', 0);
    fileEdit.addAll([edit100, edit1a, edit10, edit1b]);
    expect(fileEdit.edits, [edit100, edit10, edit1b, edit1a]);
  }

  void test_new() {
    var fileEdit = SourceFileEdit('/test.dart', 100);
    fileEdit.add(SourceEdit(1, 2, 'aaa'));
    fileEdit.add(SourceEdit(10, 20, 'bbb'));
    expect(
      fileEdit.toString(),
      '{"file":"/test.dart","fileStamp":100,"edits":['
      '{"offset":10,"length":20,"replacement":"bbb"},'
      '{"offset":1,"length":2,"replacement":"aaa"}]}',
    );
  }

  void test_toJson() {
    var fileEdit = SourceFileEdit('/test.dart', 100);
    fileEdit.add(SourceEdit(1, 2, 'aaa'));
    fileEdit.add(SourceEdit(10, 20, 'bbb'));
    var expectedJson = {
      fileKey: '/test.dart',
      fileStampKey: 100,
      editsKey: [
        {offsetKey: 10, lengthKey: 20, replacementKey: 'bbb'},
        {offsetKey: 1, lengthKey: 2, replacementKey: 'aaa'},
      ],
    };
    expect(fileEdit.toJson(), expectedJson);
  }
}

@reflectiveTest
class LinkedEditGroupTest {
  void test_new() {
    var group = LinkedEditGroup.empty();
    group.addPosition(Position('/a.dart', 1), 2);
    group.addPosition(Position('/b.dart', 10), 2);
    expect(
      group.toString(),
      '{"positions":['
      '{"file":"/a.dart","offset":1},'
      '{"file":"/b.dart","offset":10}],"length":2,"suggestions":[]}',
    );
  }

  void test_toJson() {
    var group = LinkedEditGroup.empty();
    group.addPosition(Position('/a.dart', 1), 2);
    group.addPosition(Position('/b.dart', 10), 2);
    group.addSuggestion(
      LinkedEditSuggestion('AA', LinkedEditSuggestionKind.TYPE),
    );
    group.addSuggestion(
      LinkedEditSuggestion('BB', LinkedEditSuggestionKind.TYPE),
    );
    expect(group.toJson(), {
      'length': 2,
      'positions': [
        {'file': '/a.dart', 'offset': 1},
        {'file': '/b.dart', 'offset': 10},
      ],
      'suggestions': [
        {'kind': 'TYPE', 'value': 'AA'},
        {'kind': 'TYPE', 'value': 'BB'},
      ],
    });
  }
}

@reflectiveTest
class LinkedEditSuggestionTest {
  void test_eqEq() {
    var a = LinkedEditSuggestion('a', LinkedEditSuggestionKind.METHOD);
    var a2 = LinkedEditSuggestion('a', LinkedEditSuggestionKind.METHOD);
    var b = LinkedEditSuggestion('a', LinkedEditSuggestionKind.TYPE);
    var c = LinkedEditSuggestion('c', LinkedEditSuggestionKind.METHOD);
    expect(a == a, isTrue);
    expect(a == a2, isTrue);
    // ignore: unrelated_type_equality_checks
    expect(a == this, isFalse);
    expect(a == b, isFalse);
    expect(a == c, isFalse);
  }
}

@reflectiveTest
class PositionTest {
  void test_eqEq() {
    var a = Position('/a.dart', 1);
    var a2 = Position('/a.dart', 1);
    var b = Position('/b.dart', 1);
    expect(a == a, isTrue);
    expect(a == a2, isTrue);
    expect(a == b, isFalse);
    // ignore: unrelated_type_equality_checks
    expect(a == this, isFalse);
  }

  void test_hashCode() {
    var position = Position('/test.dart', 1);
    position.hashCode;
  }

  void test_new() {
    var position = Position('/test.dart', 1);
    expect(position.file, '/test.dart');
    expect(position.offset, 1);
    expect(position.toString(), '{"file":"/test.dart","offset":1}');
  }

  void test_toJson() {
    var position = Position('/test.dart', 1);
    var expectedJson = {fileKey: '/test.dart', offsetKey: 1};
    expect(position.toJson(), expectedJson);
  }
}
