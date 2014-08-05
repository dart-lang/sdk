// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This code was auto-generated, is not intended to be edited, and is subject to
// significant change. Please see the README file for more information.

library test.services.correction.change;

import 'package:analysis_services/constants.dart';
import 'package:analysis_services/correction/change.dart';
import 'package:analysis_testing/reflective_tests.dart';
import 'package:unittest/unittest.dart';


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
  void test_toJson() {
    Change change = new Change('msg');
    change.add(new FileEdit('/a.dart')
        ..add(new Edit(1, 2, 'aaa'))
        ..add(new Edit(10, 20, 'bbb')));
    change.add(new FileEdit('/b.dart')
        ..add(new Edit(21, 22, 'xxx'))
        ..add(new Edit(210, 220, 'yyy')));
    {
      var group = new LinkedEditGroup('id-a');
      change.addLinkedEditGroup(group
          ..addPosition(new Position('/ga.dart', 1), 2)
          ..addPosition(new Position('/ga.dart', 10), 2));
      group.addSuggestion(
          new LinkedEditSuggestion(LinkedEditSuggestionKind.TYPE, 'AA'));
      group.addSuggestion(
          new LinkedEditSuggestion(LinkedEditSuggestionKind.TYPE, 'BB'));
    }
    change.addLinkedEditGroup(new LinkedEditGroup('id-b')
        ..addPosition(new Position('/gb.dart', 10), 5)
        ..addPosition(new Position('/gb.dart', 100), 5));
    var expectedJson = {
      'message': 'msg',
      'edits': [{
          'file': '/a.dart',
          'edits': [{
              'offset': 1,
              'length': 2,
              'relacement': 'aaa'
            }, {
              'offset': 10,
              'length': 20,
              'relacement': 'bbb'
            }]
        }, {
          'file': '/b.dart',
          'edits': [{
              'offset': 21,
              'length': 22,
              'relacement': 'xxx'
            }, {
              'offset': 210,
              'length': 220,
              'relacement': 'yyy'
            }]
        }],
      'linkedEditGroups': [{
          'id': 'id-a',
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
          'id': 'id-b',
          'length': 5,
          'positions': [{
              'file': '/gb.dart',
              'offset': 10
            }, {
              'file': '/gb.dart',
              'offset': 100
            }],
          'suggestions': []
        }]
    };
    expect(change.toJson(), expectedJson);
    // some toString()
    change.toString();
  }
}


@ReflectiveTestCase()
class EditTest {
  void test_end() {
    Edit edit = new Edit(1, 2, 'foo');
    expect(edit.end, 3);
  }

  void test_new() {
    Edit edit = new Edit(1, 2, 'foo');
    expect(edit.offset, 1);
    expect(edit.length, 2);
    expect(edit.replacement, 'foo');
    expect(edit.toString(), 'Edit(offset=1, length=2, replacement=:>foo<:)');
  }

  void test_toJson() {
    Edit edit = new Edit(1, 2, 'foo');
    var expectedJson = {
      OFFSET: 1,
      LENGTH: 2,
      REPLACEMENT: 'foo'
    };
    expect(edit.toJson(), expectedJson);
  }
  void test_eqEq() {
    Edit a = new Edit(1, 2, 'aaa');
    Edit a2 = new Edit(1, 2, 'aaa');
    Edit b = new Edit(1, 2, 'aaa');
    expect(a == a, isTrue);
    expect(a == new Edit(1, 2, 'aaa'), isTrue);
    expect(a == this, isFalse);
    expect(a == new Edit(1, 2, 'bbb'), isFalse);
    expect(a == new Edit(10, 2, 'aaa'), isFalse);
  }

}


@ReflectiveTestCase()
class FileEditTest {
  void test_new() {
    FileEdit fileEdit = new FileEdit('/test.dart');
    fileEdit.add(new Edit(1, 2, 'aaa'));
    fileEdit.add(new Edit(10, 20, 'bbb'));
    expect(
        fileEdit.toString(),
        'FileEdit(file=/test.dart, edits=['
            'Edit(offset=1, length=2, replacement=:>aaa<:), '
            'Edit(offset=10, length=20, replacement=:>bbb<:)])');
  }

  void test_toJson() {
    FileEdit fileEdit = new FileEdit('/test.dart');
    fileEdit.add(new Edit(1, 2, 'aaa'));
    fileEdit.add(new Edit(10, 20, 'bbb'));
    var expectedJson = {
      FILE: '/test.dart',
      EDITS: [{
          OFFSET: 1,
          LENGTH: 2,
          REPLACEMENT: 'aaa'
        }, {
          OFFSET: 10,
          LENGTH: 20,
          REPLACEMENT: 'bbb'
        },]
    };
    expect(fileEdit.toJson(), expectedJson);
  }
}


@ReflectiveTestCase()
class LinkedEditSuggestionTest {
  void test_eqEq() {
    var a = new LinkedEditSuggestion(LinkedEditSuggestionKind.METHOD, 'a');
    var a2 = new LinkedEditSuggestion(LinkedEditSuggestionKind.METHOD, 'a');
    var b = new LinkedEditSuggestion(LinkedEditSuggestionKind.TYPE, 'a');
    var c = new LinkedEditSuggestion(LinkedEditSuggestionKind.METHOD, 'c');
    expect(a == a, isTrue);
    expect(a == a2, isTrue);
    expect(a == this, isFalse);
    expect(a == b, isFalse);
    expect(a == c, isFalse);
  }
}


@ReflectiveTestCase()
class LinkedEditGroupTest {
  void test_new() {
    LinkedEditGroup group = new LinkedEditGroup('my-id');
    group.addPosition(new Position('/a.dart', 1), 2);
    group.addPosition(new Position('/b.dart', 10), 2);
    expect(
        group.toString(),
        'LinkedEditGroup(id=my-id, length=2, positions=['
            'Position(file=/a.dart, offset=1), '
            'Position(file=/b.dart, offset=10)], suggestions=[])');
  }

  void test_toJson() {
    LinkedEditGroup group = new LinkedEditGroup('my-id');
    group.addPosition(new Position('/a.dart', 1), 2);
    group.addPosition(new Position('/b.dart', 10), 2);
    group.addSuggestion(
        new LinkedEditSuggestion(LinkedEditSuggestionKind.TYPE, 'AA'));
    group.addSuggestion(
        new LinkedEditSuggestion(LinkedEditSuggestionKind.TYPE, 'BB'));
    expect(group.toJson(), {
      'id': 'my-id',
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
    expect(position.toString(), 'Position(file=/test.dart, offset=1)');
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
