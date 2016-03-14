dart_library.library('dart/convert', null, /* Imports */[
  'dart/_runtime',
  'dart/core',
  'dart/async',
  'dart/typed_data',
  'dart/_internal',
  'dart/collection'
], /* Lazy imports */[
], function(exports, dart, core, async, typed_data, _internal, collection) {
  'use strict';
  let dartx = dart.dartx;
  const _allowInvalid = Symbol('_allowInvalid');
  const Codec$ = dart.generic(function(S, T) {
    class Codec extends core.Object {
      Codec() {
      }
      encode(input) {
        dart.as(input, S);
        return this.encoder.convert(input);
      }
      decode(encoded) {
        dart.as(encoded, T);
        return this.decoder.convert(encoded);
      }
      fuse(other) {
        dart.as(other, Codec$(T, dart.dynamic));
        return new (_FusedCodec$(S, T, dart.dynamic))(this, other);
      }
      get inverted() {
        return new (_InvertedCodec$(T, S))(this);
      }
    }
    dart.setSignature(Codec, {
      constructors: () => ({Codec: [Codec$(S, T), []]}),
      methods: () => ({
        encode: [T, [S]],
        decode: [S, [T]],
        fuse: [Codec$(S, dart.dynamic), [Codec$(T, dart.dynamic)]]
      })
    });
    return Codec;
  });
  let Codec = Codec$();
  class Encoding extends Codec$(core.String, core.List$(core.int)) {
    Encoding() {
      super.Codec();
    }
    decodeStream(byteStream) {
      return byteStream.transform(this.decoder).fold(new core.StringBuffer(), dart.fn((buffer, string) => ((() => {
        dart.dsend(buffer, 'write', string);
        return buffer;
      })()))).then(dart.fn(buffer => dart.toString(buffer), core.String, [dart.dynamic]));
    }
    static getByName(name) {
      if (name == null) return null;
      name = name[dartx.toLowerCase]();
      return Encoding._nameToEncoding[dartx.get](name);
    }
  }
  dart.setSignature(Encoding, {
    constructors: () => ({Encoding: [Encoding, []]}),
    methods: () => ({decodeStream: [async.Future$(core.String), [async.Stream$(core.List$(core.int))]]}),
    statics: () => ({getByName: [Encoding, [core.String]]}),
    names: ['getByName']
  });
  dart.defineLazyProperties(Encoding, {
    get _nameToEncoding() {
      return dart.map({"iso_8859-1:1987": LATIN1, "iso-ir-100": LATIN1, "iso_8859-1": LATIN1, "iso-8859-1": LATIN1, latin1: LATIN1, l1: LATIN1, ibm819: LATIN1, cp819: LATIN1, csisolatin1: LATIN1, "iso-ir-6": ASCII, "ansi_x3.4-1968": ASCII, "ansi_x3.4-1986": ASCII, "iso_646.irv:1991": ASCII, "iso646-us": ASCII, "us-ascii": ASCII, us: ASCII, ibm367: ASCII, cp367: ASCII, csascii: ASCII, ascii: ASCII, csutf8: UTF8, "utf-8": UTF8}, core.String, Encoding);
    },
    set _nameToEncoding(_) {}
  });
  class AsciiCodec extends Encoding {
    AsciiCodec(opts) {
      let allowInvalid = opts && 'allowInvalid' in opts ? opts.allowInvalid : false;
      this[_allowInvalid] = allowInvalid;
      super.Encoding();
    }
    get name() {
      return "us-ascii";
    }
    decode(bytes, opts) {
      let allowInvalid = opts && 'allowInvalid' in opts ? opts.allowInvalid : null;
      if (allowInvalid == null) allowInvalid = this[_allowInvalid];
      if (dart.notNull(allowInvalid)) {
        return dart.const(new AsciiDecoder({allowInvalid: true})).convert(bytes);
      } else {
        return dart.const(new AsciiDecoder({allowInvalid: false})).convert(bytes);
      }
    }
    get encoder() {
      return dart.const(new AsciiEncoder());
    }
    get decoder() {
      return dart.notNull(this[_allowInvalid]) ? dart.const(new AsciiDecoder({allowInvalid: true})) : dart.const(new AsciiDecoder({allowInvalid: false}));
    }
  }
  dart.setSignature(AsciiCodec, {
    constructors: () => ({AsciiCodec: [AsciiCodec, [], {allowInvalid: core.bool}]}),
    methods: () => ({decode: [core.String, [core.List$(core.int)], {allowInvalid: core.bool}]})
  });
  const ASCII = dart.const(new AsciiCodec());
  const _ASCII_MASK = 127;
  const _subsetMask = Symbol('_subsetMask');
  const Converter$ = dart.generic(function(S, T) {
    class Converter extends core.Object {
      Converter() {
      }
      fuse(other) {
        dart.as(other, Converter$(T, dart.dynamic));
        return new (_FusedConverter$(S, T, dart.dynamic))(this, other);
      }
      startChunkedConversion(sink) {
        dart.as(sink, core.Sink$(T));
        dart.throw(new core.UnsupportedError(`This converter does not support chunked conversions: ${this}`));
      }
      bind(source) {
        dart.as(source, async.Stream$(S));
        return async.Stream$(T).eventTransformed(source, dart.fn(sink => new _ConverterStreamEventSink(this, sink), _ConverterStreamEventSink, [async.EventSink]));
      }
    }
    Converter[dart.implements] = () => [async.StreamTransformer$(S, T)];
    dart.setSignature(Converter, {
      constructors: () => ({Converter: [Converter$(S, T), []]}),
      methods: () => ({
        fuse: [Converter$(S, dart.dynamic), [Converter$(T, dart.dynamic)]],
        startChunkedConversion: [ChunkedConversionSink, [core.Sink$(T)]],
        bind: [async.Stream$(T), [async.Stream$(S)]]
      })
    });
    return Converter;
  });
  let Converter = Converter$();
  class _UnicodeSubsetEncoder extends Converter$(core.String, core.List$(core.int)) {
    _UnicodeSubsetEncoder(subsetMask) {
      this[_subsetMask] = subsetMask;
      super.Converter();
    }
    convert(string, start, end) {
      if (start === void 0) start = 0;
      if (end === void 0) end = null;
      let stringLength = string[dartx.length];
      core.RangeError.checkValidRange(start, end, stringLength);
      if (end == null) end = stringLength;
      let length = dart.notNull(end) - dart.notNull(start);
      let result = typed_data.Uint8List.new(length);
      for (let i = 0; i < length; i++) {
        let codeUnit = string[dartx.codeUnitAt](dart.notNull(start) + i);
        if ((dart.notNull(codeUnit) & ~dart.notNull(this[_subsetMask])) != 0) {
          dart.throw(new core.ArgumentError("String contains invalid characters."));
        }
        result[dartx.set](i, codeUnit);
      }
      return dart.as(result, core.List$(core.int));
    }
    startChunkedConversion(sink) {
      if (!dart.is(sink, ByteConversionSink)) {
        sink = ByteConversionSink.from(sink);
      }
      return new _UnicodeSubsetEncoderSink(this[_subsetMask], dart.as(sink, ByteConversionSink));
    }
    bind(stream) {
      return super.bind(stream);
    }
  }
  dart.setSignature(_UnicodeSubsetEncoder, {
    constructors: () => ({_UnicodeSubsetEncoder: [_UnicodeSubsetEncoder, [core.int]]}),
    methods: () => ({
      convert: [core.List$(core.int), [core.String], [core.int, core.int]],
      startChunkedConversion: [StringConversionSink, [core.Sink$(core.List$(core.int))]],
      bind: [async.Stream$(core.List$(core.int)), [async.Stream$(core.String)]]
    })
  });
  class AsciiEncoder extends _UnicodeSubsetEncoder {
    AsciiEncoder() {
      super._UnicodeSubsetEncoder(_ASCII_MASK);
    }
  }
  dart.setSignature(AsciiEncoder, {
    constructors: () => ({AsciiEncoder: [AsciiEncoder, []]})
  });
  const _sink = Symbol('_sink');
  class StringConversionSinkMixin extends core.Object {
    add(str) {
      return this.addSlice(str, 0, str[dartx.length], false);
    }
    asUtf8Sink(allowMalformed) {
      return new _Utf8ConversionSink(this, allowMalformed);
    }
    asStringSink() {
      return new _StringConversionSinkAsStringSinkAdapter(this);
    }
  }
  StringConversionSinkMixin[dart.implements] = () => [StringConversionSink];
  dart.setSignature(StringConversionSinkMixin, {
    methods: () => ({
      add: [dart.void, [core.String]],
      asUtf8Sink: [ByteConversionSink, [core.bool]],
      asStringSink: [ClosableStringSink, []]
    })
  });
  class StringConversionSinkBase extends StringConversionSinkMixin {}
  class _UnicodeSubsetEncoderSink extends StringConversionSinkBase {
    _UnicodeSubsetEncoderSink(subsetMask, sink) {
      this[_subsetMask] = subsetMask;
      this[_sink] = sink;
    }
    close() {
      this[_sink].close();
    }
    addSlice(source, start, end, isLast) {
      core.RangeError.checkValidRange(start, end, source[dartx.length]);
      for (let i = start; dart.notNull(i) < dart.notNull(end); i = dart.notNull(i) + 1) {
        let codeUnit = source[dartx.codeUnitAt](i);
        if ((dart.notNull(codeUnit) & ~dart.notNull(this[_subsetMask])) != 0) {
          dart.throw(new core.ArgumentError(`Source contains invalid character with code point: ${codeUnit}.`));
        }
      }
      this[_sink].add(source[dartx.codeUnits][dartx.sublist](start, end));
      if (dart.notNull(isLast)) {
        this.close();
      }
    }
  }
  dart.setSignature(_UnicodeSubsetEncoderSink, {
    constructors: () => ({_UnicodeSubsetEncoderSink: [_UnicodeSubsetEncoderSink, [core.int, ByteConversionSink]]}),
    methods: () => ({
      close: [dart.void, []],
      addSlice: [dart.void, [core.String, core.int, core.int, core.bool]]
    })
  });
  const _convertInvalid = Symbol('_convertInvalid');
  class _UnicodeSubsetDecoder extends Converter$(core.List$(core.int), core.String) {
    _UnicodeSubsetDecoder(allowInvalid, subsetMask) {
      this[_allowInvalid] = allowInvalid;
      this[_subsetMask] = subsetMask;
      super.Converter();
    }
    convert(bytes, start, end) {
      if (start === void 0) start = 0;
      if (end === void 0) end = null;
      let byteCount = bytes[dartx.length];
      core.RangeError.checkValidRange(start, end, byteCount);
      if (end == null) end = byteCount;
      let length = dart.notNull(end) - dart.notNull(start);
      for (let i = start; dart.notNull(i) < dart.notNull(end); i = dart.notNull(i) + 1) {
        let byte = bytes[dartx.get](i);
        if ((dart.notNull(byte) & ~dart.notNull(this[_subsetMask])) != 0) {
          if (!dart.notNull(this[_allowInvalid])) {
            dart.throw(new core.FormatException(`Invalid value in input: ${byte}`));
          }
          return this[_convertInvalid](bytes, start, end);
        }
      }
      return core.String.fromCharCodes(bytes, start, end);
    }
    [_convertInvalid](bytes, start, end) {
      let buffer = new core.StringBuffer();
      for (let i = start; dart.notNull(i) < dart.notNull(end); i = dart.notNull(i) + 1) {
        let value = bytes[dartx.get](i);
        if ((dart.notNull(value) & ~dart.notNull(this[_subsetMask])) != 0) value = 65533;
        buffer.writeCharCode(value);
      }
      return buffer.toString();
    }
    bind(stream) {
      return super.bind(stream);
    }
  }
  dart.setSignature(_UnicodeSubsetDecoder, {
    constructors: () => ({_UnicodeSubsetDecoder: [_UnicodeSubsetDecoder, [core.bool, core.int]]}),
    methods: () => ({
      convert: [core.String, [core.List$(core.int)], [core.int, core.int]],
      [_convertInvalid]: [core.String, [core.List$(core.int), core.int, core.int]],
      bind: [async.Stream$(core.String), [async.Stream$(core.List$(core.int))]]
    })
  });
  class AsciiDecoder extends _UnicodeSubsetDecoder {
    AsciiDecoder(opts) {
      let allowInvalid = opts && 'allowInvalid' in opts ? opts.allowInvalid : false;
      super._UnicodeSubsetDecoder(allowInvalid, _ASCII_MASK);
    }
    startChunkedConversion(sink) {
      let stringSink = null;
      if (dart.is(sink, StringConversionSink)) {
        stringSink = sink;
      } else {
        stringSink = StringConversionSink.from(sink);
      }
      if (dart.notNull(this[_allowInvalid])) {
        return new _ErrorHandlingAsciiDecoderSink(stringSink.asUtf8Sink(false));
      } else {
        return new _SimpleAsciiDecoderSink(stringSink);
      }
    }
  }
  dart.setSignature(AsciiDecoder, {
    constructors: () => ({AsciiDecoder: [AsciiDecoder, [], {allowInvalid: core.bool}]}),
    methods: () => ({startChunkedConversion: [ByteConversionSink, [core.Sink$(core.String)]]})
  });
  const _utf8Sink = Symbol('_utf8Sink');
  const ChunkedConversionSink$ = dart.generic(function(T) {
    class ChunkedConversionSink extends core.Object {
      ChunkedConversionSink() {
      }
      static withCallback(callback) {
        return new (_SimpleCallbackSink$(T))(callback);
      }
    }
    ChunkedConversionSink[dart.implements] = () => [core.Sink$(T)];
    dart.setSignature(ChunkedConversionSink, {
      constructors: () => ({
        ChunkedConversionSink: [ChunkedConversionSink$(T), []],
        withCallback: [ChunkedConversionSink$(T), [dart.functionType(dart.void, [core.List$(T)])]]
      })
    });
    return ChunkedConversionSink;
  });
  let ChunkedConversionSink = ChunkedConversionSink$();
  class ByteConversionSink extends ChunkedConversionSink$(core.List$(core.int)) {
    ByteConversionSink() {
      super.ChunkedConversionSink();
    }
    static withCallback(callback) {
      return new _ByteCallbackSink(callback);
    }
    static from(sink) {
      return new _ByteAdapterSink(sink);
    }
  }
  dart.setSignature(ByteConversionSink, {
    constructors: () => ({
      ByteConversionSink: [ByteConversionSink, []],
      withCallback: [ByteConversionSink, [dart.functionType(dart.void, [core.List$(core.int)])]],
      from: [ByteConversionSink, [core.Sink$(core.List$(core.int))]]
    })
  });
  class ByteConversionSinkBase extends ByteConversionSink {
    ByteConversionSinkBase() {
      super.ByteConversionSink();
    }
    addSlice(chunk, start, end, isLast) {
      this.add(chunk[dartx.sublist](start, end));
      if (dart.notNull(isLast)) this.close();
    }
  }
  dart.setSignature(ByteConversionSinkBase, {
    methods: () => ({addSlice: [dart.void, [core.List$(core.int), core.int, core.int, core.bool]]})
  });
  class _ErrorHandlingAsciiDecoderSink extends ByteConversionSinkBase {
    _ErrorHandlingAsciiDecoderSink(utf8Sink) {
      this[_utf8Sink] = utf8Sink;
    }
    close() {
      this[_utf8Sink].close();
    }
    add(source) {
      this.addSlice(source, 0, source[dartx.length], false);
    }
    addSlice(source, start, end, isLast) {
      core.RangeError.checkValidRange(start, end, source[dartx.length]);
      for (let i = start; dart.notNull(i) < dart.notNull(end); i = dart.notNull(i) + 1) {
        if ((dart.notNull(source[dartx.get](i)) & ~dart.notNull(_ASCII_MASK)) != 0) {
          if (dart.notNull(i) > dart.notNull(start)) this[_utf8Sink].addSlice(source, start, i, false);
          this[_utf8Sink].add(dart.const(dart.list([239, 191, 189], core.int)));
          start = dart.notNull(i) + 1;
        }
      }
      if (dart.notNull(start) < dart.notNull(end)) {
        this[_utf8Sink].addSlice(source, start, end, isLast);
      } else if (dart.notNull(isLast)) {
        this.close();
      }
    }
  }
  dart.setSignature(_ErrorHandlingAsciiDecoderSink, {
    constructors: () => ({_ErrorHandlingAsciiDecoderSink: [_ErrorHandlingAsciiDecoderSink, [ByteConversionSink]]}),
    methods: () => ({
      close: [dart.void, []],
      add: [dart.void, [core.List$(core.int)]]
    })
  });
  class _SimpleAsciiDecoderSink extends ByteConversionSinkBase {
    _SimpleAsciiDecoderSink(sink) {
      this[_sink] = sink;
    }
    close() {
      this[_sink].close();
    }
    add(source) {
      for (let i = 0; i < dart.notNull(source[dartx.length]); i++) {
        if ((dart.notNull(source[dartx.get](i)) & ~dart.notNull(_ASCII_MASK)) != 0) {
          dart.throw(new core.FormatException("Source contains non-ASCII bytes."));
        }
      }
      this[_sink].add(core.String.fromCharCodes(source));
    }
    addSlice(source, start, end, isLast) {
      let length = source[dartx.length];
      core.RangeError.checkValidRange(start, end, length);
      if (dart.notNull(start) < dart.notNull(end)) {
        if (start != 0 || end != length) {
          source = source[dartx.sublist](start, end);
        }
        this.add(source);
      }
      if (dart.notNull(isLast)) this.close();
    }
  }
  dart.setSignature(_SimpleAsciiDecoderSink, {
    constructors: () => ({_SimpleAsciiDecoderSink: [_SimpleAsciiDecoderSink, [core.Sink]]}),
    methods: () => ({
      close: [dart.void, []],
      add: [dart.void, [core.List$(core.int)]]
    })
  });
  class _ByteAdapterSink extends ByteConversionSinkBase {
    _ByteAdapterSink(sink) {
      this[_sink] = sink;
    }
    add(chunk) {
      return this[_sink].add(chunk);
    }
    close() {
      return this[_sink].close();
    }
  }
  dart.setSignature(_ByteAdapterSink, {
    constructors: () => ({_ByteAdapterSink: [_ByteAdapterSink, [core.Sink$(core.List$(core.int))]]}),
    methods: () => ({
      add: [dart.void, [core.List$(core.int)]],
      close: [dart.void, []]
    })
  });
  const _buffer = Symbol('_buffer');
  const _callback = Symbol('_callback');
  const _bufferIndex = Symbol('_bufferIndex');
  class _ByteCallbackSink extends ByteConversionSinkBase {
    _ByteCallbackSink(callback) {
      this[_buffer] = typed_data.Uint8List.new(_ByteCallbackSink._INITIAL_BUFFER_SIZE);
      this[_callback] = callback;
      this[_bufferIndex] = 0;
    }
    add(chunk) {
      let freeCount = dart.notNull(this[_buffer][dartx.length]) - dart.notNull(this[_bufferIndex]);
      if (dart.notNull(chunk[dartx.length]) > freeCount) {
        let oldLength = this[_buffer][dartx.length];
        let newLength = dart.notNull(_ByteCallbackSink._roundToPowerOf2(dart.notNull(chunk[dartx.length]) + dart.notNull(oldLength))) * 2;
        let grown = typed_data.Uint8List.new(newLength);
        grown[dartx.setRange](0, this[_buffer][dartx.length], this[_buffer]);
        this[_buffer] = grown;
      }
      this[_buffer][dartx.setRange](this[_bufferIndex], dart.notNull(this[_bufferIndex]) + dart.notNull(chunk[dartx.length]), chunk);
      this[_bufferIndex] = dart.notNull(this[_bufferIndex]) + dart.notNull(chunk[dartx.length]);
    }
    static _roundToPowerOf2(v) {
      dart.assert(dart.notNull(v) > 0);
      v = dart.notNull(v) - 1;
      v = dart.notNull(v) | dart.notNull(v) >> 1;
      v = dart.notNull(v) | dart.notNull(v) >> 2;
      v = dart.notNull(v) | dart.notNull(v) >> 4;
      v = dart.notNull(v) | dart.notNull(v) >> 8;
      v = dart.notNull(v) | dart.notNull(v) >> 16;
      v = dart.notNull(v) + 1;
      return v;
    }
    close() {
      this[_callback](this[_buffer][dartx.sublist](0, this[_bufferIndex]));
    }
  }
  dart.setSignature(_ByteCallbackSink, {
    constructors: () => ({_ByteCallbackSink: [_ByteCallbackSink, [dart.functionType(dart.void, [core.List$(core.int)])]]}),
    methods: () => ({
      add: [dart.void, [core.Iterable$(core.int)]],
      close: [dart.void, []]
    }),
    statics: () => ({_roundToPowerOf2: [core.int, [core.int]]}),
    names: ['_roundToPowerOf2']
  });
  _ByteCallbackSink._INITIAL_BUFFER_SIZE = 1024;
  const _ChunkedConversionCallback$ = dart.generic(function(T) {
    const _ChunkedConversionCallback = dart.typedef('_ChunkedConversionCallback', () => dart.functionType(dart.void, [T]));
    return _ChunkedConversionCallback;
  });
  let _ChunkedConversionCallback = _ChunkedConversionCallback$();
  const _accumulated = Symbol('_accumulated');
  const _SimpleCallbackSink$ = dart.generic(function(T) {
    class _SimpleCallbackSink extends ChunkedConversionSink$(T) {
      _SimpleCallbackSink(callback) {
        this[_accumulated] = dart.list([], T);
        this[_callback] = callback;
        super.ChunkedConversionSink();
      }
      add(chunk) {
        dart.as(chunk, T);
        this[_accumulated][dartx.add](chunk);
      }
      close() {
        this[_callback](this[_accumulated]);
      }
    }
    dart.setSignature(_SimpleCallbackSink, {
      constructors: () => ({_SimpleCallbackSink: [_SimpleCallbackSink$(T), [_ChunkedConversionCallback$(core.List$(T))]]}),
      methods: () => ({
        add: [dart.void, [T]],
        close: [dart.void, []]
      })
    });
    return _SimpleCallbackSink;
  });
  let _SimpleCallbackSink = _SimpleCallbackSink$();
  const _EventSinkAdapter$ = dart.generic(function(T) {
    class _EventSinkAdapter extends core.Object {
      _EventSinkAdapter(sink) {
        this[_sink] = sink;
      }
      add(data) {
        dart.as(data, T);
        return this[_sink].add(data);
      }
      close() {
        return this[_sink].close();
      }
    }
    _EventSinkAdapter[dart.implements] = () => [ChunkedConversionSink$(T)];
    dart.setSignature(_EventSinkAdapter, {
      constructors: () => ({_EventSinkAdapter: [_EventSinkAdapter$(T), [async.EventSink$(T)]]}),
      methods: () => ({
        add: [dart.void, [T]],
        close: [dart.void, []]
      })
    });
    return _EventSinkAdapter;
  });
  let _EventSinkAdapter = _EventSinkAdapter$();
  const _eventSink = Symbol('_eventSink');
  const _chunkedSink = Symbol('_chunkedSink');
  const _ConverterStreamEventSink$ = dart.generic(function(S, T) {
    class _ConverterStreamEventSink extends core.Object {
      _ConverterStreamEventSink(converter, sink) {
        this[_eventSink] = sink;
        this[_chunkedSink] = converter.startChunkedConversion(sink);
      }
      add(o) {
        dart.as(o, S);
        return this[_chunkedSink].add(o);
      }
      addError(error, stackTrace) {
        if (stackTrace === void 0) stackTrace = null;
        this[_eventSink].addError(error, stackTrace);
      }
      close() {
        return this[_chunkedSink].close();
      }
    }
    _ConverterStreamEventSink[dart.implements] = () => [async.EventSink$(S)];
    dart.setSignature(_ConverterStreamEventSink, {
      constructors: () => ({_ConverterStreamEventSink: [_ConverterStreamEventSink$(S, T), [Converter, async.EventSink$(T)]]}),
      methods: () => ({
        add: [dart.void, [S]],
        addError: [dart.void, [core.Object], [core.StackTrace]],
        close: [dart.void, []]
      })
    });
    return _ConverterStreamEventSink;
  });
  let _ConverterStreamEventSink = _ConverterStreamEventSink$();
  const _first = Symbol('_first');
  const _second = Symbol('_second');
  const _FusedCodec$ = dart.generic(function(S, M, T) {
    class _FusedCodec extends Codec$(S, T) {
      get encoder() {
        return dart.as(this[_first].encoder.fuse(this[_second].encoder), Converter$(S, T));
      }
      get decoder() {
        return dart.as(this[_second].decoder.fuse(this[_first].decoder), Converter$(T, S));
      }
      _FusedCodec(first, second) {
        this[_first] = first;
        this[_second] = second;
        super.Codec();
      }
    }
    dart.setSignature(_FusedCodec, {
      constructors: () => ({_FusedCodec: [_FusedCodec$(S, M, T), [Codec$(S, M), Codec$(M, T)]]})
    });
    return _FusedCodec;
  });
  let _FusedCodec = _FusedCodec$();
  const _codec = Symbol('_codec');
  const _InvertedCodec$ = dart.generic(function(T, S) {
    class _InvertedCodec extends Codec$(T, S) {
      _InvertedCodec(codec) {
        this[_codec] = codec;
        super.Codec();
      }
      get encoder() {
        return this[_codec].decoder;
      }
      get decoder() {
        return this[_codec].encoder;
      }
      get inverted() {
        return this[_codec];
      }
    }
    dart.setSignature(_InvertedCodec, {
      constructors: () => ({_InvertedCodec: [_InvertedCodec$(T, S), [Codec$(S, T)]]})
    });
    return _InvertedCodec;
  });
  let _InvertedCodec = _InvertedCodec$();
  const _FusedConverter$ = dart.generic(function(S, M, T) {
    class _FusedConverter extends Converter$(S, T) {
      _FusedConverter(first, second) {
        this[_first] = first;
        this[_second] = second;
        super.Converter();
      }
      convert(input) {
        dart.as(input, S);
        return dart.as(this[_second].convert(this[_first].convert(input)), T);
      }
      startChunkedConversion(sink) {
        dart.as(sink, core.Sink$(T));
        return this[_first].startChunkedConversion(this[_second].startChunkedConversion(sink));
      }
    }
    dart.setSignature(_FusedConverter, {
      constructors: () => ({_FusedConverter: [_FusedConverter$(S, M, T), [Converter, Converter]]}),
      methods: () => ({
        convert: [T, [S]],
        startChunkedConversion: [ChunkedConversionSink, [core.Sink$(T)]]
      })
    });
    return _FusedConverter;
  });
  let _FusedConverter = _FusedConverter$();
  const _name = Symbol('_name');
  class HtmlEscapeMode extends core.Object {
    _(name, escapeLtGt, escapeQuot, escapeApos, escapeSlash) {
      this[_name] = name;
      this.escapeLtGt = escapeLtGt;
      this.escapeQuot = escapeQuot;
      this.escapeApos = escapeApos;
      this.escapeSlash = escapeSlash;
    }
    toString() {
      return this[_name];
    }
  }
  dart.defineNamedConstructor(HtmlEscapeMode, '_');
  dart.setSignature(HtmlEscapeMode, {
    constructors: () => ({_: [HtmlEscapeMode, [core.String, core.bool, core.bool, core.bool, core.bool]]})
  });
  dart.defineLazyProperties(HtmlEscapeMode, {
    get UNKNOWN() {
      return dart.const(new HtmlEscapeMode._('unknown', true, true, true, true));
    },
    get ATTRIBUTE() {
      return dart.const(new HtmlEscapeMode._('attribute', false, true, false, false));
    },
    get ELEMENT() {
      return dart.const(new HtmlEscapeMode._('element', true, false, false, true));
    }
  });
  const _convert = Symbol('_convert');
  class HtmlEscape extends Converter$(core.String, core.String) {
    HtmlEscape(mode) {
      if (mode === void 0) mode = HtmlEscapeMode.UNKNOWN;
      this.mode = mode;
      super.Converter();
    }
    convert(text) {
      let val = this[_convert](text, 0, text[dartx.length]);
      return val == null ? text : val;
    }
    [_convert](text, start, end) {
      let result = null;
      for (let i = start; dart.notNull(i) < dart.notNull(end); i = dart.notNull(i) + 1) {
        let ch = text[dartx.get](i);
        let replace = null;
        switch (ch) {
          case '&':
          {
            replace = '&amp;';
            break;
          }
          case ' ':
          {
            replace = '&nbsp;';
            break;
          }
          case '"':
          {
            if (dart.notNull(this.mode.escapeQuot)) replace = '&quot;';
            break;
          }
          case "'":
          {
            if (dart.notNull(this.mode.escapeApos)) replace = '&#x27;';
            break;
          }
          case '<':
          {
            if (dart.notNull(this.mode.escapeLtGt)) replace = '&lt;';
            break;
          }
          case '>':
          {
            if (dart.notNull(this.mode.escapeLtGt)) replace = '&gt;';
            break;
          }
          case '/':
          {
            if (dart.notNull(this.mode.escapeSlash)) replace = '&#x2F;';
            break;
          }
        }
        if (replace != null) {
          if (result == null) result = new core.StringBuffer(text[dartx.substring](start, i));
          result.write(replace);
        } else if (result != null) {
          result.write(ch);
        }
      }
      return result != null ? dart.toString(result) : null;
    }
    startChunkedConversion(sink) {
      if (!dart.is(sink, StringConversionSink)) {
        sink = StringConversionSink.from(sink);
      }
      return new _HtmlEscapeSink(this, dart.as(sink, StringConversionSink));
    }
  }
  dart.setSignature(HtmlEscape, {
    constructors: () => ({HtmlEscape: [HtmlEscape, [], [HtmlEscapeMode]]}),
    methods: () => ({
      convert: [core.String, [core.String]],
      [_convert]: [core.String, [core.String, core.int, core.int]],
      startChunkedConversion: [StringConversionSink, [core.Sink$(core.String)]]
    })
  });
  const HTML_ESCAPE = dart.const(new HtmlEscape());
  const _escape = Symbol('_escape');
  class _HtmlEscapeSink extends StringConversionSinkBase {
    _HtmlEscapeSink(escape, sink) {
      this[_escape] = escape;
      this[_sink] = sink;
    }
    addSlice(chunk, start, end, isLast) {
      let val = this[_escape][_convert](chunk, start, end);
      if (val == null) {
        this[_sink].addSlice(chunk, start, end, isLast);
      } else {
        this[_sink].add(val);
        if (dart.notNull(isLast)) this[_sink].close();
      }
    }
    close() {
      return this[_sink].close();
    }
  }
  dart.setSignature(_HtmlEscapeSink, {
    constructors: () => ({_HtmlEscapeSink: [_HtmlEscapeSink, [HtmlEscape, StringConversionSink]]}),
    methods: () => ({
      addSlice: [dart.void, [core.String, core.int, core.int, core.bool]],
      close: [dart.void, []]
    })
  });
  class JsonUnsupportedObjectError extends core.Error {
    JsonUnsupportedObjectError(unsupportedObject, opts) {
      let cause = opts && 'cause' in opts ? opts.cause : null;
      this.unsupportedObject = unsupportedObject;
      this.cause = cause;
      super.Error();
    }
    toString() {
      if (this.cause != null) {
        return "Converting object to an encodable object failed.";
      } else {
        return "Converting object did not return an encodable object.";
      }
    }
  }
  dart.setSignature(JsonUnsupportedObjectError, {
    constructors: () => ({JsonUnsupportedObjectError: [JsonUnsupportedObjectError, [dart.dynamic], {cause: dart.dynamic}]})
  });
  class JsonCyclicError extends JsonUnsupportedObjectError {
    JsonCyclicError(object) {
      super.JsonUnsupportedObjectError(object);
    }
    toString() {
      return "Cyclic error in JSON stringify";
    }
  }
  dart.setSignature(JsonCyclicError, {
    constructors: () => ({JsonCyclicError: [JsonCyclicError, [core.Object]]})
  });
  const _reviver = Symbol('_reviver');
  const _toEncodable$ = Symbol('_toEncodable');
  class JsonCodec extends Codec$(core.Object, core.String) {
    JsonCodec(opts) {
      let reviver = opts && 'reviver' in opts ? opts.reviver : null;
      let toEncodable = opts && 'toEncodable' in opts ? opts.toEncodable : null;
      this[_reviver] = reviver;
      this[_toEncodable$] = toEncodable;
      super.Codec();
    }
    withReviver(reviver) {
      this.JsonCodec({reviver: reviver});
    }
    decode(source, opts) {
      let reviver = opts && 'reviver' in opts ? opts.reviver : null;
      if (reviver == null) reviver = this[_reviver];
      if (reviver == null) return this.decoder.convert(source);
      return new JsonDecoder(reviver).convert(source);
    }
    encode(value, opts) {
      let toEncodable = opts && 'toEncodable' in opts ? opts.toEncodable : null;
      if (toEncodable == null) toEncodable = this[_toEncodable$];
      if (toEncodable == null) return this.encoder.convert(value);
      return new JsonEncoder(dart.as(toEncodable, dart.functionType(core.Object, [core.Object]))).convert(value);
    }
    get encoder() {
      if (this[_toEncodable$] == null) return dart.const(new JsonEncoder());
      return new JsonEncoder(dart.as(this[_toEncodable$], dart.functionType(core.Object, [core.Object])));
    }
    get decoder() {
      if (this[_reviver] == null) return dart.const(new JsonDecoder());
      return new JsonDecoder(this[_reviver]);
    }
  }
  dart.defineNamedConstructor(JsonCodec, 'withReviver');
  dart.setSignature(JsonCodec, {
    constructors: () => ({
      JsonCodec: [JsonCodec, [], {reviver: dart.functionType(dart.dynamic, [dart.dynamic, dart.dynamic]), toEncodable: dart.functionType(dart.dynamic, [dart.dynamic])}],
      withReviver: [JsonCodec, [dart.functionType(dart.dynamic, [dart.dynamic, dart.dynamic])]]
    }),
    methods: () => ({
      decode: [dart.dynamic, [core.String], {reviver: dart.functionType(dart.dynamic, [dart.dynamic, dart.dynamic])}],
      encode: [core.String, [core.Object], {toEncodable: dart.functionType(dart.dynamic, [dart.dynamic])}]
    })
  });
  const JSON = dart.const(new JsonCodec());
  const _Reviver = dart.typedef('_Reviver', () => dart.functionType(dart.dynamic, [dart.dynamic, dart.dynamic]));
  const _ToEncodable = dart.typedef('_ToEncodable', () => dart.functionType(dart.dynamic, [dart.dynamic]));
  class JsonEncoder extends Converter$(core.Object, core.String) {
    JsonEncoder(toEncodable) {
      if (toEncodable === void 0) toEncodable = null;
      this.indent = null;
      this[_toEncodable$] = toEncodable;
      super.Converter();
    }
    withIndent(indent, toEncodable) {
      if (toEncodable === void 0) toEncodable = null;
      this.indent = indent;
      this[_toEncodable$] = toEncodable;
      super.Converter();
    }
    convert(object) {
      return _JsonStringStringifier.stringify(object, dart.as(this[_toEncodable$], dart.functionType(dart.dynamic, [dart.dynamic])), this.indent);
    }
    startChunkedConversion(sink) {
      if (!dart.is(sink, StringConversionSink)) {
        sink = StringConversionSink.from(sink);
      } else if (dart.is(sink, _Utf8EncoderSink)) {
        return new _JsonUtf8EncoderSink(sink[_sink], this[_toEncodable$], JsonUtf8Encoder._utf8Encode(this.indent), JsonUtf8Encoder.DEFAULT_BUFFER_SIZE);
      }
      return new _JsonEncoderSink(dart.as(sink, StringConversionSink), this[_toEncodable$], this.indent);
    }
    bind(stream) {
      return super.bind(stream);
    }
    fuse(other) {
      if (dart.is(other, Utf8Encoder)) {
        return new JsonUtf8Encoder(this.indent, dart.as(this[_toEncodable$], dart.functionType(dart.dynamic, [core.Object])));
      }
      return super.fuse(other);
    }
  }
  dart.defineNamedConstructor(JsonEncoder, 'withIndent');
  dart.setSignature(JsonEncoder, {
    constructors: () => ({
      JsonEncoder: [JsonEncoder, [], [dart.functionType(core.Object, [core.Object])]],
      withIndent: [JsonEncoder, [core.String], [dart.functionType(core.Object, [core.Object])]]
    }),
    methods: () => ({
      convert: [core.String, [core.Object]],
      startChunkedConversion: [ChunkedConversionSink$(core.Object), [core.Sink$(core.String)]],
      bind: [async.Stream$(core.String), [async.Stream$(core.Object)]],
      fuse: [Converter$(core.Object, dart.dynamic), [Converter$(core.String, dart.dynamic)]]
    })
  });
  const _indent = Symbol('_indent');
  const _bufferSize = Symbol('_bufferSize');
  class JsonUtf8Encoder extends Converter$(core.Object, core.List$(core.int)) {
    JsonUtf8Encoder(indent, toEncodable, bufferSize) {
      if (indent === void 0) indent = null;
      if (toEncodable === void 0) toEncodable = null;
      if (bufferSize === void 0) bufferSize = JsonUtf8Encoder.DEFAULT_BUFFER_SIZE;
      this[_indent] = JsonUtf8Encoder._utf8Encode(indent);
      this[_toEncodable$] = toEncodable;
      this[_bufferSize] = bufferSize;
      super.Converter();
    }
    static _utf8Encode(string) {
      if (string == null) return null;
      if (dart.notNull(string[dartx.isEmpty])) return typed_data.Uint8List.new(0);
      checkAscii: {
        for (let i = 0; i < dart.notNull(string[dartx.length]); i++) {
          if (dart.notNull(string[dartx.codeUnitAt](i)) >= 128) break checkAscii;
        }
        return string[dartx.codeUnits];
      }
      return UTF8.encode(string);
    }
    convert(object) {
      let bytes = dart.list([], core.List$(core.int));
      function addChunk(chunk, start, end) {
        if (dart.notNull(start) > 0 || dart.notNull(end) < dart.notNull(chunk[dartx.length])) {
          let length = dart.notNull(end) - dart.notNull(start);
          chunk = typed_data.Uint8List.view(chunk[dartx.buffer], dart.notNull(chunk[dartx.offsetInBytes]) + dart.notNull(start), length);
        }
        bytes[dartx.add](chunk);
      }
      dart.fn(addChunk, dart.void, [typed_data.Uint8List, core.int, core.int]);
      _JsonUtf8Stringifier.stringify(object, this[_indent], dart.as(this[_toEncodable$], dart.functionType(dart.dynamic, [core.Object])), this[_bufferSize], addChunk);
      if (bytes[dartx.length] == 1) return bytes[dartx.get](0);
      let length = 0;
      for (let i = 0; i < dart.notNull(bytes[dartx.length]); i++) {
        length = dart.notNull(length) + dart.notNull(bytes[dartx.get](i)[dartx.length]);
      }
      let result = typed_data.Uint8List.new(length);
      for (let i = 0, offset = 0; i < dart.notNull(bytes[dartx.length]); i++) {
        let byteList = bytes[dartx.get](i);
        let end = offset + dart.notNull(byteList[dartx.length]);
        result[dartx.setRange](offset, end, byteList);
        offset = end;
      }
      return result;
    }
    startChunkedConversion(sink) {
      let byteSink = null;
      if (dart.is(sink, ByteConversionSink)) {
        byteSink = sink;
      } else {
        byteSink = ByteConversionSink.from(sink);
      }
      return new _JsonUtf8EncoderSink(byteSink, this[_toEncodable$], this[_indent], this[_bufferSize]);
    }
    bind(stream) {
      return super.bind(stream);
    }
    fuse(other) {
      return super.fuse(other);
    }
  }
  dart.setSignature(JsonUtf8Encoder, {
    constructors: () => ({JsonUtf8Encoder: [JsonUtf8Encoder, [], [core.String, dart.functionType(dart.dynamic, [core.Object]), core.int]]}),
    methods: () => ({
      convert: [core.List$(core.int), [core.Object]],
      startChunkedConversion: [ChunkedConversionSink$(core.Object), [core.Sink$(core.List$(core.int))]],
      bind: [async.Stream$(core.List$(core.int)), [async.Stream$(core.Object)]],
      fuse: [Converter$(core.Object, dart.dynamic), [Converter$(core.List$(core.int), dart.dynamic)]]
    }),
    statics: () => ({_utf8Encode: [core.List$(core.int), [core.String]]}),
    names: ['_utf8Encode']
  });
  JsonUtf8Encoder.DEFAULT_BUFFER_SIZE = 256;
  const _isDone = Symbol('_isDone');
  class _JsonEncoderSink extends ChunkedConversionSink$(core.Object) {
    _JsonEncoderSink(sink, toEncodable, indent) {
      this[_sink] = sink;
      this[_toEncodable$] = toEncodable;
      this[_indent] = indent;
      this[_isDone] = false;
      super.ChunkedConversionSink();
    }
    add(o) {
      if (dart.notNull(this[_isDone])) {
        dart.throw(new core.StateError("Only one call to add allowed"));
      }
      this[_isDone] = true;
      let stringSink = this[_sink].asStringSink();
      _JsonStringStringifier.printOn(o, stringSink, dart.as(this[_toEncodable$], dart.functionType(dart.dynamic, [dart.dynamic])), this[_indent]);
      stringSink.close();
    }
    close() {}
  }
  dart.setSignature(_JsonEncoderSink, {
    constructors: () => ({_JsonEncoderSink: [_JsonEncoderSink, [StringConversionSink, core.Function, core.String]]}),
    methods: () => ({
      add: [dart.void, [core.Object]],
      close: [dart.void, []]
    })
  });
  const _addChunk = Symbol('_addChunk');
  class _JsonUtf8EncoderSink extends ChunkedConversionSink$(core.Object) {
    _JsonUtf8EncoderSink(sink, toEncodable, indent, bufferSize) {
      this[_sink] = sink;
      this[_toEncodable$] = toEncodable;
      this[_indent] = indent;
      this[_bufferSize] = bufferSize;
      this[_isDone] = false;
      super.ChunkedConversionSink();
    }
    [_addChunk](chunk, start, end) {
      this[_sink].addSlice(chunk, start, end, false);
    }
    add(object) {
      if (dart.notNull(this[_isDone])) {
        dart.throw(new core.StateError("Only one call to add allowed"));
      }
      this[_isDone] = true;
      _JsonUtf8Stringifier.stringify(object, this[_indent], dart.as(this[_toEncodable$], dart.functionType(dart.dynamic, [core.Object])), this[_bufferSize], dart.bind(this, _addChunk));
      this[_sink].close();
    }
    close() {
      if (!dart.notNull(this[_isDone])) {
        this[_isDone] = true;
        this[_sink].close();
      }
    }
  }
  dart.setSignature(_JsonUtf8EncoderSink, {
    constructors: () => ({_JsonUtf8EncoderSink: [_JsonUtf8EncoderSink, [ByteConversionSink, core.Function, core.List$(core.int), core.int]]}),
    methods: () => ({
      [_addChunk]: [dart.void, [typed_data.Uint8List, core.int, core.int]],
      add: [dart.void, [core.Object]],
      close: [dart.void, []]
    })
  });
  class JsonDecoder extends Converter$(core.String, core.Object) {
    JsonDecoder(reviver) {
      if (reviver === void 0) reviver = null;
      this[_reviver] = reviver;
      super.Converter();
    }
    convert(input) {
      return _parseJson(input, this[_reviver]);
    }
    startChunkedConversion(sink) {
      return new _JsonDecoderSink(this[_reviver], sink);
    }
    bind(stream) {
      return super.bind(stream);
    }
  }
  dart.setSignature(JsonDecoder, {
    constructors: () => ({JsonDecoder: [JsonDecoder, [], [dart.functionType(dart.dynamic, [dart.dynamic, dart.dynamic])]]}),
    methods: () => ({
      convert: [dart.dynamic, [core.String]],
      startChunkedConversion: [StringConversionSink, [core.Sink$(core.Object)]],
      bind: [async.Stream$(core.Object), [async.Stream$(core.String)]]
    })
  });
  function _parseJson(source, reviver) {
    if (!(typeof source == 'string')) dart.throw(new core.ArgumentError(source));
    let parsed = null;
    try {
      parsed = dart.global.JSON.parse(source);
    } catch (e) {
      dart.throw(new core.FormatException(String(e)));
    }

    if (reviver == null) {
      return _convertJsonToDartLazy(parsed);
    } else {
      return _convertJsonToDart(parsed, reviver);
    }
  }
  dart.fn(_parseJson, dart.dynamic, [core.String, dart.functionType(dart.dynamic, [dart.dynamic, dart.dynamic])]);
  function _defaultToEncodable(object) {
    return dart.dsend(object, 'toJson');
  }
  dart.fn(_defaultToEncodable, core.Object, [dart.dynamic]);
  const _seen = Symbol('_seen');
  const _checkCycle = Symbol('_checkCycle');
  const _removeSeen = Symbol('_removeSeen');
  class _JsonStringifier extends core.Object {
    _JsonStringifier(_toEncodable) {
      this[_seen] = core.List.new();
      this[_toEncodable$] = _toEncodable != null ? _toEncodable : _defaultToEncodable;
    }
    static hexDigit(x) {
      return dart.notNull(x) < 10 ? 48 + dart.notNull(x) : 87 + dart.notNull(x);
    }
    writeStringContent(s) {
      let offset = 0;
      let length = s[dartx.length];
      for (let i = 0; i < dart.notNull(length); i++) {
        let charCode = s[dartx.codeUnitAt](i);
        if (dart.notNull(charCode) > dart.notNull(_JsonStringifier.BACKSLASH)) continue;
        if (dart.notNull(charCode) < 32) {
          if (i > offset) this.writeStringSlice(s, offset, i);
          offset = i + 1;
          this.writeCharCode(_JsonStringifier.BACKSLASH);
          switch (charCode) {
            case _JsonStringifier.BACKSPACE:
            {
              this.writeCharCode(_JsonStringifier.CHAR_b);
              break;
            }
            case _JsonStringifier.TAB:
            {
              this.writeCharCode(_JsonStringifier.CHAR_t);
              break;
            }
            case _JsonStringifier.NEWLINE:
            {
              this.writeCharCode(_JsonStringifier.CHAR_n);
              break;
            }
            case _JsonStringifier.FORM_FEED:
            {
              this.writeCharCode(_JsonStringifier.CHAR_f);
              break;
            }
            case _JsonStringifier.CARRIAGE_RETURN:
            {
              this.writeCharCode(_JsonStringifier.CHAR_r);
              break;
            }
            default:
            {
              this.writeCharCode(_JsonStringifier.CHAR_u);
              this.writeCharCode(_JsonStringifier.CHAR_0);
              this.writeCharCode(_JsonStringifier.CHAR_0);
              this.writeCharCode(_JsonStringifier.hexDigit(dart.notNull(charCode) >> 4 & 15));
              this.writeCharCode(_JsonStringifier.hexDigit(dart.notNull(charCode) & 15));
              break;
            }
          }
        } else if (charCode == _JsonStringifier.QUOTE || charCode == _JsonStringifier.BACKSLASH) {
          if (i > offset) this.writeStringSlice(s, offset, i);
          offset = i + 1;
          this.writeCharCode(_JsonStringifier.BACKSLASH);
          this.writeCharCode(charCode);
        }
      }
      if (offset == 0) {
        this.writeString(s);
      } else if (offset < dart.notNull(length)) {
        this.writeStringSlice(s, offset, length);
      }
    }
    [_checkCycle](object) {
      for (let i = 0; i < dart.notNull(this[_seen][dartx.length]); i++) {
        if (core.identical(object, this[_seen][dartx.get](i))) {
          dart.throw(new JsonCyclicError(object));
        }
      }
      this[_seen][dartx.add](object);
    }
    [_removeSeen](object) {
      dart.assert(!dart.notNull(this[_seen][dartx.isEmpty]));
      dart.assert(core.identical(this[_seen][dartx.last], object));
      this[_seen][dartx.removeLast]();
    }
    writeObject(object) {
      if (dart.notNull(this.writeJsonValue(object))) return;
      this[_checkCycle](object);
      try {
        let customJson = dart.dcall(this[_toEncodable$], object);
        if (!dart.notNull(this.writeJsonValue(customJson))) {
          dart.throw(new JsonUnsupportedObjectError(object));
        }
        this[_removeSeen](object);
      } catch (e) {
        dart.throw(new JsonUnsupportedObjectError(object, {cause: e}));
      }

    }
    writeJsonValue(object) {
      if (typeof object == 'number') {
        if (!dart.notNull(object[dartx.isFinite])) return false;
        this.writeNumber(object);
        return true;
      } else if (core.identical(object, true)) {
        this.writeString('true');
        return true;
      } else if (core.identical(object, false)) {
        this.writeString('false');
        return true;
      } else if (object == null) {
        this.writeString('null');
        return true;
      } else if (typeof object == 'string') {
        this.writeString('"');
        this.writeStringContent(object);
        this.writeString('"');
        return true;
      } else if (dart.is(object, core.List)) {
        this[_checkCycle](object);
        this.writeList(object);
        this[_removeSeen](object);
        return true;
      } else if (dart.is(object, core.Map)) {
        this[_checkCycle](object);
        this.writeMap(dart.as(object, core.Map$(core.String, core.Object)));
        this[_removeSeen](object);
        return true;
      } else {
        return false;
      }
    }
    writeList(list) {
      this.writeString('[');
      if (dart.notNull(list[dartx.length]) > 0) {
        this.writeObject(list[dartx.get](0));
        for (let i = 1; i < dart.notNull(list[dartx.length]); i++) {
          this.writeString(',');
          this.writeObject(list[dartx.get](i));
        }
      }
      this.writeString(']');
    }
    writeMap(map) {
      this.writeString('{');
      let separator = '"';
      map[dartx.forEach](dart.fn((key, value) => {
        this.writeString(separator);
        separator = ',"';
        this.writeStringContent(key);
        this.writeString('":');
        this.writeObject(value);
      }, dart.void, [core.String, core.Object]));
      this.writeString('}');
    }
  }
  dart.setSignature(_JsonStringifier, {
    constructors: () => ({_JsonStringifier: [_JsonStringifier, [dart.functionType(core.Object, [core.Object])]]}),
    methods: () => ({
      writeStringContent: [dart.void, [core.String]],
      [_checkCycle]: [dart.void, [dart.dynamic]],
      [_removeSeen]: [dart.void, [dart.dynamic]],
      writeObject: [dart.void, [dart.dynamic]],
      writeJsonValue: [core.bool, [dart.dynamic]],
      writeList: [dart.void, [core.List]],
      writeMap: [dart.void, [core.Map$(core.String, core.Object)]]
    }),
    statics: () => ({hexDigit: [core.int, [core.int]]}),
    names: ['hexDigit']
  });
  _JsonStringifier.BACKSPACE = 8;
  _JsonStringifier.TAB = 9;
  _JsonStringifier.NEWLINE = 10;
  _JsonStringifier.CARRIAGE_RETURN = 13;
  _JsonStringifier.FORM_FEED = 12;
  _JsonStringifier.QUOTE = 34;
  _JsonStringifier.CHAR_0 = 48;
  _JsonStringifier.BACKSLASH = 92;
  _JsonStringifier.CHAR_b = 98;
  _JsonStringifier.CHAR_f = 102;
  _JsonStringifier.CHAR_n = 110;
  _JsonStringifier.CHAR_r = 114;
  _JsonStringifier.CHAR_t = 116;
  _JsonStringifier.CHAR_u = 117;
  const _indentLevel = Symbol('_indentLevel');
  class _JsonPrettyPrintMixin extends core.Object {
    _JsonPrettyPrintMixin() {
      this[_indentLevel] = 0;
    }
    writeList(list) {
      if (dart.notNull(list[dartx.isEmpty])) {
        this.writeString('[]');
      } else {
        this.writeString('[\n');
        this[_indentLevel] = dart.notNull(this[_indentLevel]) + 1;
        this.writeIndentation(this[_indentLevel]);
        this.writeObject(list[dartx.get](0));
        for (let i = 1; i < dart.notNull(list[dartx.length]); i++) {
          this.writeString(',\n');
          this.writeIndentation(this[_indentLevel]);
          this.writeObject(list[dartx.get](i));
        }
        this.writeString('\n');
        this[_indentLevel] = dart.notNull(this[_indentLevel]) - 1;
        this.writeIndentation(this[_indentLevel]);
        this.writeString(']');
      }
    }
    writeMap(map) {
      if (dart.notNull(map[dartx.isEmpty])) {
        this.writeString('{}');
      } else {
        this.writeString('{\n');
        this[_indentLevel] = dart.notNull(this[_indentLevel]) + 1;
        let first = true;
        map[dartx.forEach](dart.fn((key, value) => {
          if (!first) {
            this.writeString(",\n");
          }
          this.writeIndentation(this[_indentLevel]);
          this.writeString('"');
          this.writeStringContent(key);
          this.writeString('": ');
          this.writeObject(value);
          first = false;
        }, dart.void, [core.String, core.Object]));
        this.writeString('\n');
        this[_indentLevel] = dart.notNull(this[_indentLevel]) - 1;
        this.writeIndentation(this[_indentLevel]);
        this.writeString('}');
      }
    }
  }
  _JsonPrettyPrintMixin[dart.implements] = () => [_JsonStringifier];
  dart.setSignature(_JsonPrettyPrintMixin, {
    methods: () => ({
      writeList: [dart.void, [core.List]],
      writeMap: [dart.void, [core.Map]]
    })
  });
  class _JsonStringStringifier extends _JsonStringifier {
    _JsonStringStringifier(sink, _toEncodable) {
      this[_sink] = sink;
      super._JsonStringifier(dart.as(_toEncodable, dart.functionType(core.Object, [core.Object])));
    }
    static stringify(object, toEncodable, indent) {
      let output = new core.StringBuffer();
      _JsonStringStringifier.printOn(object, output, toEncodable, indent);
      return output.toString();
    }
    static printOn(object, output, toEncodable, indent) {
      let stringifier = null;
      if (indent == null) {
        stringifier = new _JsonStringStringifier(output, toEncodable);
      } else {
        stringifier = new _JsonStringStringifierPretty(output, toEncodable, indent);
      }
      dart.dsend(stringifier, 'writeObject', object);
    }
    writeNumber(number) {
      this[_sink].write(dart.toString(number));
    }
    writeString(string) {
      this[_sink].write(string);
    }
    writeStringSlice(string, start, end) {
      this[_sink].write(string[dartx.substring](start, end));
    }
    writeCharCode(charCode) {
      this[_sink].writeCharCode(charCode);
    }
  }
  dart.setSignature(_JsonStringStringifier, {
    constructors: () => ({_JsonStringStringifier: [_JsonStringStringifier, [core.StringSink, dart.dynamic]]}),
    methods: () => ({
      writeNumber: [dart.void, [core.num]],
      writeString: [dart.void, [core.String]],
      writeStringSlice: [dart.void, [core.String, core.int, core.int]],
      writeCharCode: [dart.void, [core.int]]
    }),
    statics: () => ({
      stringify: [core.String, [dart.dynamic, dart.functionType(dart.dynamic, [dart.dynamic]), core.String]],
      printOn: [dart.void, [dart.dynamic, core.StringSink, dart.functionType(dart.dynamic, [dart.dynamic]), core.String]]
    }),
    names: ['stringify', 'printOn']
  });
  class _JsonStringStringifierPretty extends dart.mixin(_JsonStringStringifier, _JsonPrettyPrintMixin) {
    _JsonStringStringifierPretty(sink, toEncodable, indent) {
      this[_indent] = indent;
      super._JsonStringStringifier(sink, toEncodable);
    }
    writeIndentation(count) {
      for (let i = 0; i < dart.notNull(count); i++)
        this.writeString(this[_indent]);
    }
  }
  dart.setSignature(_JsonStringStringifierPretty, {
    constructors: () => ({_JsonStringStringifierPretty: [_JsonStringStringifierPretty, [core.StringSink, core.Function, core.String]]}),
    methods: () => ({writeIndentation: [dart.void, [core.int]]})
  });
  class _JsonUtf8Stringifier extends _JsonStringifier {
    _JsonUtf8Stringifier(toEncodable, bufferSize, addChunk) {
      this.addChunk = addChunk;
      this.bufferSize = bufferSize;
      this.buffer = typed_data.Uint8List.new(bufferSize);
      this.index = 0;
      super._JsonStringifier(dart.as(toEncodable, dart.functionType(core.Object, [core.Object])));
    }
    static stringify(object, indent, toEncodableFunction, bufferSize, addChunk) {
      let stringifier = null;
      if (indent != null) {
        stringifier = new _JsonUtf8StringifierPretty(toEncodableFunction, indent, bufferSize, addChunk);
      } else {
        stringifier = new _JsonUtf8Stringifier(toEncodableFunction, bufferSize, addChunk);
      }
      stringifier.writeObject(object);
      stringifier.flush();
    }
    flush() {
      if (dart.notNull(this.index) > 0) {
        dart.dcall(this.addChunk, this.buffer, 0, this.index);
      }
      this.buffer = null;
      this.index = 0;
    }
    writeNumber(number) {
      this.writeAsciiString(dart.toString(number));
    }
    writeAsciiString(string) {
      for (let i = 0; i < dart.notNull(string[dartx.length]); i++) {
        let char = string[dartx.codeUnitAt](i);
        dart.assert(dart.notNull(char) <= 127);
        this.writeByte(char);
      }
    }
    writeString(string) {
      this.writeStringSlice(string, 0, string[dartx.length]);
    }
    writeStringSlice(string, start, end) {
      for (let i = start; dart.notNull(i) < dart.notNull(end); i = dart.notNull(i) + 1) {
        let char = string[dartx.codeUnitAt](i);
        if (dart.notNull(char) <= 127) {
          this.writeByte(char);
        } else {
          if ((dart.notNull(char) & 64512) == 55296 && dart.notNull(i) + 1 < dart.notNull(end)) {
            let nextChar = string[dartx.codeUnitAt](dart.notNull(i) + 1);
            if ((dart.notNull(nextChar) & 64512) == 56320) {
              char = 65536 + ((dart.notNull(char) & 1023) << 10) + (dart.notNull(nextChar) & 1023);
              this.writeFourByteCharCode(char);
              i = dart.notNull(i) + 1;
              continue;
            }
          }
          this.writeMultiByteCharCode(char);
        }
      }
    }
    writeCharCode(charCode) {
      if (dart.notNull(charCode) <= 127) {
        this.writeByte(charCode);
        return;
      }
      this.writeMultiByteCharCode(charCode);
    }
    writeMultiByteCharCode(charCode) {
      if (dart.notNull(charCode) <= 2047) {
        this.writeByte(192 | dart.notNull(charCode) >> 6);
        this.writeByte(128 | dart.notNull(charCode) & 63);
        return;
      }
      if (dart.notNull(charCode) <= 65535) {
        this.writeByte(224 | dart.notNull(charCode) >> 12);
        this.writeByte(128 | dart.notNull(charCode) >> 6 & 63);
        this.writeByte(128 | dart.notNull(charCode) & 63);
        return;
      }
      this.writeFourByteCharCode(charCode);
    }
    writeFourByteCharCode(charCode) {
      dart.assert(dart.notNull(charCode) <= 1114111);
      this.writeByte(240 | dart.notNull(charCode) >> 18);
      this.writeByte(128 | dart.notNull(charCode) >> 12 & 63);
      this.writeByte(128 | dart.notNull(charCode) >> 6 & 63);
      this.writeByte(128 | dart.notNull(charCode) & 63);
    }
    writeByte(byte) {
      dart.assert(dart.notNull(byte) <= 255);
      if (this.index == this.buffer[dartx.length]) {
        dart.dcall(this.addChunk, this.buffer, 0, this.index);
        this.buffer = typed_data.Uint8List.new(this.bufferSize);
        this.index = 0;
      }
      this.buffer[dartx.set]((() => {
        let x = this.index;
        this.index = dart.notNull(x) + 1;
        return x;
      })(), byte);
    }
  }
  dart.setSignature(_JsonUtf8Stringifier, {
    constructors: () => ({_JsonUtf8Stringifier: [_JsonUtf8Stringifier, [dart.dynamic, core.int, core.Function]]}),
    methods: () => ({
      flush: [dart.void, []],
      writeNumber: [dart.void, [core.num]],
      writeAsciiString: [dart.void, [core.String]],
      writeString: [dart.void, [core.String]],
      writeStringSlice: [dart.void, [core.String, core.int, core.int]],
      writeCharCode: [dart.void, [core.int]],
      writeMultiByteCharCode: [dart.void, [core.int]],
      writeFourByteCharCode: [dart.void, [core.int]],
      writeByte: [dart.void, [core.int]]
    }),
    statics: () => ({stringify: [dart.void, [core.Object, core.List$(core.int), dart.functionType(dart.dynamic, [core.Object]), core.int, dart.functionType(dart.void, [typed_data.Uint8List, core.int, core.int])]]}),
    names: ['stringify']
  });
  class _JsonUtf8StringifierPretty extends dart.mixin(_JsonUtf8Stringifier, _JsonPrettyPrintMixin) {
    _JsonUtf8StringifierPretty(toEncodableFunction, indent, bufferSize, addChunk) {
      this.indent = indent;
      super._JsonUtf8Stringifier(toEncodableFunction, dart.as(bufferSize, core.int), dart.as(addChunk, core.Function));
    }
    writeIndentation(count) {
      let indent = this.indent;
      let indentLength = indent[dartx.length];
      if (indentLength == 1) {
        let char = indent[dartx.get](0);
        while (dart.notNull(count) > 0) {
          this.writeByte(char);
          count = dart.notNull(count) - 1;
        }
        return;
      }
      while (dart.notNull(count) > 0) {
        count = dart.notNull(count) - 1;
        let end = dart.notNull(this.index) + dart.notNull(indentLength);
        if (end <= dart.notNull(this.buffer[dartx.length])) {
          this.buffer[dartx.setRange](this.index, end, indent);
          this.index = end;
        } else {
          for (let i = 0; i < dart.notNull(indentLength); i++) {
            this.writeByte(indent[dartx.get](i));
          }
        }
      }
    }
  }
  dart.setSignature(_JsonUtf8StringifierPretty, {
    constructors: () => ({_JsonUtf8StringifierPretty: [_JsonUtf8StringifierPretty, [dart.dynamic, core.List$(core.int), dart.dynamic, dart.dynamic]]}),
    methods: () => ({writeIndentation: [dart.void, [core.int]]})
  });
  class Latin1Codec extends Encoding {
    Latin1Codec(opts) {
      let allowInvalid = opts && 'allowInvalid' in opts ? opts.allowInvalid : false;
      this[_allowInvalid] = allowInvalid;
      super.Encoding();
    }
    get name() {
      return "iso-8859-1";
    }
    decode(bytes, opts) {
      let allowInvalid = opts && 'allowInvalid' in opts ? opts.allowInvalid : null;
      if (allowInvalid == null) allowInvalid = this[_allowInvalid];
      if (dart.notNull(allowInvalid)) {
        return dart.const(new Latin1Decoder({allowInvalid: true})).convert(bytes);
      } else {
        return dart.const(new Latin1Decoder({allowInvalid: false})).convert(bytes);
      }
    }
    get encoder() {
      return dart.const(new Latin1Encoder());
    }
    get decoder() {
      return dart.notNull(this[_allowInvalid]) ? dart.const(new Latin1Decoder({allowInvalid: true})) : dart.const(new Latin1Decoder({allowInvalid: false}));
    }
  }
  dart.setSignature(Latin1Codec, {
    constructors: () => ({Latin1Codec: [Latin1Codec, [], {allowInvalid: core.bool}]}),
    methods: () => ({decode: [core.String, [core.List$(core.int)], {allowInvalid: core.bool}]})
  });
  const LATIN1 = dart.const(new Latin1Codec());
  const _LATIN1_MASK = 255;
  class Latin1Encoder extends _UnicodeSubsetEncoder {
    Latin1Encoder() {
      super._UnicodeSubsetEncoder(_LATIN1_MASK);
    }
  }
  dart.setSignature(Latin1Encoder, {
    constructors: () => ({Latin1Encoder: [Latin1Encoder, []]})
  });
  class Latin1Decoder extends _UnicodeSubsetDecoder {
    Latin1Decoder(opts) {
      let allowInvalid = opts && 'allowInvalid' in opts ? opts.allowInvalid : false;
      super._UnicodeSubsetDecoder(allowInvalid, _LATIN1_MASK);
    }
    startChunkedConversion(sink) {
      let stringSink = null;
      if (dart.is(sink, StringConversionSink)) {
        stringSink = sink;
      } else {
        stringSink = StringConversionSink.from(sink);
      }
      if (!dart.notNull(this[_allowInvalid])) return new _Latin1DecoderSink(stringSink);
      return new _Latin1AllowInvalidDecoderSink(stringSink);
    }
  }
  dart.setSignature(Latin1Decoder, {
    constructors: () => ({Latin1Decoder: [Latin1Decoder, [], {allowInvalid: core.bool}]}),
    methods: () => ({startChunkedConversion: [ByteConversionSink, [core.Sink$(core.String)]]})
  });
  const _addSliceToSink = Symbol('_addSliceToSink');
  class _Latin1DecoderSink extends ByteConversionSinkBase {
    _Latin1DecoderSink(sink) {
      this[_sink] = sink;
    }
    close() {
      this[_sink].close();
    }
    add(source) {
      this.addSlice(source, 0, source[dartx.length], false);
    }
    [_addSliceToSink](source, start, end, isLast) {
      this[_sink].add(core.String.fromCharCodes(source, start, end));
      if (dart.notNull(isLast)) this.close();
    }
    addSlice(source, start, end, isLast) {
      core.RangeError.checkValidRange(start, end, source[dartx.length]);
      for (let i = start; dart.notNull(i) < dart.notNull(end); i = dart.notNull(i) + 1) {
        let char = source[dartx.get](i);
        if (dart.notNull(char) > dart.notNull(_LATIN1_MASK) || dart.notNull(char) < 0) {
          dart.throw(new core.FormatException("Source contains non-Latin-1 characters."));
        }
      }
      if (dart.notNull(start) < dart.notNull(end)) {
        this[_addSliceToSink](source, start, end, isLast);
      }
      if (dart.notNull(isLast)) {
        this.close();
      }
    }
  }
  dart.setSignature(_Latin1DecoderSink, {
    constructors: () => ({_Latin1DecoderSink: [_Latin1DecoderSink, [StringConversionSink]]}),
    methods: () => ({
      close: [dart.void, []],
      add: [dart.void, [core.List$(core.int)]],
      [_addSliceToSink]: [dart.void, [core.List$(core.int), core.int, core.int, core.bool]]
    })
  });
  class _Latin1AllowInvalidDecoderSink extends _Latin1DecoderSink {
    _Latin1AllowInvalidDecoderSink(sink) {
      super._Latin1DecoderSink(sink);
    }
    addSlice(source, start, end, isLast) {
      core.RangeError.checkValidRange(start, end, source[dartx.length]);
      for (let i = start; dart.notNull(i) < dart.notNull(end); i = dart.notNull(i) + 1) {
        let char = source[dartx.get](i);
        if (dart.notNull(char) > dart.notNull(_LATIN1_MASK) || dart.notNull(char) < 0) {
          if (dart.notNull(i) > dart.notNull(start)) this[_addSliceToSink](source, start, i, false);
          this[_addSliceToSink](dart.const(dart.list([65533], core.int)), 0, 1, false);
          start = dart.notNull(i) + 1;
        }
      }
      if (dart.notNull(start) < dart.notNull(end)) {
        this[_addSliceToSink](source, start, end, isLast);
      }
      if (dart.notNull(isLast)) {
        this.close();
      }
    }
  }
  dart.setSignature(_Latin1AllowInvalidDecoderSink, {
    constructors: () => ({_Latin1AllowInvalidDecoderSink: [_Latin1AllowInvalidDecoderSink, [StringConversionSink]]})
  });
  class LineSplitter extends Converter$(core.String, core.List$(core.String)) {
    LineSplitter() {
      super.Converter();
    }
    convert(data) {
      let lines = core.List$(core.String).new();
      _LineSplitterSink._addSlice(data, 0, data[dartx.length], true, dart.bind(lines, dartx.add));
      return lines;
    }
    startChunkedConversion(sink) {
      if (!dart.is(sink, StringConversionSink)) {
        sink = StringConversionSink.from(dart.as(sink, core.Sink$(core.String)));
      }
      return new _LineSplitterSink(dart.as(sink, StringConversionSink));
    }
  }
  dart.setSignature(LineSplitter, {
    constructors: () => ({LineSplitter: [LineSplitter, []]}),
    methods: () => ({
      convert: [core.List$(core.String), [core.String]],
      startChunkedConversion: [StringConversionSink, [core.Sink]]
    })
  });
  const _carry = Symbol('_carry');
  class _LineSplitterSink extends StringConversionSinkBase {
    _LineSplitterSink(sink) {
      this[_sink] = sink;
      this[_carry] = null;
    }
    addSlice(chunk, start, end, isLast) {
      if (this[_carry] != null) {
        chunk = dart.notNull(this[_carry]) + dart.notNull(chunk[dartx.substring](start, end));
        start = 0;
        end = chunk[dartx.length];
        this[_carry] = null;
      }
      this[_carry] = _LineSplitterSink._addSlice(chunk, start, end, isLast, dart.bind(this[_sink], 'add'));
      if (dart.notNull(isLast)) this[_sink].close();
    }
    close() {
      this.addSlice('', 0, 0, true);
    }
    static _addSlice(chunk, start, end, isLast, adder) {
      let pos = start;
      while (dart.notNull(pos) < dart.notNull(end)) {
        let skip = 0;
        let char = chunk[dartx.codeUnitAt](pos);
        if (char == _LineSplitterSink._LF) {
          skip = 1;
        } else if (char == _LineSplitterSink._CR) {
          skip = 1;
          if (dart.notNull(pos) + 1 < dart.notNull(end)) {
            if (chunk[dartx.codeUnitAt](dart.notNull(pos) + 1) == _LineSplitterSink._LF) {
              skip = 2;
            }
          } else if (!dart.notNull(isLast)) {
            return chunk[dartx.substring](start, end);
          }
        }
        if (skip > 0) {
          adder(chunk[dartx.substring](start, pos));
          start = pos = dart.notNull(pos) + skip;
        } else {
          pos = dart.notNull(pos) + 1;
        }
      }
      if (pos != start) {
        let carry = chunk[dartx.substring](start, pos);
        if (dart.notNull(isLast)) {
          adder(carry);
        } else {
          return carry;
        }
      }
      return null;
    }
  }
  dart.setSignature(_LineSplitterSink, {
    constructors: () => ({_LineSplitterSink: [_LineSplitterSink, [StringConversionSink]]}),
    methods: () => ({
      addSlice: [dart.void, [core.String, core.int, core.int, core.bool]],
      close: [dart.void, []]
    }),
    statics: () => ({_addSlice: [core.String, [core.String, core.int, core.int, core.bool, dart.functionType(dart.void, [core.String])]]}),
    names: ['_addSlice']
  });
  _LineSplitterSink._LF = 10;
  _LineSplitterSink._CR = 13;
  class StringConversionSink extends ChunkedConversionSink$(core.String) {
    StringConversionSink() {
      super.ChunkedConversionSink();
    }
    static withCallback(callback) {
      return new _StringCallbackSink(callback);
    }
    static from(sink) {
      return new _StringAdapterSink(sink);
    }
    static fromStringSink(sink) {
      return new _StringSinkConversionSink(sink);
    }
  }
  dart.setSignature(StringConversionSink, {
    constructors: () => ({
      StringConversionSink: [StringConversionSink, []],
      withCallback: [StringConversionSink, [dart.functionType(dart.void, [core.String])]],
      from: [StringConversionSink, [core.Sink$(core.String)]],
      fromStringSink: [StringConversionSink, [core.StringSink]]
    })
  });
  class ClosableStringSink extends core.StringSink {
    static fromStringSink(sink, onClose) {
      return new _ClosableStringSink(sink, onClose);
    }
  }
  dart.setSignature(ClosableStringSink, {
    constructors: () => ({fromStringSink: [ClosableStringSink, [core.StringSink, dart.functionType(dart.void, [])]]})
  });
  const _StringSinkCloseCallback = dart.typedef('_StringSinkCloseCallback', () => dart.functionType(dart.void, []));
  class _ClosableStringSink extends core.Object {
    _ClosableStringSink(sink, callback) {
      this[_sink] = sink;
      this[_callback] = callback;
    }
    close() {
      return this[_callback]();
    }
    writeCharCode(charCode) {
      return this[_sink].writeCharCode(charCode);
    }
    write(o) {
      return this[_sink].write(o);
    }
    writeln(o) {
      if (o === void 0) o = "";
      return this[_sink].writeln(o);
    }
    writeAll(objects, separator) {
      if (separator === void 0) separator = "";
      return this[_sink].writeAll(objects, separator);
    }
  }
  _ClosableStringSink[dart.implements] = () => [ClosableStringSink];
  dart.setSignature(_ClosableStringSink, {
    constructors: () => ({_ClosableStringSink: [_ClosableStringSink, [core.StringSink, _StringSinkCloseCallback]]}),
    methods: () => ({
      close: [dart.void, []],
      writeCharCode: [dart.void, [core.int]],
      write: [dart.void, [core.Object]],
      writeln: [dart.void, [], [core.Object]],
      writeAll: [dart.void, [core.Iterable], [core.String]]
    })
  });
  const _flush = Symbol('_flush');
  class _StringConversionSinkAsStringSinkAdapter extends core.Object {
    _StringConversionSinkAsStringSinkAdapter(chunkedSink) {
      this[_chunkedSink] = chunkedSink;
      this[_buffer] = new core.StringBuffer();
    }
    close() {
      if (dart.notNull(this[_buffer].isNotEmpty)) this[_flush]();
      this[_chunkedSink].close();
    }
    writeCharCode(charCode) {
      this[_buffer].writeCharCode(charCode);
      if (dart.notNull(this[_buffer].length) > dart.notNull(_StringConversionSinkAsStringSinkAdapter._MIN_STRING_SIZE)) this[_flush]();
    }
    write(o) {
      if (dart.notNull(this[_buffer].isNotEmpty)) this[_flush]();
      let str = dart.toString(o);
      this[_chunkedSink].add(dart.toString(o));
    }
    writeln(o) {
      if (o === void 0) o = "";
      this[_buffer].writeln(o);
      if (dart.notNull(this[_buffer].length) > dart.notNull(_StringConversionSinkAsStringSinkAdapter._MIN_STRING_SIZE)) this[_flush]();
    }
    writeAll(objects, separator) {
      if (separator === void 0) separator = "";
      if (dart.notNull(this[_buffer].isNotEmpty)) this[_flush]();
      let iterator = objects[dartx.iterator];
      if (!dart.notNull(iterator.moveNext())) return;
      if (dart.notNull(separator[dartx.isEmpty])) {
        do {
          this[_chunkedSink].add(dart.toString(iterator.current));
        } while (dart.notNull(iterator.moveNext()));
      } else {
        this[_chunkedSink].add(dart.toString(iterator.current));
        while (dart.notNull(iterator.moveNext())) {
          this.write(separator);
          this[_chunkedSink].add(dart.toString(iterator.current));
        }
      }
    }
    [_flush]() {
      let accumulated = dart.toString(this[_buffer]);
      this[_buffer].clear();
      this[_chunkedSink].add(accumulated);
    }
  }
  _StringConversionSinkAsStringSinkAdapter[dart.implements] = () => [ClosableStringSink];
  dart.setSignature(_StringConversionSinkAsStringSinkAdapter, {
    constructors: () => ({_StringConversionSinkAsStringSinkAdapter: [_StringConversionSinkAsStringSinkAdapter, [StringConversionSink]]}),
    methods: () => ({
      close: [dart.void, []],
      writeCharCode: [dart.void, [core.int]],
      write: [dart.void, [core.Object]],
      writeln: [dart.void, [], [core.Object]],
      writeAll: [dart.void, [core.Iterable], [core.String]],
      [_flush]: [dart.void, []]
    })
  });
  _StringConversionSinkAsStringSinkAdapter._MIN_STRING_SIZE = 16;
  const _stringSink = Symbol('_stringSink');
  class _StringSinkConversionSink extends StringConversionSinkBase {
    _StringSinkConversionSink(stringSink) {
      this[_stringSink] = stringSink;
    }
    close() {}
    addSlice(str, start, end, isLast) {
      if (start != 0 || end != str[dartx.length]) {
        for (let i = start; dart.notNull(i) < dart.notNull(end); i = dart.notNull(i) + 1) {
          this[_stringSink].writeCharCode(str[dartx.codeUnitAt](i));
        }
      } else {
        this[_stringSink].write(str);
      }
      if (dart.notNull(isLast)) this.close();
    }
    add(str) {
      return this[_stringSink].write(str);
    }
    asUtf8Sink(allowMalformed) {
      return new _Utf8StringSinkAdapter(this, this[_stringSink], allowMalformed);
    }
    asStringSink() {
      return ClosableStringSink.fromStringSink(this[_stringSink], dart.bind(this, 'close'));
    }
  }
  dart.setSignature(_StringSinkConversionSink, {
    constructors: () => ({_StringSinkConversionSink: [_StringSinkConversionSink, [core.StringSink]]}),
    methods: () => ({
      close: [dart.void, []],
      addSlice: [dart.void, [core.String, core.int, core.int, core.bool]]
    })
  });
  class _StringCallbackSink extends _StringSinkConversionSink {
    _StringCallbackSink(callback) {
      this[_callback] = callback;
      super._StringSinkConversionSink(new core.StringBuffer());
    }
    close() {
      let buffer = dart.as(this[_stringSink], core.StringBuffer);
      let accumulated = dart.toString(buffer);
      buffer.clear();
      this[_callback](accumulated);
    }
    asUtf8Sink(allowMalformed) {
      return new _Utf8StringSinkAdapter(this, this[_stringSink], allowMalformed);
    }
  }
  dart.setSignature(_StringCallbackSink, {
    constructors: () => ({_StringCallbackSink: [_StringCallbackSink, [_ChunkedConversionCallback$(core.String)]]})
  });
  class _StringAdapterSink extends StringConversionSinkBase {
    _StringAdapterSink(sink) {
      this[_sink] = sink;
    }
    add(str) {
      return this[_sink].add(str);
    }
    addSlice(str, start, end, isLast) {
      if (start == 0 && end == str[dartx.length]) {
        this.add(str);
      } else {
        this.add(str[dartx.substring](start, end));
      }
      if (dart.notNull(isLast)) this.close();
    }
    close() {
      return this[_sink].close();
    }
  }
  dart.setSignature(_StringAdapterSink, {
    constructors: () => ({_StringAdapterSink: [_StringAdapterSink, [core.Sink$(core.String)]]}),
    methods: () => ({
      addSlice: [dart.void, [core.String, core.int, core.int, core.bool]],
      close: [dart.void, []]
    })
  });
  const _decoder = Symbol('_decoder');
  class _Utf8StringSinkAdapter extends ByteConversionSink {
    _Utf8StringSinkAdapter(sink, stringSink, allowMalformed) {
      this[_sink] = sink;
      this[_decoder] = new _Utf8Decoder(stringSink, allowMalformed);
      super.ByteConversionSink();
    }
    close() {
      this[_decoder].close();
      if (this[_sink] != null) this[_sink].close();
    }
    add(chunk) {
      this.addSlice(chunk, 0, chunk[dartx.length], false);
    }
    addSlice(codeUnits, startIndex, endIndex, isLast) {
      this[_decoder].convert(codeUnits, startIndex, endIndex);
      if (dart.notNull(isLast)) this.close();
    }
  }
  dart.setSignature(_Utf8StringSinkAdapter, {
    constructors: () => ({_Utf8StringSinkAdapter: [_Utf8StringSinkAdapter, [core.Sink, core.StringSink, core.bool]]}),
    methods: () => ({
      close: [dart.void, []],
      add: [dart.void, [core.List$(core.int)]],
      addSlice: [dart.void, [core.List$(core.int), core.int, core.int, core.bool]]
    })
  });
  class _Utf8ConversionSink extends ByteConversionSink {
    _Utf8ConversionSink(sink, allowMalformed) {
      this._(sink, new core.StringBuffer(), allowMalformed);
    }
    _(chunkedSink, stringBuffer, allowMalformed) {
      this[_chunkedSink] = chunkedSink;
      this[_decoder] = new _Utf8Decoder(stringBuffer, allowMalformed);
      this[_buffer] = stringBuffer;
      super.ByteConversionSink();
    }
    close() {
      this[_decoder].close();
      if (dart.notNull(this[_buffer].isNotEmpty)) {
        let accumulated = dart.toString(this[_buffer]);
        this[_buffer].clear();
        this[_chunkedSink].addSlice(accumulated, 0, accumulated[dartx.length], true);
      } else {
        this[_chunkedSink].close();
      }
    }
    add(chunk) {
      this.addSlice(chunk, 0, chunk[dartx.length], false);
    }
    addSlice(chunk, startIndex, endIndex, isLast) {
      this[_decoder].convert(chunk, startIndex, endIndex);
      if (dart.notNull(this[_buffer].isNotEmpty)) {
        let accumulated = dart.toString(this[_buffer]);
        this[_chunkedSink].addSlice(accumulated, 0, accumulated[dartx.length], isLast);
        this[_buffer].clear();
        return;
      }
      if (dart.notNull(isLast)) this.close();
    }
  }
  dart.defineNamedConstructor(_Utf8ConversionSink, '_');
  dart.setSignature(_Utf8ConversionSink, {
    constructors: () => ({
      _Utf8ConversionSink: [_Utf8ConversionSink, [StringConversionSink, core.bool]],
      _: [_Utf8ConversionSink, [StringConversionSink, core.StringBuffer, core.bool]]
    }),
    methods: () => ({
      close: [dart.void, []],
      add: [dart.void, [core.List$(core.int)]],
      addSlice: [dart.void, [core.List$(core.int), core.int, core.int, core.bool]]
    })
  });
  const UNICODE_REPLACEMENT_CHARACTER_RUNE = 65533;
  const UNICODE_BOM_CHARACTER_RUNE = 65279;
  const _allowMalformed = Symbol('_allowMalformed');
  class Utf8Codec extends Encoding {
    Utf8Codec(opts) {
      let allowMalformed = opts && 'allowMalformed' in opts ? opts.allowMalformed : false;
      this[_allowMalformed] = allowMalformed;
      super.Encoding();
    }
    get name() {
      return "utf-8";
    }
    decode(codeUnits, opts) {
      let allowMalformed = opts && 'allowMalformed' in opts ? opts.allowMalformed : null;
      if (allowMalformed == null) allowMalformed = this[_allowMalformed];
      return new Utf8Decoder({allowMalformed: allowMalformed}).convert(codeUnits);
    }
    get encoder() {
      return new Utf8Encoder();
    }
    get decoder() {
      return new Utf8Decoder({allowMalformed: this[_allowMalformed]});
    }
  }
  dart.setSignature(Utf8Codec, {
    constructors: () => ({Utf8Codec: [Utf8Codec, [], {allowMalformed: core.bool}]}),
    methods: () => ({decode: [core.String, [core.List$(core.int)], {allowMalformed: core.bool}]})
  });
  const UTF8 = dart.const(new Utf8Codec());
  const _fillBuffer = Symbol('_fillBuffer');
  const _writeSurrogate = Symbol('_writeSurrogate');
  class Utf8Encoder extends Converter$(core.String, core.List$(core.int)) {
    Utf8Encoder() {
      super.Converter();
    }
    convert(string, start, end) {
      if (start === void 0) start = 0;
      if (end === void 0) end = null;
      let stringLength = string[dartx.length];
      core.RangeError.checkValidRange(start, end, stringLength);
      if (end == null) end = stringLength;
      let length = dart.notNull(end) - dart.notNull(start);
      if (length == 0) return typed_data.Uint8List.new(0);
      let encoder = new _Utf8Encoder.withBufferSize(length * 3);
      let endPosition = encoder[_fillBuffer](string, start, end);
      dart.assert(dart.notNull(endPosition) >= dart.notNull(end) - 1);
      if (endPosition != end) {
        let lastCodeUnit = string[dartx.codeUnitAt](dart.notNull(end) - 1);
        dart.assert(_isLeadSurrogate(lastCodeUnit));
        let wasCombined = encoder[_writeSurrogate](lastCodeUnit, 0);
        dart.assert(!dart.notNull(wasCombined));
      }
      return encoder[_buffer][dartx.sublist](0, encoder[_bufferIndex]);
    }
    startChunkedConversion(sink) {
      if (!dart.is(sink, ByteConversionSink)) {
        sink = ByteConversionSink.from(sink);
      }
      return new _Utf8EncoderSink(dart.as(sink, ByteConversionSink));
    }
    bind(stream) {
      return super.bind(stream);
    }
  }
  dart.setSignature(Utf8Encoder, {
    constructors: () => ({Utf8Encoder: [Utf8Encoder, []]}),
    methods: () => ({
      convert: [core.List$(core.int), [core.String], [core.int, core.int]],
      startChunkedConversion: [StringConversionSink, [core.Sink$(core.List$(core.int))]],
      bind: [async.Stream$(core.List$(core.int)), [async.Stream$(core.String)]]
    })
  });
  class _Utf8Encoder extends core.Object {
    _Utf8Encoder() {
      this.withBufferSize(_Utf8Encoder._DEFAULT_BYTE_BUFFER_SIZE);
    }
    withBufferSize(bufferSize) {
      this[_buffer] = _Utf8Encoder._createBuffer(bufferSize);
      this[_carry] = 0;
      this[_bufferIndex] = 0;
    }
    static _createBuffer(size) {
      return typed_data.Uint8List.new(size);
    }
    [_writeSurrogate](leadingSurrogate, nextCodeUnit) {
      if (dart.notNull(_isTailSurrogate(nextCodeUnit))) {
        let rune = _combineSurrogatePair(leadingSurrogate, nextCodeUnit);
        dart.assert(dart.notNull(rune) > dart.notNull(_THREE_BYTE_LIMIT));
        dart.assert(dart.notNull(rune) <= dart.notNull(_FOUR_BYTE_LIMIT));
        this[_buffer][dartx.set]((() => {
          let x = this[_bufferIndex];
          this[_bufferIndex] = dart.notNull(x) + 1;
          return x;
        })(), 240 | dart.notNull(rune) >> 18);
        this[_buffer][dartx.set]((() => {
          let x = this[_bufferIndex];
          this[_bufferIndex] = dart.notNull(x) + 1;
          return x;
        })(), 128 | dart.notNull(rune) >> 12 & 63);
        this[_buffer][dartx.set]((() => {
          let x = this[_bufferIndex];
          this[_bufferIndex] = dart.notNull(x) + 1;
          return x;
        })(), 128 | dart.notNull(rune) >> 6 & 63);
        this[_buffer][dartx.set]((() => {
          let x = this[_bufferIndex];
          this[_bufferIndex] = dart.notNull(x) + 1;
          return x;
        })(), 128 | dart.notNull(rune) & 63);
        return true;
      } else {
        this[_buffer][dartx.set]((() => {
          let x = this[_bufferIndex];
          this[_bufferIndex] = dart.notNull(x) + 1;
          return x;
        })(), 224 | dart.notNull(leadingSurrogate) >> 12);
        this[_buffer][dartx.set]((() => {
          let x = this[_bufferIndex];
          this[_bufferIndex] = dart.notNull(x) + 1;
          return x;
        })(), 128 | dart.notNull(leadingSurrogate) >> 6 & 63);
        this[_buffer][dartx.set]((() => {
          let x = this[_bufferIndex];
          this[_bufferIndex] = dart.notNull(x) + 1;
          return x;
        })(), 128 | dart.notNull(leadingSurrogate) & 63);
        return false;
      }
    }
    [_fillBuffer](str, start, end) {
      if (start != end && dart.notNull(_isLeadSurrogate(str[dartx.codeUnitAt](dart.notNull(end) - 1)))) {
        end = dart.notNull(end) - 1;
      }
      let stringIndex = null;
      for (stringIndex = start; dart.notNull(stringIndex) < dart.notNull(end); stringIndex = dart.notNull(stringIndex) + 1) {
        let codeUnit = str[dartx.codeUnitAt](stringIndex);
        if (dart.notNull(codeUnit) <= dart.notNull(_ONE_BYTE_LIMIT)) {
          if (dart.notNull(this[_bufferIndex]) >= dart.notNull(this[_buffer][dartx.length])) break;
          this[_buffer][dartx.set]((() => {
            let x = this[_bufferIndex];
            this[_bufferIndex] = dart.notNull(x) + 1;
            return x;
          })(), codeUnit);
        } else if (dart.notNull(_isLeadSurrogate(codeUnit))) {
          if (dart.notNull(this[_bufferIndex]) + 3 >= dart.notNull(this[_buffer][dartx.length])) break;
          let nextCodeUnit = str[dartx.codeUnitAt](dart.notNull(stringIndex) + 1);
          let wasCombined = this[_writeSurrogate](codeUnit, nextCodeUnit);
          if (dart.notNull(wasCombined)) {
            stringIndex = dart.notNull(stringIndex) + 1;
          }
        } else {
          let rune = codeUnit;
          if (dart.notNull(rune) <= dart.notNull(_TWO_BYTE_LIMIT)) {
            if (dart.notNull(this[_bufferIndex]) + 1 >= dart.notNull(this[_buffer][dartx.length])) break;
            this[_buffer][dartx.set]((() => {
              let x = this[_bufferIndex];
              this[_bufferIndex] = dart.notNull(x) + 1;
              return x;
            })(), 192 | dart.notNull(rune) >> 6);
            this[_buffer][dartx.set]((() => {
              let x = this[_bufferIndex];
              this[_bufferIndex] = dart.notNull(x) + 1;
              return x;
            })(), 128 | dart.notNull(rune) & 63);
          } else {
            dart.assert(dart.notNull(rune) <= dart.notNull(_THREE_BYTE_LIMIT));
            if (dart.notNull(this[_bufferIndex]) + 2 >= dart.notNull(this[_buffer][dartx.length])) break;
            this[_buffer][dartx.set]((() => {
              let x = this[_bufferIndex];
              this[_bufferIndex] = dart.notNull(x) + 1;
              return x;
            })(), 224 | dart.notNull(rune) >> 12);
            this[_buffer][dartx.set]((() => {
              let x = this[_bufferIndex];
              this[_bufferIndex] = dart.notNull(x) + 1;
              return x;
            })(), 128 | dart.notNull(rune) >> 6 & 63);
            this[_buffer][dartx.set]((() => {
              let x = this[_bufferIndex];
              this[_bufferIndex] = dart.notNull(x) + 1;
              return x;
            })(), 128 | dart.notNull(rune) & 63);
          }
        }
      }
      return stringIndex;
    }
  }
  dart.defineNamedConstructor(_Utf8Encoder, 'withBufferSize');
  dart.setSignature(_Utf8Encoder, {
    constructors: () => ({
      _Utf8Encoder: [_Utf8Encoder, []],
      withBufferSize: [_Utf8Encoder, [core.int]]
    }),
    methods: () => ({
      [_writeSurrogate]: [core.bool, [core.int, core.int]],
      [_fillBuffer]: [core.int, [core.String, core.int, core.int]]
    }),
    statics: () => ({_createBuffer: [core.List$(core.int), [core.int]]}),
    names: ['_createBuffer']
  });
  _Utf8Encoder._DEFAULT_BYTE_BUFFER_SIZE = 1024;
  class _Utf8EncoderSink extends dart.mixin(_Utf8Encoder, StringConversionSinkMixin) {
    _Utf8EncoderSink(sink) {
      this[_sink] = sink;
      super._Utf8Encoder();
    }
    close() {
      if (this[_carry] != 0) {
        this.addSlice("", 0, 0, true);
        return;
      }
      this[_sink].close();
    }
    addSlice(str, start, end, isLast) {
      this[_bufferIndex] = 0;
      if (start == end && !dart.notNull(isLast)) {
        return;
      }
      if (this[_carry] != 0) {
        let nextCodeUnit = 0;
        if (start != end) {
          nextCodeUnit = str[dartx.codeUnitAt](start);
        } else {
          dart.assert(isLast);
        }
        let wasCombined = this[_writeSurrogate](this[_carry], nextCodeUnit);
        dart.assert(!dart.notNull(wasCombined) || start != end);
        if (dart.notNull(wasCombined)) {
          start = dart.notNull(start) + 1;
        }
        this[_carry] = 0;
      }
      do {
        start = this[_fillBuffer](str, start, end);
        let isLastSlice = dart.notNull(isLast) && start == end;
        if (start == dart.notNull(end) - 1 && dart.notNull(_isLeadSurrogate(str[dartx.codeUnitAt](start)))) {
          if (dart.notNull(isLast) && dart.notNull(this[_bufferIndex]) < dart.notNull(this[_buffer][dartx.length]) - 3) {
            let hasBeenCombined = this[_writeSurrogate](str[dartx.codeUnitAt](start), 0);
            dart.assert(!dart.notNull(hasBeenCombined));
          } else {
            this[_carry] = str[dartx.codeUnitAt](start);
          }
          start = dart.notNull(start) + 1;
        }
        this[_sink].addSlice(this[_buffer], 0, this[_bufferIndex], isLastSlice);
        this[_bufferIndex] = 0;
      } while (dart.notNull(start) < dart.notNull(end));
      if (dart.notNull(isLast)) this.close();
    }
  }
  dart.setSignature(_Utf8EncoderSink, {
    constructors: () => ({_Utf8EncoderSink: [_Utf8EncoderSink, [ByteConversionSink]]}),
    methods: () => ({
      close: [dart.void, []],
      addSlice: [dart.void, [core.String, core.int, core.int, core.bool]]
    })
  });
  class Utf8Decoder extends Converter$(core.List$(core.int), core.String) {
    Utf8Decoder(opts) {
      let allowMalformed = opts && 'allowMalformed' in opts ? opts.allowMalformed : false;
      this[_allowMalformed] = allowMalformed;
      super.Converter();
    }
    convert(codeUnits, start, end) {
      if (start === void 0) start = 0;
      if (end === void 0) end = null;
      let length = codeUnits[dartx.length];
      core.RangeError.checkValidRange(start, end, length);
      if (end == null) end = length;
      let buffer = new core.StringBuffer();
      let decoder = new _Utf8Decoder(buffer, this[_allowMalformed]);
      decoder.convert(codeUnits, start, end);
      decoder.close();
      return buffer.toString();
    }
    startChunkedConversion(sink) {
      let stringSink = null;
      if (dart.is(sink, StringConversionSink)) {
        stringSink = sink;
      } else {
        stringSink = StringConversionSink.from(sink);
      }
      return stringSink.asUtf8Sink(this[_allowMalformed]);
    }
    bind(stream) {
      return super.bind(stream);
    }
    fuse(next) {
      return super.fuse(next);
    }
  }
  dart.setSignature(Utf8Decoder, {
    constructors: () => ({Utf8Decoder: [Utf8Decoder, [], {allowMalformed: core.bool}]}),
    methods: () => ({
      convert: [core.String, [core.List$(core.int)], [core.int, core.int]],
      startChunkedConversion: [ByteConversionSink, [core.Sink$(core.String)]],
      bind: [async.Stream$(core.String), [async.Stream$(core.List$(core.int))]],
      fuse: [Converter$(core.List$(core.int), dart.dynamic), [Converter$(core.String, dart.dynamic)]]
    })
  });
  const _ONE_BYTE_LIMIT = 127;
  const _TWO_BYTE_LIMIT = 2047;
  const _THREE_BYTE_LIMIT = 65535;
  const _FOUR_BYTE_LIMIT = 1114111;
  const _SURROGATE_MASK = 63488;
  const _SURROGATE_TAG_MASK = 64512;
  const _SURROGATE_VALUE_MASK = 1023;
  const _LEAD_SURROGATE_MIN = 55296;
  const _TAIL_SURROGATE_MIN = 56320;
  function _isSurrogate(codeUnit) {
    return (dart.notNull(codeUnit) & dart.notNull(_SURROGATE_MASK)) == _LEAD_SURROGATE_MIN;
  }
  dart.fn(_isSurrogate, core.bool, [core.int]);
  function _isLeadSurrogate(codeUnit) {
    return (dart.notNull(codeUnit) & dart.notNull(_SURROGATE_TAG_MASK)) == _LEAD_SURROGATE_MIN;
  }
  dart.fn(_isLeadSurrogate, core.bool, [core.int]);
  function _isTailSurrogate(codeUnit) {
    return (dart.notNull(codeUnit) & dart.notNull(_SURROGATE_TAG_MASK)) == _TAIL_SURROGATE_MIN;
  }
  dart.fn(_isTailSurrogate, core.bool, [core.int]);
  function _combineSurrogatePair(lead, tail) {
    return 65536 + ((dart.notNull(lead) & dart.notNull(_SURROGATE_VALUE_MASK)) << 10) | dart.notNull(tail) & dart.notNull(_SURROGATE_VALUE_MASK);
  }
  dart.fn(_combineSurrogatePair, core.int, [core.int, core.int]);
  const _isFirstCharacter = Symbol('_isFirstCharacter');
  const _value = Symbol('_value');
  const _expectedUnits = Symbol('_expectedUnits');
  const _extraUnits = Symbol('_extraUnits');
  class _Utf8Decoder extends core.Object {
    _Utf8Decoder(stringSink, allowMalformed) {
      this[_stringSink] = stringSink;
      this[_allowMalformed] = allowMalformed;
      this[_isFirstCharacter] = true;
      this[_value] = 0;
      this[_expectedUnits] = 0;
      this[_extraUnits] = 0;
    }
    get hasPartialInput() {
      return dart.notNull(this[_expectedUnits]) > 0;
    }
    close() {
      this.flush();
    }
    flush() {
      if (dart.notNull(this.hasPartialInput)) {
        if (!dart.notNull(this[_allowMalformed])) {
          dart.throw(new core.FormatException("Unfinished UTF-8 octet sequence"));
        }
        this[_stringSink].writeCharCode(UNICODE_REPLACEMENT_CHARACTER_RUNE);
        this[_value] = 0;
        this[_expectedUnits] = 0;
        this[_extraUnits] = 0;
      }
    }
    convert(codeUnits, startIndex, endIndex) {
      let value = this[_value];
      let expectedUnits = this[_expectedUnits];
      let extraUnits = this[_extraUnits];
      this[_value] = 0;
      this[_expectedUnits] = 0;
      this[_extraUnits] = 0;
      function scanOneByteCharacters(units, from) {
        let to = endIndex;
        let mask = _ONE_BYTE_LIMIT;
        for (let i = from; dart.notNull(i) < dart.notNull(to); i = dart.notNull(i) + 1) {
          let unit = dart.dindex(units, i);
          if (!dart.equals(dart.dsend(unit, '&', mask), unit)) return dart.notNull(i) - dart.notNull(from);
        }
        return dart.notNull(to) - dart.notNull(from);
      }
      dart.fn(scanOneByteCharacters, core.int, [dart.dynamic, core.int]);
      const addSingleBytes = (function(from, to) {
        dart.assert(dart.notNull(from) >= dart.notNull(startIndex) && dart.notNull(from) <= dart.notNull(endIndex));
        dart.assert(dart.notNull(to) >= dart.notNull(startIndex) && dart.notNull(to) <= dart.notNull(endIndex));
        this[_stringSink].write(core.String.fromCharCodes(codeUnits, from, to));
      }).bind(this);
      dart.fn(addSingleBytes, dart.void, [core.int, core.int]);
      let i = startIndex;
      loop:
        while (true) {
          multibyte:
            if (dart.notNull(expectedUnits) > 0) {
              do {
                if (i == endIndex) {
                  break loop;
                }
                let unit = codeUnits[dartx.get](i);
                if ((dart.notNull(unit) & 192) != 128) {
                  expectedUnits = 0;
                  if (!dart.notNull(this[_allowMalformed])) {
                    dart.throw(new core.FormatException(`Bad UTF-8 encoding 0x${unit[dartx.toRadixString](16)}`));
                  }
                  this[_isFirstCharacter] = false;
                  this[_stringSink].writeCharCode(UNICODE_REPLACEMENT_CHARACTER_RUNE);
                  break multibyte;
                } else {
                  value = dart.notNull(value) << 6 | dart.notNull(unit) & 63;
                  expectedUnits = dart.notNull(expectedUnits) - 1;
                  i = dart.notNull(i) + 1;
                }
              } while (dart.notNull(expectedUnits) > 0);
              if (dart.notNull(value) <= dart.notNull(_Utf8Decoder._LIMITS[dartx.get](dart.notNull(extraUnits) - 1))) {
                if (!dart.notNull(this[_allowMalformed])) {
                  dart.throw(new core.FormatException(`Overlong encoding of 0x${value[dartx.toRadixString](16)}`));
                }
                expectedUnits = extraUnits = 0;
                value = UNICODE_REPLACEMENT_CHARACTER_RUNE;
              }
              if (dart.notNull(value) > dart.notNull(_FOUR_BYTE_LIMIT)) {
                if (!dart.notNull(this[_allowMalformed])) {
                  dart.throw(new core.FormatException("Character outside valid Unicode range: " + `0x${value[dartx.toRadixString](16)}`));
                }
                value = UNICODE_REPLACEMENT_CHARACTER_RUNE;
              }
              if (!dart.notNull(this[_isFirstCharacter]) || value != UNICODE_BOM_CHARACTER_RUNE) {
                this[_stringSink].writeCharCode(value);
              }
              this[_isFirstCharacter] = false;
            }
          while (dart.notNull(i) < dart.notNull(endIndex)) {
            let oneBytes = scanOneByteCharacters(codeUnits, i);
            if (dart.notNull(oneBytes) > 0) {
              this[_isFirstCharacter] = false;
              addSingleBytes(i, dart.notNull(i) + dart.notNull(oneBytes));
              i = dart.notNull(i) + dart.notNull(oneBytes);
              if (i == endIndex) break;
            }
            let unit = codeUnits[dartx.get]((() => {
              let x = i;
              i = dart.notNull(x) + 1;
              return x;
            })());
            if (dart.notNull(unit) < 0) {
              if (!dart.notNull(this[_allowMalformed])) {
                dart.throw(new core.FormatException(`Negative UTF-8 code unit: -0x${(-dart.notNull(unit))[dartx.toRadixString](16)}`));
              }
              this[_stringSink].writeCharCode(UNICODE_REPLACEMENT_CHARACTER_RUNE);
            } else {
              dart.assert(dart.notNull(unit) > dart.notNull(_ONE_BYTE_LIMIT));
              if ((dart.notNull(unit) & 224) == 192) {
                value = dart.notNull(unit) & 31;
                expectedUnits = extraUnits = 1;
                continue loop;
              }
              if ((dart.notNull(unit) & 240) == 224) {
                value = dart.notNull(unit) & 15;
                expectedUnits = extraUnits = 2;
                continue loop;
              }
              if ((dart.notNull(unit) & 248) == 240 && dart.notNull(unit) < 245) {
                value = dart.notNull(unit) & 7;
                expectedUnits = extraUnits = 3;
                continue loop;
              }
              if (!dart.notNull(this[_allowMalformed])) {
                dart.throw(new core.FormatException(`Bad UTF-8 encoding 0x${unit[dartx.toRadixString](16)}`));
              }
              value = UNICODE_REPLACEMENT_CHARACTER_RUNE;
              expectedUnits = extraUnits = 0;
              this[_isFirstCharacter] = false;
              this[_stringSink].writeCharCode(value);
            }
          }
          break loop;
        }
      if (dart.notNull(expectedUnits) > 0) {
        this[_value] = value;
        this[_expectedUnits] = expectedUnits;
        this[_extraUnits] = extraUnits;
      }
    }
  }
  dart.setSignature(_Utf8Decoder, {
    constructors: () => ({_Utf8Decoder: [_Utf8Decoder, [core.StringSink, core.bool]]}),
    methods: () => ({
      close: [dart.void, []],
      flush: [dart.void, []],
      convert: [dart.void, [core.List$(core.int), core.int, core.int]]
    })
  });
  _Utf8Decoder._LIMITS = dart.const(dart.list([_ONE_BYTE_LIMIT, _TWO_BYTE_LIMIT, _THREE_BYTE_LIMIT, _FOUR_BYTE_LIMIT], core.int));
  const _processed = Symbol('_processed');
  const _computeKeys = Symbol('_computeKeys');
  const _original = Symbol('_original');
  function _convertJsonToDart(json, reviver) {
    dart.assert(reviver != null);
    function walk(e) {
      if (e == null || typeof e != "object") {
        return e;
      }
      if (Object.getPrototypeOf(e) === Array.prototype) {
        for (let i = 0; i < e.length; i++) {
          let item = e[i];
          e[i] = dart.dcall(reviver, i, walk(item));
        }
        return e;
      }
      let map = new _JsonMap(e);
      let processed = map[_processed];
      let keys = map[_computeKeys]();
      for (let i = 0; i < dart.notNull(keys[dartx.length]); i++) {
        let key = keys[dartx.get](i);
        let revived = dart.dcall(reviver, key, walk(e[key]));
        processed[key] = revived;
      }
      map[_original] = processed;
      return map;
    }
    dart.fn(walk);
    return dart.dcall(reviver, null, walk(json));
  }
  dart.fn(_convertJsonToDart, dart.dynamic, [dart.dynamic, dart.functionType(dart.dynamic, [dart.dynamic, dart.dynamic])]);
  function _convertJsonToDartLazy(object) {
    if (object == null) return null;
    if (typeof object != "object") {
      return object;
    }
    if (Object.getPrototypeOf(object) !== Array.prototype) {
      return new _JsonMap(object);
    }
    for (let i = 0; i < object.length; i++) {
      let item = object[i];
      object[i] = _convertJsonToDartLazy(item);
    }
    return object;
  }
  dart.fn(_convertJsonToDartLazy);
  const _data = Symbol('_data');
  const _isUpgraded = Symbol('_isUpgraded');
  const _upgradedMap = Symbol('_upgradedMap');
  const _process = Symbol('_process');
  const _upgrade = Symbol('_upgrade');
  class _JsonMap extends core.Object {
    _JsonMap(original) {
      this[_processed] = _JsonMap._newJavaScriptObject();
      this[_original] = original;
      this[_data] = null;
    }
    get(key) {
      if (dart.notNull(this[_isUpgraded])) {
        return this[_upgradedMap][dartx.get](key);
      } else if (!(typeof key == 'string')) {
        return null;
      } else {
        let result = _JsonMap._getProperty(this[_processed], dart.as(key, core.String));
        if (dart.notNull(_JsonMap._isUnprocessed(result))) result = this[_process](dart.as(key, core.String));
        return result;
      }
    }
    get length() {
      return dart.notNull(this[_isUpgraded]) ? this[_upgradedMap][dartx.length] : this[_computeKeys]()[dartx.length];
    }
    get isEmpty() {
      return this.length == 0;
    }
    get isNotEmpty() {
      return dart.notNull(this.length) > 0;
    }
    get keys() {
      if (dart.notNull(this[_isUpgraded])) return this[_upgradedMap][dartx.keys];
      return new _JsonMapKeyIterable(this);
    }
    get values() {
      if (dart.notNull(this[_isUpgraded])) return this[_upgradedMap][dartx.values];
      return _internal.MappedIterable.new(this[_computeKeys](), dart.fn(each => this.get(each)));
    }
    set(key, value) {
      if (dart.notNull(this[_isUpgraded])) {
        this[_upgradedMap][dartx.set](key, value);
      } else if (dart.notNull(this.containsKey(key))) {
        let processed = this[_processed];
        _JsonMap._setProperty(processed, dart.as(key, core.String), value);
        let original = this[_original];
        if (!core.identical(original, processed)) {
          _JsonMap._setProperty(original, dart.as(key, core.String), null);
        }
      } else {
        this[_upgrade]()[dartx.set](key, value);
      }
      return value;
    }
    addAll(other) {
      other[dartx.forEach](dart.fn((key, value) => {
        this.set(key, value);
      }, dart.void, [dart.dynamic, dart.dynamic]));
    }
    containsValue(value) {
      if (dart.notNull(this[_isUpgraded])) return this[_upgradedMap][dartx.containsValue](value);
      let keys = this[_computeKeys]();
      for (let i = 0; i < dart.notNull(keys[dartx.length]); i++) {
        let key = keys[dartx.get](i);
        if (dart.equals(this.get(key), value)) return true;
      }
      return false;
    }
    containsKey(key) {
      if (dart.notNull(this[_isUpgraded])) return this[_upgradedMap][dartx.containsKey](key);
      if (!(typeof key == 'string')) return false;
      return _JsonMap._hasProperty(this[_original], dart.as(key, core.String));
    }
    putIfAbsent(key, ifAbsent) {
      if (dart.notNull(this.containsKey(key))) return this.get(key);
      let value = ifAbsent();
      this.set(key, value);
      return value;
    }
    remove(key) {
      if (!dart.notNull(this[_isUpgraded]) && !dart.notNull(this.containsKey(key))) return null;
      return this[_upgrade]()[dartx.remove](key);
    }
    clear() {
      if (dart.notNull(this[_isUpgraded])) {
        this[_upgradedMap][dartx.clear]();
      } else {
        if (this[_data] != null) {
          dart.dsend(this[_data], 'clear');
        }
        this[_original] = this[_processed] = null;
        this[_data] = dart.map();
      }
    }
    forEach(f) {
      if (dart.notNull(this[_isUpgraded])) return this[_upgradedMap][dartx.forEach](f);
      let keys = this[_computeKeys]();
      for (let i = 0; i < dart.notNull(keys[dartx.length]); i++) {
        let key = keys[dartx.get](i);
        let value = _JsonMap._getProperty(this[_processed], key);
        if (dart.notNull(_JsonMap._isUnprocessed(value))) {
          value = _convertJsonToDartLazy(_JsonMap._getProperty(this[_original], key));
          _JsonMap._setProperty(this[_processed], key, value);
        }
        dart.dcall(f, key, value);
        if (!core.identical(keys, this[_data])) {
          dart.throw(new core.ConcurrentModificationError(this));
        }
      }
    }
    toString() {
      return collection.Maps.mapToString(this);
    }
    get [_isUpgraded]() {
      return this[_processed] == null;
    }
    get [_upgradedMap]() {
      dart.assert(this[_isUpgraded]);
      return dart.as(this[_data], core.Map);
    }
    [_computeKeys]() {
      dart.assert(!dart.notNull(this[_isUpgraded]));
      let keys = dart.as(this[_data], core.List);
      if (keys == null) {
        keys = this[_data] = _JsonMap._getPropertyNames(this[_original]);
      }
      return dart.as(keys, core.List$(core.String));
    }
    [_upgrade]() {
      if (dart.notNull(this[_isUpgraded])) return this[_upgradedMap];
      let result = dart.map();
      let keys = this[_computeKeys]();
      for (let i = 0; i < dart.notNull(keys[dartx.length]); i++) {
        let key = keys[dartx.get](i);
        result[dartx.set](key, this.get(key));
      }
      if (dart.notNull(keys[dartx.isEmpty])) {
        keys[dartx.add](null);
      } else {
        keys[dartx.clear]();
      }
      this[_original] = this[_processed] = null;
      this[_data] = result;
      dart.assert(this[_isUpgraded]);
      return result;
    }
    [_process](key) {
      if (!dart.notNull(_JsonMap._hasProperty(this[_original], key))) return null;
      let result = _convertJsonToDartLazy(_JsonMap._getProperty(this[_original], key));
      return _JsonMap._setProperty(this[_processed], key, result);
    }
    static _hasProperty(object, key) {
      return Object.prototype.hasOwnProperty.call(object, key);
    }
    static _getProperty(object, key) {
      return object[key];
    }
    static _setProperty(object, key, value) {
      return object[key] = value;
    }
    static _getPropertyNames(object) {
      return dart.as(Object.keys(object), core.List);
    }
    static _isUnprocessed(object) {
      return typeof object == "undefined";
    }
    static _newJavaScriptObject() {
      return Object.create(null);
    }
  }
  _JsonMap[dart.implements] = () => [collection.LinkedHashMap];
  dart.setSignature(_JsonMap, {
    constructors: () => ({_JsonMap: [_JsonMap, [dart.dynamic]]}),
    methods: () => ({
      get: [dart.dynamic, [core.Object]],
      set: [dart.void, [dart.dynamic, dart.dynamic]],
      addAll: [dart.void, [core.Map]],
      containsValue: [core.bool, [core.Object]],
      containsKey: [core.bool, [core.Object]],
      putIfAbsent: [dart.dynamic, [dart.dynamic, dart.functionType(dart.dynamic, [])]],
      remove: [dart.dynamic, [core.Object]],
      clear: [dart.void, []],
      forEach: [dart.void, [dart.functionType(dart.void, [dart.dynamic, dart.dynamic])]],
      [_computeKeys]: [core.List$(core.String), []],
      [_upgrade]: [core.Map, []],
      [_process]: [dart.dynamic, [core.String]]
    }),
    statics: () => ({
      _hasProperty: [core.bool, [dart.dynamic, core.String]],
      _getProperty: [dart.dynamic, [dart.dynamic, core.String]],
      _setProperty: [dart.dynamic, [dart.dynamic, core.String, dart.dynamic]],
      _getPropertyNames: [core.List, [dart.dynamic]],
      _isUnprocessed: [core.bool, [dart.dynamic]],
      _newJavaScriptObject: [dart.dynamic, []]
    }),
    names: ['_hasProperty', '_getProperty', '_setProperty', '_getPropertyNames', '_isUnprocessed', '_newJavaScriptObject']
  });
  dart.defineExtensionMembers(_JsonMap, [
    'get',
    'set',
    'addAll',
    'containsValue',
    'containsKey',
    'putIfAbsent',
    'remove',
    'clear',
    'forEach',
    'length',
    'isEmpty',
    'isNotEmpty',
    'keys',
    'values'
  ]);
  const _parent = Symbol('_parent');
  class _JsonMapKeyIterable extends _internal.ListIterable {
    _JsonMapKeyIterable(parent) {
      this[_parent] = parent;
      super.ListIterable();
    }
    get length() {
      return this[_parent].length;
    }
    elementAt(index) {
      return dart.as(dart.notNull(this[_parent][_isUpgraded]) ? this[_parent].keys[dartx.elementAt](index) : this[_parent][_computeKeys]()[dartx.get](index), core.String);
    }
    get iterator() {
      return dart.as(dart.notNull(this[_parent][_isUpgraded]) ? this[_parent].keys[dartx.iterator] : this[_parent][_computeKeys]()[dartx.iterator], core.Iterator);
    }
    contains(key) {
      return this[_parent].containsKey(key);
    }
  }
  dart.setSignature(_JsonMapKeyIterable, {
    constructors: () => ({_JsonMapKeyIterable: [_JsonMapKeyIterable, [_JsonMap]]}),
    methods: () => ({elementAt: [core.String, [core.int]]})
  });
  dart.defineExtensionMembers(_JsonMapKeyIterable, ['elementAt', 'contains', 'length', 'iterator']);
  class _JsonDecoderSink extends _StringSinkConversionSink {
    _JsonDecoderSink(reviver, sink) {
      this[_reviver] = reviver;
      this[_sink] = sink;
      super._StringSinkConversionSink(new core.StringBuffer());
    }
    close() {
      super.close();
      let buffer = dart.as(this[_stringSink], core.StringBuffer);
      let accumulated = dart.toString(buffer);
      buffer.clear();
      let decoded = _parseJson(accumulated, this[_reviver]);
      this[_sink].add(decoded);
      this[_sink].close();
    }
  }
  dart.setSignature(_JsonDecoderSink, {
    constructors: () => ({_JsonDecoderSink: [_JsonDecoderSink, [_Reviver, core.Sink$(core.Object)]]})
  });
  // Exports:
  exports.Codec$ = Codec$;
  exports.Codec = Codec;
  exports.Encoding = Encoding;
  exports.AsciiCodec = AsciiCodec;
  exports.ASCII = ASCII;
  exports.Converter$ = Converter$;
  exports.Converter = Converter;
  exports.AsciiEncoder = AsciiEncoder;
  exports.StringConversionSinkMixin = StringConversionSinkMixin;
  exports.StringConversionSinkBase = StringConversionSinkBase;
  exports.AsciiDecoder = AsciiDecoder;
  exports.ChunkedConversionSink$ = ChunkedConversionSink$;
  exports.ChunkedConversionSink = ChunkedConversionSink;
  exports.ByteConversionSink = ByteConversionSink;
  exports.ByteConversionSinkBase = ByteConversionSinkBase;
  exports.HtmlEscapeMode = HtmlEscapeMode;
  exports.HtmlEscape = HtmlEscape;
  exports.HTML_ESCAPE = HTML_ESCAPE;
  exports.JsonUnsupportedObjectError = JsonUnsupportedObjectError;
  exports.JsonCyclicError = JsonCyclicError;
  exports.JsonCodec = JsonCodec;
  exports.JSON = JSON;
  exports.JsonEncoder = JsonEncoder;
  exports.JsonUtf8Encoder = JsonUtf8Encoder;
  exports.JsonDecoder = JsonDecoder;
  exports.Latin1Codec = Latin1Codec;
  exports.LATIN1 = LATIN1;
  exports.Latin1Encoder = Latin1Encoder;
  exports.Latin1Decoder = Latin1Decoder;
  exports.LineSplitter = LineSplitter;
  exports.StringConversionSink = StringConversionSink;
  exports.ClosableStringSink = ClosableStringSink;
  exports.UNICODE_REPLACEMENT_CHARACTER_RUNE = UNICODE_REPLACEMENT_CHARACTER_RUNE;
  exports.UNICODE_BOM_CHARACTER_RUNE = UNICODE_BOM_CHARACTER_RUNE;
  exports.Utf8Codec = Utf8Codec;
  exports.UTF8 = UTF8;
  exports.Utf8Encoder = Utf8Encoder;
  exports.Utf8Decoder = Utf8Decoder;
});
