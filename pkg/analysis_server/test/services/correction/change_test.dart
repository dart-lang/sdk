// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/protocol_server.dart';
import 'package:analyzer/src/generated/source.dart';
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
      var fileEdit = change.getFileEdit('/a.dart');
      expect(fileEdit, isNotNull);
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
    change.addFileEdit(SourceFileEdit('/a.dart', 1)
      ..add(SourceEdit(1, 2, 'aaa'))
      ..add(SourceEdit(10, 20, 'bbb')));
    change.addFileEdit(SourceFileEdit('/b.dart', 2)
      ..add(SourceEdit(21, 22, 'xxx'))
      ..add(SourceEdit(210, 220, 'yyy')));
    {
      var group = LinkedEditGroup.empty();
      change.addLinkedEditGroup(group
        ..addPosition(Position('/ga.dart', 1), 2)
        ..addPosition(Position('/ga.dart', 10), 2));
      group.addSuggestion(
          LinkedEditSuggestion('AA', LinkedEditSuggestionKind.TYPE));
      group.addSuggestion(
          LinkedEditSuggestion('BB', LinkedEditSuggestionKind.TYPE));
    }
    change.addLinkedEditGroup(LinkedEditGroup.empty()
      ..addPosition(Position('/gb.dart', 10), 5)
      ..addPosition(Position('/gb.dart', 100), 5));
    change.selection = Position('/selection.dart', 42);
    var expectedJson = {
      'message': 'msg',
      'edits': [
        {
          'file': '/a.dart',
          'fileStamp': 1,
          'edits': [
            {'offset': 10, 'length': 20, 'replacement': 'bbb'},
            {'offset': 1, 'length': 2, 'replacement': 'aaa'}
          ]
        },
        {
          'file': '/b.dart',
          'fileStamp': 2,
          'edits': [
            {'offset': 210, 'length': 220, 'replacement': 'yyy'},
            {'offset': 21, 'length': 22, 'replacement': 'xxx'}
          ]
        }
      ],
      'linkedEditGroups': [
        {
          'length': 2,
          'positions': [
            {'file': '/ga.dart', 'offset': 1},
            {'file': '/ga.dart', 'offset': 10}
          ],
          'suggestions': [
            {'kind': 'TYPE', 'value': 'AA'},
            {'kind': 'TYPE', 'value': 'BB'}
          ]
        },
        {
          'length': 5,
          'positions': [
            {'file': '/gb.dart', 'offset': 10},
            {'file': '/gb.dart', 'offset': 100}
          ],
          'suggestions': []
        }
      ],
      'selection': {'file': '/selection.dart', 'offset': 42}
    };
    expect(change.toJson(), expectedJson);
    // some toString()
    change.toString();
  }
}

@reflectiveTest
class EditTest {
  void test_applySequence() {
    var edit1 = SourceEdit(5, 2, 'abc');
    var edit2 = SourceEdit(1, 0, '!');
    expect(
        SourceEdit.applySequence('0123456789', [edit1, edit2]), '0!1234abc789');
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
    expect(edit.toJson(),
        {'offset': 1, 'length': 2, 'replacement': 'foo', 'id': 'my-id'});
  }

  void test_toJson() {
    var edit = SourceEdit(1, 2, 'foo');
    var expectedJson = {OFFSET: 1, LENGTH: 2, REPLACEMENT: 'foo'};
    expect(edit.toJson(), expectedJson);
  }
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
        '{"offset":1,"length":2,"replacement":"aaa"}]}');
  }

  void test_toJson() {
    var fileEdit = SourceFileEdit('/test.dart', 100);
    fileEdit.add(SourceEdit(1, 2, 'aaa'));
    fileEdit.add(SourceEdit(10, 20, 'bbb'));
    var expectedJson = {
      FILE: '/test.dart',
      FILE_STAMP: 100,
      EDITS: [
        {OFFSET: 10, LENGTH: 20, REPLACEMENT: 'bbb'},
        {OFFSET: 1, LENGTH: 2, REPLACEMENT: 'aaa'},
      ]
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
        '{"file":"/b.dart","offset":10}],"length":2,"suggestions":[]}');
  }

  void test_toJson() {
    var group = LinkedEditGroup.empty();
    group.addPosition(Position('/a.dart', 1), 2);
    group.addPosition(Position('/b.dart', 10), 2);
    group.addSuggestion(
        LinkedEditSuggestion('AA', LinkedEditSuggestionKind.TYPE));
    group.addSuggestion(
        LinkedEditSuggestion('BB', LinkedEditSuggestionKind.TYPE));
    expect(group.toJson(), {
      'length': 2,
      'positions': [
        {'file': '/a.dart', 'offset': 1},
        {'file': '/b.dart', 'offset': 10}
      ],
      'suggestions': [
        {'kind': 'TYPE', 'value': 'AA'},
        {'kind': 'TYPE', 'value': 'BB'}
      ]
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
    var expectedJson = {FILE: '/test.dart', OFFSET: 1};
    expect(position.toJson(), expectedJson);
  }
}
