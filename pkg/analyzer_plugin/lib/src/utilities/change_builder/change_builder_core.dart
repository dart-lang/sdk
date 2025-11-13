// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:collection';
import 'dart:io';

import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/analysis/session.dart';
import 'package:analyzer/exception/exception.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/source/source_range.dart';
import 'package:analyzer/src/util/file_paths.dart' as file_paths;
import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:analyzer_plugin/src/utilities/change_builder/change_builder_dart.dart';
import 'package:analyzer_plugin/src/utilities/change_builder/change_builder_yaml.dart';
import 'package:analyzer_plugin/src/utilities/extensions/string_extension.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_dart.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_yaml.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_workspace.dart';
import 'package:yaml/yaml.dart';

/// A builder used to build a [SourceChange].
class ChangeBuilderImpl implements ChangeBuilder {
  /// The workspace in which the change builder should operate.
  final ChangeWorkspace workspace;

  /// A table mapping group ids to the associated linked edit groups.
  final Map<String, LinkedEditGroup> _linkedEditGroups =
      <String, LinkedEditGroup>{};

  /// The source change selection or `null` if none.
  Position? _selection;

  /// The range of the selection for the change being built, or `null` if there
  /// is no selection.
  SourceRange? _selectionRange;

  /// The default EOL to be used for new files and files that do not have EOLs.
  ///
  /// Existing files with EOL markers will always have the same EOL in inserted
  /// text.
  @override
  final String defaultEol;

  /// A description to be applied to the [SourceEdit]s being built.
  ///
  /// This is usually set temporarily to mark a whole set of fixes with a
  /// single description.
  String? currentChangeDescription;

  /// The set of [Position]s that belong to the current [EditBuilderImpl] and
  /// should not be updated in result of inserting this builder.
  final Set<Position> _lockedPositions = HashSet<Position>.identity();

  /// A map of absolute normalized path to generic file edit builders.
  final Map<String, FileEditBuilderImpl> _genericFileEditBuilders = {};

  /// A map of absolute normalized path to Dart file edit builders.
  final Map<String, DartFileEditBuilderImpl> _dartFileEditBuilders = {};

  /// A map of absolute normalized path to YAML file edit builders.
  final Map<String, YamlFileEditBuilderImpl> _yamlFileEditBuilders = {};

  /// The number of times that any of the file edit builders in this change have
  /// been modified.
  ///
  /// A file builder is considered to be modified when the list of edits is
  /// modified in any way, such as by adding a new edit to the list. For Dart
  /// file edit builders this includes changes to the list of libraries that
  /// will be imported by creating edits at a later point.
  ///
  /// This can be used, for example, to determine whether any edits were added
  /// by a given correction producer.
  int modificationCount = 0;

  /// The data used to revert any changes made since the last time [commit] was
  /// called.
  final _ChangeBuilderRevertData _revertData = _ChangeBuilderRevertData();

  /// Initializes a newly created change builder.
  ///
  /// If the builder will be used to create changes for Dart files, then either
  /// a [session] or a [workspace] must be provided (but not both).
  ChangeBuilderImpl({
    AnalysisSession? session,
    ChangeWorkspace? workspace,
    String? defaultEol,
  }) : assert(session == null || workspace == null),
       workspace = workspace ?? _SingleSessionWorkspace(session!),
       defaultEol = defaultEol ?? Platform.lineTerminator;

  /// Return `true` if this builder has edits to be applied.
  bool get hasEdits {
    return _dartFileEditBuilders.isNotEmpty ||
        _genericFileEditBuilders.isNotEmpty ||
        _yamlFileEditBuilders.isNotEmpty;
  }

