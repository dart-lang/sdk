// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.code_output;

import 'dart:async';

import 'source_information.dart';

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

  /// Adds a [sourceLocation] at the specified [targetOffset] in the buffer.
  void addSourceLocation(int targetOffset, SourceLocation sourcePosition);

  /// Applies [f] to every marker in this output.
  void forEachSourceLocation(void f(int targetOffset,
                                    SourceLocation sourceLocation));
}

abstract class AbstractCodeOutput extends CodeOutput {
  Map<int, List<SourceLocation>> markers = <int, List<SourceLocation>>{};
  bool isClosed = false;

  void _addInternal(String text);

  @override
  void add(String text) {
    if (isClosed) {
      throw new StateError("Code output is closed. Trying to write '$text'.");
    }
    _addInternal(text);
  }

  @override
  void addBuffer(CodeBuffer other) {
    if (other.markers.length > 0) {
      other.markers.forEach(
          (int targetOffset, List<SourceLocation> sourceLocations) {
        markers.putIfAbsent(length + targetOffset, () => <SourceLocation>[])
            .addAll(sourceLocations);
      });
    }
    if (!other.isClosed) {
      other.close();
    }
    _addInternal(other.getText());
  }

  void addSourceLocation(int targetOffset,
                         SourceLocation sourceLocation) {
    assert(targetOffset <= length);
    List<SourceLocation> sourceLocations =
        markers.putIfAbsent(targetOffset, () => <SourceLocation>[]);
    sourceLocations.add(sourceLocation);
  }

  void forEachSourceLocation(void f(int targetOffset, var sourceLocation)) {
    markers.forEach((int targetOffset, List<SourceLocation> sourceLocations) {
      for (SourceLocation sourceLocation in sourceLocations) {
        f(targetOffset, sourceLocation);
      }
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
