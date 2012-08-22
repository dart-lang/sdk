// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class CodeBuffer implements StringBuffer {
  StringBuffer buffer;
  List<SourceLocation> sourceLocations;
  int lastBufferOffset = 0;

  CodeBuffer()
      : buffer = new StringBuffer(),
        sourceLocations = new List<SourceLocation>();

  int get length => buffer.length;

  bool isEmpty() {
    return buffer.isEmpty();
  }

  /**
   * Converts [object] to a string and adds it to the buffer. If [object] is a
   * [CodeBuffer], adds its source locations to [sourceLocations].
   */
  CodeBuffer add(var object) {
    if (object is CodeBuffer) {
      return addBuffer(object);
    }
    buffer.add(object.toString());
    return this;
  }

  CodeBuffer addBuffer(CodeBuffer other) {
    if (other.sourceLocations.length > 0) {
      SourceLocation firstMapping = other.sourceLocations[0];
      int offsetDelta =
          buffer.length + firstMapping.offsetDelta - lastBufferOffset;
      sourceLocations.add(new SourceLocation(firstMapping.element,
                                             firstMapping.token,
                                             offsetDelta));
      for (int i = 1; i < other.sourceLocations.length; ++i) {
        sourceLocations.add(other.sourceLocations[i]);
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
    sourceLocations.clear();
    lastBufferOffset = 0;
    return this;
  }

  String toString() {
    return buffer.toString();
  }

  void setSourceLocation(Element element, Token token) {
    int offsetDelta = buffer.length - lastBufferOffset;
    sourceLocations.add(new SourceLocation(element, token, offsetDelta));
    lastBufferOffset = buffer.length;
  }

  void forEachSourceLocation(void f(Element element, Token token, int offset)) {
    int offset = 0;
    sourceLocations.forEach((sourceLocation) {
      offset += sourceLocation.offsetDelta;
      f(sourceLocation.element, sourceLocation.token, offset);
    });
  }
}

class SourceLocation {
  final Element element;
  final Token token;
  final int offsetDelta;
  SourceLocation(this.element, this.token, this.offsetDelta);
}
