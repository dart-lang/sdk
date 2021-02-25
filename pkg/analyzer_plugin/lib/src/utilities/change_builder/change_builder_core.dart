// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';
import 'dart:math' as math;

import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/analysis/session.dart';
import 'package:analyzer/exception/exception.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:analyzer_plugin/src/utilities/change_builder/change_builder_dart.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_dart.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_workspace.dart';

/// A builder used to build a [SourceChange].
class ChangeBuilderImpl implements ChangeBuilder {
  /// The workspace in which the change builder should operate, or `null` if no
  /// Dart files will be changed.
  final ChangeWorkspace workspace;

  /// The end-of-line marker used in the file being edited, or `null` if the
  /// default marker should be used.
  final String eol;

  /// A table mapping group ids to the associated linked edit groups.
  final Map<String, LinkedEditGroup> _linkedEditGroups =
      <String, LinkedEditGroup>{};

  /// The source change selection or `null` if none.
  Position _selection;

  /// The range of the selection for the change being built, or `null` if there
  /// is no selection.
  SourceRange _selectionRange;

  /// The set of [Position]s that belong to the current [EditBuilderImpl] and
  /// should not be updated in result of inserting this builder.
  final Set<Position> _lockedPositions = HashSet<Position>.identity();

  /// A map of absolute normalized path to generic file edit builders.
  final Map<String, FileEditBuilderImpl> _genericFileEditBuilders = {};

  /// A map of absolute normalized path to Dart file edit builders.
  final Map<String, DartFileEditBuilderImpl> _dartFileEditBuilders = {};

  /// Initialize a newly created change builder. If the builder will be used to
  /// create changes for Dart files, then either a [session] or a [workspace]
  /// must be provided (but not both).
  ChangeBuilderImpl(
      {AnalysisSession session, ChangeWorkspace workspace, this.eol})
      : assert(session == null || workspace == null),
        workspace = workspace ?? _SingleSessionWorkspace(session);

  @override
  SourceRange get selectionRange => _selectionRange;

  @override
  SourceChange get sourceChange {
    var change = SourceChange('');
    for (var builder in _genericFileEditBuilders.values) {
      if (builder.hasEdits) {
        change.addFileEdit(builder.fileEdit);
        builder.finalize();
      }
    }
    for (var builder in _dartFileEditBuilders.values) {
      if (builder.hasEdits) {
        change.addFileEdit(builder.fileEdit);
        builder.finalize();
      }
    }
    _linkedEditGroups.forEach((String name, LinkedEditGroup group) {
      change.addLinkedEditGroup(group);
    });
    if (_selection != null) {
      change.selection = _selection;
    }
    return change;
  }

  @override
  Future<void> addDartFileEdit(
      String path, void Function(DartFileEditBuilder builder) buildFileEdit,
      {ImportPrefixGenerator importPrefixGenerator}) async {
    if (_genericFileEditBuilders.containsKey(path)) {
      throw StateError("Can't create both a generic file edit and a dart file "
          'edit for the same file');
    }
    var builder = _dartFileEditBuilders[path];
    if (builder == null) {
      builder = await createDartFileEditBuilder(path);
      if (builder != null) {
        _dartFileEditBuilders[path] = builder;
      }
    }
    if (builder != null) {
      builder.importPrefixGenerator = importPrefixGenerator;
      buildFileEdit(builder);
    }
  }

  @Deprecated('Use either addDartFileEdit or addGenericFileEdit')
  @override
  Future<void> addFileEdit(
      String path, void Function(FileEditBuilder builder) buildFileEdit) async {
    return addGenericFileEdit(path, buildFileEdit);
  }

  @override
  Future<void> addGenericFileEdit(
      String path, void Function(FileEditBuilder builder) buildFileEdit) async {
    if (_dartFileEditBuilders.containsKey(path)) {
      throw StateError("Can't create both a generic file edit and a dart file "
          'edit for the same file');
    }
    var builder = _genericFileEditBuilders[path];
    if (builder == null) {
      builder = await createGenericFileEditBuilder(path);
      if (builder != null) {
        _genericFileEditBuilders[path] = builder;
      }
    }
    if (builder != null) {
      buildFileEdit(builder);
    }
  }

