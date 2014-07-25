// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This code was auto-generated, is not intended to be edited, and is subject to
// significant change. Please see the README file for more information.

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

  final List<LinkedPositionGroup> linkedPositionGroups = <LinkedPositionGroup>[
      ];
  LinkedPositionGroup _currentLinkedPositionGroup;
  int _currentPositionStart;

  SourceBuilder(this.file, this.offset);

  SourceBuilder.buffer() : file = null, offset = 0;

  int get length => _buffer.length;

  void addProposal(String proposal) {
    _currentLinkedPositionGroup.addProposal(proposal);
  }

  void addProposals(List<String> proposals) {
    proposals.forEach((proposal) => addProposal(proposal));
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
   * Marks start of a new linked position for the group with the given ID.
   */
  void startPosition(String groupId) {
    assert(_currentLinkedPositionGroup == null);
    for (LinkedPositionGroup position in linkedPositionGroups) {
      if (position.id == groupId) {
        _currentLinkedPositionGroup = position;
        break;
      }
    }
    if (_currentLinkedPositionGroup == null) {
      _currentLinkedPositionGroup = new LinkedPositionGroup(groupId);
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
    Position position = new Position(file, start, end - start);
    _currentLinkedPositionGroup.addPosition(position);
  }
}
