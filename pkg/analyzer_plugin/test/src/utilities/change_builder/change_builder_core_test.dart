// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:analyzer_plugin/src/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ChangeBuilderImplTest);
    defineReflectiveTests(EditBuilderImplTest);
    defineReflectiveTests(FileEditBuilderImplTest);
    defineReflectiveTests(LinkedEditBuilderImplTest);
  });
}

@reflectiveTest
class ChangeBuilderImplTest {
  test_createFileEditBuilder() async {
    ChangeBuilderImpl builder = new ChangeBuilderImpl();
    String path = '/test.dart';
    FileEditBuilderImpl fileEditBuilder =
        await builder.createFileEditBuilder(path);
    expect(fileEditBuilder, new isInstanceOf<FileEditBuilder>());
    SourceFileEdit fileEdit = fileEditBuilder.fileEdit;
    expect(fileEdit.file, path);
  }

  void test_getLinkedEditGroup() {
    ChangeBuilderImpl builder = new ChangeBuilderImpl();
    LinkedEditGroup group = builder.getLinkedEditGroup('a');
    expect(identical(builder.getLinkedEditGroup('b'), group), isFalse);
    expect(identical(builder.getLinkedEditGroup('a'), group), isTrue);
  }

  void test_setSelection() {
    Position position = new Position('test.dart', 3);
    ChangeBuilderImpl builder = new ChangeBuilderImpl();
    builder.setSelection(position);
    expect(builder.sourceChange.selection, position);
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

  test_sourceChange_oneChange() async {
    ChangeBuilderImpl builder = new ChangeBuilderImpl();
    String path = '/test.dart';
    await builder.addFileEdit(path, (FileEditBuilder builder) {});
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
  String path = '/test.dart';

  test_addLinkedEdit() async {
    ChangeBuilderImpl builder = new ChangeBuilderImpl();
    int offset = 10;
    String text = 'content';
    await builder.addFileEdit(path, (FileEditBuilder builder) {
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

  test_addSimpleLinkedEdit() async {
    ChangeBuilderImpl builder = new ChangeBuilderImpl();
    int offset = 10;
    String text = 'content';
    await builder.addFileEdit(path, (FileEditBuilder builder) {
      builder.addInsertion(10, (EditBuilder builder) {
        builder.addSimpleLinkedEdit('a', text);
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

  test_createLinkedEditBuilder() async {
    ChangeBuilderImpl builder = new ChangeBuilderImpl();
    await builder.addFileEdit(path, (FileEditBuilder builder) {
      builder.addInsertion(10, (EditBuilder builder) {
        LinkedEditBuilderImpl linkBuilder =
            (builder as EditBuilderImpl).createLinkedEditBuilder();
        expect(linkBuilder, new isInstanceOf<LinkedEditBuilder>());
      });
    });
  }

  test_selectHere() async {
    ChangeBuilderImpl builder = new ChangeBuilderImpl();
    await builder.addFileEdit(path, (FileEditBuilder builder) {
      builder.addInsertion(10, (EditBuilder builder) {
        builder.selectHere();
      });
    });
    expect(builder.sourceChange.selection.offset, 10);
  }

  test_write() async {
    ChangeBuilderImpl builder = new ChangeBuilderImpl();
    int offset = 10;
    String text = 'write';
    await builder.addFileEdit(path, (FileEditBuilder builder) {
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
    expect(fileEdit.file, path);

    List<SourceEdit> edits = fileEdit.edits;
    expect(edits, hasLength(1));
    SourceEdit edit = edits[0];
    expect(edit, isNotNull);
    expect(edit.offset, offset);
    expect(edit.length, 0);
    expect(edit.replacement, text);
  }

  test_writeln_withoutText() async {
    ChangeBuilderImpl builder = new ChangeBuilderImpl();
    int offset = 52;
    int length = 12;
    await builder.addFileEdit(path, (FileEditBuilder builder) {
      builder.addReplacement(new SourceRange(offset, length),
          (EditBuilder builder) {
        builder.writeln();
      });
    });

    SourceChange sourceChange = builder.sourceChange;
    expect(sourceChange, isNotNull);

    List<SourceFileEdit> fileEdits = sourceChange.edits;
    expect(fileEdits, hasLength(1));
    SourceFileEdit fileEdit = fileEdits[0];
    expect(fileEdit, isNotNull);
    expect(fileEdit.file, path);

    List<SourceEdit> edits = fileEdit.edits;
    expect(edits, hasLength(1));
    SourceEdit edit = edits[0];
    expect(edit, isNotNull);
    expect(edit.offset, offset);
    expect(edit.length, length);
    expect(edit.replacement == '\n' || edit.replacement == '\r\n', isTrue);
  }

  test_writeln_withText() async {
    ChangeBuilderImpl builder = new ChangeBuilderImpl();
    int offset = 52;
    int length = 12;
    String text = 'writeln';
    await builder.addFileEdit(path, (FileEditBuilder builder) {
      builder.addReplacement(new SourceRange(offset, length),
          (EditBuilder builder) {
        builder.writeln(text);
      });
    });

    SourceChange sourceChange = builder.sourceChange;
    expect(sourceChange, isNotNull);

    List<SourceFileEdit> fileEdits = sourceChange.edits;
    expect(fileEdits, hasLength(1));
    SourceFileEdit fileEdit = fileEdits[0];
    expect(fileEdit, isNotNull);
    expect(fileEdit.file, path);

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
  String path = '/test.dart';

  test_addDeletion() async {
    int offset = 23;
    int length = 7;
    ChangeBuilderImpl builder = new ChangeBuilderImpl();
    await builder.addFileEdit(path, (FileEditBuilder builder) {
      builder.addDeletion(new SourceRange(offset, length));
    });
    List<SourceEdit> edits = builder.sourceChange.edits[0].edits;
    expect(edits, hasLength(1));
    expect(edits[0].offset, offset);
    expect(edits[0].length, length);
    expect(edits[0].replacement, isEmpty);
  }

  test_addInsertion() async {
    ChangeBuilderImpl builder = new ChangeBuilderImpl();
    await builder.addFileEdit(path, (FileEditBuilder builder) {
      builder.addInsertion(10, (EditBuilder builder) {
        expect(builder, isNotNull);
      });
    });
  }

  test_addLinkedPosition() async {
    ChangeBuilderImpl builder = new ChangeBuilderImpl();
    String groupName = 'a';
    await builder.addFileEdit(path, (FileEditBuilder builder) {
      builder.addLinkedPosition(new SourceRange(3, 6), groupName);
    });

    LinkedEditGroup group = builder.getLinkedEditGroup(groupName);
    List<Position> positions = group.positions;
    expect(positions, hasLength(1));
    Position position = positions[0];
    expect(position.file, path);
    expect(position.offset, 3);
    expect(group.length, 6);
  }

  test_addReplacement() async {
    ChangeBuilderImpl builder = new ChangeBuilderImpl();
    await builder.addFileEdit(path, (FileEditBuilder builder) {
      builder.addReplacement(new SourceRange(4, 5), (EditBuilder builder) {
        expect(builder, isNotNull);
      });
    });
  }

  test_addSimpleInsertion() async {
    int offset = 23;
    String text = 'xyz';
    ChangeBuilderImpl builder = new ChangeBuilderImpl();
    await builder.addFileEdit(path, (FileEditBuilder builder) {
      builder.addSimpleInsertion(offset, text);
    });
    List<SourceEdit> edits = builder.sourceChange.edits[0].edits;
    expect(edits, hasLength(1));
    expect(edits[0].offset, offset);
    expect(edits[0].length, 0);
    expect(edits[0].replacement, text);
  }

  test_addSimpleReplacement() async {
    int offset = 23;
    int length = 7;
    String text = 'xyz';
    ChangeBuilderImpl builder = new ChangeBuilderImpl();
    await builder.addFileEdit(path, (FileEditBuilder builder) {
      builder.addSimpleReplacement(new SourceRange(offset, length), text);
    });
    List<SourceEdit> edits = builder.sourceChange.edits[0].edits;
    expect(edits, hasLength(1));
    expect(edits[0].offset, offset);
    expect(edits[0].length, length);
    expect(edits[0].replacement, text);
  }

  test_createEditBuilder() async {
    ChangeBuilderImpl builder = new ChangeBuilderImpl();
    await builder.addFileEdit(path, (FileEditBuilder builder) {
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
  String path = '/test.dart';

  test_addSuggestion() async {
    String groupName = 'a';
    ChangeBuilderImpl builder = new ChangeBuilderImpl();
    await builder.addFileEdit(path, (FileEditBuilder builder) {
      builder.addInsertion(10, (EditBuilder builder) {
        builder.addLinkedEdit(groupName, (LinkedEditBuilder builder) {
          builder.addSuggestion(LinkedEditSuggestionKind.TYPE, 'A');
        });
      });
    });

    LinkedEditGroup group = builder.getLinkedEditGroup(groupName);
    expect(group.suggestions, hasLength(1));
  }

  test_addSuggestions() async {
    String groupName = 'a';
    ChangeBuilderImpl builder = new ChangeBuilderImpl();
    await builder.addFileEdit(path, (FileEditBuilder builder) {
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
