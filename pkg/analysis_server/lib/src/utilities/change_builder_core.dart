// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analysis_server.src.utilities.change_builder_core;

import 'package:analysis_server/plugin/protocol/protocol.dart';
import 'package:analysis_server/src/provisional/edit/utilities/change_builder_core.dart';
import 'package:analyzer/src/generated/source.dart';

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
  void addFileEdit(Source source, int fileStamp,
      void buildFileEdit(FileEditBuilder builder)) {
    FileEditBuilderImpl builder = createFileEditBuilder(source, fileStamp);
    try {
      buildFileEdit(builder);
    } finally {
      _change.addFileEdit(builder.fileEdit);
    }
  }

  /**
   * Create and return a [FileEditBuilder] that can be used to build edits to
   * the given [source].
   */
  FileEditBuilderImpl createFileEditBuilder(Source source, int fileStamp) {
    return new FileEditBuilderImpl(this, source, fileStamp);
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

  LinkedEditBuilderImpl createLinkedEditBuilder() {
    return new LinkedEditBuilderImpl(this);
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
   * the given [timeStamp] and [timeStamp].
   */
  FileEditBuilderImpl(this.changeBuilder, Source source, int timeStamp)
      : fileEdit = new SourceFileEdit(source.fullName, timeStamp);

  @override
  void addInsertion(int offset, void buildEdit(EditBuilder builder)) {
    EditBuilderImpl builder = createEditBuilder(offset, 0);
    try {
      buildEdit(builder);
    } finally {
      fileEdit.add(builder.sourceEdit);
    }
  }

  @override
  void addLinkedPosition(int offset, int length, String groupName) {
    LinkedEditGroup group = changeBuilder.getLinkedEditGroup(groupName);
    Position position = new Position(fileEdit.file, offset);
    group.addPosition(position, length);
  }

  @override
  void addReplacement(
      int offset, int length, void buildEdit(EditBuilder builder)) {
    EditBuilderImpl builder = createEditBuilder(offset, length);
    try {
      buildEdit(builder);
    } finally {
      fileEdit.add(builder.sourceEdit);
    }
  }

  EditBuilderImpl createEditBuilder(int offset, int length) {
    return new EditBuilderImpl(this, offset, length);
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
