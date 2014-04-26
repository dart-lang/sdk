// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart2js;

class CodeBuffer implements StringBuffer {

  StringBuffer buffer = new StringBuffer();
  List<CodeBufferMarker> markers = new List<CodeBufferMarker>();

  int lastBufferOffset = 0;
  int mappedRangeCounter = 0;

  CodeBuffer();

  int get length => buffer.length;
  bool get isEmpty => buffer.isEmpty;
  bool get isNotEmpty => buffer.isNotEmpty;

  CodeBuffer add(var object) {
    write(object);
    return this;
  }
  /**
   * Converts [object] to a string and adds it to the buffer. If [object] is a
   * [CodeBuffer], adds its markers to [markers].
   */
  CodeBuffer write(var object) {
    if (object is CodeBuffer) {
      return addBuffer(object);
    }
    if (mappedRangeCounter == 0) setSourceLocation(null);
    buffer.write(object);
    return this;
  }

  CodeBuffer writeAll(Iterable<Object> objects, [String separator = ""]) {
    Iterator iterator = objects.iterator;
    if (!iterator.moveNext()) return this;
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
    return this;
  }

  CodeBuffer writeln([var object = ""]) {
    return write(object).write("\n");
  }

  CodeBuffer addBuffer(CodeBuffer other) {
    if (other.markers.length > 0) {
      CodeBufferMarker firstMarker = other.markers[0];
      int offsetDelta =
          buffer.length + firstMarker.offsetDelta - lastBufferOffset;
      markers.add(new CodeBufferMarker(offsetDelta,
                                       firstMarker.sourcePosition));
      for (int i = 1; i < other.markers.length; ++i) {
        markers.add(other.markers[i]);
      }
      lastBufferOffset = buffer.length + other.lastBufferOffset;
    }
    buffer.write(other.getText());
    return this;
  }

  CodeBuffer addAll(Iterable<Object> iterable) => writeAll(iterable);

  CodeBuffer writeCharCode(int charCode) {
    buffer.writeCharCode(charCode);
    return this;
  }

  CodeBuffer clear() {
    buffer = new StringBuffer();
    markers.clear();
    lastBufferOffset = 0;
    return this;
  }

  String toString() {
    throw "Don't use CodeBuffer.toString() since it drops sourcemap data.";
  }

  String getText() {
    return buffer.toString();
  }

  void beginMappedRange() {
    ++mappedRangeCounter;
  }

  void endMappedRange() {
    assert(mappedRangeCounter > 0);
    --mappedRangeCounter;
  }

  void setSourceLocation(var sourcePosition) {
    if (sourcePosition == null) {
      if (markers.length > 0 && markers.last.sourcePosition == null) return;
    }
    int offsetDelta = buffer.length - lastBufferOffset;
    markers.add(new CodeBufferMarker(offsetDelta, sourcePosition));
    lastBufferOffset = buffer.length;
  }

  void forEachSourceLocation(void f(int targetOffset, var sourcePosition)) {
    int targetOffset = 0;
    markers.forEach((marker) {
      targetOffset += marker.offsetDelta;
      f(targetOffset, marker.sourcePosition);
    });
  }
}

class CodeBufferMarker {
  final int offsetDelta;
  final sourcePosition;

  CodeBufferMarker(this.offsetDelta, this.sourcePosition);
}
