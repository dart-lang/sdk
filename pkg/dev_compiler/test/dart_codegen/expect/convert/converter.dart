part of dart.convert;
 abstract class Converter<S, T> implements StreamTransformer<S, T> {const Converter();
 T convert(S input);
 Converter<S, dynamic> fuse(Converter<T, dynamic> other) {
  return new _FusedConverter<S, T, dynamic>(this, other);
  }
 ChunkedConversionSink startChunkedConversion(Sink<T> sink) {
  throw new UnsupportedError("This converter does not support chunked conversions: $this");
  }
 Stream<T> bind(Stream<S> source) {
  return new Stream<T>.eventTransformed(source, (EventSink sink) => new _ConverterStreamEventSink(this, sink));
  }
}
 class _FusedConverter<S, M, T> extends Converter<S, T> {final Converter _first;
 final Converter _second;
 _FusedConverter(this._first, this._second);
 T convert(S input) => ((__x2) => DEVC$RT.cast(__x2, dynamic, T, "CompositeCast", """line 58, column 25 of dart:convert/converter.dart: """, __x2 is T, false))(_second.convert(_first.convert(input)));
 ChunkedConversionSink startChunkedConversion(Sink<T> sink) {
return _first.startChunkedConversion(_second.startChunkedConversion(sink));
}
}