  @override
  ChangeBuilder copy() {
    var copy = ChangeBuilderImpl(workspace: workspace, eol: eol);
    for (var entry in _linkedEditGroups.entries) {
      copy._linkedEditGroups[entry.key] = _copyLinkedEditGroup(entry.value);
    }
    copy._selection = _copyPosition(_selection);
    copy._selectionRange = _selectionRange;
    copy._lockedPositions.addAll(_lockedPositions);
    for (var entry in _genericFileEditBuilders.entries) {
      copy._genericFileEditBuilders[entry.key] = entry.value.copyWith(copy);
    }
    //
    // The file edit builders for libraries (those whose [libraryChangeBuilder]
    // is `null`) are copied first so that the copies exist when we copy the
    // builders for parts and the structure can be preserved.
    //
    var editBuilderMap = <DartFileEditBuilderImpl, DartFileEditBuilderImpl>{};
    for (var entry in _dartFileEditBuilders.entries) {
      var oldBuilder = entry.value;
      if (oldBuilder.libraryChangeBuilder == null) {
        var newBuilder = oldBuilder.copyWith(copy);
        copy._dartFileEditBuilders[entry.key] = newBuilder;
        editBuilderMap[oldBuilder] = newBuilder;
      }
    }
    for (var entry in _dartFileEditBuilders.entries) {
      var oldBuilder = entry.value;
      if (oldBuilder.libraryChangeBuilder != null) {
        var newBuilder =
            oldBuilder.copyWith(copy, editBuilderMap: editBuilderMap);
        copy._dartFileEditBuilders[entry.key] = newBuilder;
      }
    }
    return copy;
  }

  /// Create and return a [DartFileEditBuilder] that can be used to build edits
  /// to the Dart file with the given [path].
  Future<DartFileEditBuilderImpl> createDartFileEditBuilder(String path) async {
    // TODO(brianwilkerson) Make this method private when
    //  `DartChangeBuilderImpl` is removed.
    if (workspace == null) {
      throw StateError("Can't create a DartFileEditBuilder without providing "
          'either a session or a workspace');
    }
    if (!workspace.containsFile(path)) {
      return null;
    }

    var session = workspace.getSession(path);
    var result = await session.getResolvedUnit(path);
    var state = result?.state ?? ResultState.INVALID_FILE_TYPE;
    if (state == ResultState.INVALID_FILE_TYPE) {
      throw AnalysisException('Cannot analyze "$path"');
    }
    var timeStamp = state == ResultState.VALID ? 0 : -1;

    var declaredUnit = result.unit.declaredElement;
    var libraryUnit = declaredUnit.library.definingCompilationUnit;

    DartFileEditBuilderImpl libraryEditBuilder;
    if (libraryUnit != declaredUnit) {
      // If the receiver is a part file builder, then proactively cache the
      // library file builder so that imports can be finalized synchronously.
      await addDartFileEdit(libraryUnit.source.fullName, (builder) {
        libraryEditBuilder = builder as DartFileEditBuilderImpl;
      });
    }

    return DartFileEditBuilderImpl(this, result, timeStamp, libraryEditBuilder);
  }

  /// Create and return a [FileEditBuilder] that can be used to build edits to
  /// the file with the given [path].
  Future<FileEditBuilderImpl> createGenericFileEditBuilder(String path) async {
    // TODO(brianwilkerson) Make this method private when
    //  `DartChangeBuilderImpl` is removed.
    return FileEditBuilderImpl(this, path, 0);
  }

  /// Return the linked edit group with the given [groupName], creating it if it
  /// did not already exist.
  LinkedEditGroup getLinkedEditGroup(String groupName) {
    var group = _linkedEditGroups[groupName];
    if (group == null) {
      group = LinkedEditGroup.empty();
      _linkedEditGroups[groupName] = group;
    }
    return group;
  }

  @override
  void setSelection(Position position) {
    _selection = position;
  }

  /// Return a copy of the linked edit [group].
  LinkedEditGroup _copyLinkedEditGroup(LinkedEditGroup group) {
    return LinkedEditGroup(group.positions.map(_copyPosition).toList(),
        group.length, group.suggestions.toList());
  }

  /// Return a copy of the [position].
  Position _copyPosition(Position position) {
    return position == null ? null : Position(position.file, position.offset);
  }

  void _setSelectionRange(SourceRange range) {
    _selectionRange = range;
  }

  /// Update the offsets of any positions that occur at or after the given
  /// [offset] such that the positions are offset by the given [delta].
  /// Positions occur in linked edit groups and as the post-change selection.
  void _updatePositions(int offset, int delta) {
    void _updatePosition(Position position) {
      if (position.offset >= offset && !_lockedPositions.contains(position)) {
        position.offset = position.offset + delta;
      }
    }

    for (var group in _linkedEditGroups.values) {
      for (var position in group.positions) {
        _updatePosition(position);
      }
    }
    if (_selection != null) {
      _updatePosition(_selection);
    }
  }
}

