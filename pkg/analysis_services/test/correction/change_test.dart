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
  runReflectiveTests(LinkedPositionGroupTest);
  runReflectiveTests(PositionTest);
}


@ReflectiveTestCase()
class ChangeTest {
  void test_fromJson() {
    var json = {
      MESSAGE: 'msg',
      EDITS: [{
          FILE: '/a.dart',
          EDITS: [{
              OFFSET: 1,
              LENGTH: 2,
              REPLACEMENT: 'aaa'
            }, {
              OFFSET: 10,
              LENGTH: 20,
              REPLACEMENT: 'bbb'
            }]
        }, {
          FILE: '/b.dart',
          EDITS: [{
              OFFSET: 21,
              LENGTH: 22,
              REPLACEMENT: 'xxx'
            }, {
              OFFSET: 210,
              LENGTH: 220,
              REPLACEMENT: 'yyy'
            }]
        }],
      LINKED_POSITION_GROUPS: [{
          ID: 'id-a',
          POSITIONS: [{
              FILE: '/ga.dart',
              OFFSET: 1,
              LENGTH: 2
            }, {
              FILE: '/ga.dart',
              OFFSET: 10,
              LENGTH: 2
            }]
        }, {
          ID: 'id-b',
          POSITIONS: [{
              FILE: '/gb.dart',
              OFFSET: 10,
              LENGTH: 5
            }, {
              FILE: '/gb.dart',
              OFFSET: 100,
              LENGTH: 5
            }]
        }]
    };
    Change change = Change.fromJson(json);
    expect(change.message, 'msg');
    // edits
    expect(change.edits, hasLength(2));
    {
      FileEdit fileEdit = change.edits[0];
      expect(fileEdit.file, '/a.dart');
      expect(fileEdit.edits, hasLength(2));
      expect(fileEdit.edits[0], new Edit(1, 2, 'aaa'));
      expect(fileEdit.edits[1], new Edit(10, 20, 'bbb'));
    }
    {
      FileEdit fileEdit = change.edits[1];
      expect(fileEdit.file, '/b.dart');
      expect(fileEdit.edits, hasLength(2));
      expect(fileEdit.edits[0], new Edit(21, 22, 'xxx'));
      expect(fileEdit.edits[1], new Edit(210, 220, 'yyy'));
    }
    // linked position groups
    expect(change.linkedPositionGroups, hasLength(2));
    {
      LinkedPositionGroup group = change.linkedPositionGroups[0];
      expect(group.id, 'id-a');
      expect(group.positions, hasLength(2));
      expect(group.positions[0], new Position('/ga.dart', 1, 2));
      expect(group.positions[1], new Position('/ga.dart', 10, 2));
    }
    {
      LinkedPositionGroup group = change.linkedPositionGroups[1];
      expect(group.id, 'id-b');
      expect(group.positions, hasLength(2));
      expect(group.positions[0], new Position('/gb.dart', 10, 5));
      expect(group.positions[1], new Position('/gb.dart', 100, 5));
    }
  }

  void test_new() {
    Change change = new Change('msg');
    change.add(new FileEdit('/a.dart')
        ..add(new Edit(1, 2, 'aaa'))
        ..add(new Edit(10, 20, 'bbb')));
    change.add(new FileEdit('/b.dart')
        ..add(new Edit(21, 22, 'xxx'))
        ..add(new Edit(210, 220, 'yyy')));
    change.addLinkedPositionGroup(new LinkedPositionGroup('id-a')
        ..addPosition(new Position('/ga.dart', 1, 2))
        ..addPosition(new Position('/ga.dart', 10, 2)));
    change.addLinkedPositionGroup(new LinkedPositionGroup('id-b')
        ..addPosition(new Position('/gb.dart', 10, 5))
        ..addPosition(new Position('/gb.dart', 100, 5)));
    expect(
        change.toString(),
        'Change(message=msg, edits=[FileEdit(file=/a.dart, edits=['
            'Edit(offset=1, length=2, replacement=:>aaa<:), '
            'Edit(offset=10, length=20, replacement=:>bbb<:)]), '
            'FileEdit(file=/b.dart, edits=['
            'Edit(offset=21, length=22, replacement=:>xxx<:), '
            'Edit(offset=210, length=220, replacement=:>yyy<:)])], '
            'linkedPositionGroups=[' 'LinkedPositionGroup(id=id-a, positions=['
            'Position(file=/ga.dart, offset=1, length=2), '
            'Position(file=/ga.dart, offset=10, length=2)]), '
            'LinkedPositionGroup(id=id-b, positions=['
            'Position(file=/gb.dart, offset=10, length=5), '
            'Position(file=/gb.dart, offset=100, length=5)])])');
  }

