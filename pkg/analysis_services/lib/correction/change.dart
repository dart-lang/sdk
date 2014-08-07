// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This code was auto-generated, is not intended to be edited, and is subject to
// significant change. Please see the README file for more information.

library services.correction.change;

import 'package:analysis_services/constants.dart';
import 'package:analysis_services/json.dart';


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
   * A list of the [LinkedEditGroup]s in the change. 
   */
  final List<LinkedEditGroup> linkedEditGroups = <LinkedEditGroup>[];

  /**
   * The position that should be selected after the edits have been applied.
   */
  Position selection;

  Change(this.message);

  /**
   * Adds the given [FileEdit].
   */
  void add(FileEdit edit) {
    edits.add(edit);
  }

  /**
   * Adds the given [LinkedEditGroup].
   */
  void addLinkedEditGroup(LinkedEditGroup linkedEditGroup) {
    linkedEditGroups.add(linkedEditGroup);
  }

  @override
  Map<String, Object> toJson() {
    Map<String, Object> json = {
      MESSAGE: message,
      EDITS: objectToJson(edits),
      LINKED_EDIT_GROUPS: objectToJson(linkedEditGroups)
    };
    if (selection != null) {
      json[SELECTION] = selection.toJson();
    }
    return json;
  }

  @override
  String toString() =>
      'Change(message=$message, edits=$edits, '
          'linkedEditGroups=$linkedEditGroups, selection=$selection)';
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
}


/**
 * A group of linked [Position]s in multiple files that are simultaneously
 * modified - if one gets edited, all other positions in a group are edited the
 * same way. All linked positions in a group have the same content.
 */
class LinkedEditGroup implements HasToJson {
  final String id;
  int length;
  final List<Position> positions = <Position>[];
  final List<LinkedEditSuggestion> suggestions = <LinkedEditSuggestion>[];

  LinkedEditGroup(this.id);

  void addPosition(Position position, int length) {
    positions.add(position);
    this.length = length;
  }

  void addSuggestion(LinkedEditSuggestion suggestion) {
    suggestions.add(suggestion);
  }

  @override
  Map<String, Object> toJson() {
    return {
      ID: id,
      LENGTH: length,
      POSITIONS: objectToJson(positions),
      SUGGESTIONS: objectToJson(suggestions)
    };
  }

  @override
  String toString() =>
      'LinkedEditGroup(id=$id, length=$length, '
          'positions=$positions, suggestions=$suggestions)';
}


/**
 * A suggestion of a value that could be used to replace all of the linked edit
 * regions in a [LinkedEditGroup].
 */
class LinkedEditSuggestion implements HasToJson {
  final LinkedEditSuggestionKind kind;
  final String value;

  LinkedEditSuggestion(this.kind, this.value);

  bool operator ==(other) {
    if (other is LinkedEditSuggestion) {
      return other.kind == kind && other.value == value;
    }
    return false;
  }

  @override
  Map<String, Object> toJson() {
    return {
      KIND: kind.name,
      VALUE: value
    };
  }

  @override
  String toString() => '(kind=$kind, value=$value)';
}


/**
 * An enumeration of the kind of values that can be suggested for a linked edit.
 */
class LinkedEditSuggestionKind {
  static const METHOD = const LinkedEditSuggestionKind('METHOD');
  static const PARAMETER = const LinkedEditSuggestionKind('PARAMETER');
  static const TYPE = const LinkedEditSuggestionKind('TYPE');
  static const VARIABLE = const LinkedEditSuggestionKind('VARIABLE');
  final String name;

  const LinkedEditSuggestionKind(this.name);

  @override
  String toString() => name;
}


/**
 * A position in a file.
 */
class Position implements HasToJson {
  final String file;
  final int offset;

  Position(this.file, this.offset);

  int get hashCode {
    int hash = file.hashCode;
    hash = hash * 31 + offset;
    return hash;
  }

  bool operator ==(other) {
    if (other is Position) {
      return other.file == file && other.offset == offset;
    }
    return false;
  }

  @override
  Map<String, Object> toJson() {
    return {
      FILE: file,
      OFFSET: offset
    };
  }

  @override
  String toString() => 'Position(file=$file, offset=$offset)';
}
