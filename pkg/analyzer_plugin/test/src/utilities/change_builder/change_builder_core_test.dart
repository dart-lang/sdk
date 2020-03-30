// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:analyzer_plugin/src/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ChangeBuilderImplTest);
    defineReflectiveTests(EditBuilderImplTest);
    defineReflectiveTests(FileEditBuilderImplTest);
    defineReflectiveTests(LinkedEditBuilderImplTest);
  });
}

@reflectiveTest
class ChangeBuilderImplTest {
  Future<void> test_createFileEditBuilder() async {
    var builder = ChangeBuilderImpl();
    var path = '/test.dart';
    var fileEditBuilder = await builder.createFileEditBuilder(path);
    expect(fileEditBuilder, const TypeMatcher<FileEditBuilder>());
    var fileEdit = fileEditBuilder.fileEdit;
    expect(fileEdit.file, path);
  }

  void test_getLinkedEditGroup() {
    var builder = ChangeBuilderImpl();
    var group = builder.getLinkedEditGroup('a');
    expect(identical(builder.getLinkedEditGroup('b'), group), isFalse);
    expect(identical(builder.getLinkedEditGroup('a'), group), isTrue);
  }

  void test_setSelection() {
    var position = Position('test.dart', 3);
    var builder = ChangeBuilderImpl();
    builder.setSelection(position);
    expect(builder.sourceChange.selection, position);
  }

  void test_sourceChange_emptyEdit() async {
    var builder = ChangeBuilderImpl();
    var path = '/test.dart';
    await builder.addFileEdit(path, (FileEditBuilder builder) {});
    var sourceChange = builder.sourceChange;
    expect(sourceChange, isNotNull);
    expect(sourceChange.edits, isEmpty);
    expect(sourceChange.linkedEditGroups, isEmpty);
    expect(sourceChange.message, isEmpty);
    expect(sourceChange.selection, isNull);
  }

  void test_sourceChange_noEdits() {
    var builder = ChangeBuilderImpl();
    var sourceChange = builder.sourceChange;
    expect(sourceChange, isNotNull);
    expect(sourceChange.edits, isEmpty);
    expect(sourceChange.linkedEditGroups, isEmpty);
    expect(sourceChange.message, isEmpty);
    expect(sourceChange.selection, isNull);
  }

  Future<void> test_sourceChange_oneChange() async {
    var builder = ChangeBuilderImpl();
    var path = '/test.dart';
    await builder.addFileEdit(path, (FileEditBuilder builder) {
      builder.addSimpleInsertion(0, '_');
    });
    builder.getLinkedEditGroup('a');
    var sourceChange = builder.sourceChange;
    expect(sourceChange, isNotNull);
    expect(sourceChange.edits, hasLength(1));
    expect(sourceChange.linkedEditGroups, hasLength(1));
    expect(sourceChange.message, isEmpty);
    expect(sourceChange.selection, isNull);
  }
}

@reflectiveTest
class EditBuilderImplTest {
  String path = '/test.dart';

  Future<void> test_addLinkedEdit() async {
    var builder = ChangeBuilderImpl();
    var offset = 10;
    var text = 'content';
    await builder.addFileEdit(path, (FileEditBuilder builder) {
      builder.addInsertion(10, (EditBuilder builder) {
        builder.addLinkedEdit('a', (LinkedEditBuilder builder) {
          builder.write(text);
        });
        var sourceEdit = (builder as EditBuilderImpl).sourceEdit;
        expect(sourceEdit.replacement, text);
      });
    });
    var sourceChange = builder.sourceChange;
    expect(sourceChange, isNotNull);
    var groups = sourceChange.linkedEditGroups;
    expect(groups, hasLength(1));
    var group = groups[0];
    expect(group, isNotNull);
    expect(group.length, text.length);
    var positions = group.positions;
    expect(positions, hasLength(1));
    expect(positions[0].offset, offset);
  }

  Future<void> test_addSimpleLinkedEdit() async {
    var builder = ChangeBuilderImpl();
    var offset = 10;
    var text = 'content';
    await builder.addFileEdit(path, (FileEditBuilder builder) {
      builder.addInsertion(10, (EditBuilder builder) {
        builder.addSimpleLinkedEdit('a', text);
        var sourceEdit = (builder as EditBuilderImpl).sourceEdit;
        expect(sourceEdit.replacement, text);
      });
    });
    var sourceChange = builder.sourceChange;
    expect(sourceChange, isNotNull);
    var groups = sourceChange.linkedEditGroups;
    expect(groups, hasLength(1));
    var group = groups[0];
    expect(group, isNotNull);
    expect(group.length, text.length);
    var positions = group.positions;
    expect(positions, hasLength(1));
    expect(positions[0].offset, offset);
  }

