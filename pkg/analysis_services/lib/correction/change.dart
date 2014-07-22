// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This code was auto-generated, is not intended to be edited, and is subject to
// significant change. Please see the README file for more information.

library services.correction.change;

import 'package:analysis_services/constants.dart';
import 'package:analysis_services/json.dart';


_fromJsonList(List target, List<Map<String, Object>> jsonList,
    decoder(Map<String, Object> json)) {
  target.addAll(jsonList.map(decoder));
}


/**
 * A description of a single change to one or more files. 
 */
class Change implements HasToJson {
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
  Map<String, Object> toJson() {
    return {
      MESSAGE: message,
      EDITS: objectToJson(edits),
      LINKED_POSITION_GROUPS: objectToJson(linkedPositionGroups)
    };
  }

  @override
  String toString() =>
      'Change(message=$message, edits=$edits, '
          'linkedPositionGroups=$linkedPositionGroups)';

  static Change fromJson(Map<String, Object> json) {
    String message = json[MESSAGE];
    Change change = new Change(message);
    _fromJsonList(change.edits, json[EDITS], FileEdit.fromJson);
    _fromJsonList(
        change.linkedPositionGroups,
        json[LINKED_POSITION_GROUPS],
        LinkedPositionGroup.fromJson);
    return change;
  }
}


/**
 * A description of a single change to a single file. 
 */
class Edit implements HasToJson {
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

  /**
   * The offset of a character immediately after the region to be modified. 
   */
  int get end => offset + length;

  bool operator ==(other) {
    if (other is Edit) {
      return other.offset == offset &&
          other.length == length &&
          other.replacement == replacement;
    }
    return false;
  }

  @override
  Map<String, Object> toJson() {
    return {
      OFFSET: offset,
      LENGTH: length,
      REPLACEMENT: replacement
    };
  }

  @override
  String toString() =>
      "Edit(offset=$offset, length=$length, replacement=:>$replacement<:)";

  static Edit fromJson(Map<String, Object> json) {
    int offset = json[OFFSET];
    int length = json[LENGTH];
    String replacement = json[REPLACEMENT];
    return new Edit(offset, length, replacement);
  }
}


/**
 * A description of a set of changes to a single file. 
 */
class FileEdit implements HasToJson {
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
  Map<String, Object> toJson() {
    return {
      FILE: file,
      EDITS: objectToJson(edits)
    };
  }

  @override
  String toString() => "FileEdit(file=$file, edits=$edits)";

  static FileEdit fromJson(Map<String, Object> json) {
    String file = json[FILE];
    FileEdit fileEdit = new FileEdit(file);
    _fromJsonList(fileEdit.edits, json[EDITS], Edit.fromJson);
    return fileEdit;
  }
}


/**
 * A group of linked [Position]s in multiple files that are simultaneously
 * modified - if one gets edited, all other positions in a group are edited the
 * same way. All linked positions in a group have the same content.
 */
class LinkedPositionGroup implements HasToJson {
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
  Map<String, Object> toJson() {
    return {
      ID: id,
      POSITIONS: objectToJson(positions)
    };
  }

  @override
  String toString() => 'LinkedPositionGroup(id=$id, positions=$positions)';

  static LinkedPositionGroup fromJson(Map<String, Object> json) {
    String id = json[ID];
    LinkedPositionGroup group = new LinkedPositionGroup(id);
    _fromJsonList(group.positions, json[POSITIONS], Position.fromJson);
    return group;
  }
}


/**
 * A position in a file.
 */
class Position implements HasToJson {
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
  Map<String, Object> toJson() {
    return {
      FILE: file,
      OFFSET: offset,
      LENGTH: length
    };
  }

  @override
  String toString() => 'Position(file=$file, offset=$offset, length=$length)';

  static Position fromJson(Map<String, Object> json) {
    String file = json[FILE];
    int offset = json[OFFSET];
    int length = json[LENGTH];
    return new Position(file, offset, length);
  }
}
