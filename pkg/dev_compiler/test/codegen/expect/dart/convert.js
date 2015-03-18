var convert;
(function(exports) {
  'use strict';
  let ASCII = new AsciiCodec();
  let _ASCII_MASK = 127;
  let _allowInvalid = Symbol('_allowInvalid');
  class AsciiCodec extends Encoding {
    AsciiCodec(opt$) {
      let allowInvalid = opt$.allowInvalid === void 0 ? false : opt$.allowInvalid;
      this[_allowInvalid] = allowInvalid;
      super.Encoding();
    }
    get name() {
      return "us-ascii";
    }
    decode(bytes, opt$) {
      let allowInvalid = opt$.allowInvalid === void 0 ? null : opt$.allowInvalid;
      if (allowInvalid === null)
        allowInvalid = this[_allowInvalid];
      if (allowInvalid) {
        return new AsciiDecoder({allowInvalid: true}).convert(bytes);
      } else {
        return new AsciiDecoder({allowInvalid: false}).convert(bytes);
      }
    }
    get encoder() {
      return new AsciiEncoder();
    }
    get decoder() {
      return this[_allowInvalid] ? new AsciiDecoder({allowInvalid: true}) : new AsciiDecoder({allowInvalid: false});
    }
  }
  let _subsetMask = Symbol('_subsetMask');
  class _UnicodeSubsetEncoder extends Converter$(core.String, core.List$(core.int)) {
    _UnicodeSubsetEncoder($_subsetMask) {
      this[_subsetMask] = $_subsetMask;
      super.Converter();
    }
    convert(string, start, end) {
      if (start === void 0)
        start = 0;
      if (end === void 0)
        end = null;
      let stringLength = string.length;
      core.RangeError.checkValidRange(start, end, stringLength);
      if (end === null)
        end = stringLength;
      let length = dart.notNull(end) - dart.notNull(start);
      let result = new typed_data.Uint8List(length);
      for (let i = 0; dart.notNull(i) < dart.notNull(length); i = dart.notNull(i) + 1) {
        let codeUnit = string.codeUnitAt(dart.notNull(start) + dart.notNull(i));
        if ((dart.notNull(codeUnit) & ~dart.notNull(this[_subsetMask])) !== 0) {
          throw new core.ArgumentError("String contains invalid characters.");
        }
        result.set(i, codeUnit);
      }
      return dart.as(result, core.List$(core.int));
    }
    startChunkedConversion(sink) {
      if (!dart.is(sink, ByteConversionSink)) {
        sink = new ByteConversionSink.from(sink);
      }
      return new _UnicodeSubsetEncoderSink(this[_subsetMask], dart.as(sink, ByteConversionSink));
    }
    bind(stream) {
      return dart.as(super.bind(stream), async.Stream$(core.List$(core.int)));
    }
  }
  class AsciiEncoder extends _UnicodeSubsetEncoder {
    AsciiEncoder() {
      super._UnicodeSubsetEncoder(_ASCII_MASK);
    }
  }
  let _sink = Symbol('_sink');
  class _UnicodeSubsetEncoderSink extends StringConversionSinkBase {
    _UnicodeSubsetEncoderSink($_subsetMask, $_sink) {
      this[_subsetMask] = $_subsetMask;
      this[_sink] = $_sink;
      super.StringConversionSinkBase();
    }
    close() {
      this[_sink].close();
    }
    addSlice(source, start, end, isLast) {
      core.RangeError.checkValidRange(start, end, source.length);
      for (let i = start; dart.notNull(i) < dart.notNull(end); i = dart.notNull(i) + 1) {
        let codeUnit = source.codeUnitAt(i);
        if ((dart.notNull(codeUnit) & ~dart.notNull(this[_subsetMask])) !== 0) {
          throw new core.ArgumentError(`Source contains invalid character with code point: ${codeUnit}.`);
        }
      }
      this[_sink].add(source.codeUnits.sublist(start, end));
      if (isLast) {
        this.close();
      }
    }
  }
  let _convertInvalid = Symbol('_convertInvalid');
  class _UnicodeSubsetDecoder extends Converter$(core.List$(core.int), core.String) {
    _UnicodeSubsetDecoder($_allowInvalid, $_subsetMask) {
      this[_allowInvalid] = $_allowInvalid;
      this[_subsetMask] = $_subsetMask;
      super.Converter();
    }
    convert(bytes, start, end) {
      if (start === void 0)
        start = 0;
      if (end === void 0)
        end = null;
      let byteCount = bytes.length;
      core.RangeError.checkValidRange(start, end, byteCount);
      if (end === null)
        end = byteCount;
      let length = dart.notNull(end) - dart.notNull(start);
      for (let i = start; dart.notNull(i) < dart.notNull(end); i = dart.notNull(i) + 1) {
        let byte = bytes.get(i);
        if ((dart.notNull(byte) & ~dart.notNull(this[_subsetMask])) !== 0) {
          if (!dart.notNull(this[_allowInvalid])) {
            throw new core.FormatException(`Invalid value in input: ${byte}`);
          }
          return this[_convertInvalid](bytes, start, end);
        }
      }
      return new core.String.fromCharCodes(bytes, start, end);
    }
    [_convertInvalid](bytes, start, end) {
      let buffer = new core.StringBuffer();
      for (let i = start; dart.notNull(i) < dart.notNull(end); i = dart.notNull(i) + 1) {
        let value = bytes.get(i);
        if ((dart.notNull(value) & ~dart.notNull(this[_subsetMask])) !== 0)
          value = 65533;
        buffer.writeCharCode(value);
      }
      return buffer.toString();
    }
    bind(stream) {
      return dart.as(super.bind(stream), async.Stream$(core.String));
    }
  }
  class AsciiDecoder extends _UnicodeSubsetDecoder {
    AsciiDecoder(opt$) {
      let allowInvalid = opt$.allowInvalid === void 0 ? false : opt$.allowInvalid;
      super._UnicodeSubsetDecoder(allowInvalid, _ASCII_MASK);
    }
    startChunkedConversion(sink) {
      let stringSink = null;
      if (dart.is(sink, StringConversionSink)) {
        stringSink = sink;
      } else {
        stringSink = new StringConversionSink.from(sink);
      }
      if (this[_allowInvalid]) {
        return new _ErrorHandlingAsciiDecoderSink(stringSink.asUtf8Sink(false));
      } else {
        return new _SimpleAsciiDecoderSink(stringSink);
      }
    }
  }
  let _utf8Sink = Symbol('_utf8Sink');
  class _ErrorHandlingAsciiDecoderSink extends ByteConversionSinkBase {
    _ErrorHandlingAsciiDecoderSink($_utf8Sink) {
      this[_utf8Sink] = $_utf8Sink;
      super.ByteConversionSinkBase();
    }
    close() {
      this[_utf8Sink].close();
    }
    add(source) {
      this.addSlice(source, 0, source.length, false);
    }
    addSlice(source, start, end, isLast) {
      core.RangeError.checkValidRange(start, end, source.length);
      for (let i = start; dart.notNull(i) < dart.notNull(end); i = dart.notNull(i) + 1) {
        if ((dart.notNull(source.get(i)) & ~dart.notNull(_ASCII_MASK)) !== 0) {
          if (dart.notNull(i) > dart.notNull(start))
            this[_utf8Sink].addSlice(source, start, i, false);
          this[_utf8Sink].add(/* Unimplemented const */new List.from([239, 191, 189]));
          start = dart.notNull(i) + 1;
        }
      }
      if (dart.notNull(start) < dart.notNull(end)) {
        this[_utf8Sink].addSlice(source, start, end, isLast);
      } else if (isLast) {
        this.close();
      }
    }
  }
  class _SimpleAsciiDecoderSink extends ByteConversionSinkBase {
    _SimpleAsciiDecoderSink($_sink) {
      this[_sink] = $_sink;
      super.ByteConversionSinkBase();
    }
    close() {
      this[_sink].close();
    }
    add(source) {
      for (let i = 0; dart.notNull(i) < dart.notNull(source.length); i = dart.notNull(i) + 1) {
        if ((dart.notNull(source.get(i)) & ~dart.notNull(_ASCII_MASK)) !== 0) {
          throw new core.FormatException("Source contains non-ASCII bytes.");
        }
      }
      this[_sink].add(new core.String.fromCharCodes(source));
    }
    addSlice(source, start, end, isLast) {
      let length = source.length;
      core.RangeError.checkValidRange(start, end, length);
      if (dart.notNull(start) < dart.notNull(end)) {
        if (start !== 0 || end !== length) {
          source = source.sublist(start, end);
        }
        this.add(source);
      }
      if (isLast)
        this.close();
    }
  }
  class ByteConversionSink extends ChunkedConversionSink$(core.List$(core.int)) {
    ByteConversionSink() {
      super.ChunkedConversionSink();
    }
    ByteConversionSink$withCallback(callback) {
      return new _ByteCallbackSink(callback);
    }
    ByteConversionSink$from(sink) {
      return new _ByteAdapterSink(sink);
    }
  }
  dart.defineNamedConstructor(ByteConversionSink, 'withCallback');
  dart.defineNamedConstructor(ByteConversionSink, 'from');
  class ByteConversionSinkBase extends ByteConversionSink {
    addSlice(chunk, start, end, isLast) {
      this.add(chunk.sublist(start, end));
      if (isLast)
        this.close();
    }
  }
  class _ByteAdapterSink extends ByteConversionSinkBase {
    _ByteAdapterSink($_sink) {
      this[_sink] = $_sink;
      super.ByteConversionSinkBase();
    }
    add(chunk) {
      return this[_sink].add(chunk);
    }
    close() {
      return this[_sink].close();
    }
  }
  let _buffer = Symbol('_buffer');
  let _callback = Symbol('_callback');
  let _bufferIndex = Symbol('_bufferIndex');
  let _roundToPowerOf2 = Symbol('_roundToPowerOf2');
  class _ByteCallbackSink extends ByteConversionSinkBase {
    _ByteCallbackSink(callback) {
      this[_buffer] = new typed_data.Uint8List(_ByteCallbackSink._INITIAL_BUFFER_SIZE);
      this[_callback] = callback;
      this[_bufferIndex] = 0;
      super.ByteConversionSinkBase();
    }
    add(chunk) {
      let freeCount = dart.notNull(this[_buffer].length) - dart.notNull(this[_bufferIndex]);
      if (dart.notNull(chunk.length) > dart.notNull(freeCount)) {
        let oldLength = this[_buffer].length;
        let newLength = dart.notNull(_roundToPowerOf2(dart.notNull(chunk.length) + dart.notNull(oldLength))) * 2;
        let grown = new typed_data.Uint8List(newLength);
        grown.setRange(0, this[_buffer].length, this[_buffer]);
        this[_buffer] = grown;
      }
      this[_buffer].setRange(this[_bufferIndex], dart.notNull(this[_bufferIndex]) + dart.notNull(chunk.length), chunk);
      this[_bufferIndex] = chunk.length;
    }
    static [_roundToPowerOf2](v) {
      dart.assert(dart.notNull(v) > 0);
      v = dart.notNull(v) - 1;
      v = dart.notNull(v) >> 1;
      v = dart.notNull(v) >> 2;
      v = dart.notNull(v) >> 4;
      v = dart.notNull(v) >> 8;
      v = dart.notNull(v) >> 16;
      v = dart.notNull(v) + 1;
      return v;
    }
    close() {
      this[_callback](this[_buffer].sublist(0, this[_bufferIndex]));
    }
  }
  _ByteCallbackSink._INITIAL_BUFFER_SIZE = 1024;
  let ChunkedConversionSink$ = dart.generic(function(T) {
    class ChunkedConversionSink extends core.Object {
      ChunkedConversionSink() {
      }
      ChunkedConversionSink$withCallback(callback) {
        return new _SimpleCallbackSink(callback);
      }
    }
    dart.defineNamedConstructor(ChunkedConversionSink, 'withCallback');
    return ChunkedConversionSink;
  });
  let ChunkedConversionSink = ChunkedConversionSink$(dart.dynamic);
  let _accumulated = Symbol('_accumulated');
  let _SimpleCallbackSink$ = dart.generic(function(T) {
    class _SimpleCallbackSink extends ChunkedConversionSink$(T) {
      _SimpleCallbackSink($_callback) {
        this[_accumulated] = new List.from([]);
        this[_callback] = $_callback;
        super.ChunkedConversionSink();
      }
      add(chunk) {
        this[_accumulated].add(chunk);
      }
      close() {
        this[_callback](this[_accumulated]);
      }
    }
    return _SimpleCallbackSink;
  });
  let _SimpleCallbackSink = _SimpleCallbackSink$(dart.dynamic);
  let _EventSinkAdapter$ = dart.generic(function(T) {
    class _EventSinkAdapter extends core.Object {
      _EventSinkAdapter($_sink) {
        this[_sink] = $_sink;
      }
      add(data) {
        return this[_sink].add(data);
      }
      close() {
        return this[_sink].close();
      }
    }
    return _EventSinkAdapter;
  });
  let _EventSinkAdapter = _EventSinkAdapter$(dart.dynamic);
  let _eventSink = Symbol('_eventSink');
  let _chunkedSink = Symbol('_chunkedSink');
  let _ConverterStreamEventSink$ = dart.generic(function(S, T) {
    class _ConverterStreamEventSink extends core.Object {
      _ConverterStreamEventSink(converter, sink) {
        this[_eventSink] = sink;
        this[_chunkedSink] = converter.startChunkedConversion(sink);
      }
      add(o) {
        return this[_chunkedSink].add(o);
      }
      addError(error, stackTrace) {
        if (stackTrace === void 0)
          stackTrace = null;
        this[_eventSink].addError(error, stackTrace);
      }
      close() {
        return this[_chunkedSink].close();
      }
    }
    return _ConverterStreamEventSink;
  });
  let _ConverterStreamEventSink = _ConverterStreamEventSink$(dart.dynamic, dart.dynamic);
  let Codec$ = dart.generic(function(S, T) {
    class Codec extends core.Object {
      Codec() {
      }
      encode(input) {
        return this.encoder.convert(input);
      }
      decode(encoded) {
        return this.decoder.convert(encoded);
      }
      fuse(other) {
        return new _FusedCodec(this, other);
      }
      get inverted() {
        return new _InvertedCodec(this);
      }
    }
    return Codec;
  });
  let Codec = Codec$(dart.dynamic, dart.dynamic);
  let _first = Symbol('_first');
  let _second = Symbol('_second');
  let _FusedCodec$ = dart.generic(function(S, M, T) {
    class _FusedCodec extends Codec$(S, T) {
      get encoder() {
        return dart.as(this[_first].encoder.fuse(this[_second].encoder), Converter$(S, T));
      }
      get decoder() {
        return dart.as(this[_second].decoder.fuse(this[_first].decoder), Converter$(T, S));
      }
      _FusedCodec($_first, $_second) {
        this[_first] = $_first;
        this[_second] = $_second;
        super.Codec();
      }
    }
    return _FusedCodec;
  });
  let _FusedCodec = _FusedCodec$(dart.dynamic, dart.dynamic, dart.dynamic);
  let _codec = Symbol('_codec');
  let _InvertedCodec$ = dart.generic(function(T, S) {
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
    return _InvertedCodec;
  });
  let _InvertedCodec = _InvertedCodec$(dart.dynamic, dart.dynamic);
  let Converter$ = dart.generic(function(S, T) {
    class Converter extends core.Object {
      Converter() {
      }
      fuse(other) {
        return new _FusedConverter(this, other);
      }
      startChunkedConversion(sink) {
        throw new core.UnsupportedError(`This converter does not support chunked conversions: ${this}`);
      }
      bind(source) {
        return new async.Stream.eventTransformed(source, ((sink) => new _ConverterStreamEventSink(this, sink)).bind(this));
      }
    }
    return Converter;
  });
  let Converter = Converter$(dart.dynamic, dart.dynamic);
  let _FusedConverter$ = dart.generic(function(S, M, T) {
    class _FusedConverter extends Converter$(S, T) {
      _FusedConverter($_first, $_second) {
        this[_first] = $_first;
        this[_second] = $_second;
        super.Converter();
      }
      convert(input) {
        return dart.as(this[_second].convert(this[_first].convert(input)), T);
      }
      startChunkedConversion(sink) {
        return this[_first].startChunkedConversion(this[_second].startChunkedConversion(sink));
      }
    }
    return _FusedConverter;
  });
  let _FusedConverter = _FusedConverter$(dart.dynamic, dart.dynamic, dart.dynamic);
  class Encoding extends Codec$(core.String, core.List$(core.int)) {
    Encoding() {
      super.Codec();
    }
    decodeStream(byteStream) {
      return dart.as(byteStream.transform(dart.as(this.decoder, async.StreamTransformer$(core.List$(core.int), dynamic))).fold(new core.StringBuffer(), (buffer, string) => dart.dinvoke(buffer, 'write', string), buffer).then((buffer) => dart.dinvoke(buffer, 'toString')), async.Future$(core.String));
    }
    static getByName(name) {
      if (name === null)
        return null;
      name = name.toLowerCase();
      return _nameToEncoding.get(name);
    }
  }
  dart.defineLazyProperties(Encoding, {
    get _nameToEncoding() {
      return dart.map({"iso_8859-1:1987": LATIN1, "iso-ir-100": LATIN1, "iso_8859-1": LATIN1, "iso-8859-1": LATIN1, latin1: LATIN1, l1: LATIN1, ibm819: LATIN1, cp819: LATIN1, csisolatin1: LATIN1, "iso-ir-6": ASCII, "ansi_x3.4-1968": ASCII, "ansi_x3.4-1986": ASCII, "iso_646.irv:1991": ASCII, "iso646-us": ASCII, "us-ascii": ASCII, us: ASCII, ibm367: ASCII, cp367: ASCII, csascii: ASCII, ascii: ASCII, csutf8: UTF8, "utf-8": UTF8});
    },
    set _nameToEncoding(_) {}
  });
  let HTML_ESCAPE = new HtmlEscape();
  let _name = Symbol('_name');
  class HtmlEscapeMode extends core.Object {
    HtmlEscapeMode$_($_name, escapeLtGt, escapeQuot, escapeApos, escapeSlash) {
      this[_name] = $_name;
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
  HtmlEscapeMode.UNKNOWN = new HtmlEscapeMode._('unknown', true, true, true, true);
  HtmlEscapeMode.ATTRIBUTE = new HtmlEscapeMode._('attribute', false, true, false, false);
  HtmlEscapeMode.ELEMENT = new HtmlEscapeMode._('element', true, false, false, true);
  let _convert = Symbol('_convert');
  class HtmlEscape extends Converter$(core.String, core.String) {
    HtmlEscape(mode) {
      if (mode === void 0)
        mode = HtmlEscapeMode.UNKNOWN;
      this.mode = mode;
      super.Converter();
    }
    convert(text) {
      let val = this[_convert](text, 0, text.length);
      return val === null ? text : val;
    }
    [_convert](text, start, end) {
      let result = null;
      for (let i = start; dart.notNull(i) < dart.notNull(end); i = dart.notNull(i) + 1) {
        let ch = text.get(i);
        let replace = null;
        switch (ch) {
          case '&':
            replace = '&amp;';
            break;
          case ' ':
            replace = '&nbsp;';
            break;
          case '"':
            if (this.mode.escapeQuot)
              replace = '&quot;';
            break;
          case "'":
            if (this.mode.escapeApos)
              replace = '&#x27;';
            break;
          case '<':
            if (this.mode.escapeLtGt)
              replace = '&lt;';
            break;
          case '>':
            if (this.mode.escapeLtGt)
              replace = '&gt;';
            break;
          case '/':
            if (this.mode.escapeSlash)
              replace = '&#x2F;';
            break;
        }
        if (replace !== null) {
          if (result === null)
            result = new core.StringBuffer(text.substring(start, i));
          result.write(replace);
        } else if (result !== null) {
          result.write(ch);
        }
      }
      return result !== null ? result.toString() : null;
    }
    startChunkedConversion(sink) {
      if (!dart.is(sink, StringConversionSink)) {
        sink = new StringConversionSink.from(sink);
      }
      return new _HtmlEscapeSink(this, dart.as(sink, StringConversionSink));
    }
  }
  let _escape = Symbol('_escape');
  class _HtmlEscapeSink extends StringConversionSinkBase {
    _HtmlEscapeSink($_escape, $_sink) {
      this[_escape] = $_escape;
      this[_sink] = $_sink;
      super.StringConversionSinkBase();
    }
    addSlice(chunk, start, end, isLast) {
      let val = this[_escape]._convert(chunk, start, end);
      if (val === null) {
        this[_sink].addSlice(chunk, start, end, isLast);
      } else {
        this[_sink].add(val);
        if (isLast)
          this[_sink].close();
      }
    }
    close() {
      return this[_sink].close();
    }
  }
  class JsonUnsupportedObjectError extends core.Error {
    JsonUnsupportedObjectError(unsupportedObject, opt$) {
      let cause = opt$.cause === void 0 ? null : opt$.cause;
      this.unsupportedObject = unsupportedObject;
      this.cause = cause;
      super.Error();
    }
    toString() {
      if (this.cause !== null) {
        return "Converting object to an encodable object failed.";
      } else {
        return "Converting object did not return an encodable object.";
      }
    }
  }
  class JsonCyclicError extends JsonUnsupportedObjectError {
    JsonCyclicError(object) {
      super.JsonUnsupportedObjectError(object);
    }
    toString() {
      return "Cyclic error in JSON stringify";
    }
  }
  let JSON = new JsonCodec();
  let _reviver = Symbol('_reviver');
  let _toEncodable = Symbol('_toEncodable');
  class JsonCodec extends Codec$(core.Object, core.String) {
    JsonCodec(opt$) {
      let reviver = opt$.reviver === void 0 ? null : opt$.reviver;
      let toEncodable = opt$.toEncodable === void 0 ? null : opt$.toEncodable;
      this[_reviver] = reviver;
      this[_toEncodable] = toEncodable;
      super.Codec();
    }
    JsonCodec$withReviver(reviver) {
      this.JsonCodec({reviver: reviver});
    }
    decode(source, opt$) {
      let reviver = opt$.reviver === void 0 ? null : opt$.reviver;
      if (reviver === null)
        reviver = this[_reviver];
      if (reviver === null)
        return this.decoder.convert(source);
      return new JsonDecoder(reviver).convert(source);
    }
    encode(value, opt$) {
      let toEncodable = opt$.toEncodable === void 0 ? null : opt$.toEncodable;
      if (toEncodable === null)
        toEncodable = this[_toEncodable];
      if (toEncodable === null)
        return this.encoder.convert(value);
      return new JsonEncoder(dart.as(toEncodable, dart.throw_("Unimplemented type (Object) → Object"))).convert(value);
    }
    get encoder() {
      if (this[_toEncodable] === null)
        return new JsonEncoder();
      return new JsonEncoder(dart.as(this[_toEncodable], dart.throw_("Unimplemented type (Object) → Object")));
    }
    get decoder() {
      if (this[_reviver] === null)
        return new JsonDecoder();
      return new JsonDecoder(this[_reviver]);
    }
  }
  dart.defineNamedConstructor(JsonCodec, 'withReviver');
  class JsonEncoder extends Converter$(core.Object, core.String) {
    JsonEncoder(toEncodable) {
      if (toEncodable === void 0)
        toEncodable = null;
      this.indent = null;
      this[_toEncodable] = toEncodable;
      super.Converter();
    }
    JsonEncoder$withIndent(indent, toEncodable) {
      if (toEncodable === void 0)
        toEncodable = null;
      this.indent = indent;
      this[_toEncodable] = toEncodable;
      super.Converter();
    }
    convert(object) {
      return _JsonStringStringifier.stringify(object, dart.as(this[_toEncodable], dart.throw_("Unimplemented type (dynamic) → dynamic")), this.indent);
    }
    startChunkedConversion(sink) {
      if (!dart.is(sink, StringConversionSink)) {
        sink = new StringConversionSink.from(sink);
      } else if (dart.is(sink, _Utf8EncoderSink)) {
        return new _JsonUtf8EncoderSink(sink[_sink], this[_toEncodable], JsonUtf8Encoder._utf8Encode(this.indent), JsonUtf8Encoder.DEFAULT_BUFFER_SIZE);
      }
      return new _JsonEncoderSink(dart.as(sink, StringConversionSink), this[_toEncodable], this.indent);
    }
    bind(stream) {
      return dart.as(super.bind(stream), async.Stream$(core.String));
    }
    fuse(other) {
      if (dart.is(other, Utf8Encoder)) {
        return new JsonUtf8Encoder(this.indent, dart.as(this[_toEncodable], dart.throw_("Unimplemented type (Object) → dynamic")));
      }
      return super.fuse(other);
    }
  }
  dart.defineNamedConstructor(JsonEncoder, 'withIndent');
  let _indent = Symbol('_indent');
  let _bufferSize = Symbol('_bufferSize');
  let _utf8Encode = Symbol('_utf8Encode');
  class JsonUtf8Encoder extends Converter$(core.Object, core.List$(core.int)) {
    JsonUtf8Encoder(indent, toEncodable, bufferSize) {
      if (indent === void 0)
        indent = null;
      if (toEncodable === void 0)
        toEncodable = null;
      if (bufferSize === void 0)
        bufferSize = JsonUtf8Encoder.DEFAULT_BUFFER_SIZE;
      this[_indent] = _utf8Encode(indent);
      this[_toEncodable] = toEncodable;
      this[_bufferSize] = bufferSize;
      super.Converter();
    }
    static [_utf8Encode](string) {
      if (string === null)
        return null;
      if (string.isEmpty)
        return new typed_data.Uint8List(0);
      checkAscii: {
        for (let i = 0; dart.notNull(i) < dart.notNull(string.length); i = dart.notNull(i) + 1) {
          if (dart.notNull(string.codeUnitAt(i)) >= 128)
            break checkAscii;
        }
        return string.codeUnits;
      }
      return UTF8.encode(string);
    }
    convert(object) {
      let bytes = dart.as(new List.from([]), core.List$(core.List$(core.int)));
      // Function addChunk: (Uint8List, int, int) → void
      function addChunk(chunk, start, end) {
        if (dart.notNull(start) > 0 || dart.notNull(end) < dart.notNull(chunk.length)) {
          let length = dart.notNull(end) - dart.notNull(start);
          chunk = new typed_data.Uint8List.view(chunk.buffer, dart.notNull(chunk.offsetInBytes) + dart.notNull(start), length);
        }
        bytes.add(chunk);
      }
      _JsonUtf8Stringifier.stringify(object, this[_indent], dart.as(this[_toEncodable], dart.throw_("Unimplemented type (Object) → dynamic")), this[_bufferSize], addChunk);
      if (bytes.length === 1)
        return bytes.get(0);
      let length = 0;
      for (let i = 0; dart.notNull(i) < dart.notNull(bytes.length); i = dart.notNull(i) + 1) {
        length = bytes.get(i).length;
      }
      let result = new typed_data.Uint8List(length);
      for (let i = 0, offset = 0; dart.notNull(i) < dart.notNull(bytes.length); i = dart.notNull(i) + 1) {
        let byteList = bytes.get(i);
        let end = dart.notNull(offset) + dart.notNull(byteList.length);
        result.setRange(offset, end, byteList);
        offset = end;
      }
      return result;
    }
    startChunkedConversion(sink) {
      let byteSink = null;
      if (dart.is(sink, ByteConversionSink)) {
        byteSink = sink;
      } else {
        byteSink = new ByteConversionSink.from(sink);
      }
      return new _JsonUtf8EncoderSink(byteSink, this[_toEncodable], this[_indent], this[_bufferSize]);
    }
    bind(stream) {
      return dart.as(super.bind(stream), async.Stream$(core.List$(core.int)));
    }
    fuse(other) {
      return super.fuse(other);
    }
  }
  JsonUtf8Encoder.DEFAULT_BUFFER_SIZE = 256;
  let _isDone = Symbol('_isDone');
  class _JsonEncoderSink extends ChunkedConversionSink$(core.Object) {
    _JsonEncoderSink($_sink, $_toEncodable, $_indent) {
      this[_sink] = $_sink;
      this[_toEncodable] = $_toEncodable;
      this[_indent] = $_indent;
      this[_isDone] = false;
      super.ChunkedConversionSink();
    }
    add(o) {
      if (this[_isDone]) {
        throw new core.StateError("Only one call to add allowed");
      }
      this[_isDone] = true;
      let stringSink = this[_sink].asStringSink();
      _JsonStringStringifier.printOn(o, stringSink, dart.as(this[_toEncodable], dart.throw_("Unimplemented type (dynamic) → dynamic")), this[_indent]);
      stringSink.close();
    }
    close() {}
  }
  let _addChunk = Symbol('_addChunk');
  class _JsonUtf8EncoderSink extends ChunkedConversionSink$(core.Object) {
    _JsonUtf8EncoderSink($_sink, $_toEncodable, $_indent, $_bufferSize) {
      this[_sink] = $_sink;
      this[_toEncodable] = $_toEncodable;
      this[_indent] = $_indent;
      this[_bufferSize] = $_bufferSize;
      this[_isDone] = false;
      super.ChunkedConversionSink();
    }
    [_addChunk](chunk, start, end) {
      this[_sink].addSlice(chunk, start, end, false);
    }
    add(object) {
      if (this[_isDone]) {
        throw new core.StateError("Only one call to add allowed");
      }
      this[_isDone] = true;
      _JsonUtf8Stringifier.stringify(object, this[_indent], dart.as(this[_toEncodable], dart.throw_("Unimplemented type (Object) → dynamic")), this[_bufferSize], this[_addChunk]);
      this[_sink].close();
    }
    close() {
      if (!dart.notNull(this[_isDone])) {
        this[_isDone] = true;
        this[_sink].close();
      }
    }
  }
  class JsonDecoder extends Converter$(core.String, core.Object) {
    JsonDecoder(reviver) {
      if (reviver === void 0)
        reviver = null;
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
      return dart.as(super.bind(stream), async.Stream$(core.Object));
    }
  }
  // Function _parseJson: (String, (dynamic, dynamic) → dynamic) → dynamic
  function _parseJson(source, reviver) {
    if (!(typeof source == string))
      throw new core.ArgumentError(source);
    let parsed = null;
    try {
      parsed = JSON.parse(source);
    } catch (e) {
      throw new core.FormatException(String(e));
    }

    if (reviver === null) {
      return _convertJsonToDartLazy(parsed);
    } else {
      return _convertJsonToDart(parsed, reviver);
    }
  }
  // Function _defaultToEncodable: (dynamic) → Object
  function _defaultToEncodable(object) {
    return dart.dinvoke(object, 'toJson');
  }
  let _seen = Symbol('_seen');
  let _checkCycle = Symbol('_checkCycle');
  let _removeSeen = Symbol('_removeSeen');
  class _JsonStringifier extends core.Object {
    _JsonStringifier(_toEncodable) {
      this[_seen] = new core.List();
      this[_toEncodable] = dart.as(_toEncodable !== null ? _toEncodable : _defaultToEncodable, core.Function);
    }
    static hexDigit(x) {
      return dart.notNull(x) < 10 ? 48 + dart.notNull(x) : 87 + dart.notNull(x);
    }
    writeStringContent(s) {
      let offset = 0;
      let length = s.length;
      for (let i = 0; dart.notNull(i) < dart.notNull(length); i = dart.notNull(i) + 1) {
        let charCode = s.codeUnitAt(i);
        if (dart.notNull(charCode) > dart.notNull(_JsonStringifier.BACKSLASH))
          continue;
        if (dart.notNull(charCode) < 32) {
          if (dart.notNull(i) > dart.notNull(offset))
            this.writeStringSlice(s, offset, i);
          offset = dart.notNull(i) + 1;
          this.writeCharCode(_JsonStringifier.BACKSLASH);
          switch (charCode) {
            case _JsonStringifier.BACKSPACE:
              this.writeCharCode(_JsonStringifier.CHAR_b);
              break;
            case _JsonStringifier.TAB:
              this.writeCharCode(_JsonStringifier.CHAR_t);
              break;
            case _JsonStringifier.NEWLINE:
              this.writeCharCode(_JsonStringifier.CHAR_n);
              break;
            case _JsonStringifier.FORM_FEED:
              this.writeCharCode(_JsonStringifier.CHAR_f);
              break;
            case _JsonStringifier.CARRIAGE_RETURN:
              this.writeCharCode(_JsonStringifier.CHAR_r);
              break;
            default:
              this.writeCharCode(_JsonStringifier.CHAR_u);
              this.writeCharCode(_JsonStringifier.CHAR_0);
              this.writeCharCode(_JsonStringifier.CHAR_0);
              this.writeCharCode(hexDigit(dart.notNull(charCode) >> 4 & 15));
              this.writeCharCode(hexDigit(dart.notNull(charCode) & 15));
              break;
          }
        } else if (charCode === _JsonStringifier.QUOTE || charCode === _JsonStringifier.BACKSLASH) {
          if (dart.notNull(i) > dart.notNull(offset))
            this.writeStringSlice(s, offset, i);
          offset = dart.notNull(i) + 1;
          this.writeCharCode(_JsonStringifier.BACKSLASH);
          this.writeCharCode(charCode);
        }
      }
      if (offset === 0) {
        this.writeString(s);
      } else if (dart.notNull(offset) < dart.notNull(length)) {
        this.writeStringSlice(s, offset, length);
      }
    }
    [_checkCycle](object) {
      for (let i = 0; dart.notNull(i) < dart.notNull(this[_seen].length); i = dart.notNull(i) + 1) {
        if (core.identical(object, this[_seen].get(i))) {
          throw new JsonCyclicError(object);
        }
      }
      this[_seen].add(object);
    }
    [_removeSeen](object) {
      dart.assert(!dart.notNull(this[_seen].isEmpty));
      dart.assert(core.identical(this[_seen].last, object));
      this[_seen].removeLast();
    }
    writeObject(object) {
      if (this.writeJsonValue(object))
        return;
      this[_checkCycle](object);
      try {
        let customJson = dart.dinvokef(this[_toEncodable], object);
        if (!dart.notNull(this.writeJsonValue(customJson))) {
          throw new JsonUnsupportedObjectError(object);
        }
        this[_removeSeen](object);
      } catch (e) {
        throw new JsonUnsupportedObjectError(object, {cause: e});
      }

    }
    writeJsonValue(object) {
      if (dart.is(object, core.num)) {
        if (dart.dunary('!', dart.dload(object, 'isFinite')))
          return false;
        this.writeNumber(dart.as(object, core.num));
        return true;
      } else if (core.identical(object, true)) {
        this.writeString('true');
        return true;
      } else if (core.identical(object, false)) {
        this.writeString('false');
        return true;
      } else if (object === null) {
        this.writeString('null');
        return true;
      } else if (typeof object == string) {
        this.writeString('"');
        this.writeStringContent(dart.as(object, core.String));
        this.writeString('"');
        return true;
      } else if (dart.is(object, core.List)) {
        this[_checkCycle](object);
        this.writeList(dart.as(object, core.List));
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
      if (dart.notNull(list.length) > 0) {
        this.writeObject(list.get(0));
        for (let i = 1; dart.notNull(i) < dart.notNull(list.length); i = dart.notNull(i) + 1) {
          this.writeString(',');
          this.writeObject(list.get(i));
        }
      }
      this.writeString(']');
    }
    writeMap(map) {
      this.writeString('{');
      let separator = '"';
      map.forEach(((key, value) => {
        this.writeString(separator);
        separator = ',"';
        this.writeStringContent(key);
        this.writeString('":');
        this.writeObject(value);
      }).bind(this));
      this.writeString('}');
    }
  }
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
  let _indentLevel = Symbol('_indentLevel');
  class _JsonPrettyPrintMixin extends core.Object {
    _JsonPrettyPrintMixin() {
      this[_indentLevel] = 0;
    }
    writeList(list) {
      if (list.isEmpty) {
        this.writeString('[]');
      } else {
        this.writeString('[\n');
        this[_indentLevel] = dart.notNull(this[_indentLevel]) + 1;
        this.writeIndentation(this[_indentLevel]);
        this.writeObject(list.get(0));
        for (let i = 1; dart.notNull(i) < dart.notNull(list.length); i = dart.notNull(i) + 1) {
          this.writeString(',\n');
          this.writeIndentation(this[_indentLevel]);
          this.writeObject(list.get(i));
        }
        this.writeString('\n');
        this[_indentLevel] = dart.notNull(this[_indentLevel]) - 1;
        this.writeIndentation(this[_indentLevel]);
        this.writeString(']');
      }
    }
    writeMap(map) {
      if (map.isEmpty) {
        this.writeString('{}');
      } else {
        this.writeString('{\n');
        this[_indentLevel] = dart.notNull(this[_indentLevel]) + 1;
        let first = true;
        map.forEach(dart.as(((key, value) => {
          if (!dart.notNull(first)) {
            this.writeString(",\n");
          }
          this.writeIndentation(this[_indentLevel]);
          this.writeString('"');
          this.writeStringContent(key);
          this.writeString('": ');
          this.writeObject(value);
          first = false;
        }).bind(this), dart.throw_("Unimplemented type (dynamic, dynamic) → void")));
        this.writeString('\n');
        this[_indentLevel] = dart.notNull(this[_indentLevel]) - 1;
        this.writeIndentation(this[_indentLevel]);
        this.writeString('}');
      }
    }
  }
  class _JsonStringStringifier extends _JsonStringifier {
    _JsonStringStringifier($_sink, _toEncodable) {
      this[_sink] = $_sink;
      super._JsonStringifier(dart.as(_toEncodable, dart.throw_("Unimplemented type (Object) → Object")));
    }
    static stringify(object, toEncodable, indent) {
      let output = new core.StringBuffer();
      printOn(object, output, toEncodable, indent);
      return output.toString();
    }
    static printOn(object, output, toEncodable, indent) {
      let stringifier = null;
      if (indent === null) {
        stringifier = new _JsonStringStringifier(output, toEncodable);
      } else {
        stringifier = new _JsonStringStringifierPretty(output, toEncodable, indent);
      }
      dart.dinvoke(stringifier, 'writeObject', object);
    }
    writeNumber(number) {
      this[_sink].write(number.toString());
    }
    writeString(string) {
      this[_sink].write(string);
    }
    writeStringSlice(string, start, end) {
      this[_sink].write(string.substring(start, end));
    }
    writeCharCode(charCode) {
      this[_sink].writeCharCode(charCode);
    }
  }
  class _JsonStringStringifierPretty extends dart.mixin(_JsonStringStringifier, _JsonPrettyPrintMixin) {
    _JsonStringStringifierPretty(sink, toEncodable, $_indent) {
      this[_indent] = $_indent;
      super._JsonStringStringifier(sink, toEncodable);
    }
    writeIndentation(count) {
      for (let i = 0; dart.notNull(i) < dart.notNull(count); i = dart.notNull(i) + 1)
        this.writeString(this[_indent]);
    }
  }
  class _JsonUtf8Stringifier extends _JsonStringifier {
    _JsonUtf8Stringifier(toEncodable, bufferSize, addChunk) {
      this.addChunk = addChunk;
      this.bufferSize = bufferSize;
      this.buffer = new typed_data.Uint8List(bufferSize);
      this.index = 0;
      super._JsonStringifier(dart.as(toEncodable, dart.throw_("Unimplemented type (Object) → Object")));
    }
    static stringify(object, indent, toEncodableFunction, bufferSize, addChunk) {
      let stringifier = null;
      if (indent !== null) {
        stringifier = new _JsonUtf8StringifierPretty(toEncodableFunction, indent, bufferSize, addChunk);
      } else {
        stringifier = new _JsonUtf8Stringifier(toEncodableFunction, bufferSize, addChunk);
      }
      stringifier.writeObject(object);
      stringifier.flush();
    }
    flush() {
      if (dart.notNull(this.index) > 0) {
        dart.dinvokef(this.addChunk, this.buffer, 0, this.index);
      }
      this.buffer = null;
      this.index = 0;
    }
    writeNumber(number) {
      this.writeAsciiString(number.toString());
    }
    writeAsciiString(string) {
      for (let i = 0; dart.notNull(i) < dart.notNull(string.length); i = dart.notNull(i) + 1) {
        let char = string.codeUnitAt(i);
        dart.assert(dart.notNull(char) <= 127);
        this.writeByte(char);
      }
    }
    writeString(string) {
      this.writeStringSlice(string, 0, string.length);
    }
    writeStringSlice(string, start, end) {
      for (let i = start; dart.notNull(i) < dart.notNull(end); i = dart.notNull(i) + 1) {
        let char = string.codeUnitAt(i);
        if (dart.notNull(char) <= 127) {
          this.writeByte(char);
        } else {
          if ((dart.notNull(char) & 64512) === 55296 && dart.notNull(i) + 1 < dart.notNull(end)) {
            let nextChar = string.codeUnitAt(dart.notNull(i) + 1);
            if ((dart.notNull(nextChar) & 64512) === 56320) {
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
      if (this.index === this.buffer.length) {
        dart.dinvokef(this.addChunk, this.buffer, 0, this.index);
        this.buffer = new typed_data.Uint8List(this.bufferSize);
        this.index = 0;
      }
      this.buffer.set((($tmp) => this.index = dart.notNull($tmp) + 1, $tmp).bind(this)(this.index), byte);
    }
  }
  class _JsonUtf8StringifierPretty extends dart.mixin(_JsonUtf8Stringifier, _JsonPrettyPrintMixin) {
    _JsonUtf8StringifierPretty(toEncodableFunction, indent, bufferSize, addChunk) {
      this.indent = indent;
      super._JsonUtf8Stringifier(toEncodableFunction, dart.as(bufferSize, core.int), dart.as(addChunk, core.Function));
    }
    writeIndentation(count) {
      let indent = this.indent;
      let indentLength = indent.length;
      if (indentLength === 1) {
        let char = indent.get(0);
        while (dart.notNull(count) > 0) {
          this.writeByte(char);
          count = 1;
        }
        return;
      }
      while (dart.notNull(count) > 0) {
        count = dart.notNull(count) - 1;
        let end = dart.notNull(this.index) + dart.notNull(indentLength);
        if (dart.notNull(end) <= dart.notNull(this.buffer.length)) {
          this.buffer.setRange(this.index, end, indent);
          this.index = end;
        } else {
          for (let i = 0; dart.notNull(i) < dart.notNull(indentLength); i = dart.notNull(i) + 1) {
            this.writeByte(indent.get(i));
          }
        }
      }
    }
  }
  let LATIN1 = new Latin1Codec();
  let _LATIN1_MASK = 255;
  class Latin1Codec extends Encoding {
    Latin1Codec(opt$) {
      let allowInvalid = opt$.allowInvalid === void 0 ? false : opt$.allowInvalid;
      this[_allowInvalid] = allowInvalid;
      super.Encoding();
    }
    get name() {
      return "iso-8859-1";
    }
    decode(bytes, opt$) {
      let allowInvalid = opt$.allowInvalid === void 0 ? null : opt$.allowInvalid;
      if (allowInvalid === null)
        allowInvalid = this[_allowInvalid];
      if (allowInvalid) {
        return new Latin1Decoder({allowInvalid: true}).convert(bytes);
      } else {
        return new Latin1Decoder({allowInvalid: false}).convert(bytes);
      }
    }
    get encoder() {
      return new Latin1Encoder();
    }
    get decoder() {
      return this[_allowInvalid] ? new Latin1Decoder({allowInvalid: true}) : new Latin1Decoder({allowInvalid: false});
    }
  }
  class Latin1Encoder extends _UnicodeSubsetEncoder {
    Latin1Encoder() {
      super._UnicodeSubsetEncoder(_LATIN1_MASK);
    }
  }
  class Latin1Decoder extends _UnicodeSubsetDecoder {
    Latin1Decoder(opt$) {
      let allowInvalid = opt$.allowInvalid === void 0 ? false : opt$.allowInvalid;
      super._UnicodeSubsetDecoder(allowInvalid, _LATIN1_MASK);
    }
    startChunkedConversion(sink) {
      let stringSink = null;
      if (dart.is(sink, StringConversionSink)) {
        stringSink = sink;
      } else {
        stringSink = new StringConversionSink.from(sink);
      }
      if (!dart.notNull(this[_allowInvalid]))
        return new _Latin1DecoderSink(stringSink);
      return new _Latin1AllowInvalidDecoderSink(stringSink);
    }
  }
  let _addSliceToSink = Symbol('_addSliceToSink');
  class _Latin1DecoderSink extends ByteConversionSinkBase {
    _Latin1DecoderSink($_sink) {
      this[_sink] = $_sink;
      super.ByteConversionSinkBase();
    }
    close() {
      this[_sink].close();
    }
    add(source) {
      this.addSlice(source, 0, source.length, false);
    }
    [_addSliceToSink](source, start, end, isLast) {
      this[_sink].add(new core.String.fromCharCodes(source, start, end));
      if (isLast)
        this.close();
    }
    addSlice(source, start, end, isLast) {
      core.RangeError.checkValidRange(start, end, source.length);
      for (let i = start; dart.notNull(i) < dart.notNull(end); i = dart.notNull(i) + 1) {
        let char = source.get(i);
        if (dart.notNull(char) > dart.notNull(_LATIN1_MASK) || dart.notNull(char) < 0) {
          throw new core.FormatException("Source contains non-Latin-1 characters.");
        }
      }
      if (dart.notNull(start) < dart.notNull(end)) {
        this[_addSliceToSink](source, start, end, isLast);
      }
      if (isLast) {
        this.close();
      }
    }
  }
  class _Latin1AllowInvalidDecoderSink extends _Latin1DecoderSink {
    _Latin1AllowInvalidDecoderSink(sink) {
      super._Latin1DecoderSink(sink);
    }
    addSlice(source, start, end, isLast) {
      core.RangeError.checkValidRange(start, end, source.length);
      for (let i = start; dart.notNull(i) < dart.notNull(end); i = dart.notNull(i) + 1) {
        let char = source.get(i);
        if (dart.notNull(char) > dart.notNull(_LATIN1_MASK) || dart.notNull(char) < 0) {
          if (dart.notNull(i) > dart.notNull(start))
            this[_addSliceToSink](source, start, i, false);
          this[_addSliceToSink](dart.as(/* Unimplemented const */new List.from([65533]), core.List$(core.int)), 0, 1, false);
          start = dart.notNull(i) + 1;
        }
      }
      if (dart.notNull(start) < dart.notNull(end)) {
        this[_addSliceToSink](source, start, end, isLast);
      }
      if (isLast) {
        this.close();
      }
    }
  }
  class LineSplitter extends Converter$(core.String, core.List$(core.String)) {
    LineSplitter() {
      super.Converter();
    }
    convert(data) {
      let lines = new core.List();
      _LineSplitterSink._addSlice(data, 0, data.length, true, lines.add);
      return lines;
    }
    startChunkedConversion(sink) {
      if (!dart.is(sink, StringConversionSink)) {
        sink = new StringConversionSink.from(sink);
      }
      return new _LineSplitterSink(dart.as(sink, StringConversionSink));
    }
  }
  let _carry = Symbol('_carry');
  let _addSlice = Symbol('_addSlice');
  class _LineSplitterSink extends StringConversionSinkBase {
    _LineSplitterSink($_sink) {
      this[_sink] = $_sink;
      this[_carry] = null;
      super.StringConversionSinkBase();
    }
    addSlice(chunk, start, end, isLast) {
      if (this[_carry] !== null) {
        chunk = core.String['+'](this[_carry], chunk.substring(start, end));
        start = 0;
        end = chunk.length;
        this[_carry] = null;
      }
      this[_carry] = _addSlice(chunk, start, end, isLast, this[_sink].add);
      if (isLast)
        this[_sink].close();
    }
    close() {
      this.addSlice('', 0, 0, true);
    }
    static [_addSlice](chunk, start, end, isLast, adder) {
      let pos = start;
      while (dart.notNull(pos) < dart.notNull(end)) {
        let skip = 0;
        let char = chunk.codeUnitAt(pos);
        if (char === _LineSplitterSink._LF) {
          skip = 1;
        } else if (char === _LineSplitterSink._CR) {
          skip = 1;
          if (dart.notNull(pos) + 1 < dart.notNull(end)) {
            if (chunk.codeUnitAt(dart.notNull(pos) + 1) === _LineSplitterSink._LF) {
              skip = 2;
            }
          } else if (!dart.notNull(isLast)) {
            return chunk.substring(start, end);
          }
        }
        if (dart.notNull(skip) > 0) {
          adder(chunk.substring(start, pos));
          start = pos = dart.notNull(pos) + dart.notNull(skip);
        } else {
          pos = dart.notNull(pos) + 1;
        }
      }
      if (pos !== start) {
        let carry = chunk.substring(start, pos);
        if (isLast) {
          adder(carry);
        } else {
          return carry;
        }
      }
      return null;
    }
  }
  _LineSplitterSink._LF = 10;
  _LineSplitterSink._CR = 13;
  class StringConversionSink extends ChunkedConversionSink$(core.String) {
    StringConversionSink() {
      super.ChunkedConversionSink();
    }
    StringConversionSink$withCallback(callback) {
      return new _StringCallbackSink(callback);
    }
    StringConversionSink$from(sink) {
      return new _StringAdapterSink(sink);
    }
    StringConversionSink$fromStringSink(sink) {
      return new _StringSinkConversionSink(sink);
    }
  }
  dart.defineNamedConstructor(StringConversionSink, 'withCallback');
  dart.defineNamedConstructor(StringConversionSink, 'from');
  dart.defineNamedConstructor(StringConversionSink, 'fromStringSink');
  class ClosableStringSink extends core.StringSink {
    ClosableStringSink$fromStringSink(sink, onClose) {
      return new _ClosableStringSink(sink, onClose);
    }
  }
  dart.defineNamedConstructor(ClosableStringSink, 'fromStringSink');
  class _ClosableStringSink extends core.Object {
    _ClosableStringSink($_sink, $_callback) {
      this[_sink] = $_sink;
      this[_callback] = $_callback;
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
      if (o === void 0)
        o = "";
      return this[_sink].writeln(o);
    }
    writeAll(objects, separator) {
      if (separator === void 0)
        separator = "";
      return this[_sink].writeAll(objects, separator);
    }
  }
  let _flush = Symbol('_flush');
  class _StringConversionSinkAsStringSinkAdapter extends core.Object {
    _StringConversionSinkAsStringSinkAdapter($_chunkedSink) {
      this[_chunkedSink] = $_chunkedSink;
      this[_buffer] = new core.StringBuffer();
    }
    close() {
      if (this[_buffer].isNotEmpty)
        this[_flush]();
      this[_chunkedSink].close();
    }
    writeCharCode(charCode) {
      this[_buffer].writeCharCode(charCode);
      if (dart.notNull(this[_buffer].length) > dart.notNull(_StringConversionSinkAsStringSinkAdapter._MIN_STRING_SIZE))
        this[_flush]();
    }
    write(o) {
      if (this[_buffer].isNotEmpty)
        this[_flush]();
      let str = o.toString();
      this[_chunkedSink].add(o.toString());
    }
    writeln(o) {
      if (o === void 0)
        o = "";
      this[_buffer].writeln(o);
      if (dart.notNull(this[_buffer].length) > dart.notNull(_StringConversionSinkAsStringSinkAdapter._MIN_STRING_SIZE))
        this[_flush]();
    }
    writeAll(objects, separator) {
      if (separator === void 0)
        separator = "";
      if (this[_buffer].isNotEmpty)
        this[_flush]();
      let iterator = objects.iterator;
      if (!dart.notNull(iterator.moveNext()))
        return;
      if (separator.isEmpty) {
        do {
          this[_chunkedSink].add(dart.as(dart.dinvoke(iterator.current, 'toString'), core.String));
        } while (iterator.moveNext());
      } else {
        this[_chunkedSink].add(dart.as(dart.dinvoke(iterator.current, 'toString'), core.String));
        while (iterator.moveNext()) {
          this.write(separator);
          this[_chunkedSink].add(dart.as(dart.dinvoke(iterator.current, 'toString'), core.String));
        }
      }
    }
    [_flush]() {
      let accumulated = this[_buffer].toString();
      this[_buffer].clear();
      this[_chunkedSink].add(accumulated);
    }
  }
  _StringConversionSinkAsStringSinkAdapter._MIN_STRING_SIZE = 16;
  class StringConversionSinkBase extends StringConversionSinkMixin {
  }
  class StringConversionSinkMixin extends core.Object {
    add(str) {
      return this.addSlice(str, 0, str.length, false);
    }
    asUtf8Sink(allowMalformed) {
      return new _Utf8ConversionSink(this, allowMalformed);
    }
    asStringSink() {
      return new _StringConversionSinkAsStringSinkAdapter(this);
    }
  }
  let _stringSink = Symbol('_stringSink');
  class _StringSinkConversionSink extends StringConversionSinkBase {
    _StringSinkConversionSink($_stringSink) {
      this[_stringSink] = $_stringSink;
      super.StringConversionSinkBase();
    }
    close() {}
    addSlice(str, start, end, isLast) {
      if (start !== 0 || end !== str.length) {
        for (let i = start; dart.notNull(i) < dart.notNull(end); i = dart.notNull(i) + 1) {
          this[_stringSink].writeCharCode(str.codeUnitAt(i));
        }
      } else {
        this[_stringSink].write(str);
      }
      if (isLast)
        this.close();
    }
    add(str) {
      return this[_stringSink].write(str);
    }
    asUtf8Sink(allowMalformed) {
      return new _Utf8StringSinkAdapter(this, this[_stringSink], allowMalformed);
    }
    asStringSink() {
      return new ClosableStringSink.fromStringSink(this[_stringSink], this.close);
    }
  }
  class _StringCallbackSink extends _StringSinkConversionSink {
    _StringCallbackSink($_callback) {
      this[_callback] = $_callback;
      super._StringSinkConversionSink(new core.StringBuffer());
    }
    close() {
      let buffer = dart.as(this[_stringSink], core.StringBuffer);
      let accumulated = buffer.toString();
      buffer.clear();
      this[_callback](accumulated);
    }
    asUtf8Sink(allowMalformed) {
      return new _Utf8StringSinkAdapter(this, this[_stringSink], allowMalformed);
    }
  }
  class _StringAdapterSink extends StringConversionSinkBase {
    _StringAdapterSink($_sink) {
      this[_sink] = $_sink;
      super.StringConversionSinkBase();
    }
    add(str) {
      return this[_sink].add(str);
    }
    addSlice(str, start, end, isLast) {
      if (start === 0 && end === str.length) {
        this.add(str);
      } else {
        this.add(str.substring(start, end));
      }
      if (isLast)
        this.close();
    }
    close() {
      return this[_sink].close();
    }
  }
  let _decoder = Symbol('_decoder');
  class _Utf8StringSinkAdapter extends ByteConversionSink {
    _Utf8StringSinkAdapter($_sink, stringSink, allowMalformed) {
      this[_sink] = $_sink;
      this[_decoder] = new _Utf8Decoder(stringSink, allowMalformed);
      super.ByteConversionSink();
    }
    close() {
      this[_decoder].close();
      if (this[_sink] !== null)
        this[_sink].close();
    }
    add(chunk) {
      this.addSlice(chunk, 0, chunk.length, false);
    }
    addSlice(codeUnits, startIndex, endIndex, isLast) {
      this[_decoder].convert(codeUnits, startIndex, endIndex);
      if (isLast)
        this.close();
    }
  }
  let _Utf8ConversionSink$_ = Symbol('_Utf8ConversionSink$_');
  class _Utf8ConversionSink extends ByteConversionSink {
    _Utf8ConversionSink(sink, allowMalformed) {
      this[_Utf8ConversionSink$_](sink, new core.StringBuffer(), allowMalformed);
    }
    _Utf8ConversionSink$_($_chunkedSink, stringBuffer, allowMalformed) {
      this[_chunkedSink] = $_chunkedSink;
      this[_decoder] = new _Utf8Decoder(stringBuffer, allowMalformed);
      this[_buffer] = stringBuffer;
      super.ByteConversionSink();
    }
    close() {
      this[_decoder].close();
      if (this[_buffer].isNotEmpty) {
        let accumulated = this[_buffer].toString();
        this[_buffer].clear();
        this[_chunkedSink].addSlice(accumulated, 0, accumulated.length, true);
      } else {
        this[_chunkedSink].close();
      }
    }
    add(chunk) {
      this.addSlice(chunk, 0, chunk.length, false);
    }
    addSlice(chunk, startIndex, endIndex, isLast) {
      this[_decoder].convert(chunk, startIndex, endIndex);
      if (this[_buffer].isNotEmpty) {
        let accumulated = this[_buffer].toString();
        this[_chunkedSink].addSlice(accumulated, 0, accumulated.length, isLast);
        this[_buffer].clear();
        return;
      }
      if (isLast)
        this.close();
    }
  }
  dart.defineNamedConstructor(_Utf8ConversionSink, '_');
  let UNICODE_REPLACEMENT_CHARACTER_RUNE = 65533;
  let UNICODE_BOM_CHARACTER_RUNE = 65279;
  let UTF8 = new Utf8Codec();
  let _allowMalformed = Symbol('_allowMalformed');
  class Utf8Codec extends Encoding {
    Utf8Codec(opt$) {
      let allowMalformed = opt$.allowMalformed === void 0 ? false : opt$.allowMalformed;
      this[_allowMalformed] = allowMalformed;
      super.Encoding();
    }
    get name() {
      return "utf-8";
    }
    decode(codeUnits, opt$) {
      let allowMalformed = opt$.allowMalformed === void 0 ? null : opt$.allowMalformed;
      if (allowMalformed === null)
        allowMalformed = this[_allowMalformed];
      return new Utf8Decoder({allowMalformed: allowMalformed}).convert(codeUnits);
    }
    get encoder() {
      return new Utf8Encoder();
    }
    get decoder() {
      return new Utf8Decoder({allowMalformed: this[_allowMalformed]});
    }
  }
  class Utf8Encoder extends Converter$(core.String, core.List$(core.int)) {
    Utf8Encoder() {
      super.Converter();
    }
    convert(string, start, end) {
      if (start === void 0)
        start = 0;
      if (end === void 0)
        end = null;
      let stringLength = string.length;
      core.RangeError.checkValidRange(start, end, stringLength);
      if (end === null)
        end = stringLength;
      let length = dart.notNull(end) - dart.notNull(start);
      if (length === 0)
        return new typed_data.Uint8List(0);
      let encoder = new _Utf8Encoder.withBufferSize(dart.notNull(length) * 3);
      let endPosition = encoder._fillBuffer(string, start, end);
      dart.assert(dart.notNull(endPosition) >= dart.notNull(end) - 1);
      if (endPosition !== end) {
        let lastCodeUnit = string.codeUnitAt(dart.notNull(end) - 1);
        dart.assert(_isLeadSurrogate(lastCodeUnit));
        let wasCombined = encoder._writeSurrogate(lastCodeUnit, 0);
        dart.assert(!dart.notNull(wasCombined));
      }
      return encoder[_buffer].sublist(0, encoder[_bufferIndex]);
    }
    startChunkedConversion(sink) {
      if (!dart.is(sink, ByteConversionSink)) {
        sink = new ByteConversionSink.from(sink);
      }
      return new _Utf8EncoderSink(dart.as(sink, ByteConversionSink));
    }
    bind(stream) {
      return dart.as(super.bind(stream), async.Stream$(core.List$(core.int)));
    }
  }
  let _Utf8Encoder$withBufferSize = Symbol('_Utf8Encoder$withBufferSize');
  let _createBuffer = Symbol('_createBuffer');
  let _writeSurrogate = Symbol('_writeSurrogate');
  let _fillBuffer = Symbol('_fillBuffer');
  class _Utf8Encoder extends core.Object {
    _Utf8Encoder() {
      this[_Utf8Encoder$withBufferSize](_Utf8Encoder._DEFAULT_BYTE_BUFFER_SIZE);
    }
    _Utf8Encoder$withBufferSize(bufferSize) {
      this[_buffer] = _createBuffer(bufferSize);
      this[_carry] = 0;
      this[_bufferIndex] = 0;
    }
    static [_createBuffer](size) {
      return new typed_data.Uint8List(size);
    }
    [_writeSurrogate](leadingSurrogate, nextCodeUnit) {
      if (_isTailSurrogate(nextCodeUnit)) {
        let rune = _combineSurrogatePair(leadingSurrogate, nextCodeUnit);
        dart.assert(dart.notNull(rune) > dart.notNull(_THREE_BYTE_LIMIT));
        dart.assert(dart.notNull(rune) <= dart.notNull(_FOUR_BYTE_LIMIT));
        this[_buffer].set((($tmp) => this[_bufferIndex] = dart.notNull($tmp) + 1, $tmp).bind(this)(this[_bufferIndex]), 240 | dart.notNull(rune) >> 18);
        this[_buffer].set((($tmp) => this[_bufferIndex] = dart.notNull($tmp) + 1, $tmp).bind(this)(this[_bufferIndex]), 128 | dart.notNull(rune) >> 12 & 63);
        this[_buffer].set((($tmp) => this[_bufferIndex] = dart.notNull($tmp) + 1, $tmp).bind(this)(this[_bufferIndex]), 128 | dart.notNull(rune) >> 6 & 63);
        this[_buffer].set((($tmp) => this[_bufferIndex] = dart.notNull($tmp) + 1, $tmp).bind(this)(this[_bufferIndex]), 128 | dart.notNull(rune) & 63);
        return true;
      } else {
        this[_buffer].set((($tmp) => this[_bufferIndex] = dart.notNull($tmp) + 1, $tmp).bind(this)(this[_bufferIndex]), 224 | dart.notNull(leadingSurrogate) >> 12);
        this[_buffer].set((($tmp) => this[_bufferIndex] = dart.notNull($tmp) + 1, $tmp).bind(this)(this[_bufferIndex]), 128 | dart.notNull(leadingSurrogate) >> 6 & 63);
        this[_buffer].set((($tmp) => this[_bufferIndex] = dart.notNull($tmp) + 1, $tmp).bind(this)(this[_bufferIndex]), 128 | dart.notNull(leadingSurrogate) & 63);
        return false;
      }
    }
    [_fillBuffer](str, start, end) {
      if (start !== end && dart.notNull(_isLeadSurrogate(str.codeUnitAt(dart.notNull(end) - 1)))) {
        end = dart.notNull(end) - 1;
      }
      let stringIndex = null;
      for (stringIndex = start; dart.notNull(stringIndex) < dart.notNull(end); stringIndex = dart.notNull(stringIndex) + 1) {
        let codeUnit = str.codeUnitAt(stringIndex);
        if (dart.notNull(codeUnit) <= dart.notNull(_ONE_BYTE_LIMIT)) {
          if (dart.notNull(this[_bufferIndex]) >= dart.notNull(this[_buffer].length))
            break;
          this[_buffer].set((($tmp) => this[_bufferIndex] = dart.notNull($tmp) + 1, $tmp).bind(this)(this[_bufferIndex]), codeUnit);
        } else if (_isLeadSurrogate(codeUnit)) {
          if (dart.notNull(this[_bufferIndex]) + 3 >= dart.notNull(this[_buffer].length))
            break;
          let nextCodeUnit = str.codeUnitAt(dart.notNull(stringIndex) + 1);
          let wasCombined = this[_writeSurrogate](codeUnit, nextCodeUnit);
          if (wasCombined)
            stringIndex = dart.notNull(stringIndex) + 1;
        } else {
          let rune = codeUnit;
          if (dart.notNull(rune) <= dart.notNull(_TWO_BYTE_LIMIT)) {
            if (dart.notNull(this[_bufferIndex]) + 1 >= dart.notNull(this[_buffer].length))
              break;
            this[_buffer].set((($tmp) => this[_bufferIndex] = dart.notNull($tmp) + 1, $tmp).bind(this)(this[_bufferIndex]), 192 | dart.notNull(rune) >> 6);
            this[_buffer].set((($tmp) => this[_bufferIndex] = dart.notNull($tmp) + 1, $tmp).bind(this)(this[_bufferIndex]), 128 | dart.notNull(rune) & 63);
          } else {
            dart.assert(dart.notNull(rune) <= dart.notNull(_THREE_BYTE_LIMIT));
            if (dart.notNull(this[_bufferIndex]) + 2 >= dart.notNull(this[_buffer].length))
              break;
            this[_buffer].set((($tmp) => this[_bufferIndex] = dart.notNull($tmp) + 1, $tmp).bind(this)(this[_bufferIndex]), 224 | dart.notNull(rune) >> 12);
            this[_buffer].set((($tmp) => this[_bufferIndex] = dart.notNull($tmp) + 1, $tmp).bind(this)(this[_bufferIndex]), 128 | dart.notNull(rune) >> 6 & 63);
            this[_buffer].set((($tmp) => this[_bufferIndex] = dart.notNull($tmp) + 1, $tmp).bind(this)(this[_bufferIndex]), 128 | dart.notNull(rune) & 63);
          }
        }
      }
      return stringIndex;
    }
  }
  dart.defineNamedConstructor(_Utf8Encoder, 'withBufferSize');
  _Utf8Encoder._DEFAULT_BYTE_BUFFER_SIZE = 1024;
  class _Utf8EncoderSink extends dart.mixin(_Utf8Encoder, StringConversionSinkMixin) {
    _Utf8EncoderSink($_sink) {
      this[_sink] = $_sink;
      super._Utf8Encoder();
    }
    close() {
      if (this[_carry] !== 0) {
        this.addSlice("", 0, 0, true);
        return;
      }
      this[_sink].close();
    }
    addSlice(str, start, end, isLast) {
      this[_bufferIndex] = 0;
      if (start === end && !dart.notNull(isLast)) {
        return;
      }
      if (this[_carry] !== 0) {
        let nextCodeUnit = 0;
        if (start !== end) {
          nextCodeUnit = str.codeUnitAt(start);
        } else {
          dart.assert(isLast);
        }
        let wasCombined = this[_writeSurrogate](this[_carry], nextCodeUnit);
        dart.assert(!dart.notNull(wasCombined) || start !== end);
        if (wasCombined)
          start = dart.notNull(start) + 1;
        this[_carry] = 0;
      }
      do {
        start = this[_fillBuffer](str, start, end);
        let isLastSlice = dart.notNull(isLast) && start === end;
        if (start === dart.notNull(end) - 1 && dart.notNull(_isLeadSurrogate(str.codeUnitAt(start)))) {
          if (dart.notNull(isLast) && dart.notNull(this[_bufferIndex]) < dart.notNull(this[_buffer].length) - 3) {
            let hasBeenCombined = this[_writeSurrogate](str.codeUnitAt(start), 0);
            dart.assert(!dart.notNull(hasBeenCombined));
          } else {
            this[_carry] = str.codeUnitAt(start);
          }
          start = dart.notNull(start) + 1;
        }
        this[_sink].addSlice(this[_buffer], 0, this[_bufferIndex], isLastSlice);
        this[_bufferIndex] = 0;
      } while (dart.notNull(start) < dart.notNull(end));
      if (isLast)
        this.close();
    }
  }
  class Utf8Decoder extends Converter$(core.List$(core.int), core.String) {
    Utf8Decoder(opt$) {
      let allowMalformed = opt$.allowMalformed === void 0 ? false : opt$.allowMalformed;
      this[_allowMalformed] = allowMalformed;
      super.Converter();
    }
    convert(codeUnits, start, end) {
      if (start === void 0)
        start = 0;
      if (end === void 0)
        end = null;
      let length = codeUnits.length;
      core.RangeError.checkValidRange(start, end, length);
      if (end === null)
        end = length;
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
        stringSink = new StringConversionSink.from(sink);
      }
      return stringSink.asUtf8Sink(this[_allowMalformed]);
    }
    bind(stream) {
      return dart.as(super.bind(stream), async.Stream$(core.String));
    }
    fuse(next) {
      return super.fuse(next);
    }
  }
  let _ONE_BYTE_LIMIT = 127;
  let _TWO_BYTE_LIMIT = 2047;
  let _THREE_BYTE_LIMIT = 65535;
  let _FOUR_BYTE_LIMIT = 1114111;
  let _SURROGATE_MASK = 63488;
  let _SURROGATE_TAG_MASK = 64512;
  let _SURROGATE_VALUE_MASK = 1023;
  let _LEAD_SURROGATE_MIN = 55296;
  let _TAIL_SURROGATE_MIN = 56320;
  // Function _isSurrogate: (int) → bool
  function _isSurrogate(codeUnit) {
    return (dart.notNull(codeUnit) & dart.notNull(_SURROGATE_MASK)) === _LEAD_SURROGATE_MIN;
  }
  // Function _isLeadSurrogate: (int) → bool
  function _isLeadSurrogate(codeUnit) {
    return (dart.notNull(codeUnit) & dart.notNull(_SURROGATE_TAG_MASK)) === _LEAD_SURROGATE_MIN;
  }
  // Function _isTailSurrogate: (int) → bool
  function _isTailSurrogate(codeUnit) {
    return (dart.notNull(codeUnit) & dart.notNull(_SURROGATE_TAG_MASK)) === _TAIL_SURROGATE_MIN;
  }
  // Function _combineSurrogatePair: (int, int) → int
  function _combineSurrogatePair(lead, tail) {
    return 65536 + ((dart.notNull(lead) & dart.notNull(_SURROGATE_VALUE_MASK)) << 10) | dart.notNull(tail) & dart.notNull(_SURROGATE_VALUE_MASK);
  }
  let _isFirstCharacter = Symbol('_isFirstCharacter');
  let _value = Symbol('_value');
  let _expectedUnits = Symbol('_expectedUnits');
  let _extraUnits = Symbol('_extraUnits');
  class _Utf8Decoder extends core.Object {
    _Utf8Decoder($_stringSink, $_allowMalformed) {
      this[_stringSink] = $_stringSink;
      this[_allowMalformed] = $_allowMalformed;
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
      if (this.hasPartialInput) {
        if (!dart.notNull(this[_allowMalformed])) {
          throw new core.FormatException("Unfinished UTF-8 octet sequence");
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
      // Function scanOneByteCharacters: (dynamic, int) → int
      function scanOneByteCharacters(units, from) {
        let to = endIndex;
        let mask = _ONE_BYTE_LIMIT;
        for (let i = from; dart.notNull(i) < dart.notNull(to); i = dart.notNull(i) + 1) {
          let unit = dart.dindex(units, i);
          if (!dart.equals(dart.dbinary(unit, '&', mask), unit))
            return dart.notNull(i) - dart.notNull(from);
        }
        return dart.notNull(to) - dart.notNull(from);
      }
      // Function addSingleBytes: (int, int) → void
      function addSingleBytes(from, to) {
        dart.assert(dart.notNull(from) >= dart.notNull(startIndex) && dart.notNull(from) <= dart.notNull(endIndex));
        dart.assert(dart.notNull(to) >= dart.notNull(startIndex) && dart.notNull(to) <= dart.notNull(endIndex));
        this[_stringSink].write(new core.String.fromCharCodes(codeUnits, from, to));
      }
      let i = startIndex;
      loop:
        while (true) {
          multibyte:
            if (dart.notNull(expectedUnits) > 0) {
              do {
                if (i === endIndex) {
                  break loop;
                }
                let unit = codeUnits.get(i);
                if ((dart.notNull(unit) & 192) !== 128) {
                  expectedUnits = 0;
                  if (!dart.notNull(this[_allowMalformed])) {
                    throw new core.FormatException(`Bad UTF-8 encoding 0x${unit.toRadixString(16)}`);
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
              if (dart.notNull(value) <= dart.notNull(_Utf8Decoder._LIMITS.get(dart.notNull(extraUnits) - 1))) {
                if (!dart.notNull(this[_allowMalformed])) {
                  throw new core.FormatException(`Overlong encoding of 0x${value.toRadixString(16)}`);
                }
                expectedUnits = extraUnits = 0;
                value = UNICODE_REPLACEMENT_CHARACTER_RUNE;
              }
              if (dart.notNull(value) > dart.notNull(_FOUR_BYTE_LIMIT)) {
                if (!dart.notNull(this[_allowMalformed])) {
                  throw new core.FormatException("Character outside valid Unicode range: " + `0x${value.toRadixString(16)}`);
                }
                value = UNICODE_REPLACEMENT_CHARACTER_RUNE;
              }
              if (!dart.notNull(this[_isFirstCharacter]) || value !== UNICODE_BOM_CHARACTER_RUNE) {
                this[_stringSink].writeCharCode(value);
              }
              this[_isFirstCharacter] = false;
            }
          while (dart.notNull(i) < dart.notNull(endIndex)) {
            let oneBytes = scanOneByteCharacters(codeUnits, i);
            if (dart.notNull(oneBytes) > 0) {
              this[_isFirstCharacter] = false;
              addSingleBytes(i, dart.notNull(i) + dart.notNull(oneBytes));
              i = oneBytes;
              if (i === endIndex)
                break;
            }
            let unit = codeUnits.get((($tmp) => i = dart.notNull($tmp) + 1, $tmp)(i));
            if (dart.notNull(unit) < 0) {
              if (!dart.notNull(this[_allowMalformed])) {
                throw new core.FormatException(`Negative UTF-8 code unit: -0x${(-dart.notNull(unit)).toRadixString(16)}`);
              }
              this[_stringSink].writeCharCode(UNICODE_REPLACEMENT_CHARACTER_RUNE);
            } else {
              dart.assert(dart.notNull(unit) > dart.notNull(_ONE_BYTE_LIMIT));
              if ((dart.notNull(unit) & 224) === 192) {
                value = dart.notNull(unit) & 31;
                expectedUnits = extraUnits = 1;
                continue loop;
              }
              if ((dart.notNull(unit) & 240) === 224) {
                value = dart.notNull(unit) & 15;
                expectedUnits = extraUnits = 2;
                continue loop;
              }
              if ((dart.notNull(unit) & 248) === 240 && dart.notNull(unit) < 245) {
                value = dart.notNull(unit) & 7;
                expectedUnits = extraUnits = 3;
                continue loop;
              }
              if (!dart.notNull(this[_allowMalformed])) {
                throw new core.FormatException(`Bad UTF-8 encoding 0x${unit.toRadixString(16)}`);
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
  _Utf8Decoder._LIMITS = /* Unimplemented const */new List.from([_ONE_BYTE_LIMIT, _TWO_BYTE_LIMIT, _THREE_BYTE_LIMIT, _FOUR_BYTE_LIMIT]);
  let _processed = Symbol('_processed');
  let _original = Symbol('_original');
  // Function _convertJsonToDart: (dynamic, (dynamic, dynamic) → dynamic) → dynamic
  function _convertJsonToDart(json, reviver) {
    dart.assert(reviver !== null);
    // Function walk: (dynamic) → dynamic
    function walk(e) {
      if (e == null || typeof e != "object") {
        return e;
      }
      if (Object.getPrototypeOf(e) === Array.prototype) {
        for (let i = 0; dart.notNull(i) < e.length; i = dart.notNull(i) + 1) {
          let item = e[i];
          e[i] = reviver(i, walk(item));
        }
        return e;
      }
      let map = new _JsonMap(e);
      let processed = map[_processed];
      let keys = map._computeKeys();
      for (let i = 0; dart.notNull(i) < dart.notNull(keys.length); i = dart.notNull(i) + 1) {
        let key = keys.get(i);
        let revived = reviver(key, walk(e[key]));
        processed[key] = revived;
      }
      map[_original] = processed;
      return map;
    }
    return reviver(null, walk(json));
  }
  // Function _convertJsonToDartLazy: (dynamic) → dynamic
  function _convertJsonToDartLazy(object) {
    if (object === null)
      return null;
    if (typeof object != "object") {
      return object;
    }
    if (Object.getPrototypeOf(object) !== Array.prototype) {
      return new _JsonMap(object);
    }
    for (let i = 0; dart.notNull(i) < object.length; i = dart.notNull(i) + 1) {
      let item = object[i];
      object[i] = _convertJsonToDartLazy(item);
    }
    return object;
  }
  let _data = Symbol('_data');
  let _isUpgraded = Symbol('_isUpgraded');
  let _upgradedMap = Symbol('_upgradedMap');
  let _process = Symbol('_process');
  let _computeKeys = Symbol('_computeKeys');
  let _upgrade = Symbol('_upgrade');
  let _hasProperty = Symbol('_hasProperty');
  let _getProperty = Symbol('_getProperty');
  let _setProperty = Symbol('_setProperty');
  let _getPropertyNames = Symbol('_getPropertyNames');
  let _isUnprocessed = Symbol('_isUnprocessed');
  let _newJavaScriptObject = Symbol('_newJavaScriptObject');
  class _JsonMap extends core.Object {
    _JsonMap($_original) {
      this[_processed] = _newJavaScriptObject();
      this[_original] = $_original;
      this[_data] = null;
    }
    get(key) {
      if (this[_isUpgraded]) {
        return this[_upgradedMap].get(key);
      } else if (!(typeof key == string)) {
        return null;
      } else {
        let result = _getProperty(this[_processed], dart.as(key, core.String));
        if (_isUnprocessed(result))
          result = this[_process](dart.as(key, core.String));
        return result;
      }
    }
    get length() {
      return this[_isUpgraded] ? this[_upgradedMap].length : this[_computeKeys]().length;
    }
    get isEmpty() {
      return this.length === 0;
    }
    get isNotEmpty() {
      return dart.notNull(this.length) > 0;
    }
    get keys() {
      if (this[_isUpgraded])
        return this[_upgradedMap].keys;
      return new _JsonMapKeyIterable(this);
    }
    get values() {
      if (this[_isUpgraded])
        return this[_upgradedMap].values;
      return new _internal.MappedIterable(this[_computeKeys](), ((each) => this.get(each)).bind(this));
    }
    set(key, value) {
      if (this[_isUpgraded]) {
        this[_upgradedMap].set(key, value);
      } else if (this.containsKey(key)) {
        let processed = this[_processed];
        _setProperty(processed, dart.as(key, core.String), value);
        let original = this[_original];
        if (!dart.notNull(core.identical(original, processed))) {
          _setProperty(original, dart.as(key, core.String), null);
        }
      } else {
        this[_upgrade]().set(key, value);
      }
    }
    addAll(other) {
      other.forEach(((key, value) => {
        this.set(key, value);
      }).bind(this));
    }
    containsValue(value) {
      if (this[_isUpgraded])
        return this[_upgradedMap].containsValue(value);
      let keys = this[_computeKeys]();
      for (let i = 0; dart.notNull(i) < dart.notNull(keys.length); i = dart.notNull(i) + 1) {
        let key = keys.get(i);
        if (dart.equals(this.get(key), value))
          return true;
      }
      return false;
    }
    containsKey(key) {
      if (this[_isUpgraded])
        return this[_upgradedMap].containsKey(key);
      if (!(typeof key == string))
        return false;
      return _hasProperty(this[_original], dart.as(key, core.String));
    }
    putIfAbsent(key, ifAbsent) {
      if (this.containsKey(key))
        return this.get(key);
      let value = ifAbsent();
      this.set(key, value);
      return value;
    }
    remove(key) {
      if (!dart.notNull(this[_isUpgraded]) && !dart.notNull(this.containsKey(key)))
        return null;
      return this[_upgrade]().remove(key);
    }
    clear() {
      if (this[_isUpgraded]) {
        this[_upgradedMap].clear();
      } else {
        if (this[_data] !== null) {
          dart.dinvoke(this[_data], 'clear');
        }
        this[_original] = this[_processed] = null;
        this[_data] = dart.map();
      }
    }
    forEach(f) {
      if (this[_isUpgraded])
        return this[_upgradedMap].forEach(f);
      let keys = this[_computeKeys]();
      for (let i = 0; dart.notNull(i) < dart.notNull(keys.length); i = dart.notNull(i) + 1) {
        let key = keys.get(i);
        let value = _getProperty(this[_processed], key);
        if (_isUnprocessed(value)) {
          value = _convertJsonToDartLazy(_getProperty(this[_original], key));
          _setProperty(this[_processed], key, value);
        }
        f(key, value);
        if (!dart.notNull(core.identical(keys, this[_data]))) {
          throw new core.ConcurrentModificationError(this);
        }
      }
    }
    toString() {
      return collection.Maps.mapToString(this);
    }
    get [_isUpgraded]() {
      return this[_processed] === null;
    }
    get [_upgradedMap]() {
      dart.assert(this[_isUpgraded]);
      return dart.as(this[_data], core.Map);
    }
    [_computeKeys]() {
      dart.assert(!dart.notNull(this[_isUpgraded]));
      let keys = dart.as(this[_data], core.List);
      if (keys === null) {
        keys = this[_data] = _getPropertyNames(this[_original]);
      }
      return dart.as(keys, core.List$(core.String));
    }
    [_upgrade]() {
      if (this[_isUpgraded])
        return this[_upgradedMap];
      let result = dart.map();
      let keys = this[_computeKeys]();
      for (let i = 0; dart.notNull(i) < dart.notNull(keys.length); i = dart.notNull(i) + 1) {
        let key = keys.get(i);
        result.set(key, this.get(key));
      }
      if (keys.isEmpty) {
        keys.add(null);
      } else {
        keys.clear();
      }
      this[_original] = this[_processed] = null;
      this[_data] = result;
      dart.assert(this[_isUpgraded]);
      return result;
    }
    [_process](key) {
      if (!dart.notNull(_hasProperty(this[_original], key)))
        return null;
      let result = _convertJsonToDartLazy(_getProperty(this[_original], key));
      return _setProperty(this[_processed], key, result);
    }
    static [_hasProperty](object, key) {
      return Object.prototype.hasOwnProperty.call(object, key);
    }
    static [_getProperty](object, key) {
      return object[key];
    }
    static [_setProperty](object, key, value) {
      return object[key] = value;
    }
    static [_getPropertyNames](object) {
      return dart.as(Object.keys(object), core.List);
    }
    static [_isUnprocessed](object) {
      return typeof object == "undefined";
    }
    static [_newJavaScriptObject]() {
      return Object.create(null);
    }
  }
  let _parent = Symbol('_parent');
  class _JsonMapKeyIterable extends _internal.ListIterable {
    _JsonMapKeyIterable($_parent) {
      this[_parent] = $_parent;
      super.ListIterable();
    }
    get length() {
      return this[_parent].length;
    }
    elementAt(index) {
      return dart.as(this[_parent][_isUpgraded] ? this[_parent].keys.elementAt(index) : this[_parent]._computeKeys().get(index), core.String);
    }
    get iterator() {
      return dart.as(this[_parent][_isUpgraded] ? this[_parent].keys.iterator : this[_parent]._computeKeys().iterator, core.Iterator);
    }
    contains(key) {
      return this[_parent].containsKey(key);
    }
  }
  class _JsonDecoderSink extends _StringSinkConversionSink {
    _JsonDecoderSink($_reviver, $_sink) {
      this[_reviver] = $_reviver;
      this[_sink] = $_sink;
      super._StringSinkConversionSink(new core.StringBuffer());
    }
    close() {
      super.close();
      let buffer = dart.as(this[_stringSink], core.StringBuffer);
      let accumulated = buffer.toString();
      buffer.clear();
      let decoded = _parseJson(accumulated, this[_reviver]);
      this[_sink].add(decoded);
      this[_sink].close();
    }
  }
  // Exports:
  exports.ASCII = ASCII;
  exports.AsciiCodec = AsciiCodec;
  exports.AsciiEncoder = AsciiEncoder;
  exports.AsciiDecoder = AsciiDecoder;
  exports.ByteConversionSink = ByteConversionSink;
  exports.ByteConversionSinkBase = ByteConversionSinkBase;
  exports.ChunkedConversionSink = ChunkedConversionSink;
  exports.ChunkedConversionSink$ = ChunkedConversionSink$;
  exports.Codec = Codec;
  exports.Codec$ = Codec$;
  exports.Converter = Converter;
  exports.Converter$ = Converter$;
  exports.Encoding = Encoding;
  exports.HTML_ESCAPE = HTML_ESCAPE;
  exports.HtmlEscapeMode = HtmlEscapeMode;
  exports.HtmlEscape = HtmlEscape;
  exports.JsonUnsupportedObjectError = JsonUnsupportedObjectError;
  exports.JsonCyclicError = JsonCyclicError;
  exports.JSON = JSON;
  exports.JsonCodec = JsonCodec;
  exports.JsonEncoder = JsonEncoder;
  exports.JsonUtf8Encoder = JsonUtf8Encoder;
  exports.JsonDecoder = JsonDecoder;
  exports.LATIN1 = LATIN1;
  exports.Latin1Codec = Latin1Codec;
  exports.Latin1Encoder = Latin1Encoder;
  exports.Latin1Decoder = Latin1Decoder;
  exports.LineSplitter = LineSplitter;
  exports.StringConversionSink = StringConversionSink;
  exports.ClosableStringSink = ClosableStringSink;
  exports.StringConversionSinkBase = StringConversionSinkBase;
  exports.StringConversionSinkMixin = StringConversionSinkMixin;
  exports.UNICODE_REPLACEMENT_CHARACTER_RUNE = UNICODE_REPLACEMENT_CHARACTER_RUNE;
  exports.UNICODE_BOM_CHARACTER_RUNE = UNICODE_BOM_CHARACTER_RUNE;
  exports.UTF8 = UTF8;
  exports.Utf8Codec = Utf8Codec;
  exports.Utf8Encoder = Utf8Encoder;
  exports.Utf8Decoder = Utf8Decoder;
})(convert || (convert = {}));
