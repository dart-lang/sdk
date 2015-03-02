// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.convert;

// TODO(floitsch) - Document - Issue 13097
const HtmlEscape HTML_ESCAPE = const HtmlEscape();

class HtmlEscapeMode {
  final String _name;
  final bool escapeLtGt;
  final bool escapeQuot;
  final bool escapeApos;
  final bool escapeSlash;

  // TODO(floitsch) - Document - Issue 13097
  static const HtmlEscapeMode UNKNOWN =
    const HtmlEscapeMode._('unknown', true, true, true, true);

  // TODO(floitsch) - Document - Issue 13097
  static const HtmlEscapeMode ATTRIBUTE =
    const HtmlEscapeMode._('attribute', false, true, false, false);

  // TODO(floitsch) - Document - Issue 13097
  static const HtmlEscapeMode ELEMENT =
    const HtmlEscapeMode._('element', true, false, false, true);

  // TODO(floitsch) - Document - Issue 13097
  const HtmlEscapeMode._(this._name, this.escapeLtGt, this.escapeQuot,
    this.escapeApos, this.escapeSlash);

  String toString() => _name;
}

  // TODO(floitsch) - Document - Issue 13097
class HtmlEscape extends Converter<String, String> {

  // TODO(floitsch) - Document - Issue 13097
  final HtmlEscapeMode mode;

  // TODO(floitsch) - Document - Issue 13097
  const HtmlEscape([this.mode = HtmlEscapeMode.UNKNOWN]);

  String convert(String text) {
    var val = _convert(text, 0, text.length);
    return val == null ? text : val;
  }

  String _convert(String text, int start, int end) {
    StringBuffer result = null;
    for (int i = start; i < end; i++) {
      var ch = text[i];
      String replace = null;
      switch (ch) {
        case '&': replace = '&amp;'; break;
        case '\u00A0'/*NO-BREAK SPACE*/: replace = '&nbsp;'; break;
        case '"': if (mode.escapeQuot) replace = '&quot;'; break;
        case "'": if (mode.escapeApos) replace = '&#x27;'; break;
        case '<': if (mode.escapeLtGt) replace = '&lt;'; break;
        case '>': if (mode.escapeLtGt) replace = '&gt;'; break;
        case '/': if (mode.escapeSlash) replace = '&#x2F;'; break;
      }
      if (replace != null) {
        if (result == null) result = new StringBuffer(text.substring(start, i));
        result.write(replace);
      } else if (result != null) {
        result.write(ch);
      }
    }

    return result != null ? result.toString() : null;
  }

  StringConversionSink startChunkedConversion(Sink<String> sink) {
    if (sink is! StringConversionSink) {
      sink = new StringConversionSink.from(sink);
    }
    return new _HtmlEscapeSink(this, sink);
  }
}

class _HtmlEscapeSink extends StringConversionSinkBase {
  final HtmlEscape _escape;
  final StringConversionSink _sink;

  _HtmlEscapeSink(this._escape, this._sink);

  void addSlice(String chunk, int start, int end, bool isLast) {
    var val = _escape._convert(chunk, start, end);
    if(val == null) {
      _sink.addSlice(chunk, start, end, isLast);
    } else {
      _sink.add(val);
      if (isLast) _sink.close();
    }
  }

  void close() => _sink.close();
}
