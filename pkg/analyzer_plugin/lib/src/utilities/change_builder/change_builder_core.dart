// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';

/**
 * A builder used to build a [SourceChange].
 */
class ChangeBuilderImpl implements ChangeBuilder {
  /**
   * The end-of-line marker used in the file being edited, or `null` if the
   * default marker should be used.
   */
  String eol = null;

  /**
   * The change that is being built.
   */
  final SourceChange _change = new SourceChange('');

  /**
   * A table mapping group ids to the associated linked edit groups.
   */
  final Map<String, LinkedEditGroup> _linkedEditGroups =
      <String, LinkedEditGroup>{};

  /**
   * Initialize a newly created change builder.
   */
  ChangeBuilderImpl();

  @override
  SourceChange get sourceChange {
    _linkedEditGroups.forEach((String name, LinkedEditGroup group) {
      _change.addLinkedEditGroup(group);
    });
    _linkedEditGroups.clear();
    return _change;
  }

  @override
  Future<Null> addFileEdit(String path, int fileStamp,
      void buildFileEdit(FileEditBuilder builder)) async {
    FileEditBuilderImpl builder = await createFileEditBuilder(path, fileStamp);
    buildFileEdit(builder);
    _change.addFileEdit(builder.fileEdit);
    builder.finalize();
  }

  /**
   * Create and return a [FileEditBuilder] that can be used to build edits to
   * the file with the given [path] and [timeStamp].
   */
  Future<FileEditBuilderImpl> createFileEditBuilder(
      String path, int timeStamp) async {
    return new FileEditBuilderImpl(this, path, timeStamp);
  }

  /**
   * Return the linked edit group with the given [groupName], creating it if it
   * did not already exist.
   */
  LinkedEditGroup getLinkedEditGroup(String groupName) {
    LinkedEditGroup group = _linkedEditGroups[groupName];
    if (group == null) {
      group = new LinkedEditGroup.empty();
      _linkedEditGroups[groupName] = group;
    }
    return group;
  }

  @override
  void setSelection(Position position) {
    _change.selection = position;
  }
}

/**
 * A builder used to build a [SourceEdit] as part of a [SourceFileEdit].
 */
class EditBuilderImpl implements EditBuilder {
  /**
   * The builder being used to create the source file edit of which the source
   * edit will be a part.
   */
  final FileEditBuilderImpl fileEditBuilder;

  /**
   * The offset of the region being replaced.
   */
  final int offset;

  /**
   * The length of the region being replaced.
   */
  final int length;

  /**
   * The offset of the selection for the change being built, or `-1` if the
   * selection is not inside the change being built.
   */
  int _selectionOffset = -1;

  /**
   * The end-of-line marker used in the file being edited, or `null` if the
   * default marker should be used.
   */
  String _eol = null;

  /**
   * The buffer in which the content of the edit is being composed.
   */
  final StringBuffer _buffer = new StringBuffer();

  /**
   * Initialize a newly created builder to build a source edit.
   */
  EditBuilderImpl(this.fileEditBuilder, this.offset, this.length) {
    _eol = fileEditBuilder.changeBuilder.eol;
  }

  /**
   * Create and return an edit representing the replacement of a region of the
   * file with the accumulated text.
   */
  SourceEdit get sourceEdit =>
      new SourceEdit(offset, length, _buffer.toString());

  @override
  void addLinkedEdit(
      String groupName, void buildLinkedEdit(LinkedEditBuilder builder)) {
    LinkedEditBuilderImpl builder = createLinkedEditBuilder();
    int start = offset + _buffer.length;
    try {
      buildLinkedEdit(builder);
    } finally {
      int end = offset + _buffer.length;
      int length = end - start;
      Position position = new Position(fileEditBuilder.fileEdit.file, start);
      LinkedEditGroup group =
          fileEditBuilder.changeBuilder.getLinkedEditGroup(groupName);
      group.addPosition(position, length);
      for (LinkedEditSuggestion suggestion in builder.suggestions) {
        group.addSuggestion(suggestion);
      }
    }
  }

  @override
  void addSimpleLinkedEdit(String groupName, String text,
      {LinkedEditSuggestionKind kind, List<String> suggestions}) {
    addLinkedEdit(groupName, (LinkedEditBuilder builder) {
      builder.write(text);
      if (kind != null && suggestions != null) {
        for (String suggestion in suggestions) {
          builder.addSuggestion(kind, suggestion);
        }
      } else if (kind != null || suggestions != null) {
        throw new ArgumentError(
            'Either both kind and suggestions must be provided or neither.');
      }
    });
  }

  LinkedEditBuilderImpl createLinkedEditBuilder() {
    return new LinkedEditBuilderImpl(this);
  }

  @override
  void selectHere() {
    _selectionOffset = offset + _buffer.length;
  }

  @override
  void write(String string) {
    _buffer.write(string);
  }

  @override
  void writeln([String string]) {
    if (string != null) {
      _buffer.write(string);
    }
    if (_eol == null) {
      _buffer.writeln();
    } else {
      _buffer.write(_eol);
    }
  }
}

