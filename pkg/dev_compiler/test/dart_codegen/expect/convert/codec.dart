part of dart.convert;
 abstract class Codec<S, T> {const Codec();
 T encode(S input) => encoder.convert(input);
 S decode(T encoded) => decoder.convert(encoded);
 Converter<S, T> get encoder;
 Converter<T, S> get decoder;
 Codec<S, dynamic> fuse(Codec<T, dynamic> other) {
  return new _FusedCodec<S, T, dynamic>(this, other);
  }
 Codec<T, S> get inverted => new _InvertedCodec<T, S>(this);
}
 class _FusedCodec<S, M, T> extends Codec<S, T> {final Codec<S, M> _first;
 final Codec<M, T> _second;
 Converter<S, T> get encoder => ((__x2) => DEVC$RT.cast(__x2, DEVC$RT.type((Converter<S, dynamic> _) {
}
), DEVC$RT.type((Converter<S, T> _) {
}
), "CompositeCast", """line 87, column 34 of dart:convert/codec.dart: """, __x2 is Converter<S, T>, false))(_first.encoder.fuse(_second.encoder));
 Converter<T, S> get decoder => ((__x3) => DEVC$RT.cast(__x3, DEVC$RT.type((Converter<T, dynamic> _) {
}
), DEVC$RT.type((Converter<T, S> _) {
}
), "CompositeCast", """line 88, column 34 of dart:convert/codec.dart: """, __x3 is Converter<T, S>, false))(_second.decoder.fuse(_first.decoder));
 _FusedCodec(this._first, this._second);
}
 class _InvertedCodec<T, S> extends Codec<T, S> {final Codec<S, T> _codec;
 _InvertedCodec(Codec<S, T> codec) : _codec = codec;
 Converter<T, S> get encoder => _codec.decoder;
 Converter<S, T> get decoder => _codec.encoder;
 Codec<S, T> get inverted => _codec;
}