/// A builder used to build a [SourceEdit] as part of a [SourceFileEdit].
class EditBuilderImpl implements EditBuilder {
  /// The builder being used to create the source file edit of which the source
  /// edit will be a part.
  final FileEditBuilderImpl fileEditBuilder;

  /// The offset of the region being replaced.
  final int offset;

  /// The length of the region being replaced.
  final int length;

  /// The range of the selection for the change being built, or `null` if the
  /// selection is not inside the change being built.
  SourceRange _selectionRange;

  /// The end-of-line marker used in the file being edited, or `null` if the
  /// default marker should be used.
  String _eol;

  /// The buffer in which the content of the edit is being composed.
  final StringBuffer _buffer = StringBuffer();

  /// Initialize a newly created builder to build a source edit.
  EditBuilderImpl(this.fileEditBuilder, this.offset, this.length) {
    _eol = fileEditBuilder.changeBuilder.eol;
  }

  /// Create and return an edit representing the replacement of a region of the
  /// file with the accumulated text.
  SourceEdit get sourceEdit => SourceEdit(offset, length, _buffer.toString());

  @override
  void addLinkedEdit(String groupName,
      void Function(LinkedEditBuilder builder) buildLinkedEdit) {
    var builder = createLinkedEditBuilder();
    var start = offset + _buffer.length;
    try {
      buildLinkedEdit(builder);
    } finally {
      var end = offset + _buffer.length;
      var length = end - start;
      if (length != 0) {
        var position = Position(fileEditBuilder.fileEdit.file, start);
        fileEditBuilder.changeBuilder._lockedPositions.add(position);
        var group = fileEditBuilder.changeBuilder.getLinkedEditGroup(groupName);
        group.addPosition(position, length);
        for (var suggestion in builder.suggestions) {
          group.addSuggestion(suggestion);
        }
      }
    }
  }

  @override
  void addSimpleLinkedEdit(String groupName, String text,
      {LinkedEditSuggestionKind kind, List<String> suggestions}) {
    addLinkedEdit(groupName, (LinkedEditBuilder builder) {
      builder.write(text);
      if (kind != null && suggestions != null) {
        for (var suggestion in suggestions) {
          builder.addSuggestion(kind, suggestion);
        }
      } else if (kind != null || suggestions != null) {
        throw ArgumentError(
            'Either both kind and suggestions must be provided or neither.');
      }
    });
  }

  LinkedEditBuilderImpl createLinkedEditBuilder() {
    return LinkedEditBuilderImpl(this);
  }

  @override
  void selectAll(void Function() writer) {
    var rangeOffset = _buffer.length;
    writer();
    var rangeLength = _buffer.length - rangeOffset;
    _selectionRange = SourceRange(offset + rangeOffset, rangeLength);
  }

