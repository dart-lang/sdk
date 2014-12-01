// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.services.correction.change;

import 'package:analysis_server/src/constants.dart';
import 'package:analysis_server/src/protocol_server.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:unittest/unittest.dart';

import '../../reflective_tests.dart';


main() {
  groupSep = ' | ';
  runReflectiveTests(ChangeTest);
  runReflectiveTests(EditTest);
  runReflectiveTests(FileEditTest);
  runReflectiveTests(LinkedEditGroupTest);
  runReflectiveTests(LinkedEditSuggestionTest);
  runReflectiveTests(PositionTest);
}


@ReflectiveTestCase()
class ChangeTest {
  void test_addEdit() {
    SourceChange change = new SourceChange('msg');
    SourceEdit edit1 = new SourceEdit(1, 2, 'a');
    SourceEdit edit2 = new SourceEdit(1, 2, 'b');
    expect(change.edits, hasLength(0));
    change.addEdit('/a.dart', 0, edit1);
    expect(change.edits, hasLength(1));
    change.addEdit('/a.dart', 0, edit2);
    expect(change.edits, hasLength(1));
    {
      SourceFileEdit fileEdit = change.getFileEdit('/a.dart');
      expect(fileEdit, isNotNull);
      expect(fileEdit.edits, unorderedEquals([edit1, edit2]));
    }
  }

  void test_getFileEdit() {
    SourceChange change = new SourceChange('msg');
    SourceFileEdit fileEdit = new SourceFileEdit('/a.dart', 0);
    change.addFileEdit(fileEdit);
    expect(change.getFileEdit('/a.dart'), fileEdit);
  }

  void test_getFileEdit_empty() {
    SourceChange change = new SourceChange('msg');
    expect(change.getFileEdit('/some.dart'), isNull);
  }

  void test_toJson() {
    SourceChange change = new SourceChange('msg');
    change.addFileEdit(new SourceFileEdit('/a.dart', 1)
        ..add(new SourceEdit(1, 2, 'aaa'))
        ..add(new SourceEdit(10, 20, 'bbb')));
    change.addFileEdit(new SourceFileEdit('/b.dart', 2)
        ..add(new SourceEdit(21, 22, 'xxx'))
        ..add(new SourceEdit(210, 220, 'yyy')));
    {
      var group = new LinkedEditGroup.empty();
      change.addLinkedEditGroup(group
          ..addPosition(new Position('/ga.dart', 1), 2)
          ..addPosition(new Position('/ga.dart', 10), 2));
      group.addSuggestion(
          new LinkedEditSuggestion('AA', LinkedEditSuggestionKind.TYPE));
      group.addSuggestion(
          new LinkedEditSuggestion('BB', LinkedEditSuggestionKind.TYPE));
    }
    change.addLinkedEditGroup(new LinkedEditGroup.empty()
        ..addPosition(new Position('/gb.dart', 10), 5)
        ..addPosition(new Position('/gb.dart', 100), 5));
    change.selection = new Position('/selection.dart', 42);
    var expectedJson = {
      'message': 'msg',
      'edits': [{
          'file': '/a.dart',
          'fileStamp': 1,
          'edits': [{
              'offset': 10,
              'length': 20,
              'replacement': 'bbb'
            }, {
              'offset': 1,
              'length': 2,
              'replacement': 'aaa'
            }]
        }, {
          'file': '/b.dart',
          'fileStamp': 2,
          'edits': [{
              'offset': 210,
              'length': 220,
              'replacement': 'yyy'
            }, {
              'offset': 21,
              'length': 22,
              'replacement': 'xxx'
            }]
        }],
      'linkedEditGroups': [{
          'length': 2,
          'positions': [{
              'file': '/ga.dart',
              'offset': 1
            }, {
              'file': '/ga.dart',
              'offset': 10
            }],
          'suggestions': [{
              'kind': 'TYPE',
              'value': 'AA'
            }, {
              'kind': 'TYPE',
              'value': 'BB'
            }]
        }, {
          'length': 5,
          'positions': [{
              'file': '/gb.dart',
              'offset': 10
            }, {
              'file': '/gb.dart',
              'offset': 100
            }],
          'suggestions': []
        }],
      'selection': {
        'file': '/selection.dart',
        'offset': 42
      }
    };
    expect(change.toJson(), expectedJson);
    // some toString()
    change.toString();
  }
}


@ReflectiveTestCase()
class EditTest {
  void test_applySequence() {
    SourceEdit edit1 = new SourceEdit(5, 2, 'abc');
    SourceEdit edit2 = new SourceEdit(1, 0, '!');
    expect(
        SourceEdit.applySequence('0123456789', [edit1, edit2]),
        '0!1234abc789');
  }

  void test_editFromRange() {
    SourceRange range = new SourceRange(1, 2);
    SourceEdit edit = newSourceEdit_range(range, 'foo');
    expect(edit.offset, 1);
    expect(edit.length, 2);
    expect(edit.replacement, 'foo');
  }

  void test_eqEq() {
    SourceEdit a = new SourceEdit(1, 2, 'aaa');
    expect(a == a, isTrue);
    expect(a == new SourceEdit(1, 2, 'aaa'), isTrue);
    expect(a == this, isFalse);
    expect(a == new SourceEdit(1, 2, 'bbb'), isFalse);
    expect(a == new SourceEdit(10, 2, 'aaa'), isFalse);
  }

  void test_new() {
    SourceEdit edit = new SourceEdit(1, 2, 'foo', id: 'my-id');
    expect(edit.offset, 1);
    expect(edit.length, 2);
    expect(edit.replacement, 'foo');
    expect(edit.toJson(), {
      'offset': 1,
      'length': 2,
      'replacement': 'foo',
      'id': 'my-id'
    });
  }
  void test_toJson() {
    SourceEdit edit = new SourceEdit(1, 2, 'foo');
    var expectedJson = {
      OFFSET: 1,
      LENGTH: 2,
      REPLACEMENT: 'foo'
    };
    expect(edit.toJson(), expectedJson);
  }

}


