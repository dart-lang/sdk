// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.code_output;

import 'dart:async';

import '../source_file.dart';

import 'source_map_builder.dart';

class CodeOutputMarker {
  final int offsetDelta;
  final SourceFileLocation sourcePosition;

  CodeOutputMarker(this.offsetDelta, this.sourcePosition);
}

abstract class CodeOutput {
  List<CodeOutputMarker> markers = new List<CodeOutputMarker>();

  int lastBufferOffset = 0;
  int mappedRangeCounter = 0;

  int get length;

  void _writeInternal(String text);

  /// Converts [object] to a string and adds it to the buffer. If [object] is a
  /// [CodeBuffer], adds its markers to [markers].
  void write(var object) {
    if (object is CodeBuffer) {
      addBuffer(object);
      return;
    }
    if (mappedRangeCounter == 0) setSourceLocation(null);
    _writeInternal(object);
  }

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
    _writeInternal(other.getText());
  }

  void beginMappedRange() {
    ++mappedRangeCounter;
  }

  void endMappedRange() {
    assert(mappedRangeCounter > 0);
    --mappedRangeCounter;
  }

  void setSourceLocation(SourceFileLocation sourcePosition) {
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
}

/// [CodeOutput] using a [StringBuffer] as backend.
class CodeBuffer extends CodeOutput implements StringBuffer {
  StringBuffer buffer = new StringBuffer();

  @override
  void _writeInternal(String text) {
    buffer.write(text);
  }

  @override
  int get length => buffer.length;

  @override
  bool get isEmpty => buffer.isEmpty;

  @override
  bool get isNotEmpty => buffer.isNotEmpty;

  @override
  void writeAll(Iterable<Object> objects, [String separator = ""]) {
    Iterator iterator = objects.iterator;
    if (!iterator.moveNext()) return;
    if (separator.isEmpty) {
      do {
        write(iterator.current);
      } while (iterator.moveNext());
    } else {
      write(iterator.current);
      while (iterator.moveNext()) {
        write(separator);
        write(iterator.current);
      }
    }
  }

  @override
  void writeln([var object = ""]) {
    write(object);
    write("\n");
  }

  @override
  void writeCharCode(int charCode) {
    buffer.writeCharCode(charCode);
  }

  @override
  void clear() {
    buffer = new StringBuffer();
    markers.clear();
    lastBufferOffset = 0;
  }

  String toString() {
    throw "Don't use CodeBuffer.toString() since it drops sourcemap data.";
  }

  String getText() {
    return buffer.toString();
  }
}

/// [CodeOutput] using a [CompilationOutput] as backend.
class StreamCodeOutput extends CodeOutput {
  int length = 0;
  final EventSink<String> output;

  StreamCodeOutput(this.output);

  @override
  void _writeInternal(String text) {
    output.add(text);
    length += text.length;
  }

  void close() {
    output.close();
  }
}

/// [StreamCodeSink] that collects line information.
class LineColumnCodeOutput extends StreamCodeOutput
    implements LineColumnProvider {
  int lastLineStart = 0;
  List<int> lineStarts = <int>[0];

  LineColumnCodeOutput(EventSink<String> output) : super(output);

  @override
  void _writeInternal(String text) {
    int offset = lastLineStart;
    int index = 0;
    while (index < text.length) {
      // Unix uses '\n' and Windows uses '\r\n', so this algorithm works for
      // both platforms.
      index = text.indexOf('\n', index) + 1;
      if (index <= 0) break;
      lastLineStart = offset + index;
      lineStarts.add(lastLineStart);
    }
    super._writeInternal(text);
  }

  @override
  int getLine(int offset) {
    List<int> starts = lineStarts;
    if (offset < 0|| starts.last <= offset) {
      throw 'bad position #$offset in buffer with length ${length}.';
    }
    int first = 0;
    int count = starts.length;
    while (count > 1) {
      int step = count ~/ 2;
      int middle = first + step;
      int lineStart = starts[middle];
      if (offset < lineStart) {
        count = step;
      } else {
        first = middle;
        count -= step;
      }
    }
    return first;
  }

  @override
  int getColumn(int line, int offset) {
    return offset - lineStarts[line];
  }

  @override
  void close() {
    lineStarts.add(length);
    super.close();
  }
}