  @override
  void selectHere() {
    _selectionRange = SourceRange(offset + _buffer.length, 0);
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

/// A builder used to build a [SourceFileEdit] within a [SourceChange].
class FileEditBuilderImpl implements FileEditBuilder {
  /// The builder being used to create the source change of which the source
  /// file edit will be a part.
  final ChangeBuilderImpl changeBuilder;

  /// The source file edit that is being built.
  final SourceFileEdit fileEdit;

  /// Initialize a newly created builder to build a source file edit within the
  /// change being built by the given [changeBuilder]. The file being edited has
  /// the given absolute [path] and [timeStamp].
  FileEditBuilderImpl(this.changeBuilder, String path, int timeStamp)
      : fileEdit = SourceFileEdit(path, timeStamp);

  /// Return `true` if this builder has edits to be applied.
  bool get hasEdits => fileEdit.edits.isNotEmpty;

  @override
  void addDeletion(SourceRange range) {
    if (range.length > 0) {
      var builder = createEditBuilder(range.offset, range.length);
      _addEditBuilder(builder);
    }
  }

  @override
  void addInsertion(int offset, void Function(EditBuilder builder) buildEdit) {
    var builder = createEditBuilder(offset, 0);
    try {
      buildEdit(builder);
    } finally {
      _addEditBuilder(builder);
    }
  }

  @override
  void addLinkedPosition(SourceRange range, String groupName) {
    var group = changeBuilder.getLinkedEditGroup(groupName);
    var position =
        Position(fileEdit.file, range.offset + _deltaToOffset(range.offset));
    group.addPosition(position, range.length);
  }

  @override
  void addReplacement(
      SourceRange range, void Function(EditBuilder builder) buildEdit) {
    var builder = createEditBuilder(range.offset, range.length);
    try {
      buildEdit(builder);
    } finally {
      _addEditBuilder(builder);
    }
  }

  @override
  void addSimpleInsertion(int offset, String text) {
    var builder = createEditBuilder(offset, 0);
    try {
      builder.write(text);
    } finally {
      _addEditBuilder(builder);
    }
  }

  @override
  void addSimpleReplacement(SourceRange range, String text) {
    var builder = createEditBuilder(range.offset, range.length);
    try {
      builder.write(text);
    } finally {
      _addEditBuilder(builder);
    }
  }

  FileEditBuilderImpl copyWith(ChangeBuilderImpl changeBuilder) {
    var copy =
        FileEditBuilderImpl(changeBuilder, fileEdit.file, fileEdit.fileStamp);
    copy.fileEdit.edits.addAll(fileEdit.edits);
    return copy;
  }

  EditBuilderImpl createEditBuilder(int offset, int length) {
    return EditBuilderImpl(this, offset, length);
  }

  /// Finalize the source file edit that is being built.
  void finalize() {
    // Nothing to do.
  }

  /// Replace edits in the [range] with the given [edit].
  /// The [range] is relative to the original code.
  void replaceEdits(SourceRange range, SourceEdit edit) {
    fileEdit.edits.removeWhere((edit) {
      if (range.contains(edit.offset)) {
        if (!range.contains(edit.end)) {
          throw StateError('$edit is not completely in $range');
        }
        return true;
      } else if (range.contains(edit.end)) {
        throw StateError('$edit is not completely in $range');
      }
      return false;
    });

    _addEdit(edit);
  }

  /// Add the edit from the given [edit] to the edits associates with the
  /// current file.
  void _addEdit(SourceEdit edit) {
    fileEdit.add(edit);
    var delta = _editDelta(edit);
    changeBuilder._updatePositions(
        edit.offset + math.max<int>(0, delta), delta);
    changeBuilder._lockedPositions.clear();
  }

  /// Add the edit from the given [builder] to the edits associates with the
  /// current file.
  void _addEditBuilder(EditBuilderImpl builder) {
    var edit = builder.sourceEdit;
    _addEdit(edit);
    _captureSelection(builder, edit);
  }

  /// Capture the selection offset if one was set.
  void _captureSelection(EditBuilderImpl builder, SourceEdit edit) {
    var range = builder._selectionRange;
    if (range != null) {
      var position = Position(fileEdit.file, range.offset + _deltaToEdit(edit));
      changeBuilder.setSelection(position);
      changeBuilder._setSelectionRange(range);
    }
  }

  /// Return the current delta caused by edits that will be applied before the
  /// [targetEdit]. In other words, if all of the edits that occur before the
  /// target edit were to be applied, then the text at the offset of the target
  /// edit before the applied edits will be at `offset + _deltaToOffset(offset)`
  /// after the edits.
  int _deltaToEdit(SourceEdit targetEdit) {
    var delta = 0;
    for (var edit in fileEdit.edits) {
      if (edit.offset < targetEdit.offset) {
        delta += _editDelta(edit);
      }
    }
    return delta;
  }

  /// Return the current delta caused by edits that will be applied before the
  /// given [offset]. In other words, if all of the edits that have so far been
  /// added were to be applied, then the text at the given `offset` before the
  /// applied edits will be at `offset + _deltaToOffset(offset)` after the
  /// edits.
  int _deltaToOffset(int offset) {
    var delta = 0;
    for (var edit in fileEdit.edits) {
      if (edit.offset <= offset) {
        delta += _editDelta(edit);
      }
    }
    return delta;
  }

  /// Return the delta introduced by the given `edit`.
  int _editDelta(SourceEdit edit) => edit.replacement.length - edit.length;
}

/// A builder used to build a [LinkedEdit] region within an edit.
class LinkedEditBuilderImpl implements LinkedEditBuilder {
  final EditBuilderImpl editBuilder;

  final List<LinkedEditSuggestion> suggestions = <LinkedEditSuggestion>[];

  LinkedEditBuilderImpl(this.editBuilder);

  @override
  void addSuggestion(LinkedEditSuggestionKind kind, String value) {
    suggestions.add(LinkedEditSuggestion(value, kind));
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

/// Workspace that wraps a single [AnalysisSession].
class _SingleSessionWorkspace extends ChangeWorkspace {
  final AnalysisSession session;

  _SingleSessionWorkspace(this.session);

  @override
  bool containsFile(String path) {
    var analysisContext = session.analysisContext;
    return analysisContext.contextRoot.isAnalyzed(path);
  }

  @override
  AnalysisSession getSession(String path) {
    if (containsFile(path)) {
      return session;
    }
    throw StateError('Not in a context root: $path');
  }
}
