// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.code_output;

import 'dart:async';

import 'source_information.dart';

class CodeOutputMarker {
  final int offsetDelta;
  final SourceLocation sourcePosition;

  CodeOutputMarker(this.offsetDelta, this.sourcePosition);
}

abstract class CodeOutputListener {
  void onText(String text);
  void onDone(int length);
}

abstract class CodeOutput {
  /// Write [text] to this output.
  ///
  /// If the output is closed, a [StateError] is thrown.
  void add(String text);

  /// Adds the content of [buffer] to the output and adds its markers to
  /// [markers].
  ///
  /// If the output is closed, a [StateError] is thrown.
  void addBuffer(CodeBuffer buffer);

  /// Returns the number of characters currently write to this output.
  int get length;

  /// Returns `true` if this output has been closed.
  bool get isClosed;

  /// Closes the output. Further writes will cause a [StateError].
  void close();

  /// Sets the [sourcePosition] for the code next added to this output.
  void setSourceLocation(SourceLocation sourcePosition);

  /// Applies [f] to every marker in this output.
  void forEachSourceLocation(void f(int targetOffset,
                                    SourceLocation sourceLocation));
}

abstract class AbstractCodeOutput extends CodeOutput {
  List<CodeOutputMarker> markers = new List<CodeOutputMarker>();
  int lastBufferOffset = 0;
  int mappedRangeCounter = 0;
  bool isClosed = false;

  void _addInternal(String text);

  @override
  void add(String text) {
    if (isClosed) {
      throw new StateError("Code output is closed. Trying to write '$text'.");
    }
    if (mappedRangeCounter == 0) setSourceLocation(null);
    _addInternal(text);
  }

  @override
  void addBuffer(CodeBuffer other) {
    if (other.markers.length > 0) {
      CodeOutputMarker firstMarker = other.markers[0];
      int offsetDelta =
          length + firstMarker.offsetDelta - lastBufferOffset;
      markers.add(new CodeOutputMarker(offsetDelta,
                                       firstMarker.sourcePosition));
      for (int i = 1; i < other.markers.length; ++i) {
        markers.add(other.markers[i]);
      }
      lastBufferOffset = length + other.lastBufferOffset;
    }
    if (!other.isClosed) {
      other.close();
    }
    _addInternal(other.getText());
  }

  void beginMappedRange() {
    ++mappedRangeCounter;
  }

  void endMappedRange() {
    assert(mappedRangeCounter > 0);
    --mappedRangeCounter;
  }

  void setSourceLocation(SourceLocation sourcePosition) {
    if (sourcePosition == null) {
      if (markers.length > 0 && markers.last.sourcePosition == null) return;
    }
    int offsetDelta = length - lastBufferOffset;
    markers.add(new CodeOutputMarker(offsetDelta, sourcePosition));
    lastBufferOffset = length;
  }

  void forEachSourceLocation(void f(int targetOffset, var sourcePosition)) {
    int targetOffset = 0;
    markers.forEach((marker) {
      targetOffset += marker.offsetDelta;
      f(targetOffset, marker.sourcePosition);
    });
  }

  void close() {
    if (isClosed) {
      throw new StateError("Code output is already closed.");
    }
    isClosed = true;
  }
}

/// [CodeOutput] using a [StringBuffer] as backend.
class CodeBuffer extends AbstractCodeOutput {
  StringBuffer buffer = new StringBuffer();

  @override
  void _addInternal(String text) {
    buffer.write(text);
  }

  @override
  int get length => buffer.length;

  String getText() {
    return buffer.toString();
  }

  String toString() {
    throw "Don't use CodeBuffer.toString() since it drops sourcemap data.";
  }
}

/// [CodeOutput] using a [CompilationOutput] as backend.
class StreamCodeOutput extends AbstractCodeOutput {
  int length = 0;
  final EventSink<String> output;
  final List<CodeOutputListener> _listeners;

  StreamCodeOutput(this.output, [this._listeners]);

  @override
  void _addInternal(String text) {
    output.add(text);
    length += text.length;
    if (_listeners != null) {
      _listeners.forEach((listener) => listener.onText(text));
    }
  }

  void close() {
    output.close();
    super.close();
    if (_listeners != null) {
      _listeners.forEach((listener) => listener.onDone(length));
    }
  }
}
