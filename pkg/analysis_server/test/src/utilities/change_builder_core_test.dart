// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analysis_server.test.src.utilities.change_builder_core_test;

import 'package:analysis_server/plugin/protocol/protocol.dart';
import 'package:analysis_server/src/provisional/edit/utilities/change_builder_core.dart';
import 'package:analysis_server/src/utilities/change_builder_core.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';
import 'package:unittest/unittest.dart';

import '../../domain_execution_test.dart';
import '../../utils.dart';

main() {
  initializeTestEnvironment();
  defineReflectiveTests(ChangeBuilderImplTest);
  defineReflectiveTests(EditBuilderImplTest);
  defineReflectiveTests(FileEditBuilderImplTest);
  defineReflectiveTests(LinkedEditBuilderImplTest);
}

@reflectiveTest
class ChangeBuilderImplTest {
  void test_createFileEditBuilder() {
    ChangeBuilderImpl builder = new ChangeBuilderImpl();
    TestSource source = new TestSource('/test.dart');
    int timeStamp = 54;
    FileEditBuilderImpl fileEditBuilder =
        builder.createFileEditBuilder(source, timeStamp);
    expect(fileEditBuilder, new isInstanceOf<FileEditBuilder>());
    SourceFileEdit fileEdit = fileEditBuilder.fileEdit;
    expect(fileEdit.file, source.fullName);
    expect(fileEdit.fileStamp, timeStamp);
  }

  void test_getLinkedEditGroup() {
    ChangeBuilderImpl builder = new ChangeBuilderImpl();
    LinkedEditGroup group = builder.getLinkedEditGroup('a');
    expect(identical(builder.getLinkedEditGroup('b'), group), isFalse);
    expect(identical(builder.getLinkedEditGroup('a'), group), isTrue);
  }

  void test_sourceChange_noChanges() {
    ChangeBuilderImpl builder = new ChangeBuilderImpl();
    SourceChange sourceChange = builder.sourceChange;
    expect(sourceChange, isNotNull);
    expect(sourceChange.edits, isEmpty);
    expect(sourceChange.linkedEditGroups, isEmpty);
    expect(sourceChange.message, isEmpty);
    expect(sourceChange.selection, isNull);
  }

  void test_sourceChange_oneChange() {
    ChangeBuilderImpl builder = new ChangeBuilderImpl();
    TestSource source = new TestSource('/test.dart');
    builder.addFileEdit(source, 0, (FileEditBuilder builder) {});
    builder.getLinkedEditGroup('a');
    SourceChange sourceChange = builder.sourceChange;
    expect(sourceChange, isNotNull);
    expect(sourceChange.edits, hasLength(1));
    expect(sourceChange.linkedEditGroups, hasLength(1));
    expect(sourceChange.message, isEmpty);
    expect(sourceChange.selection, isNull);
  }
}

@reflectiveTest
class EditBuilderImplTest {
  TestSource source = new TestSource('/test.dart');

  void test_addLinkedEdit() {
    ChangeBuilderImpl builder = new ChangeBuilderImpl();
    int offset = 10;
    String text = 'content';
    builder.addFileEdit(source, 0, (FileEditBuilder builder) {
      builder.addInsertion(10, (EditBuilder builder) {
        builder.addLinkedEdit('a', (LinkedEditBuilder builder) {
          builder.write(text);
        });
        SourceEdit sourceEdit = (builder as EditBuilderImpl).sourceEdit;
        expect(sourceEdit.replacement, text);
      });
    });
    SourceChange sourceChange = builder.sourceChange;
    expect(sourceChange, isNotNull);
    List<LinkedEditGroup> groups = sourceChange.linkedEditGroups;
    expect(groups, hasLength(1));
    LinkedEditGroup group = groups[0];
    expect(group, isNotNull);
    expect(group.length, text.length);
    List<Position> positions = group.positions;
    expect(positions, hasLength(1));
    expect(positions[0].offset, offset);
  }

  void test_createLinkedEditBuilder() {
    ChangeBuilderImpl builder = new ChangeBuilderImpl();
    builder.addFileEdit(source, 0, (FileEditBuilder builder) {
      builder.addInsertion(10, (EditBuilder builder) {
        LinkedEditBuilderImpl linkBuilder =
            (builder as EditBuilderImpl).createLinkedEditBuilder();
        expect(linkBuilder, new isInstanceOf<LinkedEditBuilder>());
      });
    });
  }

  void test_write() {
    ChangeBuilderImpl builder = new ChangeBuilderImpl();
    int timeStamp = 93;
    int offset = 10;
    String text = 'write';
    builder.addFileEdit(source, timeStamp, (FileEditBuilder builder) {
      builder.addInsertion(offset, (EditBuilder builder) {
        builder.write(text);
      });
    });

    SourceChange sourceChange = builder.sourceChange;
    expect(sourceChange, isNotNull);

    List<SourceFileEdit> fileEdits = sourceChange.edits;
    expect(fileEdits, hasLength(1));
    SourceFileEdit fileEdit = fileEdits[0];
    expect(fileEdit, isNotNull);
    expect(fileEdit.file, source.fullName);
    expect(fileEdit.fileStamp, timeStamp);

    List<SourceEdit> edits = fileEdit.edits;
    expect(edits, hasLength(1));
    SourceEdit edit = edits[0];
    expect(edit, isNotNull);
    expect(edit.offset, offset);
    expect(edit.length, 0);
    expect(edit.replacement, text);
  }