  void test_toJson() {
    Change change = new Change('msg');
    change.add(new FileEdit('/a.dart')
        ..add(new Edit(1, 2, 'aaa'))
        ..add(new Edit(10, 20, 'bbb')));
    change.add(new FileEdit('/b.dart')
        ..add(new Edit(21, 22, 'xxx'))
        ..add(new Edit(210, 220, 'yyy')));
    change.addLinkedPositionGroup(new LinkedPositionGroup('id-a')
        ..addPosition(new Position('/ga.dart', 1, 2))
        ..addPosition(new Position('/ga.dart', 10, 2)));
    change.addLinkedPositionGroup(new LinkedPositionGroup('id-b')
        ..addPosition(new Position('/gb.dart', 10, 5))
        ..addPosition(new Position('/gb.dart', 100, 5)));
    var expectedJson = {
      MESSAGE: 'msg',
      EDITS: [{
          FILE: '/a.dart',
          EDITS: [{
              OFFSET: 1,
              LENGTH: 2,
              REPLACEMENT: 'aaa'
            }, {
              OFFSET: 10,
              LENGTH: 20,
              REPLACEMENT: 'bbb'
            }]
        }, {
          FILE: '/b.dart',
          EDITS: [{
              OFFSET: 21,
              LENGTH: 22,
              REPLACEMENT: 'xxx'
            }, {
              OFFSET: 210,
              LENGTH: 220,
              REPLACEMENT: 'yyy'
            }]
        }],
      LINKED_POSITION_GROUPS: [{
          ID: 'id-a',
          POSITIONS: [{
              FILE: '/ga.dart',
              OFFSET: 1,
              LENGTH: 2
            }, {
              FILE: '/ga.dart',
              OFFSET: 10,
              LENGTH: 2
            }]
        }, {
          ID: 'id-b',
          POSITIONS: [{
              FILE: '/gb.dart',
              OFFSET: 10,
              LENGTH: 5
            }, {
              FILE: '/gb.dart',
              OFFSET: 100,
              LENGTH: 5
            }]
        }]
    };
    expect(change.toJson(), expectedJson);
  }
}


@ReflectiveTestCase()
class EditTest {
  void test_end() {
    Edit edit = new Edit(1, 2, 'foo');
    expect(edit.end, 3);
  }

  void test_fromJson() {
    var json = {
      OFFSET: 1,
      LENGTH: 2,
      REPLACEMENT: 'foo'
    };
    Edit edit = Edit.fromJson(json);
    expect(edit.offset, 1);
    expect(edit.length, 2);
    expect(edit.replacement, 'foo');
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
  void test_fromJson() {
    var json = {
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
    var fileEdit = FileEdit.fromJson(json);
    expect(fileEdit.file, '/test.dart');
    expect(fileEdit.edits, hasLength(2));
    expect(fileEdit.edits[0], new Edit(1, 2, 'aaa'));
    expect(fileEdit.edits[1], new Edit(10, 20, 'bbb'));
  }

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
    expect(fileEdit.toJson(), {
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
    });
  }
}


@ReflectiveTestCase()
class LinkedPositionGroupTest {
  void test_addWrongLength() {
    LinkedPositionGroup group = new LinkedPositionGroup('my-id');
    group.addPosition(new Position('/a.dart', 1, 2));
    expect(() {
      group.addPosition(new Position('/b.dart', 10, 20));
    }, throws);
  }

  void test_fromJson() {
    var json = {
      ID: 'my-id',
      POSITIONS: [{
          FILE: '/a.dart',
          OFFSET: 1,
          LENGTH: 2
        }, {
          FILE: '/b.dart',
          OFFSET: 10,
          LENGTH: 2
        }]
    };
    LinkedPositionGroup group = LinkedPositionGroup.fromJson(json);
    expect(group.id, 'my-id');
    expect(group.positions, hasLength(2));
    expect(group.positions[0], new Position('/a.dart', 1, 2));
    expect(group.positions[1], new Position('/b.dart', 10, 2));
  }

  void test_new() {
    LinkedPositionGroup group = new LinkedPositionGroup('my-id');
    group.addPosition(new Position('/a.dart', 1, 2));
    group.addPosition(new Position('/b.dart', 10, 2));
    expect(
        group.toString(),
        'LinkedPositionGroup(id=my-id, positions=['
            'Position(file=/a.dart, offset=1, length=2), '
            'Position(file=/b.dart, offset=10, length=2)])');
  }

  void test_toJson() {
    LinkedPositionGroup group = new LinkedPositionGroup('my-id');
    group.addPosition(new Position('/a.dart', 1, 2));
    group.addPosition(new Position('/b.dart', 10, 2));
    var expectedJson = {
      ID: 'my-id',
      POSITIONS: [{
          FILE: '/a.dart',
          OFFSET: 1,
          LENGTH: 2
        }, {
          FILE: '/b.dart',
          OFFSET: 10,
          LENGTH: 2
        }]
    };
    expect(group.toJson(), expectedJson);
  }
}


@ReflectiveTestCase()
class PositionTest {
  void test_eqEq() {
    Position a = new Position('/a.dart', 1, 2);
    Position a2 = new Position('/a.dart', 1, 2);
    Position b = new Position('/b.dart', 1, 2);
    expect(a == a, isTrue);
    expect(a == a2, isTrue);
    expect(a == b, isFalse);
    expect(a == this, isFalse);
  }

  void test_fromJson() {
    var json = {
      FILE: '/test.dart',
      OFFSET: 1,
      LENGTH: 2
    };
    Position position = Position.fromJson(json);
    expect(position.file, '/test.dart');
    expect(position.offset, 1);
    expect(position.length, 2);
  }

  void test_hashCode() {
    Position position = new Position('/test.dart', 1, 2);
    position.hashCode;
  }

  void test_new() {
    Position position = new Position('/test.dart', 1, 2);
    expect(position.file, '/test.dart');
    expect(position.offset, 1);
    expect(position.length, 2);
    expect(
        position.toString(),
        'Position(file=/test.dart, offset=1, length=2)');
  }

  void test_toJson() {
    Position position = new Position('/test.dart', 1, 2);
    var expectedJson = {
      FILE: '/test.dart',
      OFFSET: 1,
      LENGTH: 2
    };
    expect(position.toJson(), expectedJson);
  }
}