  @override
  SourceRange? get selectionRange => _selectionRange;

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
    for (var builder in _yamlFileEditBuilders.values) {
      if (builder.hasEdits) {
        change.addFileEdit(builder.fileEdit);
        builder.finalize();
      }
    }
    _linkedEditGroups.forEach((String name, LinkedEditGroup group) {
      change.addLinkedEditGroup(group);
    });
    var selection = _selection;
    if (selection != null) {
      change.selection = selection;
      var selectionRange = _selectionRange;
      if (selectionRange != null) {
        change.selectionLength = selectionRange.length;
      }
    }
    return change;
  }

  @override
  Future<void> addDartFileEdit(
    String path,
    FutureOr<void> Function(DartFileEditBuilder builder) buildFileEdit, {
    bool createEditsForImports = true,
  }) async {
    assert(file_paths.isDart(workspace.resourceProvider.pathContext, path));
    if (_genericFileEditBuilders.containsKey(path)) {
      throw StateError(
        "Can't create both a generic file edit and a dart file "
        'edit for the same file',
      );
    }
    if (_yamlFileEditBuilders.containsKey(path)) {
      throw StateError(
        "Can't create both a yaml file edit and a dart file "
        'edit for the same file',
      );
    }
    var builder = _dartFileEditBuilders[path];
    if (builder == null) {
      builder = await _createDartFileEditBuilder(
        path,
        createEditsForImports: createEditsForImports,
      );
      if (builder != null) {
        // It's not currently supported to call this method twice concurrently
        // for the same file as two builder may be produced because of the above
        // `await` so detect this and throw to avoid losing edits.
        if (_dartFileEditBuilders.containsKey(path)) {
          throw StateError(
            "Can't add multiple edits concurrently for the same file",
          );
        }
        _dartFileEditBuilders[path] = builder;
        _revertData._addedDartFileEditBuilders.add(path);
      }
    }
    if (builder != null) {
      builder.currentChangeDescription = currentChangeDescription;
      await buildFileEdit(builder);
    }
  }

  @override
  Future<void> addGenericFileEdit(
    String path,
    void Function(FileEditBuilder builder) buildFileEdit,
  ) async {
    // Dart and YAML files should always use their specific builders because
    // otherwise we might throw below if multiple callers (such as fixes in
    // "dart fix") use different methods.
    // TODO(dantup): Add these asserts in when we can advertise this as a
    //  breaking change (for plugins that might be calling this method for
    //  dart files). Without them, server code could also accidentally do this
    //  and re-introduce https://github.com/dart-lang/sdk/issues/55092
    // assert(!file_paths.isDart(workspace.resourceProvider.pathContext, path),
    //     'Use addDartFileEdit for editing Dart files');
    // assert(!file_paths.isYaml(workspace.resourceProvider.pathContext, path),
    //     'Use addYamlFileEdit for editing YAML files');

    if (_dartFileEditBuilders.containsKey(path)) {
      throw StateError(
        "Can't create both a dart file edit and a generic file "
        'edit for the same file',
      );
    }
    if (_yamlFileEditBuilders.containsKey(path)) {
      throw StateError(
        "Can't create both a yaml file edit and a generic file "
        'edit for the same file',
      );
    }
    var builder = _genericFileEditBuilders[path];
    if (builder == null) {
      var eol = _getLineEnding(path);
      builder = FileEditBuilderImpl(this, path, 0, eol: eol);
      _genericFileEditBuilders[path] = builder;
      _revertData._addedGenericFileEditBuilders.add(path);
    }
    builder.currentChangeDescription = currentChangeDescription;
    buildFileEdit(builder);
  }

  @override
  Future<void> addYamlFileEdit(
    String path,
    void Function(YamlFileEditBuilder builder) buildFileEdit,
  ) async {
    assert(file_paths.isYaml(workspace.resourceProvider.pathContext, path));
    if (_dartFileEditBuilders.containsKey(path)) {
      throw StateError(
        "Can't create both a dart file edit and a yaml file "
        'edit for the same file',
      );
    }
    if (_genericFileEditBuilders.containsKey(path)) {
      throw StateError(
        "Can't create both a generic file edit and a yaml file "
        'edit for the same file',
      );
    }
    var builder = _yamlFileEditBuilders[path];
    if (builder == null) {
      String content;
      try {
        // TODO(dantup): Can this use FileContentCache?
        content = workspace.resourceProvider.getFile(path).readAsStringSync();
      } catch (_) {
        content = '';
      }
      var eol = content.endOfLine ?? defaultEol;

      builder = YamlFileEditBuilderImpl(
        this,
        path,
        loadYamlDocument(content, recover: true),
        0,
        eol: eol,
      );
      _yamlFileEditBuilders[path] = builder;
      _revertData._addedYamlFileEditBuilders.add(path);
    }
    builder.currentChangeDescription = currentChangeDescription;
    buildFileEdit(builder);
  }

  /// Commit the changes that have been made up to this point.
  void commit() {
    // Capture the current values of simple values.
    _revertData._selection = _selection;
    _revertData._selectionRange = _selectionRange;
    _revertData._currentChangeDescription = currentChangeDescription;
    _revertData._modificationCount = modificationCount;

    // Discard any information about changes to maps.
    _revertData._addedLinkedEditGroups.clear();
    _revertData._addedLinkedEditGroupPositions.clear();
    _revertData._addedLinkedEditGroupSuggestions.clear();

    _revertData._addedGenericFileEditBuilders.clear();
    _revertData._addedDartFileEditBuilders.clear();
    _revertData._addedYamlFileEditBuilders.clear();

    // Commit the changes in any pre-existing builders.
    for (var builder in _genericFileEditBuilders.values) {
      builder.commit();
    }
    for (var builder in _dartFileEditBuilders.values) {
      builder.commit();
    }
    for (var builder in _yamlFileEditBuilders.values) {
      builder.commit();
    }
  }

  /// Return the linked edit group with the given [groupName], creating it if it
  /// did not already exist.
  LinkedEditGroup getLinkedEditGroup(String groupName) {
    var group = _linkedEditGroups[groupName];
    if (group == null) {
      group = LinkedEditGroup.empty();
      _linkedEditGroups[groupName] = group;
      _revertData._addedLinkedEditGroups[groupName] = group;
    }
    return group;
  }

  @override
  bool hasEditsFor(String path) {
    return _dartFileEditBuilders.containsKey(path) ||
        _genericFileEditBuilders.containsKey(path) ||
        _yamlFileEditBuilders.containsKey(path);
  }

  /// Revert any changes made since the last time [commit] was called.
  void revert() {
    // Set simple values back to their previous values.
    _selection = _revertData._selection;
    _selectionRange = _revertData._selectionRange;
    currentChangeDescription = _revertData._currentChangeDescription;
    modificationCount = _revertData._modificationCount;

    // Remove any linked edit groups that have been added.
    for (var entry in _revertData._addedLinkedEditGroups.entries) {
      _linkedEditGroups.remove(entry.key);
    }
    // Remove any positions or suggestions that were added to pre-existing
    // link edit groups.
    //
    // Note that this code assumes that the lengths of the groups have not been
    // changed. It's invalid to change the length, but there's no code to
    // validate that it hasn't been changed.
    for (var entry in _revertData._addedLinkedEditGroupPositions.entries) {
      for (var position in entry.value) {
        entry.key.positions.remove(position);
      }
    }
    for (var entry in _revertData._addedLinkedEditGroupSuggestions.entries) {
      for (var suggestion in entry.value) {
        entry.key.suggestions.remove(suggestion);
      }
    }
    // Discard any data about linked edit groups because it's no longer needed.
    _revertData._addedLinkedEditGroups.clear();
    _revertData._addedLinkedEditGroupPositions.clear();
    _revertData._addedLinkedEditGroupSuggestions.clear();

    // Remove any file edit builders that have been added.
    for (var path in _revertData._addedGenericFileEditBuilders) {
      _genericFileEditBuilders.remove(path);
    }
    for (var path in _revertData._addedDartFileEditBuilders) {
      _dartFileEditBuilders.remove(path);
    }
    for (var path in _revertData._addedYamlFileEditBuilders) {
      _yamlFileEditBuilders.remove(path);
    }
    // Revert the data changes in any pre-existing builders.
    for (var builder in _genericFileEditBuilders.values) {
      builder.revert();
    }
    for (var builder in _dartFileEditBuilders.values) {
      builder.revert();
    }
    for (var builder in _yamlFileEditBuilders.values) {
      builder.revert();
    }
    // Discard any data about file builders because it's no longer needed.
    _revertData._addedGenericFileEditBuilders.clear();
    _revertData._addedDartFileEditBuilders.clear();
    _revertData._addedYamlFileEditBuilders.clear();
  }

  @override
  void setSelection(Position position) {
    _selection = position;
    // Clear any existing selection range, since it is no long valid.
    _selectionRange = null;
  }

  /// Create and return a [DartFileEditBuilder] that can be used to build edits
  /// to the Dart file with the given [path].
  Future<DartFileEditBuilderImpl?> _createDartFileEditBuilder(
    String? path, {
    bool createEditsForImports = true,
  }) async {
    if (path == null || !workspace.containsFile(path)) {
      return null;
    }

    var session = workspace.getSession(path);
    var libraryResult = await session?.getResolvedLibraryContaining(path);
    if (libraryResult is! ResolvedLibraryResult) {
      throw AnalysisException('Cannot analyze "$path"');
    }
    var unitResult = libraryResult.unitWithPath(path);
    if (unitResult == null) {
      // Should not ever happen, if it does, the above method for the library is
      // broken.
      throw AnalysisException('Cannot analyze "$path"');
    }
    var timeStamp = unitResult.exists ? 0 : -1;

    var declaredFragment = unitResult.unit.declaredFragment;
    var firstFragment = declaredFragment?.element.firstFragment;

    DartFileEditBuilderImpl? libraryEditBuilder;
    if (firstFragment != null && firstFragment != declaredFragment) {
      // If the receiver is a part file builder, then proactively cache the
      // library file builder so that imports can be finalized synchronously.
      await addDartFileEdit(
        firstFragment.source.fullName,
        (builder) {
          libraryEditBuilder = builder as DartFileEditBuilderImpl;
        },
        createEditsForImports: createEditsForImports,
      );
    }

    var eol = unitResult.content.endOfLine ?? defaultEol;
    return DartFileEditBuilderImpl(
      this,
      libraryResult,
      unitResult,
      timeStamp,
      libraryEditBuilder,
      createEditsForImports: createEditsForImports,
      eol: eol,
    );
  }

  /// Reads the EOL used in [filePath], defaulting to [Platform.lineTerminator] if
  /// there was no line ending or the file cannot be read.
  String _getLineEnding(String filePath) {
    String? eol;
    try {
      // TODO(dantup): Can this use FileContentCache?
      var content = workspace.resourceProvider
          .getFile(filePath)
          .readAsStringSync();
      eol = content.endOfLine;
    } catch (_) {}
    return eol ?? defaultEol;
  }

  void _setSelectionRange(SourceRange range) {
    _selectionRange = range;
    // If we previously had a selection, update it to this new offset.
    var selection = _selection;
    if (selection != null) {
      _selection = Position(selection.file, range.offset);
    }
  }

  /// Update the offsets of any positions that occur at or after the given
  /// [offset] such that the positions are offset by the given [delta].
  /// Positions occur in linked edit groups and as the post-change selection.
  void _updatePositions(int offset, int delta) {
    void updatePosition(Position position) {
      if (position.offset >= offset && !_lockedPositions.contains(position)) {
        position.offset = position.offset + delta;
      }
    }

    for (var group in _linkedEditGroups.values) {
      for (var position in group.positions) {
        updatePosition(position);
      }
    }
    var selection = _selection;
    if (selection != null) {
      updatePosition(selection);
    }
    var selectionRange = _selectionRange;
    if (selectionRange != null) {
      if (selectionRange.offset >= offset) {
        _selectionRange = SourceRange(
          selectionRange.offset + delta,
          selectionRange.length,
        );
      }
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

  /// A user-friendly description of this change.
  final String? description;

  /// The range of the selection for the change being built, or `null` if the
  /// selection is not inside the change being built.
  SourceRange? _selectionRange;

  /// The buffer in which the content of the edit is being composed.
  final StringBuffer _buffer = StringBuffer();

  /// Whether the builder is currently writing an edit group.
  ///
  /// This flag is set internally when writing an edit group to prevent
  /// nested/overlapping edit groups from being produced.
  bool _isWritingEditGroup = false;

  /// Initialize a newly created builder to build a source edit.
  EditBuilderImpl(
    this.fileEditBuilder,
    this.offset,
    this.length, {
    this.description,
  });

  /// The end-of-line marker used in the file being edited.
  String get eol => fileEditBuilder.eol;

  /// Create and return an edit representing the replacement of a region of the
  /// file with the accumulated text.
  SourceEdit get sourceEdit =>
      SourceEdit(offset, length, _buffer.toString(), description: description);

  @override
  void addLinkedEdit(
    String groupName,
    void Function(LinkedEditBuilder builder) buildLinkedEdit,
  ) {
    var builder = createLinkedEditBuilder();
    var start = offset + _buffer.length;
    // If we're already writing an edit group we must not produce others nested
    // inside, so just call the callback without capturing the group.
    if (_isWritingEditGroup) {
      return buildLinkedEdit(builder);
    }
    try {
      _isWritingEditGroup = true;
      buildLinkedEdit(builder);
    } finally {
      _isWritingEditGroup = false;
      var end = offset + _buffer.length;
      var length = end - start;
      if (length != 0) {
        var position = Position(fileEditBuilder.fileEdit.file, start);
        fileEditBuilder.changeBuilder._lockedPositions.add(position);
        var group = fileEditBuilder.changeBuilder.getLinkedEditGroup(groupName);
        group.addPosition(position, length);
        var revertData = fileEditBuilder.changeBuilder._revertData;
        revertData._addedLinkedEditGroupPositions
            .putIfAbsent(group, () => [])
            .add(position);
        for (var suggestion in builder.suggestions) {
          group.addSuggestion(suggestion);
          revertData._addedLinkedEditGroupSuggestions
              .putIfAbsent(group, () => [])
              .add(suggestion);
        }
      }
    }
  }

  @override
  void addSimpleLinkedEdit(
    String groupName,
    String text, {
    LinkedEditSuggestionKind? kind,
    List<String>? suggestions,
  }) {
    addLinkedEdit(groupName, (LinkedEditBuilder builder) {
      builder.write(text);
      if (kind != null && suggestions != null) {
        for (var suggestion in suggestions) {
          builder.addSuggestion(kind, suggestion);
        }
      } else if (kind != null || suggestions != null) {
        throw ArgumentError(
          'Either both kind and suggestions must be provided or neither.',
        );
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
  void writeln([String? string]) {
    if (string != null) {
      _buffer.write(string);
    }
    _buffer.write(eol);
  }
}

/// A builder used to build a [SourceFileEdit] within a [SourceChange].
class FileEditBuilderImpl implements FileEditBuilder {
  /// The builder being used to create the source change of which the source
  /// file edit will be a part.
  final ChangeBuilderImpl changeBuilder;

  /// The source file edit that is being built.
  final SourceFileEdit fileEdit;

  /// The end of line marker being used by this file.
  @override
  final String eol;

  /// A description to be applied to the changes being built.
  ///
  /// This is usually set temporarily to mark a whole set of fixes with a
  /// single description.
  String? currentChangeDescription;

  final _FileEditBuilderRevertData _revertData = _FileEditBuilderRevertData();

  /// Initialize a newly created builder to build a source file edit within the
  /// change being built by the given [changeBuilder]. The file being edited has
  /// the given absolute [path] and [timeStamp].
  FileEditBuilderImpl(
    this.changeBuilder,
    String path,
    int timeStamp, {
    required this.eol,
  }) : fileEdit = SourceFileEdit(path, timeStamp);

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
  void addInsertion(
    int offset,
    void Function(EditBuilder builder) buildEdit, {
    bool insertBeforeExisting = false,
  }) {
    var builder = createEditBuilder(offset, 0);
    try {
      buildEdit(builder);
    } finally {
      _addEditBuilder(builder, insertBeforeExisting: insertBeforeExisting);
    }
  }

  @override
  void addLinkedPosition(SourceRange range, String groupName) {
    var group = changeBuilder.getLinkedEditGroup(groupName);
    var position = Position(
      fileEdit.file,
      range.offset + _deltaToOffset(range.offset),
    );
    group.addPosition(position, range.length);
    var revertData = changeBuilder._revertData;
    revertData._addedLinkedEditGroupPositions
        .putIfAbsent(group, () => [])
        .add(position);
  }

  @override
  void addReplacement(
    SourceRange range,
    void Function(EditBuilder builder) buildEdit,
  ) {
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

  /// Commit the changes that have been made up to this point.
  void commit() {
    _revertData._currentChangeDescription = currentChangeDescription;

    _revertData._addedEdits.clear();
  }

  EditBuilderImpl createEditBuilder(int offset, int length) {
    return EditBuilderImpl(
      this,
      offset,
      length,
      description: currentChangeDescription,
    );
  }

  /// Finalize the source file edit that is being built.
  void finalize() {
    // Nothing to do.
  }

  /// Replace edits in the [range] with the given [edit].
  ///
  /// The [range] is relative to the original code.
  void replaceEdits(SourceRange range, SourceEdit edit) {
    // This does not record the edits that are being replaced, so we cannot
    // correctly revert the current transaction.
    //
    // I think this is ok because this method is only called from
    // `DartFileEditBuilder.format`, which isn't called from the bulk fix
    // processor. But we will need to fix this if we start using it in a context
    // where we do want to be able to revert such changes.
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

  /// Revert any changes made since the last time [commit] was called.
  void revert() {
    currentChangeDescription = _revertData._currentChangeDescription;

    fileEdit.edits.removeWhere(_revertData._addedEdits.contains);
  }

  /// Add the edit from the given [edit] to the edits associated with the
  /// current file.
  void _addEdit(SourceEdit edit, {bool insertBeforeExisting = false}) {
    fileEdit.add(edit, insertBeforeExisting: insertBeforeExisting);
    _revertData._addedEdits.add(edit);
    var delta = _editDelta(edit);
    changeBuilder._updatePositions(edit.offset, delta);
    changeBuilder._lockedPositions.clear();
    changeBuilder.modificationCount++;
  }

  /// Add the edit from the given [builder] to the edits associated with the
  /// current file.
  ///
  /// If [insertBeforeExisting] is `true`, inserts made at the same offset as
  /// other edits will be inserted such that they appear before them in the
  /// resulting document.
  void _addEditBuilder(
    EditBuilderImpl builder, {
    bool insertBeforeExisting = false,
  }) {
    var edit = builder.sourceEdit;
    _addEdit(edit, insertBeforeExisting: insertBeforeExisting);
    _captureSelection(builder, edit);
  }

  /// Capture the selection offset if one was set.
  void _captureSelection(EditBuilderImpl builder, SourceEdit edit) {
    var range = builder._selectionRange;
    if (range != null) {
      var position = Position(fileEdit.file, range.offset + _deltaToEdit(edit));
      var newRange = SourceRange(position.offset, range.length);
      changeBuilder.setSelection(position);
      changeBuilder._setSelectionRange(newRange);
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
    for (var value in values) {
      addSuggestion(kind, value);
    }
  }

  @override
  void write(String string) {
    editBuilder.write(string);
  }

  @override
  void writeln([String? string]) {
    editBuilder.writeln(string);
  }
}

/// The data used to revert any changes made to a [ChangeBuilder] since the last
/// time [commit] was called.
class _ChangeBuilderRevertData {
  /// The last committed value of the change builder's `_selection`.
  Position? _selection;

  /// The last committed value of the change builder's `_selectionRange`.
  SourceRange? _selectionRange;

  /// The last committed value of the change builder's
  /// `currentChangeDescription`.
  String? _currentChangeDescription;

  /// The last committed value of the change builder's `modificationCount`.
  int _modificationCount = 0;

  /// A map from the names of linked edit groups to the linked edit groups that
  /// have been added since the last commit.
  final Map<String, LinkedEditGroup> _addedLinkedEditGroups = {};

  /// A map from pre-existing linked edit groups to the positions that were
  /// added to the group.
  final Map<LinkedEditGroup, List<Position>> _addedLinkedEditGroupPositions =
      {};

  /// A map from pre-existing linked edit groups to the suggestions that were
  /// added to the group.
  final Map<LinkedEditGroup, List<LinkedEditSuggestion>>
  _addedLinkedEditGroupSuggestions = {};

  /// A map of absolute normalized path to generic file edit builders that have
  /// been added since the last commit.
  final Set<String> _addedGenericFileEditBuilders = {};

  /// A map of absolute normalized path to Dart file edit builders that have
  /// been added since the last commit.
  final Set<String> _addedDartFileEditBuilders = {};

  /// A map of absolute normalized path to YAML file edit builders that have
  /// been added since the last commit.
  final Set<String> _addedYamlFileEditBuilders = {};
}

/// The data used to revert any changes made to a [FileEditBuilder] since the
/// last time [commit] was called.
class _FileEditBuilderRevertData {
  /// The last committed value of the change builder's
  /// `currentChangeDescription`.
  String? _currentChangeDescription;

  // This needs to be an identify set because it is possible for the data-driven
  // fixes support to produce the same set of (multiple) edits multiple times.
  // More investigation is required to determine whether that behavior is a bug
  // in the data-driven fixes support or whether this is (or can be) caused by
  // the data being used by it. If it is a bug that can be fixed, then we can
  // safely use a non-identiy set, though leaving it won't cause any problems.
  //
  // In either case, when that happens, the second set of edits will usually
  // conflict with the previous set of edits. Because the edits are the same,
  // they will return `true` from `==`, causing some of the edits to not be
  // recorded in this set. When the conflict is detected and an attempt is made
  // to revert the changes, only the one edit in this set will be removed from
  // the builder's list, making it impossible to correctly revert the change.
  //
  // The other option would be to make this a list, but doing so would decrease
  // the performance of `revert`.
  final Set<SourceEdit> _addedEdits = HashSet.identity();
}

/// Workspace that wraps a single [AnalysisSession].
class _SingleSessionWorkspace extends ChangeWorkspace {
  final AnalysisSession session;

  _SingleSessionWorkspace(this.session);

  @override
  ResourceProvider get resourceProvider => session.resourceProvider;

  @override
  bool containsFile(String path) {
    var analysisContext = session.analysisContext;
    return analysisContext.contextRoot.isAnalyzed(path);
  }

  @override
  AnalysisSession? getSession(String path) {
    if (containsFile(path)) {
      return session;
    }
    throw StateError('Not in a context root: $path');
  }
}
