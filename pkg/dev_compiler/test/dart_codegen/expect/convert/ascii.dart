part of dart.convert;
 const AsciiCodec ASCII = const AsciiCodec();
 const int _ASCII_MASK = 0x7F;
 class AsciiCodec extends Encoding {final bool _allowInvalid;
 const AsciiCodec({
  bool allowInvalid : false}
) : _allowInvalid = allowInvalid;
 String get name => "us-ascii";
 String decode(List<int> bytes, {
  bool allowInvalid}
) {
  if (allowInvalid == null) allowInvalid = _allowInvalid;
   if (allowInvalid) {
    return const AsciiDecoder(allowInvalid: true).convert(bytes);
    }
   else {
    return const AsciiDecoder(allowInvalid: false).convert(bytes);
    }
  }
 AsciiEncoder get encoder => const AsciiEncoder();
 AsciiDecoder get decoder => _allowInvalid ? const AsciiDecoder(allowInvalid: true) : const AsciiDecoder(allowInvalid: false);
}
 class _UnicodeSubsetEncoder extends Converter<String, List<int>> {final int _subsetMask;
 const _UnicodeSubsetEncoder(this._subsetMask);
 List<int> convert(String string, [int start = 0, int end]) {
int stringLength = string.length;
 RangeError.checkValidRange(start, end, stringLength);
 if (end == null) end = stringLength;
 int length = end - start;
 List result = new Uint8List(length);
 for (int i = 0; i < length; i++) {
  var codeUnit = string.codeUnitAt(start + i);
   if ((codeUnit & ~_subsetMask) != 0) {
    throw new ArgumentError("String contains invalid characters.");
    }
   result[i] = codeUnit;
  }
 return DDC$RT.cast(result, DDC$RT.type((List<dynamic> _) {
  }
), DDC$RT.type((List<int> _) {
  }
), "CastDynamic", """line 96, column 12 of dart:convert/ascii.dart: """, result is List<int>, false);
}
 StringConversionSink startChunkedConversion(Sink<List<int>> sink) {
if (sink is! ByteConversionSink) {
  sink = new ByteConversionSink.from(sink);
  }
 return new _UnicodeSubsetEncoderSink(_subsetMask, DDC$RT.cast(sink, DDC$RT.type((Sink<List<int>> _) {
  }
), ByteConversionSink, "CastGeneral", """line 109, column 55 of dart:convert/ascii.dart: """, sink is ByteConversionSink, true));
}
 Stream<List<int>> bind(Stream<String> stream) => ((__x0) => DDC$RT.cast(__x0, DDC$RT.type((DDC$async$.Stream<dynamic> _) {
}
), DDC$RT.type((DDC$async$.Stream<List<int>> _) {
}
), "CastDynamic", """line 113, column 52 of dart:convert/ascii.dart: """, __x0 is DDC$async$.Stream<List<int>>, false))(super.bind(stream));
}
 class AsciiEncoder extends _UnicodeSubsetEncoder {const AsciiEncoder() : super(_ASCII_MASK);
}
 class _UnicodeSubsetEncoderSink extends StringConversionSinkBase {final ByteConversionSink _sink;
 final int _subsetMask;
 _UnicodeSubsetEncoderSink(this._subsetMask, this._sink);
 void close() {
_sink.close();
}
 void addSlice(String source, int start, int end, bool isLast) {
RangeError.checkValidRange(start, end, source.length);
 for (int i = start; i < end; i++) {
int codeUnit = source.codeUnitAt(i);
 if ((codeUnit & ~_subsetMask) != 0) {
throw new ArgumentError("Source contains invalid character with code point: $codeUnit.");
}
}
 _sink.add(source.codeUnits.sublist(start, end));
 if (isLast) {
close();
}
}
}
 abstract class _UnicodeSubsetDecoder extends Converter<List<int>, String> {final bool _allowInvalid;
 final int _subsetMask;
 const _UnicodeSubsetDecoder(this._allowInvalid, this._subsetMask);
 String convert(List<int> bytes, [int start = 0, int end]) {
int byteCount = bytes.length;
 RangeError.checkValidRange(start, end, byteCount);
 if (end == null) end = byteCount;
 int length = end - start;
 for (int i = start; i < end; i++) {
int byte = bytes[i];
 if ((byte & ~_subsetMask) != 0) {
if (!_allowInvalid) {
throw new FormatException("Invalid value in input: $byte");
}
 return _convertInvalid(bytes, start, end);
}
}
 return new String.fromCharCodes(bytes, start, end);
}
 String _convertInvalid(List<int> bytes, int start, int end) {
StringBuffer buffer = new StringBuffer();
 for (int i = start; i < end; i++) {
int value = bytes[i];
 if ((value & ~_subsetMask) != 0) value = 0xFFFD;
 buffer.writeCharCode(value);
}
 return buffer.toString();
}
 ByteConversionSink startChunkedConversion(Sink<String> sink);
 Stream<String> bind(Stream<List<int>> stream) => ((__x1) => DDC$RT.cast(__x1, DDC$RT.type((DDC$async$.Stream<dynamic> _) {
}
), DDC$RT.type((DDC$async$.Stream<String> _) {
}
), "CastDynamic", """line 221, column 52 of dart:convert/ascii.dart: """, __x1 is DDC$async$.Stream<String>, false))(super.bind(stream));
}
 class AsciiDecoder extends _UnicodeSubsetDecoder {const AsciiDecoder({
bool allowInvalid : false}
) : super(allowInvalid, _ASCII_MASK);
 ByteConversionSink startChunkedConversion(Sink<String> sink) {
StringConversionSink stringSink;
 if (sink is StringConversionSink) {
stringSink = sink;
}
 else {
stringSink = new StringConversionSink.from(sink);
}
 if (_allowInvalid) {
return new _ErrorHandlingAsciiDecoderSink(stringSink.asUtf8Sink(false));
}
 else {
return new _SimpleAsciiDecoderSink(stringSink);
}
}
}
 class _ErrorHandlingAsciiDecoderSink extends ByteConversionSinkBase {ByteConversionSink _utf8Sink;
 _ErrorHandlingAsciiDecoderSink(this._utf8Sink);
 void close() {
_utf8Sink.close();
}
 void add(List<int> source) {
addSlice(source, 0, source.length, false);
}
 void addSlice(List<int> source, int start, int end, bool isLast) {
RangeError.checkValidRange(start, end, source.length);
 for (int i = start; i < end; i++) {
if ((source[i] & ~_ASCII_MASK) != 0) {
if (i > start) _utf8Sink.addSlice(source, start, i, false);
 _utf8Sink.add(const <int> [0xEF, 0xBF, 0xBD]);
 start = i + 1;
}
}
 if (start < end) {
_utf8Sink.addSlice(source, start, end, isLast);
}
 else if (isLast) {
close();
}
}
}
 class _SimpleAsciiDecoderSink extends ByteConversionSinkBase {Sink _sink;
 _SimpleAsciiDecoderSink(this._sink);
 void close() {
_sink.close();
}
 void add(List<int> source) {
for (int i = 0; i < source.length; i++) {
if ((source[i] & ~_ASCII_MASK) != 0) {
throw new FormatException("Source contains non-ASCII bytes.");
}
}
 _sink.add(new String.fromCharCodes(source));
}
 void addSlice(List<int> source, int start, int end, bool isLast) {
final int length = source.length;
 RangeError.checkValidRange(start, end, length);
 if (start < end) {
if (start != 0 || end != length) {
source = source.sublist(start, end);
}
 add(source);
}
 if (isLast) close();
}
}
