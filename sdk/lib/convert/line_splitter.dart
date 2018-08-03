// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.convert;

// Character constants.
const int _LF = 10;
const int _CR = 13;

/**
 * A [StreamTransformer] that splits a [String] into individual lines.
 *
 * A line is terminated by either a CR (U+000D), a LF (U+000A), a
 * CR+LF sequence (DOS line ending),
 * and a final non-empty line can be ended by the end of the string.
 *
 * The returned lines do not contain the line terminators.
 */

class LineSplitter extends StreamTransformerBase<String, String> {
  const LineSplitter();

  /// Split [lines] into individual lines.
  ///
  /// If [start] and [end] are provided, only split the contents of
  /// `lines.substring(start, end)`. The [start] and [end] values must
  /// specify a valid sub-range of [lines]
  /// (`0 <= start <= end <= lines.length`).
  static Iterable<String> split(String lines, [int start = 0, int end]) sync* {
    end = RangeError.checkValidRange(start, end, lines.length);
    int sliceStart = start;
    int char = 0;
    for (int i = start; i < end; i++) {
      int previousChar = char;
      char = lines.codeUnitAt(i);
      if (char != _CR) {
        if (char != _LF) continue;
        if (previousChar == _CR) {
          sliceStart = i + 1;
          continue;
        }
      }
      yield lines.substring(sliceStart, i);
      sliceStart = i + 1;
    }
    if (sliceStart < end) {
      yield lines.substring(sliceStart, end);
    }
  }

  List<String> convert(String data) {
    List<String> lines = <String>[];
    int end = data.length;
    int sliceStart = 0;
    int char = 0;
    for (int i = 0; i < end; i++) {
      int previousChar = char;
      char = data.codeUnitAt(i);
      if (char != _CR) {
        if (char != _LF) continue;
        if (previousChar == _CR) {
          sliceStart = i + 1;
          continue;
        }
      }
      lines.add(data.substring(sliceStart, i));
      sliceStart = i + 1;
    }
    if (sliceStart < end) {
      lines.add(data.substring(sliceStart, end));
    }
    return lines;
  }

  StringConversionSink startChunkedConversion(Sink<String> sink) {
    if (sink is! StringConversionSink) {
      sink = new StringConversionSink.from(sink);
    }
    return new _LineSplitterSink(sink);
  }

  Stream<String> bind(Stream<String> stream) {
    return new Stream<String>.eventTransformed(
        stream, (EventSink<String> sink) => new _LineSplitterEventSink(sink));
  }
}

// TODO(floitsch): deal with utf8.
class _LineSplitterSink extends StringConversionSinkBase {
  final StringConversionSink _sink;

  /// The carry-over from the previous chunk.
  ///
  /// If the previous slice ended in a line without a line terminator,
  /// then the next slice may continue the line.
  String _carry;

  /// Whether to skip a leading LF character from the next slice.
  ///
  /// If the previous slice ended on a CR character, a following LF
  /// would be part of the same line termination, and should be ignored.
  ///
  /// Only `true` when [_carry] is `null`.
  bool _skipLeadingLF = false;

  _LineSplitterSink(this._sink);

  void addSlice(String chunk, int start, int end, bool isLast) {
    end = RangeError.checkValidRange(start, end, chunk.length);
    // If the chunk is empty, it's probably because it's the last one.
    // Handle that here, so we know the range is non-empty below.
    if (start >= end) {
      if (isLast) close();
      return;
    }
    if (_carry != null) {
      assert(!_skipLeadingLF);
      chunk = _carry + chunk.substring(start, end);
      start = 0;
      end = chunk.length;
      _carry = null;
    } else if (_skipLeadingLF) {
      if (chunk.codeUnitAt(start) == _LF) {
        start += 1;
      }
      _skipLeadingLF = false;
    }
    _addLines(chunk, start, end);
    if (isLast) close();
  }

  void close() {
    if (_carry != null) {
      _sink.add(_carry);
      _carry = null;
    }
    _sink.close();
  }

  void _addLines(String lines, int start, int end) {
    int sliceStart = start;
    int char = 0;
    for (int i = start; i < end; i++) {
      int previousChar = char;
      char = lines.codeUnitAt(i);
      if (char != _CR) {
        if (char != _LF) continue;
        if (previousChar == _CR) {
          sliceStart = i + 1;
          continue;
        }
      }
      _sink.add(lines.substring(sliceStart, i));
      sliceStart = i + 1;
    }
    if (sliceStart < end) {
      _carry = lines.substring(sliceStart, end);
    } else {
      _skipLeadingLF = (char == _CR);
    }
  }
}

class _LineSplitterEventSink extends _LineSplitterSink
    implements EventSink<String> {
  final EventSink<String> _eventSink;

  _LineSplitterEventSink(EventSink<String> eventSink)
      : _eventSink = eventSink,
        super(new StringConversionSink.from(eventSink));

  void addError(Object o, [StackTrace stackTrace]) {
    _eventSink.addError(o, stackTrace);
  }
}