@ReflectiveTestCase()
class FileEditTest {
  void test_add_sorts() {
    SourceEdit edit1a = new SourceEdit(1, 0, 'a1');
    SourceEdit edit1b = new SourceEdit(1, 0, 'a2');
    SourceEdit edit10 = new SourceEdit(10, 1, 'b');
    SourceEdit edit100 = new SourceEdit(100, 2, 'c');
    SourceFileEdit fileEdit = new SourceFileEdit('/test.dart', 0);
    fileEdit.add(edit100);
    fileEdit.add(edit1a);
    fileEdit.add(edit1b);
    fileEdit.add(edit10);
    expect(fileEdit.edits, [edit100, edit10, edit1b, edit1a]);
  }

  void test_addAll() {
    SourceEdit edit1a = new SourceEdit(1, 0, 'a1');
    SourceEdit edit1b = new SourceEdit(1, 0, 'a2');
    SourceEdit edit10 = new SourceEdit(10, 1, 'b');
    SourceEdit edit100 = new SourceEdit(100, 2, 'c');
    SourceFileEdit fileEdit = new SourceFileEdit('/test.dart', 0);
    fileEdit.addAll([edit100, edit1a, edit10, edit1b]);
    expect(fileEdit.edits, [edit100, edit10, edit1b, edit1a]);
  }

  void test_new() {
    SourceFileEdit fileEdit = new SourceFileEdit('/test.dart', 100);
    fileEdit.add(new SourceEdit(1, 2, 'aaa'));
    fileEdit.add(new SourceEdit(10, 20, 'bbb'));
    expect(
        fileEdit.toString(),
        '{"file":"/test.dart","fileStamp":100,"edits":['
            '{"offset":10,"length":20,"replacement":"bbb"},'
            '{"offset":1,"length":2,"replacement":"aaa"}]}');
  }

  void test_toJson() {
    SourceFileEdit fileEdit = new SourceFileEdit('/test.dart', 100);
    fileEdit.add(new SourceEdit(1, 2, 'aaa'));
    fileEdit.add(new SourceEdit(10, 20, 'bbb'));
    var expectedJson = {
      FILE: '/test.dart',
      FILE_STAMP: 100,
      EDITS: [{
          OFFSET: 10,
          LENGTH: 20,
          REPLACEMENT: 'bbb'
        }, {
          OFFSET: 1,
          LENGTH: 2,
          REPLACEMENT: 'aaa'
        },]
    };
    expect(fileEdit.toJson(), expectedJson);
  }
}


@ReflectiveTestCase()
class LinkedEditGroupTest {
  void test_new() {
    LinkedEditGroup group = new LinkedEditGroup.empty();
    group.addPosition(new Position('/a.dart', 1), 2);
    group.addPosition(new Position('/b.dart', 10), 2);
    expect(
        group.toString(),
        '{"positions":[' '{"file":"/a.dart","offset":1},'
            '{"file":"/b.dart","offset":10}],"length":2,"suggestions":[]}');
  }

  void test_toJson() {
    LinkedEditGroup group = new LinkedEditGroup.empty();
    group.addPosition(new Position('/a.dart', 1), 2);
    group.addPosition(new Position('/b.dart', 10), 2);
    group.addSuggestion(
        new LinkedEditSuggestion('AA', LinkedEditSuggestionKind.TYPE));
    group.addSuggestion(
        new LinkedEditSuggestion('BB', LinkedEditSuggestionKind.TYPE));
    expect(group.toJson(), {
      'length': 2,
      'positions': [{
          'file': '/a.dart',
          'offset': 1
        }, {
          'file': '/b.dart',
          'offset': 10
        }],
      'suggestions': [{
          'kind': 'TYPE',
          'value': 'AA'
        }, {
          'kind': 'TYPE',
          'value': 'BB'
        }]
    });
  }
}


@ReflectiveTestCase()
class LinkedEditSuggestionTest {
  void test_eqEq() {
    var a = new LinkedEditSuggestion('a', LinkedEditSuggestionKind.METHOD);
    var a2 = new LinkedEditSuggestion('a', LinkedEditSuggestionKind.METHOD);
    var b = new LinkedEditSuggestion('a', LinkedEditSuggestionKind.TYPE);
    var c = new LinkedEditSuggestion('c', LinkedEditSuggestionKind.METHOD);
    expect(a == a, isTrue);
    expect(a == a2, isTrue);
    expect(a == this, isFalse);
    expect(a == b, isFalse);
    expect(a == c, isFalse);
  }
}


@ReflectiveTestCase()
class PositionTest {
  void test_eqEq() {
    Position a = new Position('/a.dart', 1);
    Position a2 = new Position('/a.dart', 1);
    Position b = new Position('/b.dart', 1);
    expect(a == a, isTrue);
    expect(a == a2, isTrue);
    expect(a == b, isFalse);
    expect(a == this, isFalse);
  }

  void test_hashCode() {
    Position position = new Position('/test.dart', 1);
    position.hashCode;
  }

  void test_new() {
    Position position = new Position('/test.dart', 1);
    expect(position.file, '/test.dart');
    expect(position.offset, 1);
    expect(position.toString(), '{"file":"/test.dart","offset":1}');
  }

  void test_toJson() {
    Position position = new Position('/test.dart', 1);
    var expectedJson = {
      FILE: '/test.dart',
      OFFSET: 1
    };
    expect(position.toJson(), expectedJson);
  }
}
