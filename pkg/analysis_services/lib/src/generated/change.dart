// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This code was auto-generated, is not intended to be edited, and is subject to
// significant change. Please see the README file for more information.

library services.change;

import 'dart:collection';
import 'package:analyzer/src/generated/java_io.dart' show JavaFile;
import 'package:analyzer/src/generated/source.dart';

/**
 * Describes some abstract operation to perform.
 *
 * [Change] implementations in "services" plugin cannot perform operation themselves, they are
 * just descriptions of operation. Actual operation should be performed by client.
 */
abstract class Change {
  final String name;

  Change(this.name);
}

/**
 * Composition of several [Change]s.
 */
class CompositeChange extends Change {
  List<Change> _children = [];

  CompositeChange(String name, [Iterable<Change> changes]) : super(name) {
    if (changes != null) {
      _children.addAll(changes);
    }
  }

  /**
   * Adds given [Change]s.
   */
  void add(List<Change> changes) {
    _children.addAll(changes);
  }

  /**
   * @return the children [Change]s.
   */
  List<Change> get children => _children;
}

/**
 * [Change] to create new file.
 */
class CreateFileChange extends Change {
  final JavaFile file;

  final String content;

  CreateFileChange(String name, this.file, this.content) : super(name);
}

/**
 * Describes a text edit. Edits are executed by applying them to a [Source].
 */
class Edit {
  /**
   * The offset at which to apply the edit.
   */
  final int offset;

  /**
   * The length of the text interval to replace.
   */
  final int length;

  /**
   * The replacement text.
   */
  final String replacement;

  /**
   * Create an edit.
   *
   * @param offset the offset at which to apply the edit
   * @param length the length of the text interval replace
   * @param replacement the replacement text
   */
  Edit(this.offset, this.length, this.replacement);

  /**
   * Create an edit.
   *
   * @param range the [SourceRange] to replace
   * @param replacement the replacement text
   */
  Edit.range(SourceRange range, String replacement) : this(range.offset, range.length, replacement);

  @override
  String toString() => "${(offset < 0 ? "(" : "X(")}offset: ${offset}, length ${length}, replacement :>${replacement}<:)";
}

/**
 * Composition of two [CompositeChange]s. First change should be displayed in preview, but
 * merged into second one before execution.
 */
class MergeCompositeChange extends Change {
  final CompositeChange previewChange;

  final CompositeChange executeChange;

  MergeCompositeChange(String name, this.previewChange, this.executeChange) : super(name);
}

/**
 * [Change] to apply to single [Source].
 */
class SourceChange extends Change {
  final Source source;

  final List<Edit> edits = [];

  Map<String, List<Edit>> _editGroups = new LinkedHashMap();

  /**
   * @param name the name of this change to display in UI
   * @param source the [Source] to change
   */
  SourceChange(String name, this.source) : super(name);

  /**
   * Adds the [Edit] to apply.
   */
  void addEdit(Edit edit, [String description = '']) {
    // add to all edits
    edits.add(edit);
    // add to group
    {
      List<Edit> group = _editGroups[description];
      if (group == null) {
        group = [];
        _editGroups[description] = group;
      }
      group.add(edit);
    }
  }

  /**
   * @return the [Edit]s grouped by their descriptions.
   */
  Map<String, List<Edit>> get editGroups => _editGroups;
}

/**
 * Manages multiple [SourceChange] objects.
 */
class SourceChangeManager {
  Map<Source, SourceChange> _changeMap = {};

  /**
   * @return the [SourceChange] to record modifications for given [Source].
   */
  SourceChange get(Source source) {
    SourceChange change = _changeMap[source];
    if (change == null) {
      change = new SourceChange(source.shortName, source);
      _changeMap[source] = change;
    }
    return change;
  }

  /**
   * @return all [SourceChange] in this manager.
   */
  List<SourceChange> get changes {
    Iterable<SourceChange> changes = _changeMap.values;
    return new List.from(changes);
  }
}