// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.convert;

/**
 * This class splits [String] values into individual lines.
 */
class LineSplitter extends Converter<String, List<String>> {

  const LineSplitter();

  List<String> convert(String data) {
    var lines = new List<String>();

    _LineSplitterSink._addSlice(data, 0, data.length, true, lines.add);

    return lines;
  }

  StringConversionSink startChunkedConversion(Sink<String> sink) {
    if (sink is! StringConversionSink) {
      sink = new StringConversionSink.from(sink);
    }
    return new _LineSplitterSink(sink);
  }
}

// TODO(floitsch): deal with utf8.
class _LineSplitterSink extends StringConversionSinkBase {
  static const int _LF = 10;
  static const int _CR = 13;

  final StringConversionSink _sink;

  String _carry;

  _LineSplitterSink(this._sink);

  void addSlice(String chunk, int start, int end, bool isLast) {
    if (_carry != null) {
      chunk = _carry + chunk.substring(start, end);
      start = 0;
      end = chunk.length;
      _carry = null;
    }
    _carry = _addSlice(chunk, start, end, isLast, _sink.add);
    if (isLast) _sink.close();
  }

  void close() {
    addSlice('', 0, 0, true);
  }

  static String _addSlice(String chunk, int start, int end, bool isLast,
                          void adder(String val)) {

    int pos = start;
    while (pos < end) {
      int skip = 0;
      int char = chunk.codeUnitAt(pos);
      if (char == _LF) {
        skip = 1;
      } else if (char == _CR) {
        skip = 1;
        if (pos + 1 < end) {
          if (chunk.codeUnitAt(pos + 1) == _LF) {
            skip = 2;
          }
        } else if (!isLast) {
          return chunk.substring(start, end);
        }
      }
      if (skip > 0) {
        adder(chunk.substring(start, pos));
        start = pos = pos + skip;
      } else {
        pos++;
      }
    }
    if (pos != start) {
      var carry = chunk.substring(start, pos);
      if (isLast) {
        // Add remaining
        adder(carry);
      } else {
        return carry;
      }
    }
    return null;
  }
}