  void test_writeln_withoutText() {
    ChangeBuilderImpl builder = new ChangeBuilderImpl();
    int timeStamp = 39;
    int offset = 52;
    int length = 12;
    builder.addFileEdit(source, timeStamp, (FileEditBuilder builder) {
      builder.addReplacement(offset, length, (EditBuilder builder) {
        builder.writeln();
      });
    });

    SourceChange sourceChange = builder.sourceChange;
    expect(sourceChange, isNotNull);

    List<SourceFileEdit> fileEdits = sourceChange.edits;
    expect(fileEdits, hasLength(1));
    SourceFileEdit fileEdit = fileEdits[0];
    expect(fileEdit, isNotNull);
    expect(fileEdit.file, source.fullName);
    expect(fileEdit.fileStamp, timeStamp);

    List<SourceEdit> edits = fileEdit.edits;
    expect(edits, hasLength(1));
    SourceEdit edit = edits[0];
    expect(edit, isNotNull);
    expect(edit.offset, offset);
    expect(edit.length, length);
    expect(edit.replacement == '\n' || edit.replacement == '\r\n', isTrue);
  }

  void test_writeln_withText() {
    ChangeBuilderImpl builder = new ChangeBuilderImpl();
    int timeStamp = 39;
    int offset = 52;
    int length = 12;
    String text = 'writeln';
    builder.addFileEdit(source, timeStamp, (FileEditBuilder builder) {
      builder.addReplacement(offset, length, (EditBuilder builder) {
        builder.writeln(text);
      });
    });

    SourceChange sourceChange = builder.sourceChange;
    expect(sourceChange, isNotNull);

    List<SourceFileEdit> fileEdits = sourceChange.edits;
    expect(fileEdits, hasLength(1));
    SourceFileEdit fileEdit = fileEdits[0];
    expect(fileEdit, isNotNull);
    expect(fileEdit.file, source.fullName);
    expect(fileEdit.fileStamp, timeStamp);

    List<SourceEdit> edits = fileEdit.edits;
    expect(edits, hasLength(1));
    SourceEdit edit = edits[0];
    expect(edit, isNotNull);
    expect(edit.offset, offset);
    expect(edit.length, length);
    expect(edit.replacement == '$text\n' || edit.replacement == '$text\r\n',
        isTrue);
  }
}

@reflectiveTest
class FileEditBuilderImplTest {
  TestSource source = new TestSource('/test.dart');

  void test_addInsertion() {
    ChangeBuilderImpl builder = new ChangeBuilderImpl();
    builder.addFileEdit(source, 0, (FileEditBuilder builder) {
      builder.addInsertion(10, (EditBuilder builder) {
        expect(builder, isNotNull);
      });
    });
  }

  void test_addLinkedPosition() {
    ChangeBuilderImpl changeBuilder = new ChangeBuilderImpl();
    String groupName = 'a';
    changeBuilder.addFileEdit(source, 0, (FileEditBuilder builder) {
      builder.addLinkedPosition(3, 6, groupName);
    });

    LinkedEditGroup group = changeBuilder.getLinkedEditGroup(groupName);
    List<Position> positions = group.positions;
    expect(positions, hasLength(1));
    Position position = positions[0];
    expect(position.file, source.fullName);
    expect(position.offset, 3);
    expect(group.length, 6);
  }

  void test_addReplacement() {
    ChangeBuilderImpl builder = new ChangeBuilderImpl();
    builder.addFileEdit(source, 0, (FileEditBuilder builder) {
      builder.addReplacement(4, 5, (EditBuilder builder) {
        expect(builder, isNotNull);
      });
    });
  }

  void test_createEditBuilder() {
    ChangeBuilderImpl builder = new ChangeBuilderImpl();
    builder.addFileEdit(source, 0, (FileEditBuilder builder) {
      int offset = 4;
      int length = 5;
      EditBuilderImpl editBuilder =
          (builder as FileEditBuilderImpl).createEditBuilder(offset, length);
      expect(editBuilder, new isInstanceOf<EditBuilder>());
      SourceEdit sourceEdit = editBuilder.sourceEdit;
      expect(sourceEdit.length, length);
      expect(sourceEdit.offset, offset);
      expect(sourceEdit.replacement, isEmpty);
    });
  }
}

@reflectiveTest
class LinkedEditBuilderImplTest {
  TestSource source = new TestSource('/test.dart');

  void test_addSuggestion() {
    String groupName = 'a';
    ChangeBuilderImpl builder = new ChangeBuilderImpl();
    builder.addFileEdit(source, 0, (FileEditBuilder builder) {
      builder.addInsertion(10, (EditBuilder builder) {
        builder.addLinkedEdit(groupName, (LinkedEditBuilder builder) {
          builder.addSuggestion(LinkedEditSuggestionKind.TYPE, 'A');
        });
      });
    });

    LinkedEditGroup group = builder.getLinkedEditGroup(groupName);
    expect(group.suggestions, hasLength(1));
  }

  void test_addSuggestions() {
    String groupName = 'a';
    ChangeBuilderImpl builder = new ChangeBuilderImpl();
    builder.addFileEdit(source, 0, (FileEditBuilder builder) {
      builder.addInsertion(10, (EditBuilder builder) {
        builder.addLinkedEdit(groupName, (LinkedEditBuilder builder) {
          builder.addSuggestions(LinkedEditSuggestionKind.TYPE, ['A', 'B']);
        });
      });
    });

    LinkedEditGroup group = builder.getLinkedEditGroup(groupName);
    expect(group.suggestions, hasLength(2));
  }
}
