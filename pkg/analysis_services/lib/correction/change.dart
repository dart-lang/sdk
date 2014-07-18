// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This code was auto-generated, is not intended to be edited, and is subject to
// significant change. Please see the README file for more information.

library services.correction.change;

import 'package:analyzer/src/generated/source.dart';


/**
 * A description of a single change to one or more files. 
 */
class Change {
  /**
   * A textual description of the change to be applied. 
   */
  final String message;

  /**
   * A list of the [FileEdit]s used to effect the change. 
   */
  final List<FileEdit> edits = <FileEdit>[];

  /**
   * A list of the [LinkedPositionGroup]s in the change. 
   */
  final List<LinkedPositionGroup> linkedPositionGroups = <LinkedPositionGroup>[
      ];

  Change(this.message);

  /**
   * Adds the given [FileEdit].
   */
  void add(FileEdit edit) {
    edits.add(edit);
  }

  /**
   * Adds the given [LinkedPositionGroup].
   */
  void addLinkedPositionGroup(LinkedPositionGroup linkedPositionGroup) {
    linkedPositionGroups.add(linkedPositionGroup);
  }

  @override
  String toString() =>
      'Change(message=$message, edits=${edits.join(' ')}, '
          'linkedPositionGroups=${linkedPositionGroups.join(', ')})';
}


/**
 * A description of a single change to a single file. 
 */
class Edit {
  /**
   * The offset of the region to be modified. 
   */
  final int offset;

  /**
   * The length of the region to be modified.
   */
  final int length;

  /**
   * The text that is to replace the specified region in the original text. 
   */
  final String replacement;

  Edit(this.offset, this.length, this.replacement);

  Edit.range(SourceRange range, String replacement) : this(
      range.offset,
      range.length,
      replacement);

  /**
   * The offset of a character immediately after the region to be modified. 
   */
  int get end => offset + length;

  @override
  String toString() =>
      "Edit(offset=$offset, length=$length, replacement=:>$replacement<:)";
}


/**
 * A description of a set of changes to a single file. 
 */
class FileEdit {
  /**
   * The file to be modified.
   */
  final String file;

  /**
   * A list of the [Edit]s used to effect the change. 
   */
  final List<Edit> edits = <Edit>[];

  FileEdit(this.file);

  /**
   * Adds the given [Edit] to the list.
   */
  void add(Edit edit) {
    edits.add(edit);
  }

  @override
  String toString() => "FileEdit(file=$file, edits=${edits.join(' ')})";
}


/**
 * A group of linked [Position]s in multiple files that are simultaneously
 * modified - if one gets edited, all other positions in a group are edited the
 * same way. All linked positions in a group have the same content.
 */
class LinkedPositionGroup {
  final String id;
  final List<Position> positions = <Position>[];

  LinkedPositionGroup(this.id);

  void add(Position position) {
    if (positions.isNotEmpty && position.length != positions[0].length) {
      throw new ArgumentError(
          'All positions should have the same length. '
              'Was: ${positions[0].length}. New: ${position.length}');
    }
    positions.add(position);
  }

  @override
  String toString() => 'LinkedPositionGroup(id=$id, positions=$positions)';
}


/**
 * A position in a file.
 */
class Position {
  final String file;
  final int offset;
  final int length;

  Position(this.file, this.offset, this.length);

  int get hashCode {
    int hash = file.hashCode;
    hash = hash * 31 + offset;
    hash = hash * 31 + length;
    return hash;
  }

  bool operator ==(other) {
    if (other is Position) {
      return other.file == file &&
          other.offset == offset &&
          other.length == length;
    }
    return false;
  }

  @override
  String toString() => 'Position(file=$file, offset=$offset, length=$length)';
}
