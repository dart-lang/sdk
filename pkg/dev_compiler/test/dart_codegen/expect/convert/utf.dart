part of dart.convert;
 const int UNICODE_REPLACEMENT_CHARACTER_RUNE = 0xFFFD;
 const int UNICODE_BOM_CHARACTER_RUNE = 0xFEFF;
 const Utf8Codec UTF8 = const Utf8Codec();
 class Utf8Codec extends Encoding {final bool _allowMalformed;
 const Utf8Codec({
  bool allowMalformed : false}
) : _allowMalformed = allowMalformed;
 String get name => "utf-8";
 String decode(List<int> codeUnits, {
  bool allowMalformed}
) {
  if (allowMalformed == null) allowMalformed = _allowMalformed;
   return new Utf8Decoder(allowMalformed: allowMalformed).convert(codeUnits);
  }
 Utf8Encoder get encoder => new Utf8Encoder();
 Utf8Decoder get decoder {
  return new Utf8Decoder(allowMalformed: _allowMalformed);
  }
}
 class Utf8Encoder extends Converter<String, List<int>> {const Utf8Encoder();
 List<int> convert(String string, [int start = 0, int end]) {
int stringLength = string.length;
 RangeError.checkValidRange(start, end, stringLength);
 if (end == null) end = stringLength;
 int length = end - start;
 if (length == 0) return new Uint8List(0);
 _Utf8Encoder encoder = new _Utf8Encoder.withBufferSize(length * 3);
 int endPosition = encoder._fillBuffer(string, start, end);
 assert (endPosition >= end - 1); if (endPosition != end) {
  int lastCodeUnit = string.codeUnitAt(end - 1);
   assert (_isLeadSurrogate(lastCodeUnit)); bool wasCombined = encoder._writeSurrogate(lastCodeUnit, 0);
   assert (!wasCombined);}
 return encoder._buffer.sublist(0, encoder._bufferIndex);
}
 StringConversionSink startChunkedConversion(Sink<List<int>> sink) {
if (sink is! ByteConversionSink) {
  sink = new ByteConversionSink.from(sink);
  }
 return new _Utf8EncoderSink(DEVC$RT.cast(sink, DEVC$RT.type((Sink<List<int>> _) {
  }
), ByteConversionSink, "ImplicitCast", """line 125, column 33 of dart:convert/utf.dart: """, sink is ByteConversionSink, true));
}
 Stream<List<int>> bind(Stream<String> stream) => ((__x25) => DEVC$RT.cast(__x25, DEVC$RT.type((DDC$async$.Stream<dynamic> _) {
}
), DEVC$RT.type((DDC$async$.Stream<List<int>> _) {
}
), "CompositeCast", """line 129, column 52 of dart:convert/utf.dart: """, __x25 is DDC$async$.Stream<List<int>>, false))(super.bind(stream));
}
 class _Utf8Encoder {int _carry = 0;
 int _bufferIndex = 0;
 final List<int> _buffer;
 static const _DEFAULT_BYTE_BUFFER_SIZE = 1024;
 _Utf8Encoder() : this.withBufferSize(_DEFAULT_BYTE_BUFFER_SIZE);
 _Utf8Encoder.withBufferSize(int bufferSize) : _buffer = _createBuffer(bufferSize);
 static List<int> _createBuffer(int size) => new Uint8List(size);
 bool _writeSurrogate(int leadingSurrogate, int nextCodeUnit) {
if (_isTailSurrogate(nextCodeUnit)) {
int rune = _combineSurrogatePair(leadingSurrogate, nextCodeUnit);
 assert (rune > _THREE_BYTE_LIMIT); assert (rune <= _FOUR_BYTE_LIMIT); _buffer[_bufferIndex++] = 0xF0 | (rune >> 18);
 _buffer[_bufferIndex++] = 0x80 | ((rune >> 12) & 0x3f);
 _buffer[_bufferIndex++] = 0x80 | ((rune >> 6) & 0x3f);
 _buffer[_bufferIndex++] = 0x80 | (rune & 0x3f);
 return true;
}
 else {
_buffer[_bufferIndex++] = 0xE0 | (leadingSurrogate >> 12);
 _buffer[_bufferIndex++] = 0x80 | ((leadingSurrogate >> 6) & 0x3f);
 _buffer[_bufferIndex++] = 0x80 | (leadingSurrogate & 0x3f);
 return false;
}
}
 int _fillBuffer(String str, int start, int end) {
if (start != end && _isLeadSurrogate(str.codeUnitAt(end - 1))) {
end--;
}
 int stringIndex;
 for (stringIndex = start; stringIndex < end; stringIndex++) {
int codeUnit = str.codeUnitAt(stringIndex);
 if (codeUnit <= _ONE_BYTE_LIMIT) {
  if (_bufferIndex >= _buffer.length) break;
   _buffer[_bufferIndex++] = codeUnit;
  }
 else if (_isLeadSurrogate(codeUnit)) {
  if (_bufferIndex + 3 >= _buffer.length) break;
   int nextCodeUnit = str.codeUnitAt(stringIndex + 1);
   bool wasCombined = _writeSurrogate(codeUnit, nextCodeUnit);
   if (wasCombined) stringIndex++;
  }
 else {
  int rune = codeUnit;
   if (rune <= _TWO_BYTE_LIMIT) {
    if (_bufferIndex + 1 >= _buffer.length) break;
     _buffer[_bufferIndex++] = 0xC0 | (rune >> 6);
     _buffer[_bufferIndex++] = 0x80 | (rune & 0x3f);
    }
   else {
    assert (rune <= _THREE_BYTE_LIMIT); if (_bufferIndex + 2 >= _buffer.length) break;
     _buffer[_bufferIndex++] = 0xE0 | (rune >> 12);
     _buffer[_bufferIndex++] = 0x80 | ((rune >> 6) & 0x3f);
     _buffer[_bufferIndex++] = 0x80 | (rune & 0x3f);
    }
  }
}
 return stringIndex;
}
}
 class _Utf8EncoderSink extends _Utf8Encoder with StringConversionSinkMixin {final ByteConversionSink _sink;
 _Utf8EncoderSink(this._sink);
 void close() {
if (_carry != 0) {
addSlice("", 0, 0, true);
 return;}
 _sink.close();
}
 void addSlice(String str, int start, int end, bool isLast) {
_bufferIndex = 0;
 if (start == end && !isLast) {
return;}
 if (_carry != 0) {
int nextCodeUnit = 0;
 if (start != end) {
nextCodeUnit = str.codeUnitAt(start);
}
 else {
assert (isLast);}
 bool wasCombined = _writeSurrogate(_carry, nextCodeUnit);
 assert (!wasCombined || start != end); if (wasCombined) start++;
 _carry = 0;
}
 do {
start = _fillBuffer(str, start, end);
 bool isLastSlice = isLast && (start == end);
 if (start == end - 1 && _isLeadSurrogate(str.codeUnitAt(start))) {
if (isLast && _bufferIndex < _buffer.length - 3) {
  bool hasBeenCombined = _writeSurrogate(str.codeUnitAt(start), 0);
   assert (!hasBeenCombined);}
 else {
  _carry = str.codeUnitAt(start);
  }
 start++;
}
 _sink.addSlice(_buffer, 0, _bufferIndex, isLastSlice);
 _bufferIndex = 0;
}
 while (start < end); if (isLast) close();
}
}
 class Utf8Decoder extends Converter<List<int>, String> {final bool _allowMalformed;
 const Utf8Decoder({
bool allowMalformed : false}
) : this._allowMalformed = allowMalformed;
 String convert(List<int> codeUnits, [int start = 0, int end]) {
int length = codeUnits.length;
 RangeError.checkValidRange(start, end, length);
 if (end == null) end = length;
 StringBuffer buffer = new StringBuffer();
 _Utf8Decoder decoder = new _Utf8Decoder(buffer, _allowMalformed);
 decoder.convert(codeUnits, start, end);
 decoder.close();
 return buffer.toString();
}
 ByteConversionSink startChunkedConversion(Sink<String> sink) {
StringConversionSink stringSink;
 if (sink is StringConversionSink) {
stringSink = sink;
}
 else {
stringSink = new StringConversionSink.from(sink);
}
 return stringSink.asUtf8Sink(_allowMalformed);
}
 Stream<String> bind(Stream<List<int>> stream) => ((__x26) => DEVC$RT.cast(__x26, DEVC$RT.type((DDC$async$.Stream<dynamic> _) {
}
), DEVC$RT.type((DDC$async$.Stream<String> _) {
}
), "CompositeCast", """line 361, column 52 of dart:convert/utf.dart: """, __x26 is DDC$async$.Stream<String>, false))(super.bind(stream));
 external Converter<List<int>, dynamic> fuse(Converter<String, dynamic> next);
}
 const int _ONE_BYTE_LIMIT = 0x7f;
 const int _TWO_BYTE_LIMIT = 0x7ff;
 const int _THREE_BYTE_LIMIT = 0xffff;
 const int _FOUR_BYTE_LIMIT = 0x10ffff;
 const int _SURROGATE_MASK = 0xF800;
 const int _SURROGATE_TAG_MASK = 0xFC00;
 const int _SURROGATE_VALUE_MASK = 0x3FF;
 const int _LEAD_SURROGATE_MIN = 0xD800;
 const int _TAIL_SURROGATE_MIN = 0xDC00;
 bool _isSurrogate(int codeUnit) => (codeUnit & _SURROGATE_MASK) == _LEAD_SURROGATE_MIN;
 bool _isLeadSurrogate(int codeUnit) => (codeUnit & _SURROGATE_TAG_MASK) == _LEAD_SURROGATE_MIN;
 bool _isTailSurrogate(int codeUnit) => (codeUnit & _SURROGATE_TAG_MASK) == _TAIL_SURROGATE_MIN;
 int _combineSurrogatePair(int lead, int tail) => 0x10000 + ((lead & _SURROGATE_VALUE_MASK) << 10) | (tail & _SURROGATE_VALUE_MASK);
 class _Utf8Decoder {final bool _allowMalformed;
 final StringSink _stringSink;
 bool _isFirstCharacter = true;
 int _value = 0;
 int _expectedUnits = 0;
 int _extraUnits = 0;
 _Utf8Decoder(this._stringSink, this._allowMalformed);
 bool get hasPartialInput => _expectedUnits > 0;
 static const List<int> _LIMITS = const <int> [_ONE_BYTE_LIMIT, _TWO_BYTE_LIMIT, _THREE_BYTE_LIMIT, _FOUR_BYTE_LIMIT];
 void close() {
flush();
}
 void flush() {
if (hasPartialInput) {
if (!_allowMalformed) {
throw new FormatException("Unfinished UTF-8 octet sequence");
}
 _stringSink.writeCharCode(UNICODE_REPLACEMENT_CHARACTER_RUNE);
 _value = 0;
 _expectedUnits = 0;
 _extraUnits = 0;
}
}
 void convert(List<int> codeUnits, int startIndex, int endIndex) {
int value = _value;
 int expectedUnits = _expectedUnits;
 int extraUnits = _extraUnits;
 _value = 0;
 _expectedUnits = 0;
 _extraUnits = 0;
 int scanOneByteCharacters(units, int from) {
final to = endIndex;
 final mask = _ONE_BYTE_LIMIT;
 for (var i = from; i < to; i++) {
final unit = units[i];
 if ((unit & mask) != unit) return i - from;
}
 return to - from;
}
 void addSingleBytes(int from, int to) {
assert (from >= startIndex && from <= endIndex); assert (to >= startIndex && to <= endIndex); _stringSink.write(new String.fromCharCodes(codeUnits, from, to));
}
 int i = startIndex;
 loop: while (true) {
multibyte: if (expectedUnits > 0) {
do {
if (i == endIndex) {
break loop;
}
 int unit = codeUnits[i];
 if ((unit & 0xC0) != 0x80) {
expectedUnits = 0;
 if (!_allowMalformed) {
  throw new FormatException("Bad UTF-8 encoding 0x${unit.toRadixString(16)}");
  }
 _isFirstCharacter = false;
 _stringSink.writeCharCode(UNICODE_REPLACEMENT_CHARACTER_RUNE);
 break multibyte;
}
 else {
value = (value << 6) | (unit & 0x3f);
 expectedUnits--;
 i++;
}
}
 while (expectedUnits > 0); if (value <= _LIMITS[extraUnits - 1]) {
if (!_allowMalformed) {
throw new FormatException("Overlong encoding of 0x${value.toRadixString(16)}");
}
 expectedUnits = extraUnits = 0;
 value = UNICODE_REPLACEMENT_CHARACTER_RUNE;
}
 if (value > _FOUR_BYTE_LIMIT) {
if (!_allowMalformed) {
throw new FormatException("Character outside valid Unicode range: " "0x${value.toRadixString(16)}");
}
 value = UNICODE_REPLACEMENT_CHARACTER_RUNE;
}
 if (!_isFirstCharacter || value != UNICODE_BOM_CHARACTER_RUNE) {
_stringSink.writeCharCode(value);
}
 _isFirstCharacter = false;
}
 while (i < endIndex) {
int oneBytes = scanOneByteCharacters(codeUnits, i);
 if (oneBytes > 0) {
_isFirstCharacter = false;
 addSingleBytes(i, i + oneBytes);
 i += oneBytes;
 if (i == endIndex) break;
}
 int unit = codeUnits[i++];
 if (unit < 0) {
if (!_allowMalformed) {
throw new FormatException("Negative UTF-8 code unit: -0x${(-unit).toRadixString(16)}");
}
 _stringSink.writeCharCode(UNICODE_REPLACEMENT_CHARACTER_RUNE);
}
 else {
assert (unit > _ONE_BYTE_LIMIT); if ((unit & 0xE0) == 0xC0) {
value = unit & 0x1F;
 expectedUnits = extraUnits = 1;
 continue loop;
}
 if ((unit & 0xF0) == 0xE0) {
value = unit & 0x0F;
 expectedUnits = extraUnits = 2;
 continue loop;
}
 if ((unit & 0xF8) == 0xF0 && unit < 0xF5) {
value = unit & 0x07;
 expectedUnits = extraUnits = 3;
 continue loop;
}
 if (!_allowMalformed) {
throw new FormatException("Bad UTF-8 encoding 0x${unit.toRadixString(16)}");
}
 value = UNICODE_REPLACEMENT_CHARACTER_RUNE;
 expectedUnits = extraUnits = 0;
 _isFirstCharacter = false;
 _stringSink.writeCharCode(value);
}
}
 break loop;
}
 if (expectedUnits > 0) {
_value = value;
 _expectedUnits = expectedUnits;
 _extraUnits = extraUnits;
}
}
}
