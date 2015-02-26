part of dart.convert;
 const Latin1Codec LATIN1 = const Latin1Codec();
 const int _LATIN1_MASK = 0xFF;
 class Latin1Codec extends Encoding {final bool _allowInvalid;
 const Latin1Codec({
  bool allowInvalid : false}
) : _allowInvalid = allowInvalid;
 String get name => "iso-8859-1";
 String decode(List<int> bytes, {
  bool allowInvalid}
) {
  if (allowInvalid == null) allowInvalid = _allowInvalid;
   if (allowInvalid) {
    return const Latin1Decoder(allowInvalid: true).convert(bytes);
    }
   else {
    return const Latin1Decoder(allowInvalid: false).convert(bytes);
    }
  }
 Converter<String, List<int>> get encoder => const Latin1Encoder();
 Converter<List<int>, String> get decoder => _allowInvalid ? const Latin1Decoder(allowInvalid: true) : const Latin1Decoder(allowInvalid: false);
}
 class Latin1Encoder extends _UnicodeSubsetEncoder {const Latin1Encoder() : super(_LATIN1_MASK);
}
 class Latin1Decoder extends _UnicodeSubsetDecoder {const Latin1Decoder({
bool allowInvalid : false}
) : super(allowInvalid, _LATIN1_MASK);
 ByteConversionSink startChunkedConversion(Sink<String> sink) {
StringConversionSink stringSink;
 if (sink is StringConversionSink) {
stringSink = sink;
}
 else {
stringSink = new StringConversionSink.from(sink);
}
 if (!_allowInvalid) return new _Latin1DecoderSink(stringSink);
 return new _Latin1AllowInvalidDecoderSink(stringSink);
}
}
 class _Latin1DecoderSink extends ByteConversionSinkBase {StringConversionSink _sink;
 _Latin1DecoderSink(this._sink);
 void close() {
_sink.close();
}
 void add(List<int> source) {
addSlice(source, 0, source.length, false);
}
 void _addSliceToSink(List<int> source, int start, int end, bool isLast) {
_sink.add(new String.fromCharCodes(source, start, end));
 if (isLast) close();
}
 void addSlice(List<int> source, int start, int end, bool isLast) {
RangeError.checkValidRange(start, end, source.length);
 for (int i = start;
 i < end;
 i++) {
int char = source[i];
 if (char > _LATIN1_MASK || char < 0) {
throw new FormatException("Source contains non-Latin-1 characters.");
}
}
 if (start < end) {
_addSliceToSink(source, start, end, isLast);
}
 if (isLast) {
close();
}
}
}
 class _Latin1AllowInvalidDecoderSink extends _Latin1DecoderSink {_Latin1AllowInvalidDecoderSink(StringConversionSink sink) : super(sink);
 void addSlice(List<int> source, int start, int end, bool isLast) {
RangeError.checkValidRange(start, end, source.length);
 for (int i = start;
 i < end;
 i++) {
int char = source[i];
 if (char > _LATIN1_MASK || char < 0) {
if (i > start) _addSliceToSink(source, start, i, false);
 _addSliceToSink(((__x26) => DDC$RT.cast(__x26, DDC$RT.type((List<dynamic> _) {
}
), DDC$RT.type((List<int> _) {
}
), "CastLiteral", """line 161, column 25 of dart:convert/latin1.dart: """, __x26 is List<int>, false))(const [0xFFFD]), 0, 1, false);
 start = i + 1;
}
}
 if (start < end) {
_addSliceToSink(source, start, end, isLast);
}
 if (isLast) {
close();
}
}
}
