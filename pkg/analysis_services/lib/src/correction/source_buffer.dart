// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library services.src.correction.source_buffer;

import 'package:analysis_services/correction/change.dart';
import 'package:analyzer/src/generated/source.dart';


/**
 * Helper for building Dart source with linked positions.
 */
class SourceBuilder {
  final String file;
  final int offset;
  final StringBuffer _buffer = new StringBuffer();

  final List<LinkedEditGroup> linkedPositionGroups = <LinkedEditGroup>[
      ];
  LinkedEditGroup _currentLinkedPositionGroup;
  int _currentPositionStart;
  int _exitOffset;

  SourceBuilder(this.file, this.offset);

  SourceBuilder.buffer() : file = null, offset = 0;

  /**
   * Returns the exit offset, maybe `null` if not set.
   */
  int get exitOffset {
    if (_exitOffset == null) {
      return null;
    }
    return offset + _exitOffset;
  }

  int get length => _buffer.length;

  void addSuggestion(LinkedEditSuggestionKind kind, String value) {
    var suggestion = new LinkedEditSuggestion(kind, value);
    _currentLinkedPositionGroup.addSuggestion(suggestion);
  }

  void addSuggestions(LinkedEditSuggestionKind kind, List<String> values) {
    values.forEach((value) => addSuggestion(kind, value));
  }

  /**
   * Appends [s] to the buffer.
   */
  SourceBuilder append(String s) {
    _buffer.write(s);
    return this;
  }

  /**
   * Ends position started using [startPosition].
   */
  void endPosition() {
    assert(_currentLinkedPositionGroup != null);
    _addPosition();
    _currentLinkedPositionGroup = null;
  }

  /**
   * Marks the current offset as an "exit" one.
   */
  void setExitOffset() {
    _exitOffset = _buffer.length;
  }

  /**
   * Marks start of a new linked position for the group with the given ID.
   */
  void startPosition(String groupId) {
    assert(_currentLinkedPositionGroup == null);
    for (LinkedEditGroup position in linkedPositionGroups) {
      if (position.id == groupId) {
        _currentLinkedPositionGroup = position;
        break;
      }
    }
    if (_currentLinkedPositionGroup == null) {
      _currentLinkedPositionGroup = new LinkedEditGroup(groupId);
      linkedPositionGroups.add(_currentLinkedPositionGroup);
    }
    _currentPositionStart = _buffer.length;
  }

  @override
  String toString() => _buffer.toString();

  /**
   * Adds position location [SourceRange] using current fields.
   */
  void _addPosition() {
    int start = offset + _currentPositionStart;
    int end = offset + _buffer.length;
    int length = end - start;
    Position position = new Position(file, start);
    _currentLinkedPositionGroup.addPosition(position, length);
  }
}