  Future<void> test_createLinkedEditBuilder() async {
    var builder = ChangeBuilderImpl();
    await builder.addFileEdit(path, (FileEditBuilder builder) {
      builder.addInsertion(10, (EditBuilder builder) {
        var linkBuilder =
            (builder as EditBuilderImpl).createLinkedEditBuilder();
        expect(linkBuilder, const TypeMatcher<LinkedEditBuilder>());
      });
    });
  }

  Future<void> test_selectHere() async {
    var builder = ChangeBuilderImpl();
    await builder.addFileEdit(path, (FileEditBuilder builder) {
      builder.addInsertion(10, (EditBuilder builder) {
        builder.selectHere();
      });
    });
    expect(builder.sourceChange.selection.offset, 10);
  }

  Future<void> test_write() async {
    var builder = ChangeBuilderImpl();
    var offset = 10;
    var text = 'write';
    await builder.addFileEdit(path, (FileEditBuilder builder) {
      builder.addInsertion(offset, (EditBuilder builder) {
        builder.write(text);
      });
    });

    var sourceChange = builder.sourceChange;
    expect(sourceChange, isNotNull);

    var fileEdits = sourceChange.edits;
    expect(fileEdits, hasLength(1));
    var fileEdit = fileEdits[0];
    expect(fileEdit, isNotNull);
    expect(fileEdit.file, path);

    var edits = fileEdit.edits;
    expect(edits, hasLength(1));
    var edit = edits[0];
    expect(edit, isNotNull);
    expect(edit.offset, offset);
    expect(edit.length, 0);
    expect(edit.replacement, text);
  }

  Future<void> test_writeln_withoutText() async {
    var builder = ChangeBuilderImpl();
    var offset = 52;
    var length = 12;
    await builder.addFileEdit(path, (FileEditBuilder builder) {
      builder.addReplacement(SourceRange(offset, length),
          (EditBuilder builder) {
        builder.writeln();
      });
    });

    var sourceChange = builder.sourceChange;
    expect(sourceChange, isNotNull);

    var fileEdits = sourceChange.edits;
    expect(fileEdits, hasLength(1));
    var fileEdit = fileEdits[0];
    expect(fileEdit, isNotNull);
    expect(fileEdit.file, path);

    var edits = fileEdit.edits;
    expect(edits, hasLength(1));
    var edit = edits[0];
    expect(edit, isNotNull);
    expect(edit.offset, offset);
    expect(edit.length, length);
    expect(edit.replacement == '\n' || edit.replacement == '\r\n', isTrue);
  }

  Future<void> test_writeln_withText() async {
    var builder = ChangeBuilderImpl();
    var offset = 52;
    var length = 12;
    var text = 'writeln';
    await builder.addFileEdit(path, (FileEditBuilder builder) {
      builder.addReplacement(SourceRange(offset, length),
          (EditBuilder builder) {
        builder.writeln(text);
      });
    });

    var sourceChange = builder.sourceChange;
    expect(sourceChange, isNotNull);

    var fileEdits = sourceChange.edits;
    expect(fileEdits, hasLength(1));
    var fileEdit = fileEdits[0];
    expect(fileEdit, isNotNull);
    expect(fileEdit.file, path);

    var edits = fileEdit.edits;
    expect(edits, hasLength(1));
    var edit = edits[0];
    expect(edit, isNotNull);
    expect(edit.offset, offset);
    expect(edit.length, length);
    expect(edit.replacement == '$text\n' || edit.replacement == '$text\r\n',
        isTrue);
  }
}

@reflectiveTest
class FileEditBuilderImplTest {
  String path = '/test.dart';

  Future<void> test_addDeletion() async {
    var offset = 23;
    var length = 7;
    var builder = ChangeBuilderImpl();
    await builder.addFileEdit(path, (FileEditBuilder builder) {
      builder.addDeletion(SourceRange(offset, length));
    });
    var edits = builder.sourceChange.edits[0].edits;
    expect(edits, hasLength(1));
    expect(edits[0].offset, offset);
    expect(edits[0].length, length);
    expect(edits[0].replacement, isEmpty);
  }

