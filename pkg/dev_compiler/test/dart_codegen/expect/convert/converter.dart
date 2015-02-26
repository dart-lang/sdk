part of dart.convert;
 abstract class Converter<S, T> implements StreamTransformer {const Converter();
 T convert(S input);
 Converter<S, dynamic> fuse(Converter<T, dynamic> other) {
  return new _FusedConverter<S, T, dynamic>(this, other);
  }
 ChunkedConversionSink startChunkedConversion(Sink sink) {
  throw new UnsupportedError("This converter does not support chunked conversions: $this");
  }
 Stream bind(Stream source) {
  return new Stream.eventTransformed(source, (EventSink sink) => new _ConverterStreamEventSink(this, sink));
  }
}
 class _FusedConverter<S, M, T> extends Converter<S, T> {final Converter _first;
 final Converter _second;
 _FusedConverter(this._first, this._second);
 T convert(S input) => ((__x4) => DDC$RT.cast(__x4, dynamic, T, "CastGeneral", """line 58, column 25 of dart:convert/converter.dart: """, __x4 is T, false))(_second.convert(_first.convert(input)));
 ChunkedConversionSink startChunkedConversion(Sink sink) {
return _first.startChunkedConversion(_second.startChunkedConversion(sink));
}
}
