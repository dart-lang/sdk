part of dart.convert;
 abstract class StringConversionSink extends ChunkedConversionSink<String> {StringConversionSink();
 factory StringConversionSink.withCallback(void callback(String accumulated)) = _StringCallbackSink;
 factory StringConversionSink.from(Sink<String> sink) = _StringAdapterSink;
 factory StringConversionSink.fromStringSink(StringSink sink) = _StringSinkConversionSink;
 void addSlice(String chunk, int start, int end, bool isLast);
 ByteConversionSink asUtf8Sink(bool allowMalformed);
 ClosableStringSink asStringSink();
}
 abstract class ClosableStringSink extends StringSink {factory ClosableStringSink.fromStringSink(StringSink sink, void onClose()) = _ClosableStringSink;
 void close();
}
 typedef void _StringSinkCloseCallback();
 class _ClosableStringSink implements ClosableStringSink {final _StringSinkCloseCallback _callback;
 final StringSink _sink;
 _ClosableStringSink(this._sink, this._callback);
 void close() => _callback();
 void writeCharCode(int charCode) => _sink.writeCharCode(charCode);
 void write(Object o) => _sink.write(o);
 void writeln([Object o = ""]) => _sink.writeln(o);
 void writeAll(Iterable objects, [String separator = ""]) => _sink.writeAll(objects, separator);
}
 class _StringConversionSinkAsStringSinkAdapter implements ClosableStringSink {static const _MIN_STRING_SIZE = 16;
 StringBuffer _buffer;
 StringConversionSink _chunkedSink;
 _StringConversionSinkAsStringSinkAdapter(this._chunkedSink) : _buffer = new StringBuffer();
 void close() {
if (_buffer.isNotEmpty) _flush();
 _chunkedSink.close();
}
 void writeCharCode(int charCode) {
_buffer.writeCharCode(charCode);
 if (_buffer.length > _MIN_STRING_SIZE) _flush();
}
 void write(Object o) {
if (_buffer.isNotEmpty) _flush();
 String str = o.toString();
 _chunkedSink.add(o.toString());
}
 void writeln([Object o = ""]) {
_buffer.writeln(o);
 if (_buffer.length > _MIN_STRING_SIZE) _flush();
}
 void writeAll(Iterable objects, [String separator = ""]) {
if (_buffer.isNotEmpty) _flush();
 Iterator iterator = objects.iterator;
 if (!iterator.moveNext()) return; if (separator.isEmpty) {
do {
_chunkedSink.add(((__x27) => DDC$RT.cast(__x27, dynamic, String, "CastGeneral", """line 147, column 26 of dart:convert/string_conversion.dart: """, __x27 is String, true))(iterator.current.toString()));
}
 while (iterator.moveNext());}
 else {
_chunkedSink.add(((__x28) => DDC$RT.cast(__x28, dynamic, String, "CastGeneral", """line 150, column 24 of dart:convert/string_conversion.dart: """, __x28 is String, true))(iterator.current.toString()));
 while (iterator.moveNext()) {
write(separator);
 _chunkedSink.add(((__x29) => DDC$RT.cast(__x29, dynamic, String, "CastGeneral", """line 153, column 26 of dart:convert/string_conversion.dart: """, __x29 is String, true))(iterator.current.toString()));
}
}
}
 void _flush() {
String accumulated = _buffer.toString();
 _buffer.clear();
 _chunkedSink.add(accumulated);
}
}
 abstract class StringConversionSinkBase extends StringConversionSinkMixin {}
 abstract class StringConversionSinkMixin implements StringConversionSink {void addSlice(String str, int start, int end, bool isLast);
 void close();
 void add(String str) => addSlice(str, 0, str.length, false);
 ByteConversionSink asUtf8Sink(bool allowMalformed) {
return new _Utf8ConversionSink(this, allowMalformed);
}
 ClosableStringSink asStringSink() {
return new _StringConversionSinkAsStringSinkAdapter(this);
}
}
 class _StringSinkConversionSink extends StringConversionSinkBase {StringSink _stringSink;
 _StringSinkConversionSink(StringSink this._stringSink);
 void close() {
}
 void addSlice(String str, int start, int end, bool isLast) {
if (start != 0 || end != str.length) {
for (int i = start;
 i < end;
 i++) {
_stringSink.writeCharCode(str.codeUnitAt(i));
}
}
 else {
_stringSink.write(str);
}
 if (isLast) close();
}
 void add(String str) => _stringSink.write(str);
 ByteConversionSink asUtf8Sink(bool allowMalformed) {
return new _Utf8StringSinkAdapter(this, _stringSink, allowMalformed);
}
 ClosableStringSink asStringSink() {
return new ClosableStringSink.fromStringSink(_stringSink, this.close);
}
}
 class _StringCallbackSink extends _StringSinkConversionSink {final _ChunkedConversionCallback<String> _callback;
 _StringCallbackSink(this._callback) : super(new StringBuffer());
 void close() {
StringBuffer buffer = DDC$RT.cast(_stringSink, StringSink, StringBuffer, "CastGeneral", """line 233, column 27 of dart:convert/string_conversion.dart: """, _stringSink is StringBuffer, true);
 String accumulated = buffer.toString();
 buffer.clear();
 _callback(accumulated);
}
 ByteConversionSink asUtf8Sink(bool allowMalformed) {
return new _Utf8StringSinkAdapter(this, _stringSink, allowMalformed);
}
}
 class _StringAdapterSink extends StringConversionSinkBase {final Sink<String> _sink;
 _StringAdapterSink(this._sink);
 void add(String str) => _sink.add(str);
 void addSlice(String str, int start, int end, bool isLast) {
if (start == 0 && end == str.length) {
add(str);
}
 else {
add(str.substring(start, end));
}
 if (isLast) close();
}
 void close() => _sink.close();
}
 class _Utf8StringSinkAdapter extends ByteConversionSink {final _Utf8Decoder _decoder;
 final Sink _sink;
 _Utf8StringSinkAdapter(this._sink, StringSink stringSink, bool allowMalformed) : _decoder = new _Utf8Decoder(stringSink, allowMalformed);
 void close() {
_decoder.close();
 if (_sink != null) _sink.close();
}
 void add(List<int> chunk) {
addSlice(chunk, 0, chunk.length, false);
}
 void addSlice(List<int> codeUnits, int startIndex, int endIndex, bool isLast) {
_decoder.convert(codeUnits, startIndex, endIndex);
 if (isLast) close();
}
}
 class _Utf8ConversionSink extends ByteConversionSink {final _Utf8Decoder _decoder;
 final StringConversionSink _chunkedSink;
 final StringBuffer _buffer;
 _Utf8ConversionSink(StringConversionSink sink, bool allowMalformed) : this._(sink, new StringBuffer(), allowMalformed);
 _Utf8ConversionSink._(this._chunkedSink, StringBuffer stringBuffer, bool allowMalformed) : _decoder = new _Utf8Decoder(stringBuffer, allowMalformed), _buffer = stringBuffer;
 void close() {
_decoder.close();
 if (_buffer.isNotEmpty) {
String accumulated = _buffer.toString();
 _buffer.clear();
 _chunkedSink.addSlice(accumulated, 0, accumulated.length, true);
}
 else {
_chunkedSink.close();
}
}
 void add(List<int> chunk) {
addSlice(chunk, 0, chunk.length, false);
}
 void addSlice(List<int> chunk, int startIndex, int endIndex, bool isLast) {
_decoder.convert(chunk, startIndex, endIndex);
 if (_buffer.isNotEmpty) {
String accumulated = _buffer.toString();
 _chunkedSink.addSlice(accumulated, 0, accumulated.length, isLast);
 _buffer.clear();
 return;}
 if (isLast) close();
}
}