  Future<void> test_addInsertion() async {
    var builder = ChangeBuilderImpl();
    await builder.addFileEdit(path, (FileEditBuilder builder) {
      builder.addInsertion(10, (EditBuilder builder) {
        expect(builder, isNotNull);
      });
    });
  }

  Future<void> test_addLinkedPosition() async {
    var builder = ChangeBuilderImpl();
    var groupName = 'a';
    await builder.addFileEdit(path, (FileEditBuilder builder) {
      builder.addLinkedPosition(SourceRange(3, 6), groupName);
    });

    var group = builder.getLinkedEditGroup(groupName);
    var positions = group.positions;
    expect(positions, hasLength(1));
    var position = positions[0];
    expect(position.file, path);
    expect(position.offset, 3);
    expect(group.length, 6);
  }

  Future<void> test_addReplacement() async {
    var builder = ChangeBuilderImpl();
    await builder.addFileEdit(path, (FileEditBuilder builder) {
      builder.addReplacement(SourceRange(4, 5), (EditBuilder builder) {
        expect(builder, isNotNull);
      });
    });
  }

  Future<void> test_addSimpleInsertion() async {
    var offset = 23;
    var text = 'xyz';
    var builder = ChangeBuilderImpl();
    await builder.addFileEdit(path, (FileEditBuilder builder) {
      builder.addSimpleInsertion(offset, text);
    });
    var edits = builder.sourceChange.edits[0].edits;
    expect(edits, hasLength(1));
    expect(edits[0].offset, offset);
    expect(edits[0].length, 0);
    expect(edits[0].replacement, text);
  }

  Future<void> test_addSimpleReplacement() async {
    var offset = 23;
    var length = 7;
    var text = 'xyz';
    var builder = ChangeBuilderImpl();
    await builder.addFileEdit(path, (FileEditBuilder builder) {
      builder.addSimpleReplacement(SourceRange(offset, length), text);
    });
    var edits = builder.sourceChange.edits[0].edits;
    expect(edits, hasLength(1));
    expect(edits[0].offset, offset);
    expect(edits[0].length, length);
    expect(edits[0].replacement, text);
  }

  Future<void> test_createEditBuilder() async {
    var builder = ChangeBuilderImpl();
    await builder.addFileEdit(path, (FileEditBuilder builder) {
      var offset = 4;
      var length = 5;
      var editBuilder =
          (builder as FileEditBuilderImpl).createEditBuilder(offset, length);
      expect(editBuilder, const TypeMatcher<EditBuilder>());
      var sourceEdit = editBuilder.sourceEdit;
      expect(sourceEdit.length, length);
      expect(sourceEdit.offset, offset);
      expect(sourceEdit.replacement, isEmpty);
    });
  }
}

@reflectiveTest
class LinkedEditBuilderImplTest {
  String path = '/test.dart';

  Future<void> test_addSuggestion() async {
    var groupName = 'a';
    var builder = ChangeBuilderImpl();
    await builder.addFileEdit(path, (FileEditBuilder builder) {
      builder.addInsertion(10, (EditBuilder builder) {
        builder.addLinkedEdit(groupName, (LinkedEditBuilder builder) {
          builder.write('A');
          builder.addSuggestion(LinkedEditSuggestionKind.TYPE, 'B');
        });
      });
    });

    var group = builder.getLinkedEditGroup(groupName);
    expect(group.suggestions, hasLength(1));
  }

  Future<void> test_addSuggestion_zeroLength() async {
    var groupName = 'a';
    var builder = ChangeBuilderImpl();
    await builder.addFileEdit(path, (FileEditBuilder builder) {
      builder.addInsertion(10, (EditBuilder builder) {
        builder.addLinkedEdit(groupName, (LinkedEditBuilder builder) {
          builder.addSuggestion(LinkedEditSuggestionKind.TYPE, 'A');
        });
      });
    });

    expect(builder.sourceChange.linkedEditGroups, isEmpty);
  }

  Future<void> test_addSuggestions() async {
    var groupName = 'a';
    var builder = ChangeBuilderImpl();
    await builder.addFileEdit(path, (FileEditBuilder builder) {
      builder.addInsertion(10, (EditBuilder builder) {
        builder.addLinkedEdit(groupName, (LinkedEditBuilder builder) {
          builder.write('A');
          builder.addSuggestions(LinkedEditSuggestionKind.TYPE, ['B', 'C']);
        });
      });
    });

    var group = builder.getLinkedEditGroup(groupName);
    expect(group.suggestions, hasLength(2));
  }
}
