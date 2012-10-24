// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class CodeBuffer implements StringBuffer {
  StringBuffer buffer;
  List<CodeBufferMarker> markers;
  int lastBufferOffset = 0;
  int mappedRangeCounter = 0;

  CodeBuffer()
      : buffer = new StringBuffer(),
        markers = new List<CodeBufferMarker>();

  int get length => buffer.length;

  bool get isEmpty {
    return buffer.isEmpty;
  }

  /**
   * Converts [object] to a string and adds it to the buffer. If [object] is a
   * [CodeBuffer], adds its markers to [markers].
   */
  CodeBuffer add(var object) {
    if (object is CodeBuffer) {
      return addBuffer(object);
    }
    if (mappedRangeCounter == 0) setSourceLocation(null);
    buffer.add(object.toString());
    return this;
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
    buffer.add(other.toString());
  }

  CodeBuffer addAll(Collection<Object> objects) {
    for (Object obj in objects) {
      add(obj);
    }
    return this;
  }

  CodeBuffer addCharCode(int charCode) {
    return add(new String.fromCharCodes([charCode]));
  }

  CodeBuffer clear() {
    buffer.clear();
    markers.clear();
    lastBufferOffset = 0;
    return this;
  }

  String toString() {
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