/**
 * A builder used to build a [SourceFileEdit] within a [SourceChange].
 */
class FileEditBuilderImpl implements FileEditBuilder {
  /**
   * The builder being used to create the source change of which the source file
   * edit will be a part.
   */
  final ChangeBuilderImpl changeBuilder;

  /**
   * The source file edit that is being built.
   */
  final SourceFileEdit fileEdit;

  /**
   * Initialize a newly created builder to build a source file edit within the
   * change being built by the given [changeBuilder]. The file being edited has
   * the given absolute [path] and [timeStamp].
   */
  FileEditBuilderImpl(this.changeBuilder, String path, int timeStamp)
      : fileEdit = new SourceFileEdit(path, timeStamp);

  @override
  void addDeletion(SourceRange range) {
    EditBuilderImpl builder = createEditBuilder(range.offset, range.length);
    fileEdit.add(builder.sourceEdit);
  }

  @override
  void addInsertion(int offset, void buildEdit(EditBuilder builder)) {
    EditBuilderImpl builder = createEditBuilder(offset, 0);
    try {
      buildEdit(builder);
    } finally {
      SourceEdit edit = builder.sourceEdit;
      fileEdit.add(edit);
      _captureSelection(builder, edit);
    }
  }

  @override
  void addLinkedPosition(SourceRange range, String groupName) {
    LinkedEditGroup group = changeBuilder.getLinkedEditGroup(groupName);
    Position position = new Position(
        fileEdit.file, range.offset + _deltaToOffset(range.offset));
    group.addPosition(position, range.length);
  }

  @override
  void addReplacement(SourceRange range, void buildEdit(EditBuilder builder)) {
    EditBuilderImpl builder = createEditBuilder(range.offset, range.length);
    try {
      buildEdit(builder);
    } finally {
      SourceEdit edit = builder.sourceEdit;
      fileEdit.add(edit);
      _captureSelection(builder, edit);
    }
  }

  @override
  void addSimpleInsertion(int offset, String text) {
    EditBuilderImpl builder = createEditBuilder(offset, 0);
    try {
      builder.write(text);
    } finally {
      SourceEdit edit = builder.sourceEdit;
      fileEdit.add(edit);
      _captureSelection(builder, edit);
    }
  }

  @override
  void addSimpleReplacement(SourceRange range, String text) {
    EditBuilderImpl builder = createEditBuilder(range.offset, range.length);
    try {
      builder.write(text);
    } finally {
      SourceEdit edit = builder.sourceEdit;
      fileEdit.add(edit);
      _captureSelection(builder, edit);
    }
  }

  EditBuilderImpl createEditBuilder(int offset, int length) {
    return new EditBuilderImpl(this, offset, length);
  }

  /**
   * Finalize the source file edit that is being built.
   */
  void finalize() {
    // Nothing to do.
  }

  /**
   * Capture the selection offset if one was set.
   */
  void _captureSelection(EditBuilderImpl builder, SourceEdit edit) {
    int offset = builder._selectionOffset;
    if (offset >= 0) {
      Position position =
          new Position(fileEdit.file, offset + _deltaToEdit(edit));
      changeBuilder.setSelection(position);
    }
  }

  /**
   * Return the current delta caused by edits that will be applied before the
   * [targetEdit]. In other words, if all of the edits that occur before the
   * target edit were to be applied, then the text at the offset of the target
   * edit before the applied edits will be at `offset + _deltaToOffset(offset)`
   * after the edits.
   */
  int _deltaToEdit(SourceEdit targetEdit) {
    int delta = 0;
    for (SourceEdit edit in fileEdit.edits) {
      if (edit.offset < targetEdit.offset) {
        delta += edit.replacement.length - edit.length;
      }
    }
    return delta;
  }

  /**
   * Return the current delta caused by edits that will be applied before the
   * given [offset]. In other words, if all of the edits that have so far been
   * added were to be applied, then the text at the given `offset` before the
   * applied edits will be at `offset + _deltaToOffset(offset)` after the edits.
   */
  int _deltaToOffset(int offset) {
    int delta = 0;
    for (SourceEdit edit in fileEdit.edits) {
      if (edit.offset <= offset) {
        delta += edit.replacement.length - edit.length;
      }
    }
    return delta;
  }
}

/**
 * A builder used to build a [LinkedEdit] region within an edit.
 */
class LinkedEditBuilderImpl implements LinkedEditBuilder {
  final EditBuilderImpl editBuilder;

  final List<LinkedEditSuggestion> suggestions = <LinkedEditSuggestion>[];

  LinkedEditBuilderImpl(this.editBuilder);

  @override
  void addSuggestion(LinkedEditSuggestionKind kind, String value) {
    suggestions.add(new LinkedEditSuggestion(value, kind));
  }

  @override
  void addSuggestions(LinkedEditSuggestionKind kind, Iterable<String> values) {
    values.forEach((value) => addSuggestion(kind, value));
  }

  @override
  void write(String string) {
    editBuilder.write(string);
  }

  @override
  void writeln([String string]) {
    editBuilder.writeln(string);
  }
}
