var convert;
(function (convert) {
  'use strict';
  let ASCII = new AsciiCodec();
  let _ASCII_MASK = 127;
  class AsciiCodec extends Encoding {
    constructor(opt$) {
      let allowInvalid = opt$.allowInvalid === undefined ? false : opt$.allowInvalid;
      this._allowInvalid = allowInvalid;
      super();
    }
    get name() { return "us-ascii"; }
    decode(bytes, opt$) {
      let allowInvalid = opt$.allowInvalid === undefined ? null : opt$.allowInvalid;
      if (allowInvalid === null) allowInvalid = this._allowInvalid;
      if (allowInvalid) {
        return new AsciiDecoder({allowInvalid: true}).convert(bytes);
      } else {
        return new AsciiDecoder({allowInvalid: false}).convert(bytes);
      }
    }
    get encoder() { return new AsciiEncoder(); }
    get decoder() { return this._allowInvalid ? new AsciiDecoder({allowInvalid: true}) : new AsciiDecoder({allowInvalid: false}); }
  }

  class _UnicodeSubsetEncoder extends Converter/* Unimplemented <String, List<int>> */ {
    constructor(_subsetMask) {
      this._subsetMask = _subsetMask;
      super();
    }
    convert(string, start, end) {
      if (start === undefined) start = 0;
      if (end === undefined) end = null;
      let stringLength = string.length;
      core.RangeError.checkValidRange(start, end, stringLength);
      if (end === null) end = stringLength;
      let length = end - start;
      let result = new typed_data.Uint8List(length);
      for (let i = 0; i < length; i++) {
        let codeUnit = string.codeUnitAt(start + i);
        if ((codeUnit & ~this._subsetMask) !== 0) {
          throw new core.ArgumentError("String contains invalid characters.");
        }
        result.set(i, codeUnit);
      }
      return dart.as(result, core.List);
    }
    startChunkedConversion(sink) {
      if (!dart.is(sink, ByteConversionSink)) {
        sink = new ByteConversionSink.from(sink);
      }
      return new _UnicodeSubsetEncoderSink(this._subsetMask, sink);
    }
    bind(stream) { return dart.as(super.bind(stream), async.Stream); }
  }

  class AsciiEncoder extends _UnicodeSubsetEncoder {
    constructor() {
      super(_ASCII_MASK);
    }
  }

  class _UnicodeSubsetEncoderSink extends StringConversionSinkBase {
    constructor(_subsetMask, _sink) {
      this._subsetMask = _subsetMask;
      this._sink = _sink;
      super();
    }
    close() {
      this._sink.close();
    }
    addSlice(source, start, end, isLast) {
      core.RangeError.checkValidRange(start, end, source.length);
      for (let i = start; i < end; i++) {
        let codeUnit = source.codeUnitAt(i);
        if ((codeUnit & ~this._subsetMask) !== 0) {
          throw new core.ArgumentError("Source contains invalid character with code point: " + (codeUnit) + ".");
        }
      }
      this._sink.add(source.codeUnits.sublist(start, end));
      if (isLast) {
        this.close();
      }
    }
  }

  class _UnicodeSubsetDecoder extends Converter/* Unimplemented <List<int>, String> */ {
    constructor(_allowInvalid, _subsetMask) {
      this._allowInvalid = _allowInvalid;
      this._subsetMask = _subsetMask;
      super();
    }
    convert(bytes, start, end) {
      if (start === undefined) start = 0;
      if (end === undefined) end = null;
      let byteCount = bytes.length;
      core.RangeError.checkValidRange(start, end, byteCount);
      if (end === null) end = byteCount;
      let length = end - start;
      for (let i = start; i < end; i++) {
        let byte = bytes.get(i);
        if ((byte & ~this._subsetMask) !== 0) {
          if (!this._allowInvalid) {
            throw new core.FormatException("Invalid value in input: " + (byte) + "");
          }
          return this._convertInvalid(bytes, start, end);
        }
      }
      return new core.String.fromCharCodes(bytes, start, end);
    }
    _convertInvalid(bytes, start, end) {
      let buffer = new core.StringBuffer();
      for (let i = start; i < end; i++) {
        let value = bytes.get(i);
        if ((value & ~this._subsetMask) !== 0) value = 65533;
        buffer.writeCharCode(value);
      }
      return buffer.toString();
    }
    bind(stream) { return dart.as(super.bind(stream), async.Stream); }
  }

  class AsciiDecoder extends _UnicodeSubsetDecoder {
    constructor(opt$) {
      let allowInvalid = opt$.allowInvalid === undefined ? false : opt$.allowInvalid;
      super(allowInvalid, _ASCII_MASK);
    }
    startChunkedConversion(sink) {
      let stringSink = null;
      if (dart.is(sink, StringConversionSink)) {
        stringSink = dart.as(sink, StringConversionSink);
      } else {
        stringSink = new StringConversionSink.from(sink);
      }
      if (_allowInvalid) {
        return new _ErrorHandlingAsciiDecoderSink(stringSink.asUtf8Sink(false));
      } else {
        return new _SimpleAsciiDecoderSink(stringSink);
      }
    }
  }

  class _ErrorHandlingAsciiDecoderSink extends ByteConversionSinkBase {
    constructor(_utf8Sink) {
      this._utf8Sink = _utf8Sink;
      super();
    }
    close() {
      this._utf8Sink.close();
    }
    add(source) {
      this.addSlice(source, 0, source.length, false);
    }
    addSlice(source, start, end, isLast) {
      core.RangeError.checkValidRange(start, end, source.length);
      for (let i = start; i < end; i++) {
        if ((source.get(i) & ~_ASCII_MASK) !== 0) {
          if (i > start) this._utf8Sink.addSlice(source, start, i, false);
          this._utf8Sink.add(/* Unimplemented const */new List.from([239, 191, 189]));
          start = i + 1;
        }
      }
      if (start < end) {
        this._utf8Sink.addSlice(source, start, end, isLast);
      } else if (isLast) {
        this.close();
      }
    }
  }

  class _SimpleAsciiDecoderSink extends ByteConversionSinkBase {
    constructor(_sink) {
      this._sink = _sink;
      super();
    }
    close() {
      this._sink.close();
    }
    add(source) {
      for (let i = 0; i < source.length; i++) {
        if ((source.get(i) & ~_ASCII_MASK) !== 0) {
          throw new core.FormatException("Source contains non-ASCII bytes.");
        }
      }
      this._sink.add(new core.String.fromCharCodes(source));
    }
    addSlice(source, start, end, isLast) {
      let length = source.length;
      core.RangeError.checkValidRange(start, end, length);
      if (start < end) {
        if (start !== 0 || end !== length) {
          source = source.sublist(start, end);
        }
        this.add(source);
      }
      if (isLast) this.close();
    }
  }

  class ByteConversionSink extends ChunkedConversionSink/* Unimplemented <List<int>> */ {
    constructor() {
      super();
    }
    /*constructor*/ withCallback(callback) {
      return new _ByteCallbackSink(callback);
    }
    /*constructor*/ from(sink) {
      return new _ByteAdapterSink(sink);
    }
  }
  dart.defineNamedConstructor(ByteConversionSink, "withCallback");
  dart.defineNamedConstructor(ByteConversionSink, "from");

  class ByteConversionSinkBase extends ByteConversionSink {
    addSlice(chunk, start, end, isLast) {
      this.add(chunk.sublist(start, end));
      if (isLast) this.close();
    }
  }

  class _ByteAdapterSink extends ByteConversionSinkBase {
    constructor(_sink) {
      this._sink = _sink;
      super();
    }
    add(chunk) { return this._sink.add(chunk); }
    close() { return this._sink.close(); }
  }

  class _ByteCallbackSink extends ByteConversionSinkBase {
    constructor(callback) {
      this._buffer = new typed_data.Uint8List(_INITIAL_BUFFER_SIZE);
      this._callback = callback;
      this._bufferIndex = 0;
      super();
    }
    add(chunk) {
      let freeCount = this._buffer.length - this._bufferIndex;
      if (chunk.length > freeCount) {
        let oldLength = this._buffer.length;
        let newLength = _roundToPowerOf2(chunk.length + oldLength) * 2;
        let grown = new typed_data.Uint8List(newLength);
        grown.setRange(0, this._buffer.length, this._buffer);
        this._buffer = grown;
      }
      this._buffer.setRange(this._bufferIndex, this._bufferIndex + chunk.length, chunk);
      this._bufferIndex = chunk.length;
    }
    static _roundToPowerOf2(v) {
      dart.assert(v > 0);
      v--;
      v = v >> 1;
      v = v >> 2;
      v = v >> 4;
      v = v >> 8;
      v = v >> 16;
      v++;
      return v;
    }
    close() {
      this._callback(this._buffer.sublist(0, this._bufferIndex));
    }
  }
  _ByteCallbackSink._INITIAL_BUFFER_SIZE = 1024;

  class ChunkedConversionSink/* Unimplemented <T> */ {
    constructor() {
    }
    /*constructor*/ withCallback(callback) {
      return new _SimpleCallbackSink(callback);
    }
  }
  dart.defineNamedConstructor(ChunkedConversionSink, "withCallback");

  class _SimpleCallbackSink/* Unimplemented <T> */ extends ChunkedConversionSink/* Unimplemented <T> */ {
    constructor(_callback) {
      this._accumulated = new List.from([]);
      this._callback = _callback;
      super();
    }
    add(chunk) {
      this._accumulated.add(chunk);
    }
    close() {
      this._callback(this._accumulated);
    }
  }

  class _EventSinkAdapter/* Unimplemented <T> */ {
    constructor(_sink) {
      this._sink = _sink;
    }
    add(data) { return this._sink.add(data); }
    close() { return this._sink.close(); }
  }

  class _ConverterStreamEventSink/* Unimplemented <S, T> */ {
    constructor(converter, sink) {
      this._eventSink = sink;
      this._chunkedSink = converter.startChunkedConversion(sink);
    }
    add(o) { return this._chunkedSink.add(o); }
    addError(error, stackTrace) {
      if (stackTrace === undefined) stackTrace = null;
      this._eventSink.addError(error, stackTrace);
    }
    close() { return this._chunkedSink.close(); }
  }

  class Codec/* Unimplemented <S, T> */ {
    constructor() {
    }
    encode(input) { return this.encoder.convert(input); }
    decode(encoded) { return this.decoder.convert(encoded); }
    fuse(other) {
      return new _FusedCodec(this, other);
    }
    get inverted() { return new _InvertedCodec(this); }
  }

  class _FusedCodec/* Unimplemented <S, M, T> */ extends Codec/* Unimplemented <S, T> */ {
    get encoder() { return dart.as(this._first.encoder.fuse(this._second.encoder), Converter); }
    get decoder() { return dart.as(this._second.decoder.fuse(this._first.decoder), Converter); }
    constructor(_first, _second) {
      this._first = _first;
      this._second = _second;
      super();
    }
  }

  class _InvertedCodec/* Unimplemented <T, S> */ extends Codec/* Unimplemented <T, S> */ {
    constructor(codec) {
      this._codec = codec;
      super();
    }
    get encoder() { return this._codec.decoder; }
    get decoder() { return this._codec.encoder; }
    get inverted() { return this._codec; }
  }

  class Converter/* Unimplemented <S, T> */ {
    constructor() {
    }
    fuse(other) {
      return new _FusedConverter(this, other);
    }
    startChunkedConversion(sink) {
      throw new core.UnsupportedError("This converter does not support chunked conversions: " + (this) + "");
    }
    bind(source) {
      return new async.Stream.eventTransformed(source, (sink) => new _ConverterStreamEventSink(this, sink));
    }
  }

  class _FusedConverter/* Unimplemented <S, M, T> */ extends Converter/* Unimplemented <S, T> */ {
    constructor(_first, _second) {
      this._first = _first;
      this._second = _second;
      super();
    }
    convert(input) { return /* Unimplemented: DownCast: dynamic to T */this._second.convert(this._first.convert(input)); }
    startChunkedConversion(sink) {
      return this._first.startChunkedConversion(this._second.startChunkedConversion(sink));
    }
  }

  class Encoding extends Codec/* Unimplemented <String, List<int>> */ {
    constructor() {
      super();
    }
    decodeStream(byteStream) {
      return dart.as(byteStream.transform(dart.as(decoder, async.StreamTransformer)).fold(new core.StringBuffer(), (buffer, string) => (dart.dinvoke(buffer, "write", string),
        buffer)).then((buffer) => dart.dinvoke(buffer, "toString")), async.Future);
    }
    static getByName(name) {
      if (name === null) return null;
      name = name.toLowerCase();
      return _nameToEncoding.get(name);
    }
  }
  dart.defineLazyProperties(Encoding, {
    get _nameToEncoding() { return dart.map({
      "iso_8859-1:1987": LATIN1,
      "iso-ir-100": LATIN1,
      "iso_8859-1": LATIN1,
      "iso-8859-1": LATIN1,
      "latin1": LATIN1,
      "l1": LATIN1,
      "ibm819": LATIN1,
      "cp819": LATIN1,
      "csisolatin1": LATIN1,
      "iso-ir-6": ASCII,
      "ansi_x3.4-1968": ASCII,
      "ansi_x3.4-1986": ASCII,
      "iso_646.irv:1991": ASCII,
      "iso646-us": ASCII,
      "us-ascii": ASCII,
      "us": ASCII,
      "ibm367": ASCII,
      "cp367": ASCII,
      "csascii": ASCII,
      "ascii": ASCII,
      "csutf8": UTF8,
      "utf-8": UTF8
    }) },
    set _nameToEncoding(x) {},
  });

  let HTML_ESCAPE = new HtmlEscape();
  class HtmlEscapeMode {
    /*constructor*/ _(_name, escapeLtGt, escapeQuot, escapeApos, escapeSlash) {
      this._name = _name;
      this.escapeLtGt = escapeLtGt;
      this.escapeQuot = escapeQuot;
      this.escapeApos = escapeApos;
      this.escapeSlash = escapeSlash;
    }
    toString() { return this._name; }
  }
  dart.defineNamedConstructor(HtmlEscapeMode, "_");
  HtmlEscapeMode.UNKNOWN = new HtmlEscapeMode._("unknown", true, true, true, true);
  HtmlEscapeMode.ATTRIBUTE = new HtmlEscapeMode._("attribute", false, true, false, false);
  HtmlEscapeMode.ELEMENT = new HtmlEscapeMode._("element", true, false, false, true);

  class HtmlEscape extends Converter/* Unimplemented <String, String> */ {
    constructor(mode) {
      if (mode === undefined) mode = HtmlEscapeMode.UNKNOWN;
      this.mode = mode;
      super();
    }
    convert(text) {
      let val = this._convert(text, 0, text.length);
      return val === null ? text : val;
    }
    _convert(text, start, end) {
      let result = null;
      for (let i = start; i < end; i++) {
        let ch = text.get(i);
        let replace = null;
        /* Unimplemented SwitchStatement: switch (ch) {case '&': replace = '&amp;'; break; case '\u00A0': replace = '&nbsp;'; break; case '"': if (mode.escapeQuot) replace = '&quot;'; break; case "'": if (mode.escapeApos) replace = '&#x27;'; break; case '<': if (mode.escapeLtGt) replace = '&lt;'; break; case '>': if (mode.escapeLtGt) replace = '&gt;'; break; case '/': if (mode.escapeSlash) replace = '&#x2F;'; break;} */if (replace !== null) {
          if (result === null) result = new core.StringBuffer(text.substring(start, i));
          result.write(replace);
        } else if (result !== null) {
          result.write(ch);
        }
      }
      return dart.as(result !== null ? result.toString() : null, core.String);
    }
    startChunkedConversion(sink) {
      if (!dart.is(sink, StringConversionSink)) {
        sink = new StringConversionSink.from(sink);
      }
      return new _HtmlEscapeSink(this, sink);
    }
  }

  class _HtmlEscapeSink extends StringConversionSinkBase {
    constructor(_escape, _sink) {
      this._escape = _escape;
      this._sink = _sink;
      super();
    }
    addSlice(chunk, start, end, isLast) {
      let val = this._escape._convert(chunk, start, end);
      if (val === null) {
        this._sink.addSlice(chunk, start, end, isLast);
      } else {
        this._sink.add(val);
        if (isLast) this._sink.close();
      }
    }
    close() { return this._sink.close(); }
  }

  class JsonUnsupportedObjectError extends core.Error {
    constructor(unsupportedObject, opt$) {
      let cause = opt$.cause === undefined ? null : opt$.cause;
      this.unsupportedObject = unsupportedObject;
      this.cause = cause;
      super();
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
    constructor(object) {
      super(object);
    }
    toString() { return "Cyclic error in JSON stringify"; }
  }

  let JSON = new JsonCodec();
  class JsonCodec extends Codec/* Unimplemented <Object, String> */ {
    constructor(opt$) {
      let reviver = opt$.reviver === undefined ? null : opt$.reviver;
      let toEncodable = opt$.toEncodable === undefined ? null : opt$.toEncodable;
      this._reviver = reviver;
      this._toEncodable = toEncodable;
      super();
    }
    /*constructor*/ withReviver(reviver) {
      withReviver.call(this, {reviver: reviver});
    }
    decode(source, opt$) {
      let reviver = opt$.reviver === undefined ? null : opt$.reviver;
      if (reviver === null) reviver = this._reviver;
      if (reviver === null) return this.decoder.convert(source);
      return new JsonDecoder(reviver).convert(source);
    }
    encode(value, opt$) {
      let toEncodable = opt$.toEncodable === undefined ? null : opt$.toEncodable;
      if (toEncodable === null) toEncodable = this._toEncodable;
      if (toEncodable === null) return this.encoder.convert(value);
      return new JsonEncoder(toEncodable).convert(value);
    }
    get encoder() {
      if (this._toEncodable === null) return new JsonEncoder();
      return new JsonEncoder(this._toEncodable);
    }
    get decoder() {
      if (this._reviver === null) return new JsonDecoder();
      return new JsonDecoder(this._reviver);
    }
  }
  dart.defineNamedConstructor(JsonCodec, "withReviver");

  class JsonEncoder extends Converter/* Unimplemented <Object, String> */ {
    constructor(toEncodable) {
      if (toEncodable === undefined) toEncodable = null;
      this.indent = null;
      this._toEncodable = toEncodable;
      super();
    }
    /*constructor*/ withIndent(indent, toEncodable) {
      if (toEncodable === undefined) toEncodable = null;
      this.indent = indent;
      this._toEncodable = toEncodable;
      Converter.call(this);
    }
    convert(object) { return _JsonStringStringifier.stringify(object, /* Unimplemented: DownCast: Function to (dynamic) → dynamic */this._toEncodable, this.indent); }
    startChunkedConversion(sink) {
      if (!dart.is(sink, StringConversionSink)) {
        sink = new StringConversionSink.from(sink);
      } else if (dart.is(sink, _Utf8EncoderSink)) {
        return new _JsonUtf8EncoderSink(sink._sink, this._toEncodable, JsonUtf8Encoder._utf8Encode(this.indent), JsonUtf8Encoder.DEFAULT_BUFFER_SIZE);
      }
      return new _JsonEncoderSink(sink, this._toEncodable, this.indent);
    }
    bind(stream) { return dart.as(super.bind(stream), async.Stream); }
    fuse(other) {
      if (dart.is(other, Utf8Encoder)) {
        return new JsonUtf8Encoder(this.indent, this._toEncodable);
      }
      return super.fuse(other);
    }
  }
  dart.defineNamedConstructor(JsonEncoder, "withIndent");

  class JsonUtf8Encoder extends Converter/* Unimplemented <Object, List<int>> */ {
    constructor(indent, toEncodable, bufferSize) {
      if (indent === undefined) indent = null;
      if (toEncodable === undefined) toEncodable = null;
      if (bufferSize === undefined) bufferSize = DEFAULT_BUFFER_SIZE;
      this._indent = _utf8Encode(indent);
      this._toEncodable = toEncodable;
      this._bufferSize = bufferSize;
      super();
    }
    static _utf8Encode(string) {
      if (string === null) return null;
      if (string.isEmpty) return new typed_data.Uint8List(0);
      checkAscii: {
        for (let i = 0; i < string.length; i++) {
          if (string.codeUnitAt(i) >= 128) break checkAscii;
        }
        return string.codeUnits;
      }
      return UTF8.encode(string);
    }
    convert(object) {
      let bytes = dart.as(new List.from([]), core.List);
      // Function addChunk: (Uint8List, int, int) → void
      function addChunk(chunk, start, end) {
        if (start > 0 || end < chunk.length) {
          let length = end - start;
          chunk = new typed_data.Uint8List.view(chunk.buffer, chunk.offsetInBytes + start, length);
        }
        bytes.add(chunk);
      }
      _JsonUtf8Stringifier.stringify(object, this._indent, /* Unimplemented: DownCast: Function to (Object) → dynamic */this._toEncodable, this._bufferSize, addChunk);
      if (bytes.length === 1) return bytes.get(0);
      let length = 0;
      for (let i = 0; i < bytes.length; i++) {
        length = bytes.get(i).length;
      }
      let result = new typed_data.Uint8List(length);
      for (let i = 0, offset = 0; i < bytes.length; i++) {
        let byteList = bytes.get(i);
        let end = offset + byteList.length;
        result.setRange(offset, end, byteList);
        offset = end;
      }
      return result;
    }
    startChunkedConversion(sink) {
      let byteSink = null;
      if (dart.is(sink, ByteConversionSink)) {
        byteSink = dart.as(sink, ByteConversionSink);
      } else {
        byteSink = new ByteConversionSink.from(sink);
      }
      return new _JsonUtf8EncoderSink(byteSink, this._toEncodable, this._indent, this._bufferSize);
    }
    bind(stream) {
      return dart.as(super.bind(stream), async.Stream);
    }
    fuse(other) {
      return super.fuse(other);
    }
  }
  JsonUtf8Encoder.DEFAULT_BUFFER_SIZE = 256;

  class _JsonEncoderSink extends ChunkedConversionSink/* Unimplemented <Object> */ {
    constructor(_sink, _toEncodable, _indent) {
      this._sink = _sink;
      this._toEncodable = _toEncodable;
      this._indent = _indent;
      this._isDone = false;
      super();
    }
    add(o) {
      if (this._isDone) {
        throw new core.StateError("Only one call to add allowed");
      }
      this._isDone = true;
      let stringSink = this._sink.asStringSink();
      _JsonStringStringifier.printOn(o, stringSink, /* Unimplemented: DownCast: Function to (dynamic) → dynamic */this._toEncodable, this._indent);
      stringSink.close();
    }
    close() {
    }
  }

  class _JsonUtf8EncoderSink extends ChunkedConversionSink/* Unimplemented <Object> */ {
    constructor(_sink, _toEncodable, _indent, _bufferSize) {
      this._sink = _sink;
      this._toEncodable = _toEncodable;
      this._indent = _indent;
      this._bufferSize = _bufferSize;
      this._isDone = false;
      super();
    }
    _addChunk(chunk, start, end) {
      this._sink.addSlice(chunk, start, end, false);
    }
    add(object) {
      if (this._isDone) {
        throw new core.StateError("Only one call to add allowed");
      }
      this._isDone = true;
      _JsonUtf8Stringifier.stringify(object, this._indent, /* Unimplemented: DownCast: Function to (Object) → dynamic */this._toEncodable, this._bufferSize, this._addChunk);
      this._sink.close();
    }
    close() {
      if (!this._isDone) {
        this._isDone = true;
        this._sink.close();
      }
    }
  }

  class JsonDecoder extends Converter/* Unimplemented <String, Object> */ {
    constructor(reviver) {
      if (reviver === undefined) reviver = null;
      this._reviver = reviver;
      super();
    }
    convert(input) { return _parseJson(input, this._reviver); }
    /* Unimplemented external StringConversionSink startChunkedConversion(Sink<Object> sink); */
    bind(stream) { return dart.as(super.bind(stream), async.Stream); }
  }

  /* Unimplemented external _parseJson(String source, reviver(key, value)) ; */
  // Function _defaultToEncodable: (dynamic) → Object
  function _defaultToEncodable(object) { return dart.dinvoke(object, "toJson"); }

  class _JsonStringifier {
    constructor(_toEncodable) {
      this._seen = new core.List();
      this._toEncodable = (_toEncodable !== null) ? _toEncodable : _defaultToEncodable;
    }
    static hexDigit(x) { return x < 10 ? 48 + x : 87 + x; }
    writeStringContent(s) {
      let offset = 0;
      let length = s.length;
      for (let i = 0; i < length; i++) {
        let charCode = s.codeUnitAt(i);
        if (charCode > BACKSLASH) continue;
        if (charCode < 32) {
          if (i > offset) this.writeStringSlice(s, offset, i);
          offset = i + 1;
          this.writeCharCode(BACKSLASH);
          /* Unimplemented SwitchStatement: switch (charCode) {case BACKSPACE: writeCharCode(CHAR_b); break; case TAB: writeCharCode(CHAR_t); break; case NEWLINE: writeCharCode(CHAR_n); break; case FORM_FEED: writeCharCode(CHAR_f); break; case CARRIAGE_RETURN: writeCharCode(CHAR_r); break; default: writeCharCode(CHAR_u); writeCharCode(CHAR_0); writeCharCode(CHAR_0); writeCharCode(hexDigit((charCode >> 4) & 0xf)); writeCharCode(hexDigit(charCode & 0xf)); break;} */} else if (charCode === QUOTE || charCode === BACKSLASH) {
          if (i > offset) this.writeStringSlice(s, offset, i);
          offset = i + 1;
          this.writeCharCode(BACKSLASH);
          this.writeCharCode(charCode);
        }
      }
      if (offset === 0) {
        this.writeString(s);
      } else if (offset < length) {
        this.writeStringSlice(s, offset, length);
      }
    }
    _checkCycle(object) {
      for (let i = 0; i < this._seen.length; i++) {
        if (core.identical(object, this._seen.get(i))) {
          throw new JsonCyclicError(object);
        }
      }
      this._seen.add(object);
    }
    _removeSeen(object) {
      dart.assert(!this._seen.isEmpty);
      dart.assert(core.identical(this._seen.last, object));
      this._seen.removeLast();
    }
    writeObject(object) {
      if (this.writeJsonValue(object)) return;
      this._checkCycle(object);
      /* Unimplemented TryStatement: try {var customJson = _toEncodable(object); if (!writeJsonValue(customJson)) {throw new JsonUnsupportedObjectError(object);} _removeSeen(object);} catch (e) {throw new JsonUnsupportedObjectError(object, cause: e);} */}
    writeJsonValue(object) {
      if (dart.is(object, core.num)) {
        if (/* Unimplemented postfix operator: !object.isFinite */) return false;
        this.writeNumber(dart.as(object, core.num));
        return true;
      } else if (core.identical(object, true)) {
        this.writeString("true");
        return true;
      } else if (core.identical(object, false)) {
        this.writeString("false");
        return true;
      } else if (object === null) {
        this.writeString("null");
        return true;
      } else if (typeof object == "string") {
        this.writeString(""");
        this.writeStringContent(dart.as(object, core.String));
        this.writeString(""");
        return true;
      } else if (dart.is(object, core.List)) {
        this._checkCycle(object);
        this.writeList(dart.as(object, core.List));
        this._removeSeen(object);
        return true;
      } else if (dart.is(object, core.Map)) {
        this._checkCycle(object);
        this.writeMap(dart.as(object, core.Map));
        this._removeSeen(object);
        return true;
      } else {
        return false;
      }
    }
    writeList(list) {
      this.writeString("[");
      if (list.length > 0) {
        this.writeObject(list.get(0));
        for (let i = 1; i < list.length; i++) {
          this.writeString(",");
          this.writeObject(list.get(i));
        }
      }
      this.writeString("]");
    }
    writeMap(map) {
      this.writeString("{");
      let separator = """;
      map.forEach((key, value) => {
        this.writeString(separator);
        separator = ","";
        this.writeStringContent(key);
        this.writeString("":");
        this.writeObject(value);
      });
      this.writeString("}");
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

  class _JsonPrettyPrintMixin {
    constructor() {
      this._indentLevel = 0;
      super();
    }
    writeList(list) {
      if (list.isEmpty) {
        writeString("[]");
      } else {
        writeString("[
        ");
        this._indentLevel++;
        this.writeIndentation(this._indentLevel);
        writeObject(list.get(0));
        for (let i = 1; i < list.length; i++) {
          writeString(",
          ");
          this.writeIndentation(this._indentLevel);
          writeObject(list.get(i));
        }
        writeString("
        ");
        this._indentLevel--;
        this.writeIndentation(this._indentLevel);
        writeString("]");
      }
    }
    writeMap(map) {
      if (map.isEmpty) {
        writeString("{}");
      } else {
        writeString("{
        ");
        this._indentLevel++;
        let first = true;
        map.forEach(/* Unimplemented: ClosureWrapLiteral: (String, Object) → dynamic to (dynamic, dynamic) → void */(key, value) => {
          if (!first) {
            writeString(",
            ");
          }
          this.writeIndentation(this._indentLevel);
          writeString(""");
          writeStringContent(key);
          writeString("": ");
          writeObject(value);
          first = false;
        });
        writeString("
        ");
        this._indentLevel--;
        this.writeIndentation(this._indentLevel);
        writeString("}");
      }
    }
  }

  class _JsonStringStringifier extends _JsonStringifier {
    constructor(_sink, _toEncodable) {
      this._sink = _sink;
      super(/* Unimplemented: DownCast: dynamic to (Object) → Object */_toEncodable);
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
      dart.dinvoke(stringifier, "writeObject", object);
    }
    writeNumber(number) {
      this._sink.write(number.toString());
    }
    writeString(string) {
      this._sink.write(string);
    }
    writeStringSlice(string, start, end) {
      this._sink.write(string.substring(start, end));
    }
    writeCharCode(charCode) {
      this._sink.writeCharCode(charCode);
    }
  }

  class _JsonStringStringifierPretty extends dart.mixin(_JsonStringStringifier, _JsonPrettyPrintMixin) {
    constructor(sink, toEncodable, _indent) {
      this._indent = _indent;
      super(sink, toEncodable);
    }
    writeIndentation(count) {
      for (let i = 0; i < count; i++) writeString(this._indent);
    }
  }

  class _JsonUtf8Stringifier extends _JsonStringifier {
    constructor(toEncodable, bufferSize, addChunk) {
      this.addChunk = addChunk;
      this.bufferSize = bufferSize;
      this.buffer = new typed_data.Uint8List(bufferSize);
      this.index = 0;
      super(/* Unimplemented: DownCast: dynamic to (Object) → Object */toEncodable);
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
      if (this.index > 0) {
        dart.dinvokef(this.addChunk, this.buffer, 0, this.index);
      }
      this.buffer = null;
      this.index = 0;
    }
    writeNumber(number) {
      this.writeAsciiString(number.toString());
    }
    writeAsciiString(string) {
      for (let i = 0; i < string.length; i++) {
        let char = string.codeUnitAt(i);
        dart.assert(char <= 127);
        this.writeByte(char);
      }
    }
    writeString(string) {
      this.writeStringSlice(string, 0, string.length);
    }
    writeStringSlice(string, start, end) {
      for (let i = start; i < end; i++) {
        let char = string.codeUnitAt(i);
        if (char <= 127) {
          this.writeByte(char);
        } else {
          if ((char & 64512) === 55296 && i + 1 < end) {
            let nextChar = string.codeUnitAt(i + 1);
            if ((nextChar & 64512) === 56320) {
              char = 65536 + ((char & 1023) << 10) + (nextChar & 1023);
              this.writeFourByteCharCode(char);
              i++;
              continue;
            }
          }
          this.writeMultiByteCharCode(char);
        }
      }
    }
    writeCharCode(charCode) {
      if (charCode <= 127) {
        this.writeByte(charCode);
        return;
      }
      this.writeMultiByteCharCode(charCode);
    }
    writeMultiByteCharCode(charCode) {
      if (charCode <= 2047) {
        this.writeByte(192 | (charCode >> 6));
        this.writeByte(128 | (charCode & 63));
        return;
      }
      if (charCode <= 65535) {
        this.writeByte(224 | (charCode >> 12));
        this.writeByte(128 | ((charCode >> 6) & 63));
        this.writeByte(128 | (charCode & 63));
        return;
      }
      this.writeFourByteCharCode(charCode);
    }
    writeFourByteCharCode(charCode) {
      dart.assert(charCode <= 1114111);
      this.writeByte(240 | (charCode >> 18));
      this.writeByte(128 | ((charCode >> 12) & 63));
      this.writeByte(128 | ((charCode >> 6) & 63));
      this.writeByte(128 | (charCode & 63));
    }
    writeByte(byte) {
      dart.assert(byte <= 255);
      if (this.index === this.buffer.length) {
        dart.dinvokef(this.addChunk, this.buffer, 0, this.index);
        this.buffer = new typed_data.Uint8List(this.bufferSize);
        this.index = 0;
      }
      this.buffer.set(this.index++, byte);
    }
  }

  class _JsonUtf8StringifierPretty extends dart.mixin(_JsonUtf8Stringifier, _JsonPrettyPrintMixin) {
    constructor(toEncodableFunction, indent, bufferSize, addChunk) {
      this.indent = indent;
      super(toEncodableFunction, dart.as(bufferSize, core.int), dart.as(addChunk, core.Function));
    }
    writeIndentation(count) {
      let indent = this.indent;
      let indentLength = indent.length;
      if (indentLength === 1) {
        let char = indent.get(0);
        while (count > 0) {
          writeByte(char);
          count = 1;
        }
        return;
      }
      while (count > 0) {
        count--;
        let end = index + indentLength;
        if (end <= buffer.length) {
          buffer.setRange(index, end, indent);
          index = end;
        } else {
          for (let i = 0; i < indentLength; i++) {
            writeByte(indent.get(i));
          }
        }
      }
    }
  }

  let LATIN1 = new Latin1Codec();
  let _LATIN1_MASK = 255;
  class Latin1Codec extends Encoding {
    constructor(opt$) {
      let allowInvalid = opt$.allowInvalid === undefined ? false : opt$.allowInvalid;
      this._allowInvalid = allowInvalid;
      super();
    }
    get name() { return "iso-8859-1"; }
    decode(bytes, opt$) {
      let allowInvalid = opt$.allowInvalid === undefined ? null : opt$.allowInvalid;
      if (allowInvalid === null) allowInvalid = this._allowInvalid;
      if (allowInvalid) {
        return new Latin1Decoder({allowInvalid: true}).convert(bytes);
      } else {
        return new Latin1Decoder({allowInvalid: false}).convert(bytes);
      }
    }
    get encoder() { return new Latin1Encoder(); }
    get decoder() { return this._allowInvalid ? new Latin1Decoder({allowInvalid: true}) : new Latin1Decoder({allowInvalid: false}); }
  }

  class Latin1Encoder extends _UnicodeSubsetEncoder {
    constructor() {
      super(_LATIN1_MASK);
    }
  }

  class Latin1Decoder extends _UnicodeSubsetDecoder {
    constructor(opt$) {
      let allowInvalid = opt$.allowInvalid === undefined ? false : opt$.allowInvalid;
      super(allowInvalid, _LATIN1_MASK);
    }
    startChunkedConversion(sink) {
      let stringSink = null;
      if (dart.is(sink, StringConversionSink)) {
        stringSink = dart.as(sink, StringConversionSink);
      } else {
        stringSink = new StringConversionSink.from(sink);
      }
      if (!_allowInvalid) return new _Latin1DecoderSink(stringSink);
      return new _Latin1AllowInvalidDecoderSink(stringSink);
    }
  }

  class _Latin1DecoderSink extends ByteConversionSinkBase {
    constructor(_sink) {
      this._sink = _sink;
      super();
    }
    close() {
      this._sink.close();
    }
    add(source) {
      this.addSlice(source, 0, source.length, false);
    }
    _addSliceToSink(source, start, end, isLast) {
      this._sink.add(new core.String.fromCharCodes(source, start, end));
      if (isLast) this.close();
    }
    addSlice(source, start, end, isLast) {
      core.RangeError.checkValidRange(start, end, source.length);
      for (let i = start; i < end; i++) {
        let char = source.get(i);
        if (char > _LATIN1_MASK || char < 0) {
          throw new core.FormatException("Source contains non-Latin-1 characters.");
        }
      }
      if (start < end) {
        this._addSliceToSink(source, start, end, isLast);
      }
      if (isLast) {
        this.close();
      }
    }
  }

  class _Latin1AllowInvalidDecoderSink extends _Latin1DecoderSink {
    constructor(sink) {
      super(sink);
    }
    addSlice(source, start, end, isLast) {
      core.RangeError.checkValidRange(start, end, source.length);
      for (let i = start; i < end; i++) {
        let char = source.get(i);
        if (char > _LATIN1_MASK || char < 0) {
          if (i > start) _addSliceToSink(source, start, i, false);
          _addSliceToSink(dart.as(/* Unimplemented const */new List.from([65533]), core.List), 0, 1, false);
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

  class LineSplitter extends Converter/* Unimplemented <String, List<String>> */ {
    constructor() {
      super();
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
      return new _LineSplitterSink(sink);
    }
  }

  class _LineSplitterSink extends StringConversionSinkBase {
    constructor(_sink) {
      this._sink = _sink;
      this._carry = null;
      super();
    }
    addSlice(chunk, start, end, isLast) {
      if (this._carry !== null) {
        chunk = core.String['+'](this._carry, chunk.substring(start, end));
        start = 0;
        end = chunk.length;
        this._carry = null;
      }
      this._carry = _addSlice(chunk, start, end, isLast, this._sink.add);
      if (isLast) this._sink.close();
    }
    close() {
      this.addSlice("", 0, 0, true);
    }
    static _addSlice(chunk, start, end, isLast, adder) {
      let pos = start;
      while (pos < end) {
        let skip = 0;
        let char = chunk.codeUnitAt(pos);
        if (char === _LF) {
          skip = 1;
        } else if (char === _CR) {
          skip = 1;
          if (pos + 1 < end) {
            if (chunk.codeUnitAt(pos + 1) === _LF) {
              skip = 2;
            }
          } else if (!isLast) {
            return chunk.substring(start, end);
          }
        }
        if (skip > 0) {
          adder(chunk.substring(start, pos));
          start = pos = pos + skip;
        } else {
          pos++;
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

  class StringConversionSink extends ChunkedConversionSink/* Unimplemented <String> */ {
    constructor() {
      super();
    }
    /*constructor*/ withCallback(callback) {
      return new _StringCallbackSink(callback);
    }
    /*constructor*/ from(sink) {
      return new _StringAdapterSink(sink);
    }
    /*constructor*/ fromStringSink(sink) {
      return new _StringSinkConversionSink(sink);
    }
  }
  dart.defineNamedConstructor(StringConversionSink, "withCallback");
  dart.defineNamedConstructor(StringConversionSink, "from");
  dart.defineNamedConstructor(StringConversionSink, "fromStringSink");

  class ClosableStringSink extends core.StringSink {
    /*constructor*/ fromStringSink(sink, onClose) {
      return new _ClosableStringSink(sink, onClose);
    }
  }
  dart.defineNamedConstructor(ClosableStringSink, "fromStringSink");

  class _ClosableStringSink {
    constructor(_sink, _callback) {
      this._sink = _sink;
      this._callback = _callback;
    }
    close() { return this._callback(); }
    writeCharCode(charCode) { return this._sink.writeCharCode(charCode); }
    write(o) { return this._sink.write(o); }
    writeln(o) {
      if (o === undefined) o = "";
      return this._sink.writeln(o)
    }
    writeAll(objects, separator) {
      if (separator === undefined) separator = "";
      return this._sink.writeAll(objects, separator)
    }
  }

  class _StringConversionSinkAsStringSinkAdapter {
    constructor(_chunkedSink) {
      this._chunkedSink = _chunkedSink;
      this._buffer = new core.StringBuffer();
    }
    close() {
      if (this._buffer.isNotEmpty) this._flush();
      this._chunkedSink.close();
    }
    writeCharCode(charCode) {
      this._buffer.writeCharCode(charCode);
      if (this._buffer.length['>'](_MIN_STRING_SIZE)) this._flush();
    }
    write(o) {
      if (this._buffer.isNotEmpty) this._flush();
      let str = o.toString();
      this._chunkedSink.add(o.toString());
    }
    writeln(o) {
      if (o === undefined) o = "";
      this._buffer.writeln(o);
      if (this._buffer.length['>'](_MIN_STRING_SIZE)) this._flush();
    }
    writeAll(objects, separator) {
      if (separator === undefined) separator = "";
      if (this._buffer.isNotEmpty) this._flush();
      let iterator = objects.iterator;
      if (!iterator.moveNext()) return;
      if (separator.isEmpty) {
        do {
          this._chunkedSink.add(dart.as(dart.dinvoke(iterator.current, "toString"), core.String));
        }
        while (iterator.moveNext());
      } else {
        this._chunkedSink.add(dart.as(dart.dinvoke(iterator.current, "toString"), core.String));
        while (iterator.moveNext()) {
          this.write(separator);
          this._chunkedSink.add(dart.as(dart.dinvoke(iterator.current, "toString"), core.String));
        }
      }
    }
    _flush() {
      let accumulated = this._buffer.toString();
      this._buffer.clear();
      this._chunkedSink.add(accumulated);
    }
  }
  _StringConversionSinkAsStringSinkAdapter._MIN_STRING_SIZE = 16;

  class StringConversionSinkBase extends StringConversionSinkMixin {
  }

  class StringConversionSinkMixin {
    add(str) { return this.addSlice(str, 0, str.length, false); }
    asUtf8Sink(allowMalformed) {
      return new _Utf8ConversionSink(this, allowMalformed);
    }
    asStringSink() {
      return new _StringConversionSinkAsStringSinkAdapter(this);
    }
  }

  class _StringSinkConversionSink extends StringConversionSinkBase {
    constructor(_stringSink) {
      this._stringSink = _stringSink;
      super();
    }
    close() {
    }
    addSlice(str, start, end, isLast) {
      if (start !== 0 || end !== str.length) {
        for (let i = start; i < end; i++) {
          this._stringSink.writeCharCode(str.codeUnitAt(i));
        }
      } else {
        this._stringSink.write(str);
      }
      if (isLast) this.close();
    }
    add(str) { return this._stringSink.write(str); }
    asUtf8Sink(allowMalformed) {
      return new _Utf8StringSinkAdapter(this, this._stringSink, allowMalformed);
    }
    asStringSink() {
      return new ClosableStringSink.fromStringSink(this._stringSink, this.close);
    }
  }

  class _StringCallbackSink extends _StringSinkConversionSink {
    constructor(_callback) {
      this._callback = _callback;
      super(new core.StringBuffer());
    }
    close() {
      let buffer = dart.as(_stringSink, core.StringBuffer);
      let accumulated = buffer.toString();
      buffer.clear();
      this._callback(accumulated);
    }
    asUtf8Sink(allowMalformed) {
      return new _Utf8StringSinkAdapter(this, _stringSink, allowMalformed);
    }
  }

  class _StringAdapterSink extends StringConversionSinkBase {
    constructor(_sink) {
      this._sink = _sink;
      super();
    }
    add(str) { return this._sink.add(str); }
    addSlice(str, start, end, isLast) {
      if (start === 0 && end === str.length) {
        this.add(str);
      } else {
        this.add(str.substring(start, end));
      }
      if (isLast) this.close();
    }
    close() { return this._sink.close(); }
  }

  class _Utf8StringSinkAdapter extends ByteConversionSink {
    constructor(_sink, stringSink, allowMalformed) {
      this._sink = _sink;
      this._decoder = new _Utf8Decoder(stringSink, allowMalformed);
      super();
    }
    close() {
      this._decoder.close();
      if (this._sink !== null) this._sink.close();
    }
    add(chunk) {
      this.addSlice(chunk, 0, chunk.length, false);
    }
    addSlice(codeUnits, startIndex, endIndex, isLast) {
      this._decoder.convert(codeUnits, startIndex, endIndex);
      if (isLast) this.close();
    }
  }

  class _Utf8ConversionSink extends ByteConversionSink {
    constructor(sink, allowMalformed) {
      _Utf8ConversionSink.call(this, sink, new core.StringBuffer(), allowMalformed);
    }
    /*constructor*/ _(_chunkedSink, stringBuffer, allowMalformed) {
      this._chunkedSink = _chunkedSink;
      this._decoder = new _Utf8Decoder(stringBuffer, allowMalformed);
      this._buffer = stringBuffer;
      ByteConversionSink.call(this);
    }
    close() {
      this._decoder.close();
      if (this._buffer.isNotEmpty) {
        let accumulated = this._buffer.toString();
        this._buffer.clear();
        this._chunkedSink.addSlice(accumulated, 0, accumulated.length, true);
      } else {
        this._chunkedSink.close();
      }
    }
    add(chunk) {
      this.addSlice(chunk, 0, chunk.length, false);
    }
    addSlice(chunk, startIndex, endIndex, isLast) {
      this._decoder.convert(chunk, startIndex, endIndex);
      if (this._buffer.isNotEmpty) {
        let accumulated = this._buffer.toString();
        this._chunkedSink.addSlice(accumulated, 0, accumulated.length, isLast);
        this._buffer.clear();
        return;
      }
      if (isLast) this.close();
    }
  }
  dart.defineNamedConstructor(_Utf8ConversionSink, "_");

  let UNICODE_REPLACEMENT_CHARACTER_RUNE = 65533;
  let UNICODE_BOM_CHARACTER_RUNE = 65279;
  let UTF8 = new Utf8Codec();
  class Utf8Codec extends Encoding {
    constructor(opt$) {
      let allowMalformed = opt$.allowMalformed === undefined ? false : opt$.allowMalformed;
      this._allowMalformed = allowMalformed;
      super();
    }
    get name() { return "utf-8"; }
    decode(codeUnits, opt$) {
      let allowMalformed = opt$.allowMalformed === undefined ? null : opt$.allowMalformed;
      if (allowMalformed === null) allowMalformed = this._allowMalformed;
      return new Utf8Decoder({allowMalformed: allowMalformed}).convert(codeUnits);
    }
    get encoder() { return new Utf8Encoder(); }
    get decoder() {
      return new Utf8Decoder({allowMalformed: this._allowMalformed});
    }
  }

  class Utf8Encoder extends Converter/* Unimplemented <String, List<int>> */ {
    constructor() {
      super();
    }
    convert(string, start, end) {
      if (start === undefined) start = 0;
      if (end === undefined) end = null;
      let stringLength = string.length;
      core.RangeError.checkValidRange(start, end, stringLength);
      if (end === null) end = stringLength;
      let length = end - start;
      if (length === 0) return new typed_data.Uint8List(0);
      let encoder = new _Utf8Encoder.withBufferSize(length * 3);
      let endPosition = encoder._fillBuffer(string, start, end);
      dart.assert(endPosition >= end - 1);
      if (endPosition !== end) {
        let lastCodeUnit = string.codeUnitAt(end - 1);
        dart.assert(_isLeadSurrogate(lastCodeUnit));
        let wasCombined = encoder._writeSurrogate(lastCodeUnit, 0);
        dart.assert(!wasCombined);
      }
      return encoder._buffer.sublist(0, encoder._bufferIndex);
    }
    startChunkedConversion(sink) {
      if (!dart.is(sink, ByteConversionSink)) {
        sink = new ByteConversionSink.from(sink);
      }
      return new _Utf8EncoderSink(sink);
    }
    bind(stream) { return dart.as(super.bind(stream), async.Stream); }
  }

  class _Utf8Encoder {
    constructor() {
      _Utf8Encoder.call(this, dart.as(_DEFAULT_BYTE_BUFFER_SIZE, core.int));
    }
    /*constructor*/ withBufferSize(bufferSize) {
      this._buffer = _createBuffer(bufferSize);
      this._carry = 0;
      this._bufferIndex = 0;
    }
    static _createBuffer(size) { return new typed_data.Uint8List(size); }
    _writeSurrogate(leadingSurrogate, nextCodeUnit) {
      if (_isTailSurrogate(nextCodeUnit)) {
        let rune = _combineSurrogatePair(leadingSurrogate, nextCodeUnit);
        dart.assert(rune > _THREE_BYTE_LIMIT);
        dart.assert(rune <= _FOUR_BYTE_LIMIT);
        this._buffer.set(this._bufferIndex++, 240 | (rune >> 18));
        this._buffer.set(this._bufferIndex++, 128 | ((rune >> 12) & 63));
        this._buffer.set(this._bufferIndex++, 128 | ((rune >> 6) & 63));
        this._buffer.set(this._bufferIndex++, 128 | (rune & 63));
        return true;
      } else {
        this._buffer.set(this._bufferIndex++, 224 | (leadingSurrogate >> 12));
        this._buffer.set(this._bufferIndex++, 128 | ((leadingSurrogate >> 6) & 63));
        this._buffer.set(this._bufferIndex++, 128 | (leadingSurrogate & 63));
        return false;
      }
    }
    _fillBuffer(str, start, end) {
      if (start !== end && _isLeadSurrogate(str.codeUnitAt(end - 1))) {
        end--;
      }
      let stringIndex = null;
      for (stringIndex = start; stringIndex < end; stringIndex++) {
        let codeUnit = str.codeUnitAt(stringIndex);
        if (codeUnit <= _ONE_BYTE_LIMIT) {
          if (this._bufferIndex >= this._buffer.length) break;
          this._buffer.set(this._bufferIndex++, codeUnit);
        } else if (_isLeadSurrogate(codeUnit)) {
          if (this._bufferIndex + 3 >= this._buffer.length) break;
          let nextCodeUnit = str.codeUnitAt(stringIndex + 1);
          let wasCombined = this._writeSurrogate(codeUnit, nextCodeUnit);
          if (wasCombined) stringIndex++;
        } else {
          let rune = codeUnit;
          if (rune <= _TWO_BYTE_LIMIT) {
            if (this._bufferIndex + 1 >= this._buffer.length) break;
            this._buffer.set(this._bufferIndex++, 192 | (rune >> 6));
            this._buffer.set(this._bufferIndex++, 128 | (rune & 63));
          } else {
            dart.assert(rune <= _THREE_BYTE_LIMIT);
            if (this._bufferIndex + 2 >= this._buffer.length) break;
            this._buffer.set(this._bufferIndex++, 224 | (rune >> 12));
            this._buffer.set(this._bufferIndex++, 128 | ((rune >> 6) & 63));
            this._buffer.set(this._bufferIndex++, 128 | (rune & 63));
          }
        }
      }
      return stringIndex;
    }
  }
  dart.defineNamedConstructor(_Utf8Encoder, "withBufferSize");
  _Utf8Encoder._DEFAULT_BYTE_BUFFER_SIZE = 1024;

  class _Utf8EncoderSink extends dart.mixin(_Utf8Encoder, StringConversionSinkMixin) {
    constructor(_sink) {
      this._sink = _sink;
      super();
    }
    close() {
      if (_carry !== 0) {
        this.addSlice("", 0, 0, true);
        return;
      }
      this._sink.close();
    }
    addSlice(str, start, end, isLast) {
      _bufferIndex = 0;
      if (start === end && !isLast) {
        return;
      }
      if (_carry !== 0) {
        let nextCodeUnit = 0;
        if (start !== end) {
          nextCodeUnit = str.codeUnitAt(start);
        } else {
          dart.assert(isLast);
        }
        let wasCombined = _writeSurrogate(_carry, nextCodeUnit);
        dart.assert(!wasCombined || start !== end);
        if (wasCombined) start++;
        _carry = 0;
      }
      do {
        start = _fillBuffer(str, start, end);
        let isLastSlice = isLast && (start === end);
        if (start === end - 1 && _isLeadSurrogate(str.codeUnitAt(start))) {
          if (isLast && _bufferIndex < _buffer.length - 3) {
            let hasBeenCombined = _writeSurrogate(str.codeUnitAt(start), 0);
            dart.assert(!hasBeenCombined);
          } else {
            _carry = str.codeUnitAt(start);
          }
          start++;
        }
        this._sink.addSlice(_buffer, 0, _bufferIndex, isLastSlice);
        _bufferIndex = 0;
      }
      while (start < end);
      if (isLast) this.close();
    }
  }

  class Utf8Decoder extends Converter/* Unimplemented <List<int>, String> */ {
    constructor(opt$) {
      let allowMalformed = opt$.allowMalformed === undefined ? false : opt$.allowMalformed;
      this._allowMalformed = allowMalformed;
      super();
    }
    convert(codeUnits, start, end) {
      if (start === undefined) start = 0;
      if (end === undefined) end = null;
      let length = codeUnits.length;
      core.RangeError.checkValidRange(start, end, length);
      if (end === null) end = length;
      let buffer = new core.StringBuffer();
      let decoder = new _Utf8Decoder(buffer, this._allowMalformed);
      decoder.convert(codeUnits, start, end);
      decoder.close();
      return buffer.toString();
    }
    startChunkedConversion(sink) {
      let stringSink = null;
      if (dart.is(sink, StringConversionSink)) {
        stringSink = dart.as(sink, StringConversionSink);
      } else {
        stringSink = new StringConversionSink.from(sink);
      }
      return stringSink.asUtf8Sink(this._allowMalformed);
    }
    bind(stream) { return dart.as(super.bind(stream), async.Stream); }
    /* Unimplemented external Converter<List<int>, dynamic> fuse(Converter<String, dynamic> next); */
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
  function _isSurrogate(codeUnit) { return (codeUnit & _SURROGATE_MASK) === _LEAD_SURROGATE_MIN; }

  // Function _isLeadSurrogate: (int) → bool
  function _isLeadSurrogate(codeUnit) { return (codeUnit & _SURROGATE_TAG_MASK) === _LEAD_SURROGATE_MIN; }

  // Function _isTailSurrogate: (int) → bool
  function _isTailSurrogate(codeUnit) { return (codeUnit & _SURROGATE_TAG_MASK) === _TAIL_SURROGATE_MIN; }

  // Function _combineSurrogatePair: (int, int) → int
  function _combineSurrogatePair(lead, tail) { return 65536 + ((lead & _SURROGATE_VALUE_MASK) << 10) | (tail & _SURROGATE_VALUE_MASK); }

  class _Utf8Decoder {
    constructor(_stringSink, _allowMalformed) {
      this._stringSink = _stringSink;
      this._allowMalformed = _allowMalformed;
      this._isFirstCharacter = true;
      this._value = 0;
      this._expectedUnits = 0;
      this._extraUnits = 0;
    }
    get hasPartialInput() { return this._expectedUnits > 0; }
    close() {
      this.flush();
    }
    flush() {
      if (this.hasPartialInput) {
        if (!this._allowMalformed) {
          throw new core.FormatException("Unfinished UTF-8 octet sequence");
        }
        this._stringSink.writeCharCode(UNICODE_REPLACEMENT_CHARACTER_RUNE);
        this._value = 0;
        this._expectedUnits = 0;
        this._extraUnits = 0;
      }
    }
    convert(codeUnits, startIndex, endIndex) {
      let value = this._value;
      let expectedUnits = this._expectedUnits;
      let extraUnits = this._extraUnits;
      this._value = 0;
      this._expectedUnits = 0;
      this._extraUnits = 0;
      // Function scanOneByteCharacters: (dynamic, int) → int
      function scanOneByteCharacters(units, from) {
        let to = endIndex;
        let mask = _ONE_BYTE_LIMIT;
        for (let i = from; i < to; i++) {
          let unit = dart.dindex(units, i);
          if (!dart.equals((dart.dbinary(unit, "&", mask)), unit)) return i - from;
        }
        return to - from;
      }
      // Function addSingleBytes: (int, int) → void
      function addSingleBytes(from, to) {
        dart.assert(from >= startIndex && from <= endIndex);
        dart.assert(to >= startIndex && to <= endIndex);
        this._stringSink.write(new core.String.fromCharCodes(codeUnits, from, to));
      }
      let i = startIndex;
      loop: while (true) {
        multibyte: if (expectedUnits > 0) {
          do {
            if (i === endIndex) {
              break loop;
            }
            let unit = codeUnits.get(i);
            if ((unit & 192) !== 128) {
              expectedUnits = 0;
              if (!this._allowMalformed) {
                throw new core.FormatException("Bad UTF-8 encoding 0x" + (unit.toRadixString(16)) + "");
              }
              this._isFirstCharacter = false;
              this._stringSink.writeCharCode(UNICODE_REPLACEMENT_CHARACTER_RUNE);
              break multibyte;
            } else {
              value = (value << 6) | (unit & 63);
              expectedUnits--;
              i++;
            }
          }
          while (expectedUnits > 0);
          if (value <= _LIMITS.get(extraUnits - 1)) {
            if (!this._allowMalformed) {
              throw new core.FormatException("Overlong encoding of 0x" + (value.toRadixString(16)) + "");
            }
            expectedUnits = extraUnits = 0;
            value = UNICODE_REPLACEMENT_CHARACTER_RUNE;
          }
          if (value > _FOUR_BYTE_LIMIT) {
            if (!this._allowMalformed) {
              throw new core.FormatException("Character outside valid Unicode range: " + "0x" + (value.toRadixString(16)) + "");
            }
            value = UNICODE_REPLACEMENT_CHARACTER_RUNE;
          }
          if (!this._isFirstCharacter || value !== UNICODE_BOM_CHARACTER_RUNE) {
            this._stringSink.writeCharCode(value);
          }
          this._isFirstCharacter = false;
        }
        while (i < endIndex) {
          let oneBytes = scanOneByteCharacters(codeUnits, i);
          if (oneBytes > 0) {
            this._isFirstCharacter = false;
            addSingleBytes(i, i + oneBytes);
            i = oneBytes;
            if (i === endIndex) break;
          }
          let unit = codeUnits.get(i++);
          if (unit < 0) {
            if (!this._allowMalformed) {
              throw new core.FormatException("Negative UTF-8 code unit: -0x" + ((-unit).toRadixString(16)) + "");
            }
            this._stringSink.writeCharCode(UNICODE_REPLACEMENT_CHARACTER_RUNE);
          } else {
            dart.assert(unit > _ONE_BYTE_LIMIT);
            if ((unit & 224) === 192) {
              value = unit & 31;
              expectedUnits = extraUnits = 1;
              continue loop;
            }
            if ((unit & 240) === 224) {
              value = unit & 15;
              expectedUnits = extraUnits = 2;
              continue loop;
            }
            if ((unit & 248) === 240 && unit < 245) {
              value = unit & 7;
              expectedUnits = extraUnits = 3;
              continue loop;
            }
            if (!this._allowMalformed) {
              throw new core.FormatException("Bad UTF-8 encoding 0x" + (unit.toRadixString(16)) + "");
            }
            value = UNICODE_REPLACEMENT_CHARACTER_RUNE;
            expectedUnits = extraUnits = 0;
            this._isFirstCharacter = false;
            this._stringSink.writeCharCode(value);
          }
        }
        break loop;
      }
      if (expectedUnits > 0) {
        this._value = value;
        this._expectedUnits = expectedUnits;
        this._extraUnits = extraUnits;
      }
    }
  }
  _Utf8Decoder._LIMITS = /* Unimplemented const */new List.from([_ONE_BYTE_LIMIT, _TWO_BYTE_LIMIT, _THREE_BYTE_LIMIT, _FOUR_BYTE_LIMIT]);

  // Exports:
  convert.ASCII = ASCII;
  convert.AsciiCodec = AsciiCodec;
  convert.AsciiEncoder = AsciiEncoder;
  convert.AsciiDecoder = AsciiDecoder;
  convert.ByteConversionSink = ByteConversionSink;
  convert.ByteConversionSinkBase = ByteConversionSinkBase;
  convert.ChunkedConversionSink = ChunkedConversionSink;
  convert.Codec = Codec;
  convert.Converter = Converter;
  convert.Encoding = Encoding;
  convert.HTML_ESCAPE = HTML_ESCAPE;
  convert.HtmlEscapeMode = HtmlEscapeMode;
  convert.HtmlEscape = HtmlEscape;
  convert.JsonUnsupportedObjectError = JsonUnsupportedObjectError;
  convert.JsonCyclicError = JsonCyclicError;
  convert.JSON = JSON;
  convert.JsonCodec = JsonCodec;
  convert.JsonEncoder = JsonEncoder;
  convert.JsonUtf8Encoder = JsonUtf8Encoder;
  convert.JsonDecoder = JsonDecoder;
  convert.LATIN1 = LATIN1;
  convert.Latin1Codec = Latin1Codec;
  convert.Latin1Encoder = Latin1Encoder;
  convert.Latin1Decoder = Latin1Decoder;
  convert.LineSplitter = LineSplitter;
  convert.StringConversionSink = StringConversionSink;
  convert.ClosableStringSink = ClosableStringSink;
  convert.StringConversionSinkBase = StringConversionSinkBase;
  convert.StringConversionSinkMixin = StringConversionSinkMixin;
  convert.UNICODE_REPLACEMENT_CHARACTER_RUNE = UNICODE_REPLACEMENT_CHARACTER_RUNE;
  convert.UNICODE_BOM_CHARACTER_RUNE = UNICODE_BOM_CHARACTER_RUNE;
  convert.UTF8 = UTF8;
  convert.Utf8Codec = Utf8Codec;
  convert.Utf8Encoder = Utf8Encoder;
  convert.Utf8Decoder = Utf8Decoder;
})(convert || (convert = {}));
