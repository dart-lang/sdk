part of dart.convert;
 const HtmlEscape HTML_ESCAPE = const HtmlEscape();
 class HtmlEscapeMode {final String _name;
 final bool escapeLtGt;
 final bool escapeQuot;
 final bool escapeApos;
 final bool escapeSlash;
 static const HtmlEscapeMode UNKNOWN = const HtmlEscapeMode._('unknown', true, true, true, true);
 static const HtmlEscapeMode ATTRIBUTE = const HtmlEscapeMode._('attribute', false, true, false, false);
 static const HtmlEscapeMode ELEMENT = const HtmlEscapeMode._('element', true, false, false, true);
 const HtmlEscapeMode._(this._name, this.escapeLtGt, this.escapeQuot, this.escapeApos, this.escapeSlash);
 String toString() => _name;
}
 class HtmlEscape extends Converter<String, String> {final HtmlEscapeMode mode;
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
   switch (ch) {case '&': replace = '&amp;';
   break;
   case '\u00A0': replace = '&nbsp;';
   break;
   case '"': if (mode.escapeQuot) replace = '&quot;';
   break;
   case "'": if (mode.escapeApos) replace = '&#x27;';
   break;
   case '<': if (mode.escapeLtGt) replace = '&lt;';
   break;
   case '>': if (mode.escapeLtGt) replace = '&gt;';
   break;
   case '/': if (mode.escapeSlash) replace = '&#x2F;';
   break;
  }
 if (replace != null) {
  if (result == null) result = new StringBuffer(text.substring(start, i));
   result.write(replace);
  }
 else if (result != null) {
  result.write(ch);
  }
}
 return result != null ? result.toString() : null;
}
 StringConversionSink startChunkedConversion(Sink<String> sink) {
if (sink is! StringConversionSink) {
sink = new StringConversionSink.from(sink);
}
 return new _HtmlEscapeSink(this, DEVC$RT.cast(sink, DEVC$RT.type((Sink<String> _) {
}
), StringConversionSink, "ImplicitCast", """line 79, column 38 of dart:convert/html_escape.dart: """, sink is StringConversionSink, true));
}
}
 class _HtmlEscapeSink extends StringConversionSinkBase {final HtmlEscape _escape;
 final StringConversionSink _sink;
 _HtmlEscapeSink(this._escape, this._sink);
 void addSlice(String chunk, int start, int end, bool isLast) {
var val = _escape._convert(chunk, start, end);
 if (val == null) {
_sink.addSlice(chunk, start, end, isLast);
}
 else {
_sink.add(val);
 if (isLast) _sink.close();
}
}
 void close() => _sink.close();
}
