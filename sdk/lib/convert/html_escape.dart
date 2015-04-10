// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.convert;

// TODO(floitsch) - Document - Issue 13097
const HtmlEscape HTML_ESCAPE = const HtmlEscape();

/**
 * HTML escape modes.
 *
 * Allows specifying a mode for HTML escaping that depend on the context
 * where the escaped result is going to be used.
 * The relevant contexts are:
 *
 * * as text content of an HTML element.
 * * as value of a (single- or double-) quoted attribute value.
 *
 * All modes require escaping of `&` (ampersand) characters, and may
 * enable escaping of more characters.
 */
class HtmlEscapeMode {
  final String _name;
  /** Whether to escape '<' and '>'. */
  final bool escapeLtGt;
  /** Whether to escape '"' (quote). */
  final bool escapeQuot;
  /** Whether to escape "'" (apostrophe). */
  final bool escapeApos;

  /**
   * Default escaping mode which escape all characters.
   *
   * The result of such an escaping is usable both in element content and
   * in any attribute value.
   *
   * The escaping only works for elements with normal HTML content,
   * and not for, for example, script or style element content,
   * which require escapes matching their particular content syntax.
   */
  static const HtmlEscapeMode UNKNOWN =
      const HtmlEscapeMode._('unknown', true, true, true);

  /**
   * Escaping mode for text going into double-quoted HTML attribute values.
   *
   * The result should not be used as the content of an unquoted
   * or single-quoted attribute value.
   *
   * Escapes only double quotes (`"`) but not single quotes (`'`).
   */
  static const HtmlEscapeMode ATTRIBUTE =
      const HtmlEscapeMode._('attribute', false, true, false);

  /**
   * Escaping mode for text going into single-quoted HTML attribute values.
   *
   * The result should not be used as the content of an unquoted
   * or double-quoted attribute value.
   *
   * Escapes only single quotes (`'`) but not double quotes (`"`).
   */
  static const HtmlEscapeMode SQ_ATTRIBUTE =
      const HtmlEscapeMode._('attribute', false, false, true);

  /**
   * Escaping mode for text going into HTML element content.
   *
   * The escaping only works for elements with normal HTML content,
   * and not for, for example, script or style element content,
   * which require escapes matching their particular content syntax.
   *
   * Escapes `<` and `>` characters.
   */
  static const HtmlEscapeMode ELEMENT =
      const HtmlEscapeMode._('element', true, false, false);

  const HtmlEscapeMode._(
      this._name, this.escapeLtGt, this.escapeQuot, this.escapeApos);

  /**
   * Create a custom escaping mode.
   *
   * All modes escape `&`.
   * The mode can further be set to escape `<` and `>` ([escapeLtGt]),
   * `"` ([escapeQuot]) and/or `'` ([escapeApos]).
   */
  const HtmlEscapeMode({String name: "custom",
                        this.escapeLtGt: false,
                        this.escapeQuot: false,
                        this.escapeApos: false}) : _name = name;

  String toString() => _name;
}

/**
 * Converter which escapes characters with special meaning in HTML.
 *
 * The converter finds characters that are siginificant in HTML source and
 * replaces them with corresponding HTML entities.
 *
 * The characters that need escaping in HTML are:
 *
 * * `&` (ampersand) always need to be escaped.
 * * `<` (less than) and '>' (greater than) when inside an element.
 * * `"` (quote) when inside a double-quoted attribute value.
 * * `'` (apostrophe) when inside a single-quoted attribute value.
 *       Apostrophe is escaped as `&#39;` instead of `&apos;` since
 *       not all browsers understand `&apos;`.
 *
 * Escaping `>` (greater than) isn't necessary, but the result is often
 * found to be easier to read if greater-than is also escaped whenever
 * less-than is.
 */
class HtmlEscape extends Converter<String, String> {

  /** The [HtmlEscapeMode] used by the converter. */
  final HtmlEscapeMode mode;

  /**
   * Create converter that escapes HTML characters.
   *
   * If [mode] is provided as either [HtmlEscapeMode.ATTRIBUTE] or
   * [HtmlEscapeMode.ELEMENT], only the corresponding subset of HTML
   * characters are escaped.
   * The default is to escape all HTML characters.
   */
  const HtmlEscape([this.mode = HtmlEscapeMode.UNKNOWN]);

  String convert(String text) {
    var val = _convert(text, 0, text.length);
    return val == null ? text : val;
  }

  /**
   * Converts the substring of text from start to end.
   *
   * Returns `null` if no changes were necessary, otherwise returns
   * the converted string.
   */
  String _convert(String text, int start, int end) {
    StringBuffer result = null;
    for (int i = start; i < end; i++) {
      var ch = text[i];
      String replacement = null;
      switch (ch) {
        case '&': replacement = '&amp;'; break;
        case '"': if (mode.escapeQuot) replacement = '&quot;'; break;
        case "'": if (mode.escapeApos) replacement = '&#39;'; break;
        case '<': if (mode.escapeLtGt) replacement = '&lt;'; break;
        case '>': if (mode.escapeLtGt) replacement = '&gt;'; break;
      }
      if (replacement != null) {
        if (result == null) result = new StringBuffer();
        if (i > start) result.write(text.substring(start, i));
        result.write(replacement);
        start = i + 1;
      }
    }
    if (result == null) return null;
    if (end > start) result.write(text.substring(start, end));
    return result.toString();
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
