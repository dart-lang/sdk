var convert;
(function(exports) {
  'use strict';
  // Function _convertJsonToDart: (dynamic, (dynamic, dynamic) → dynamic) → dynamic
  function _convertJsonToDart(json, reviver) {
    dart.assert(reviver !== null);
    // Function walk: (dynamic) → dynamic
    function walk(e) {
      if (dart.notNull(e == null) || dart.notNull(typeof e != "object")) {
        return e;
      }
      if (Object.getPrototypeOf(e) === Array.prototype) {
        for (let i = 0; i < e.length; i++) {
          let item = e[i];
          e[i] = reviver(i, walk(item));
        }
        return e;
      }
      let map = new _JsonMap(e);
      let processed = map._processed;
      let keys = map._computeKeys();
      for (let i = 0; i < keys.length; i++) {
        let key = keys.get(i);
        let revived = reviver(key, walk(e[key]));
        processed[key] = revived;
      }
      map._original = processed;
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
    for (let i = 0; i < object.length; i++) {
      let item = object[i];
      object[i] = _convertJsonToDartLazy(item);
    }
    return object;
  }
  class _JsonMap extends dart.Object {
    _JsonMap(_original) {
      this._processed = _newJavaScriptObject();
      this._original = _original;
      this._data = null;
    }
    get(key) {
      if (this._isUpgraded) {
        return this._upgradedMap.get(key);
      } else if (!(typeof key == string)) {
        return null;
      } else {
        let result = _getProperty(this._processed, dart.as(key, core.String));
        if (_isUnprocessed(result))
          result = this._process(dart.as(key, core.String));
        return result;
      }
    }
    get length() {
      return this._isUpgraded ? this._upgradedMap.length : this._computeKeys().length;
    }
    get isEmpty() {
      return this.length === 0;
    }
    get isNotEmpty() {
      return this.length > 0;
    }
    get keys() {
      if (this._isUpgraded)
        return this._upgradedMap.keys;
      return new _JsonMapKeyIterable(this);
    }
    get values() {
      if (this._isUpgraded)
        return this._upgradedMap.values;
      return new _internal.MappedIterable(this._computeKeys(), ((each) => this.get(each)).bind(this));
    }
    set(key, value) {
      if (this._isUpgraded) {
        this._upgradedMap.set(key, value);
      } else if (this.containsKey(key)) {
        let processed = this._processed;
        _setProperty(processed, dart.as(key, core.String), value);
        let original = this._original;
        if (!dart.notNull(core.identical(original, processed))) {
          _setProperty(original, dart.as(key, core.String), null);
        }
      } else {
        this._upgrade().set(key, value);
      }
    }
    addAll(other) {
      other.forEach(((key, value) => {
        this.set(key, value);
      }).bind(this));
    }
    containsValue(value) {
      if (this._isUpgraded)
        return this._upgradedMap.containsValue(value);
      let keys = this._computeKeys();
      for (let i = 0; i < keys.length; i++) {
        let key = keys.get(i);
        if (dart.equals(this.get(key), value))
          return true;
      }
      return false;
    }
    containsKey(key) {
      if (this._isUpgraded)
        return this._upgradedMap.containsKey(key);
      if (!(typeof key == string))
        return false;
      return _hasProperty(this._original, dart.as(key, core.String));
    }
    putIfAbsent(key, ifAbsent) {
      if (this.containsKey(key))
        return this.get(key);
      let value = ifAbsent();
      this.set(key, value);
      return value;
    }
    remove(key) {
      if (dart.notNull(!dart.notNull(this._isUpgraded)) && dart.notNull(!dart.notNull(this.containsKey(key))))
        return null;
      return this._upgrade().remove(key);
    }
    clear() {
      if (this._isUpgraded) {
        this._upgradedMap.clear();
      } else {
        if (this._data !== null) {
          dart.dinvoke(this._data, 'clear');
        }
        this._original = this._processed = null;
        this._data = dart.map();
      }
    }
    forEach(f) {
      if (this._isUpgraded)
        return this._upgradedMap.forEach(f);
      let keys = this._computeKeys();
      for (let i = 0; i < keys.length; i++) {
        let key = keys.get(i);
        let value = _getProperty(this._processed, key);
        if (_isUnprocessed(value)) {
          value = _convertJsonToDartLazy(_getProperty(this._original, key));
          _setProperty(this._processed, key, value);
        }
        f(key, value);
        if (!dart.notNull(core.identical(keys, this._data))) {
          throw new core.ConcurrentModificationError(this);
        }
      }
    }
    toString() {
      return collection.Maps.mapToString(this);
    }
    get _isUpgraded() {
      return this._processed === null;
    }
    get _upgradedMap() {
      dart.assert(this._isUpgraded);
      return dart.as(this._data, core.Map);
    }
    _computeKeys() {
      dart.assert(!dart.notNull(this._isUpgraded));
      let keys = dart.as(this._data, core.List);
      if (keys === null) {
        keys = this._data = _getPropertyNames(this._original);
      }
      return dart.as(keys, core.List$(core.String));
    }
    _upgrade() {
      if (this._isUpgraded)
        return this._upgradedMap;
      let result = dart.map();
      let keys = this._computeKeys();
      for (let i = 0; i < keys.length; i++) {
        let key = keys.get(i);
        result.set(key, this.get(key));
      }
      if (keys.isEmpty) {
        keys.add(null);
      } else {
        keys.clear();
      }
      this._original = this._processed = null;
      this._data = result;
      dart.assert(this._isUpgraded);
      return result;
    }
    _process(key) {
      if (!dart.notNull(_hasProperty(this._original, key)))
        return null;
      let result = _convertJsonToDartLazy(_getProperty(this._original, key));
      return _setProperty(this._processed, key, result);
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
  class _JsonMapKeyIterable extends _internal.ListIterable {
    _JsonMapKeyIterable(_parent) {
      this._parent = _parent;
      super.ListIterable();
    }
    get length() {
      return this._parent.length;
    }
    elementAt(index) {
      return dart.as(this._parent._isUpgraded ? this._parent.keys.elementAt(index) : this._parent._computeKeys().get(index), core.String);
    }
    get iterator() {
      return dart.as(this._parent._isUpgraded ? this._parent.keys.iterator : this._parent._computeKeys().iterator, core.Iterator);
    }
    contains(key) {
      return this._parent.containsKey(key);
    }
  }
  class _JsonDecoderSink extends _StringSinkConversionSink {
    _JsonDecoderSink(_reviver, _sink) {
      this._reviver = _reviver;
      this._sink = _sink;
      super._StringSinkConversionSink(new core.StringBuffer());
    }
    close() {
      super.close();
      let buffer = dart.as(this._stringSink, core.StringBuffer);
      let accumulated = buffer.toString();
      buffer.clear();
      let decoded = _parseJson(accumulated, this._reviver);
      this._sink.add(decoded);
      this._sink.close();
    }
  }
  let ASCII = new AsciiCodec();
  let _ASCII_MASK = 127;
  class AsciiCodec extends Encoding {
    AsciiCodec(opt$) {
      let allowInvalid = opt$.allowInvalid === void 0 ? false : opt$.allowInvalid;
      this._allowInvalid = allowInvalid;
      super.Encoding();
    }
    get name() {
      return "us-ascii";
    }
    decode(bytes, opt$) {
      let allowInvalid = opt$.allowInvalid === void 0 ? null : opt$.allowInvalid;
      if (allowInvalid === null)
        allowInvalid = this._allowInvalid;
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
      return this._allowInvalid ? new AsciiDecoder({allowInvalid: true}) : new AsciiDecoder({allowInvalid: false});
    }
  }
  class _UnicodeSubsetEncoder extends Converter$(core.String, core.List$(core.int)) {
    _UnicodeSubsetEncoder(_subsetMask) {
      this._subsetMask = _subsetMask;
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
      let length = end - start;
      let result = new typed_data.Uint8List(length);
      for (let i = 0; i < length; i++) {
        let codeUnit = string.codeUnitAt(start + i);
        if ((codeUnit & ~this._subsetMask) !== 0) {
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
      return new _UnicodeSubsetEncoderSink(this._subsetMask, dart.as(sink, ByteConversionSink));
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
  class _UnicodeSubsetEncoderSink extends StringConversionSinkBase {
    _UnicodeSubsetEncoderSink(_subsetMask, _sink) {
      this._subsetMask = _subsetMask;
      this._sink = _sink;
      super.StringConversionSinkBase();
    }
    close() {
      this._sink.close();
    }
    addSlice(source, start, end, isLast) {
      core.RangeError.checkValidRange(start, end, source.length);
      for (let i = start; i < end; i++) {
        let codeUnit = source.codeUnitAt(i);
        if ((codeUnit & ~this._subsetMask) !== 0) {
          throw new core.ArgumentError(`Source contains invalid character with code point: ${codeUnit}.`);
        }
      }
      this._sink.add(source.codeUnits.sublist(start, end));
      if (isLast) {
        this.close();
      }
    }
  }
  class _UnicodeSubsetDecoder extends Converter$(core.List$(core.int), core.String) {
    _UnicodeSubsetDecoder(_allowInvalid, _subsetMask) {
      this._allowInvalid = _allowInvalid;
      this._subsetMask = _subsetMask;
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
      let length = end - start;
      for (let i = start; i < end; i++) {
        let byte = bytes.get(i);
        if ((byte & ~this._subsetMask) !== 0) {
          if (!dart.notNull(this._allowInvalid)) {
            throw new core.FormatException(`Invalid value in input: ${byte}`);
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
        if ((value & ~this._subsetMask) !== 0)
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
      if (this._allowInvalid) {
        return new _ErrorHandlingAsciiDecoderSink(stringSink.asUtf8Sink(false));
      } else {
        return new _SimpleAsciiDecoderSink(stringSink);
      }
    }
  }
  class _ErrorHandlingAsciiDecoderSink extends ByteConversionSinkBase {
    _ErrorHandlingAsciiDecoderSink(_utf8Sink) {
      this._utf8Sink = _utf8Sink;
      super.ByteConversionSinkBase();
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
          if (i > start)
            this._utf8Sink.addSlice(source, start, i, false);
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
    _SimpleAsciiDecoderSink(_sink) {
      this._sink = _sink;
      super.ByteConversionSinkBase();
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
        if (dart.notNull(start !== 0) || dart.notNull(end !== length)) {
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
    _ByteAdapterSink(_sink) {
      this._sink = _sink;
      super.ByteConversionSinkBase();
    }
    add(chunk) {
      return this._sink.add(chunk);
    }
    close() {
      return this._sink.close();
    }
  }
  class _ByteCallbackSink extends ByteConversionSinkBase {
    _ByteCallbackSink(callback) {
      this._buffer = new typed_data.Uint8List(dart.as(_INITIAL_BUFFER_SIZE, core.int));
      this._callback = callback;
      this._bufferIndex = 0;
      super.ByteConversionSinkBase();
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
  let ChunkedConversionSink$ = dart.generic(function(T) {
    class ChunkedConversionSink extends dart.Object {
      ChunkedConversionSink() {
      }
      ChunkedConversionSink$withCallback(callback) {
        return new _SimpleCallbackSink(callback);
      }
    }
    dart.defineNamedConstructor(ChunkedConversionSink, 'withCallback');
    return ChunkedConversionSink;
  });
  let ChunkedConversionSink = ChunkedConversionSink$(dynamic);
  let _SimpleCallbackSink$ = dart.generic(function(T) {
    class _SimpleCallbackSink extends ChunkedConversionSink$(T) {
      _SimpleCallbackSink(_callback) {
        this._accumulated = new List.from([]);
        this._callback = _callback;
        super.ChunkedConversionSink();
      }
      add(chunk) {
        this._accumulated.add(chunk);
      }
      close() {
        this._callback(this._accumulated);
      }
    }
    return _SimpleCallbackSink;
  });
  let _SimpleCallbackSink = _SimpleCallbackSink$(dynamic);
  let _EventSinkAdapter$ = dart.generic(function(T) {
    class _EventSinkAdapter extends dart.Object {
      _EventSinkAdapter(_sink) {
        this._sink = _sink;
      }
      add(data) {
        return this._sink.add(data);
      }
      close() {
        return this._sink.close();
      }
    }
    return _EventSinkAdapter;
  });
  let _EventSinkAdapter = _EventSinkAdapter$(dynamic);
  let _ConverterStreamEventSink$ = dart.generic(function(S, T) {
    class _ConverterStreamEventSink extends dart.Object {
      _ConverterStreamEventSink(converter, sink) {
        this._eventSink = sink;
        this._chunkedSink = converter.startChunkedConversion(sink);
      }
      add(o) {
        return this._chunkedSink.add(o);
      }
      addError(error, stackTrace) {
        if (stackTrace === void 0)
          stackTrace = null;
        this._eventSink.addError(error, stackTrace);
      }
      close() {
        return this._chunkedSink.close();
      }
    }
    return _ConverterStreamEventSink;
  });
  let _ConverterStreamEventSink = _ConverterStreamEventSink$(dynamic, dynamic);
  let Codec$ = dart.generic(function(S, T) {
    class Codec extends dart.Object {
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
  let Codec = Codec$(dynamic, dynamic);
  let _FusedCodec$ = dart.generic(function(S, M, T) {
    class _FusedCodec extends Codec$(S, T) {
      get encoder() {
        return dart.as(this._first.encoder.fuse(this._second.encoder), Converter$(S, T));
      }
      get decoder() {
        return dart.as(this._second.decoder.fuse(this._first.decoder), Converter$(T, S));
      }
      _FusedCodec(_first, _second) {
        this._first = _first;
        this._second = _second;
        super.Codec();
      }
    }
    return _FusedCodec;
  });
  let _FusedCodec = _FusedCodec$(dynamic, dynamic, dynamic);
  let _InvertedCodec$ = dart.generic(function(T, S) {
    class _InvertedCodec extends Codec$(T, S) {
      _InvertedCodec(codec) {
        this._codec = codec;
        super.Codec();
      }
      get encoder() {
        return this._codec.decoder;
      }
      get decoder() {
        return this._codec.encoder;
      }
      get inverted() {
        return this._codec;
      }
    }
    return _InvertedCodec;
  });
  let _InvertedCodec = _InvertedCodec$(dynamic, dynamic);
  let Converter$ = dart.generic(function(S, T) {
    class Converter extends dart.Object {
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
  let Converter = Converter$(dynamic, dynamic);
  let _FusedConverter$ = dart.generic(function(S, M, T) {
    class _FusedConverter extends Converter$(S, T) {
      _FusedConverter(_first, _second) {
        this._first = _first;
        this._second = _second;
        super.Converter();
      }
      convert(input) {
        return dart.as(this._second.convert(this._first.convert(input)), T);
      }
      startChunkedConversion(sink) {
        return this._first.startChunkedConversion(this._second.startChunkedConversion(sink));
      }
    }
    return _FusedConverter;
  });
  let _FusedConverter = _FusedConverter$(dynamic, dynamic, dynamic);
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
    set _nameToEncoding() {}
  });
  let HTML_ESCAPE = new HtmlEscape();
  class HtmlEscapeMode extends dart.Object {
    HtmlEscapeMode$_(_name, escapeLtGt, escapeQuot, escapeApos, escapeSlash) {
      this._name = _name;
      this.escapeLtGt = escapeLtGt;
      this.escapeQuot = escapeQuot;
      this.escapeApos = escapeApos;
      this.escapeSlash = escapeSlash;
    }
    toString() {
      return this._name;
    }
  }
  dart.defineNamedConstructor(HtmlEscapeMode, '_');
  HtmlEscapeMode.UNKNOWN = new HtmlEscapeMode._('unknown', true, true, true, true);
  HtmlEscapeMode.ATTRIBUTE = new HtmlEscapeMode._('attribute', false, true, false, false);
  HtmlEscapeMode.ELEMENT = new HtmlEscapeMode._('element', true, false, false, true);
  class HtmlEscape extends Converter$(core.String, core.String) {
    HtmlEscape(mode) {
      if (mode === void 0)
        mode = HtmlEscapeMode.UNKNOWN;
      this.mode = mode;
      super.Converter();
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
      return dart.as(result !== null ? result.toString() : null, core.String);
    }
    startChunkedConversion(sink) {
      if (!dart.is(sink, StringConversionSink)) {
        sink = new StringConversionSink.from(sink);
      }
      return new _HtmlEscapeSink(this, dart.as(sink, StringConversionSink));
    }
  }
  class _HtmlEscapeSink extends StringConversionSinkBase {
    _HtmlEscapeSink(_escape, _sink) {
      this._escape = _escape;
      this._sink = _sink;
      super.StringConversionSinkBase();
    }
    addSlice(chunk, start, end, isLast) {
      let val = this._escape._convert(chunk, start, end);
      if (val === null) {
        this._sink.addSlice(chunk, start, end, isLast);
      } else {
        this._sink.add(val);
        if (isLast)
          this._sink.close();
      }
    }
    close() {
      return this._sink.close();
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
  class JsonCodec extends Codec$(core.Object, core.String) {
    JsonCodec(opt$) {
      let reviver = opt$.reviver === void 0 ? null : opt$.reviver;
      let toEncodable = opt$.toEncodable === void 0 ? null : opt$.toEncodable;
      this._reviver = reviver;
      this._toEncodable = toEncodable;
      super.Codec();
    }
    JsonCodec$withReviver(reviver) {
      this.JsonCodec({reviver: reviver});
    }
    decode(source, opt$) {
      let reviver = opt$.reviver === void 0 ? null : opt$.reviver;
      if (reviver === null)
        reviver = this._reviver;
      if (reviver === null)
        return this.decoder.convert(source);
      return new JsonDecoder(reviver).convert(source);
    }
    encode(value, opt$) {
      let toEncodable = opt$.toEncodable === void 0 ? null : opt$.toEncodable;
      if (toEncodable === null)
        toEncodable = this._toEncodable;
      if (toEncodable === null)
        return this.encoder.convert(value);
      return new JsonEncoder(dart.as(toEncodable, dart.throw_("Unimplemented type (Object) → Object"))).convert(value);
    }
    get encoder() {
      if (this._toEncodable === null)
        return new JsonEncoder();
      return new JsonEncoder(dart.as(this._toEncodable, dart.throw_("Unimplemented type (Object) → Object")));
    }
    get decoder() {
      if (this._reviver === null)
        return new JsonDecoder();
      return new JsonDecoder(this._reviver);
    }
  }
  dart.defineNamedConstructor(JsonCodec, 'withReviver');
  class JsonEncoder extends Converter$(core.Object, core.String) {
    JsonEncoder(toEncodable) {
      if (toEncodable === void 0)
        toEncodable = null;
      this.indent = null;
      this._toEncodable = toEncodable;
      super.Converter();
    }
    JsonEncoder$withIndent(indent, toEncodable) {
      if (toEncodable === void 0)
        toEncodable = null;
      this.indent = indent;
      this._toEncodable = toEncodable;
      super.Converter();
    }
    convert(object) {
      return _JsonStringStringifier.stringify(object, dart.as(this._toEncodable, dart.throw_("Unimplemented type (dynamic) → dynamic")), this.indent);
    }
    startChunkedConversion(sink) {
      if (!dart.is(sink, StringConversionSink)) {
        sink = new StringConversionSink.from(sink);
      } else if (dart.is(sink, _Utf8EncoderSink)) {
        return new _JsonUtf8EncoderSink(sink._sink, this._toEncodable, JsonUtf8Encoder._utf8Encode(this.indent), JsonUtf8Encoder.DEFAULT_BUFFER_SIZE);
      }
      return new _JsonEncoderSink(dart.as(sink, StringConversionSink), this._toEncodable, this.indent);
    }
    bind(stream) {
      return dart.as(super.bind(stream), async.Stream$(core.String));
    }
    fuse(other) {
      if (dart.is(other, Utf8Encoder)) {
        return new JsonUtf8Encoder(this.indent, dart.as(this._toEncodable, dart.throw_("Unimplemented type (Object) → dynamic")));
      }
      return super.fuse(other);
    }
  }
  dart.defineNamedConstructor(JsonEncoder, 'withIndent');
  class JsonUtf8Encoder extends Converter$(core.Object, core.List$(core.int)) {
    JsonUtf8Encoder(indent, toEncodable, bufferSize) {
      if (indent === void 0)
        indent = null;
      if (toEncodable === void 0)
        toEncodable = null;
      if (bufferSize === void 0)
        bufferSize = DEFAULT_BUFFER_SIZE;
      this._indent = _utf8Encode(indent);
      this._toEncodable = toEncodable;
      this._bufferSize = bufferSize;
      super.Converter();
    }
    static _utf8Encode(string) {
      if (string === null)
        return null;
      if (string.isEmpty)
        return new typed_data.Uint8List(0);
      checkAscii: {
        for (let i = 0; i < string.length; i++) {
          if (string.codeUnitAt(i) >= 128)
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
        if (dart.notNull(start > 0) || dart.notNull(end < chunk.length)) {
          let length = end - start;
          chunk = new typed_data.Uint8List.view(chunk.buffer, chunk.offsetInBytes + start, length);
        }
        bytes.add(chunk);
      }
      _JsonUtf8Stringifier.stringify(object, this._indent, dart.as(this._toEncodable, dart.throw_("Unimplemented type (Object) → dynamic")), this._bufferSize, addChunk);
      if (bytes.length === 1)
        return bytes.get(0);
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
        byteSink = sink;
      } else {
        byteSink = new ByteConversionSink.from(sink);
      }
      return new _JsonUtf8EncoderSink(byteSink, this._toEncodable, this._indent, this._bufferSize);
    }
    bind(stream) {
      return dart.as(super.bind(stream), async.Stream$(core.List$(core.int)));
    }
    fuse(other) {
      return super.fuse(other);
    }
  }
  JsonUtf8Encoder.DEFAULT_BUFFER_SIZE = 256;
  class _JsonEncoderSink extends ChunkedConversionSink$(core.Object) {
    _JsonEncoderSink(_sink, _toEncodable, _indent) {
      this._sink = _sink;
      this._toEncodable = _toEncodable;
      this._indent = _indent;
      this._isDone = false;
      super.ChunkedConversionSink();
    }
    add(o) {
      if (this._isDone) {
        throw new core.StateError("Only one call to add allowed");
      }
      this._isDone = true;
      let stringSink = this._sink.asStringSink();
      _JsonStringStringifier.printOn(o, stringSink, dart.as(this._toEncodable, dart.throw_("Unimplemented type (dynamic) → dynamic")), this._indent);
      stringSink.close();
    }
    close() {}
  }
  class _JsonUtf8EncoderSink extends ChunkedConversionSink$(core.Object) {
    _JsonUtf8EncoderSink(_sink, _toEncodable, _indent, _bufferSize) {
      this._sink = _sink;
      this._toEncodable = _toEncodable;
      this._indent = _indent;
      this._bufferSize = _bufferSize;
      this._isDone = false;
      super.ChunkedConversionSink();
    }
    _addChunk(chunk, start, end) {
      this._sink.addSlice(chunk, start, end, false);
    }
    add(object) {
      if (this._isDone) {
        throw new core.StateError("Only one call to add allowed");
      }
      this._isDone = true;
      _JsonUtf8Stringifier.stringify(object, this._indent, dart.as(this._toEncodable, dart.throw_("Unimplemented type (Object) → dynamic")), this._bufferSize, this._addChunk);
      this._sink.close();
    }
    close() {
      if (!dart.notNull(this._isDone)) {
        this._isDone = true;
        this._sink.close();
      }
    }
  }
  class JsonDecoder extends Converter$(core.String, core.Object) {
    JsonDecoder(reviver) {
      if (reviver === void 0)
        reviver = null;
      this._reviver = reviver;
      super.Converter();
    }
    convert(input) {
      return _parseJson(input, this._reviver);
    }
    startChunkedConversion(sink) {
      return new _JsonDecoderSink(this._reviver, sink);
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
  class _JsonStringifier extends dart.Object {
    _JsonStringifier(_toEncodable) {
      this._seen = new core.List();
      this._toEncodable = dart.as(_toEncodable !== null ? _toEncodable : _defaultToEncodable, core.Function);
    }
    static hexDigit(x) {
      return x < 10 ? 48 + x : 87 + x;
    }
    writeStringContent(s) {
      let offset = 0;
      let length = s.length;
      for (let i = 0; i < length; i++) {
        let charCode = s.codeUnitAt(i);
        if (charCode > BACKSLASH)
          continue;
        if (charCode < 32) {
          if (i > offset)
            this.writeStringSlice(s, offset, i);
          offset = i + 1;
          this.writeCharCode(BACKSLASH);
          switch (charCode) {
            case BACKSPACE:
              this.writeCharCode(CHAR_b);
              break;
            case TAB:
              this.writeCharCode(CHAR_t);
              break;
            case NEWLINE:
              this.writeCharCode(CHAR_n);
              break;
            case FORM_FEED:
              this.writeCharCode(CHAR_f);
              break;
            case CARRIAGE_RETURN:
              this.writeCharCode(CHAR_r);
              break;
            default:
              this.writeCharCode(CHAR_u);
              this.writeCharCode(CHAR_0);
              this.writeCharCode(CHAR_0);
              this.writeCharCode(hexDigit(charCode >> 4 & 15));
              this.writeCharCode(hexDigit(charCode & 15));
              break;
          }
        } else if (dart.notNull(charCode === QUOTE) || dart.notNull(charCode === BACKSLASH)) {
          if (i > offset)
            this.writeStringSlice(s, offset, i);
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
      dart.assert(!dart.notNull(this._seen.isEmpty));
      dart.assert(core.identical(this._seen.last, object));
      this._seen.removeLast();
    }
    writeObject(object) {
      if (this.writeJsonValue(object))
        return;
      this._checkCycle(object);
      try {
        let customJson = dart.dinvokef(this._toEncodable, object);
        if (!dart.notNull(this.writeJsonValue(customJson))) {
          throw new JsonUnsupportedObjectError(object);
        }
        this._removeSeen(object);
      } catch (e) {
        throw new JsonUnsupportedObjectError(object, {cause: e});
      }

    }
    writeJsonValue(object) {
      if (dart.is(object, core.num)) {
        if (dart.throw_("Unimplemented PrefixExpression: !object.isFinite"))
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
        this._checkCycle(object);
        this.writeList(dart.as(object, core.List));
        this._removeSeen(object);
        return true;
      } else if (dart.is(object, core.Map)) {
        this._checkCycle(object);
        this.writeMap(dart.as(object, core.Map$(core.String, core.Object)));
        this._removeSeen(object);
        return true;
      } else {
        return false;
      }
    }
    writeList(list) {
      this.writeString('[');
      if (list.length > 0) {
        this.writeObject(list.get(0));
        for (let i = 1; i < list.length; i++) {
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
  class _JsonPrettyPrintMixin extends dart.Object {
    _JsonPrettyPrintMixin() {
      this._indentLevel = 0;
    }
    writeList(list) {
      if (list.isEmpty) {
        this.writeString('[]');
      } else {
        this.writeString('[\n');
        this._indentLevel++;
        this.writeIndentation(this._indentLevel);
        this.writeObject(list.get(0));
        for (let i = 1; i < list.length; i++) {
          this.writeString(',\n');
          this.writeIndentation(this._indentLevel);
          this.writeObject(list.get(i));
        }
        this.writeString('\n');
        this._indentLevel--;
        this.writeIndentation(this._indentLevel);
        this.writeString(']');
      }
    }
    writeMap(map) {
      if (map.isEmpty) {
        this.writeString('{}');
      } else {
        this.writeString('{\n');
        this._indentLevel++;
        let first = true;
        map.forEach(dart.as(((key, value) => {
          if (!dart.notNull(first)) {
            this.writeString(",\n");
          }
          this.writeIndentation(this._indentLevel);
          this.writeString('"');
          this.writeStringContent(key);
          this.writeString('": ');
          this.writeObject(value);
          first = false;
        }).bind(this), dart.throw_("Unimplemented type (dynamic, dynamic) → void")));
        this.writeString('\n');
        this._indentLevel--;
        this.writeIndentation(this._indentLevel);
        this.writeString('}');
      }
    }
  }
  class _JsonStringStringifier extends _JsonStringifier {
    _JsonStringStringifier(_sink, _toEncodable) {
      this._sink = _sink;
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
    _JsonStringStringifierPretty(sink, toEncodable, _indent) {
      this._indent = _indent;
      super._JsonStringStringifier(sink, toEncodable);
    }
    writeIndentation(count) {
      for (let i = 0; i < count; i++)
        this.writeString(this._indent);
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
          if (dart.notNull((char & 64512) === 55296) && dart.notNull(i + 1 < end)) {
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
        this.writeByte(192 | charCode >> 6);
        this.writeByte(128 | charCode & 63);
        return;
      }
      if (charCode <= 65535) {
        this.writeByte(224 | charCode >> 12);
        this.writeByte(128 | charCode >> 6 & 63);
        this.writeByte(128 | charCode & 63);
        return;
      }
      this.writeFourByteCharCode(charCode);
    }
    writeFourByteCharCode(charCode) {
      dart.assert(charCode <= 1114111);
      this.writeByte(240 | charCode >> 18);
      this.writeByte(128 | charCode >> 12 & 63);
      this.writeByte(128 | charCode >> 6 & 63);
      this.writeByte(128 | charCode & 63);
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
    _JsonUtf8StringifierPretty(toEncodableFunction, indent, bufferSize, addChunk) {
      this.indent = indent;
      super._JsonUtf8Stringifier(toEncodableFunction, dart.as(bufferSize, core.int), dart.as(addChunk, core.Function));
    }
    writeIndentation(count) {
      let indent = this.indent;
      let indentLength = indent.length;
      if (indentLength === 1) {
        let char = indent.get(0);
        while (count > 0) {
          this.writeByte(char);
          count = 1;
        }
        return;
      }
      while (count > 0) {
        count--;
        let end = this.index + indentLength;
        if (end <= this.buffer.length) {
          this.buffer.setRange(this.index, end, indent);
          this.index = end;
        } else {
          for (let i = 0; i < indentLength; i++) {
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
      this._allowInvalid = allowInvalid;
      super.Encoding();
    }
    get name() {
      return "iso-8859-1";
    }
    decode(bytes, opt$) {
      let allowInvalid = opt$.allowInvalid === void 0 ? null : opt$.allowInvalid;
      if (allowInvalid === null)
        allowInvalid = this._allowInvalid;
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
      return this._allowInvalid ? new Latin1Decoder({allowInvalid: true}) : new Latin1Decoder({allowInvalid: false});
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
      if (!dart.notNull(this._allowInvalid))
        return new _Latin1DecoderSink(stringSink);
      return new _Latin1AllowInvalidDecoderSink(stringSink);
    }
  }
  class _Latin1DecoderSink extends ByteConversionSinkBase {
    _Latin1DecoderSink(_sink) {
      this._sink = _sink;
      super.ByteConversionSinkBase();
    }
    close() {
      this._sink.close();
    }
    add(source) {
      this.addSlice(source, 0, source.length, false);
    }
    _addSliceToSink(source, start, end, isLast) {
      this._sink.add(new core.String.fromCharCodes(source, start, end));
      if (isLast)
        this.close();
    }
    addSlice(source, start, end, isLast) {
      core.RangeError.checkValidRange(start, end, source.length);
      for (let i = start; i < end; i++) {
        let char = source.get(i);
        if (dart.notNull(char > _LATIN1_MASK) || dart.notNull(char < 0)) {
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
    _Latin1AllowInvalidDecoderSink(sink) {
      super._Latin1DecoderSink(sink);
    }
    addSlice(source, start, end, isLast) {
      core.RangeError.checkValidRange(start, end, source.length);
      for (let i = start; i < end; i++) {
        let char = source.get(i);
        if (dart.notNull(char > _LATIN1_MASK) || dart.notNull(char < 0)) {
          if (i > start)
            this._addSliceToSink(source, start, i, false);
          this._addSliceToSink(dart.as(/* Unimplemented const */new List.from([65533]), core.List$(core.int)), 0, 1, false);
          start = i + 1;
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
  class _LineSplitterSink extends StringConversionSinkBase {
    _LineSplitterSink(_sink) {
      this._sink = _sink;
      this._carry = null;
      super.StringConversionSinkBase();
    }
    addSlice(chunk, start, end, isLast) {
      if (this._carry !== null) {
        chunk = core.String['+'](this._carry, chunk.substring(start, end));
        start = 0;
        end = chunk.length;
        this._carry = null;
      }
      this._carry = _addSlice(chunk, start, end, isLast, this._sink.add);
      if (isLast)
        this._sink.close();
    }
    close() {
      this.addSlice('', 0, 0, true);
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
          } else if (!dart.notNull(isLast)) {
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
  class _ClosableStringSink extends dart.Object {
    _ClosableStringSink(_sink, _callback) {
      this._sink = _sink;
      this._callback = _callback;
    }
    close() {
      return this._callback();
    }
    writeCharCode(charCode) {
      return this._sink.writeCharCode(charCode);
    }
    write(o) {
      return this._sink.write(o);
    }
    writeln(o) {
      if (o === void 0)
        o = "";
      return this._sink.writeln(o);
    }
    writeAll(objects, separator) {
      if (separator === void 0)
        separator = "";
      return this._sink.writeAll(objects, separator);
    }
  }
  class _StringConversionSinkAsStringSinkAdapter extends dart.Object {
    _StringConversionSinkAsStringSinkAdapter(_chunkedSink) {
      this._chunkedSink = _chunkedSink;
      this._buffer = new core.StringBuffer();
    }
    close() {
      if (this._buffer.isNotEmpty)
        this._flush();
      this._chunkedSink.close();
    }
    writeCharCode(charCode) {
      this._buffer.writeCharCode(charCode);
      if (this._buffer.length['>'](_MIN_STRING_SIZE))
        this._flush();
    }
    write(o) {
      if (this._buffer.isNotEmpty)
        this._flush();
      let str = o.toString();
      this._chunkedSink.add(o.toString());
    }
    writeln(o) {
      if (o === void 0)
        o = "";
      this._buffer.writeln(o);
      if (this._buffer.length['>'](_MIN_STRING_SIZE))
        this._flush();
    }
    writeAll(objects, separator) {
      if (separator === void 0)
        separator = "";
      if (this._buffer.isNotEmpty)
        this._flush();
      let iterator = objects.iterator;
      if (!dart.notNull(iterator.moveNext()))
        return;
      if (separator.isEmpty) {
        do {
          this._chunkedSink.add(dart.as(dart.dinvoke(iterator.current, 'toString'), core.String));
        } while (iterator.moveNext());
      } else {
        this._chunkedSink.add(dart.as(dart.dinvoke(iterator.current, 'toString'), core.String));
        while (iterator.moveNext()) {
          this.write(separator);
          this._chunkedSink.add(dart.as(dart.dinvoke(iterator.current, 'toString'), core.String));
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
  class StringConversionSinkMixin extends dart.Object {
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
  class _StringSinkConversionSink extends StringConversionSinkBase {
    _StringSinkConversionSink(_stringSink) {
      this._stringSink = _stringSink;
      super.StringConversionSinkBase();
    }
    close() {}
    addSlice(str, start, end, isLast) {
      if (dart.notNull(start !== 0) || dart.notNull(end !== str.length)) {
        for (let i = start; i < end; i++) {
          this._stringSink.writeCharCode(str.codeUnitAt(i));
        }
      } else {
        this._stringSink.write(str);
      }
      if (isLast)
        this.close();
    }
    add(str) {
      return this._stringSink.write(str);
    }
    asUtf8Sink(allowMalformed) {
      return new _Utf8StringSinkAdapter(this, this._stringSink, allowMalformed);
    }
    asStringSink() {
      return new ClosableStringSink.fromStringSink(this._stringSink, this.close);
    }
  }
  class _StringCallbackSink extends _StringSinkConversionSink {
    _StringCallbackSink(_callback) {
      this._callback = _callback;
      super._StringSinkConversionSink(new core.StringBuffer());
    }
    close() {
      let buffer = dart.as(this._stringSink, core.StringBuffer);
      let accumulated = buffer.toString();
      buffer.clear();
      this._callback(accumulated);
    }
    asUtf8Sink(allowMalformed) {
      return new _Utf8StringSinkAdapter(this, this._stringSink, allowMalformed);
    }
  }
  class _StringAdapterSink extends StringConversionSinkBase {
    _StringAdapterSink(_sink) {
      this._sink = _sink;
      super.StringConversionSinkBase();
    }
    add(str) {
      return this._sink.add(str);
    }
    addSlice(str, start, end, isLast) {
      if (dart.notNull(start === 0) && dart.notNull(end === str.length)) {
        this.add(str);
      } else {
        this.add(str.substring(start, end));
      }
      if (isLast)
        this.close();
    }
    close() {
      return this._sink.close();
    }
  }
  class _Utf8StringSinkAdapter extends ByteConversionSink {
    _Utf8StringSinkAdapter(_sink, stringSink, allowMalformed) {
      this._sink = _sink;
      this._decoder = new _Utf8Decoder(stringSink, allowMalformed);
      super.ByteConversionSink();
    }
    close() {
      this._decoder.close();
      if (this._sink !== null)
        this._sink.close();
    }
    add(chunk) {
      this.addSlice(chunk, 0, chunk.length, false);
    }
    addSlice(codeUnits, startIndex, endIndex, isLast) {
      this._decoder.convert(codeUnits, startIndex, endIndex);
      if (isLast)
        this.close();
    }
  }
  class _Utf8ConversionSink extends ByteConversionSink {
    _Utf8ConversionSink(sink, allowMalformed) {
      this._Utf8ConversionSink$_(sink, new core.StringBuffer(), allowMalformed);
    }
    _Utf8ConversionSink$_(_chunkedSink, stringBuffer, allowMalformed) {
      this._chunkedSink = _chunkedSink;
      this._decoder = new _Utf8Decoder(stringBuffer, allowMalformed);
      this._buffer = stringBuffer;
      super.ByteConversionSink();
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
      if (isLast)
        this.close();
    }
  }
  dart.defineNamedConstructor(_Utf8ConversionSink, '_');
  let UNICODE_REPLACEMENT_CHARACTER_RUNE = 65533;
  let UNICODE_BOM_CHARACTER_RUNE = 65279;
  let UTF8 = new Utf8Codec();
  class Utf8Codec extends Encoding {
    Utf8Codec(opt$) {
      let allowMalformed = opt$.allowMalformed === void 0 ? false : opt$.allowMalformed;
      this._allowMalformed = allowMalformed;
      super.Encoding();
    }
    get name() {
      return "utf-8";
    }
    decode(codeUnits, opt$) {
      let allowMalformed = opt$.allowMalformed === void 0 ? null : opt$.allowMalformed;
      if (allowMalformed === null)
        allowMalformed = this._allowMalformed;
      return new Utf8Decoder({allowMalformed: allowMalformed}).convert(codeUnits);
    }
    get encoder() {
      return new Utf8Encoder();
    }
    get decoder() {
      return new Utf8Decoder({allowMalformed: this._allowMalformed});
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
      let length = end - start;
      if (length === 0)
        return new typed_data.Uint8List(0);
      let encoder = new _Utf8Encoder.withBufferSize(length * 3);
      let endPosition = encoder._fillBuffer(string, start, end);
      dart.assert(endPosition >= end - 1);
      if (endPosition !== end) {
        let lastCodeUnit = string.codeUnitAt(end - 1);
        dart.assert(_isLeadSurrogate(lastCodeUnit));
        let wasCombined = encoder._writeSurrogate(lastCodeUnit, 0);
        dart.assert(!dart.notNull(wasCombined));
      }
      return encoder._buffer.sublist(0, encoder._bufferIndex);
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
  class _Utf8Encoder extends dart.Object {
    _Utf8Encoder() {
      this._Utf8Encoder$withBufferSize(dart.as(_DEFAULT_BYTE_BUFFER_SIZE, core.int));
    }
    _Utf8Encoder$withBufferSize(bufferSize) {
      this._buffer = _createBuffer(bufferSize);
      this._carry = 0;
      this._bufferIndex = 0;
    }
    static _createBuffer(size) {
      return new typed_data.Uint8List(size);
    }
    _writeSurrogate(leadingSurrogate, nextCodeUnit) {
      if (_isTailSurrogate(nextCodeUnit)) {
        let rune = _combineSurrogatePair(leadingSurrogate, nextCodeUnit);
        dart.assert(rune > _THREE_BYTE_LIMIT);
        dart.assert(rune <= _FOUR_BYTE_LIMIT);
        this._buffer.set(this._bufferIndex++, 240 | rune >> 18);
        this._buffer.set(this._bufferIndex++, 128 | rune >> 12 & 63);
        this._buffer.set(this._bufferIndex++, 128 | rune >> 6 & 63);
        this._buffer.set(this._bufferIndex++, 128 | rune & 63);
        return true;
      } else {
        this._buffer.set(this._bufferIndex++, 224 | leadingSurrogate >> 12);
        this._buffer.set(this._bufferIndex++, 128 | leadingSurrogate >> 6 & 63);
        this._buffer.set(this._bufferIndex++, 128 | leadingSurrogate & 63);
        return false;
      }
    }
    _fillBuffer(str, start, end) {
      if (dart.notNull(start !== end) && dart.notNull(_isLeadSurrogate(str.codeUnitAt(end - 1)))) {
        end--;
      }
      let stringIndex = null;
      for (stringIndex = start; stringIndex < end; stringIndex++) {
        let codeUnit = str.codeUnitAt(stringIndex);
        if (codeUnit <= _ONE_BYTE_LIMIT) {
          if (this._bufferIndex >= this._buffer.length)
            break;
          this._buffer.set(this._bufferIndex++, codeUnit);
        } else if (_isLeadSurrogate(codeUnit)) {
          if (this._bufferIndex + 3 >= this._buffer.length)
            break;
          let nextCodeUnit = str.codeUnitAt(stringIndex + 1);
          let wasCombined = this._writeSurrogate(codeUnit, nextCodeUnit);
          if (wasCombined)
            stringIndex++;
        } else {
          let rune = codeUnit;
          if (rune <= _TWO_BYTE_LIMIT) {
            if (this._bufferIndex + 1 >= this._buffer.length)
              break;
            this._buffer.set(this._bufferIndex++, 192 | rune >> 6);
            this._buffer.set(this._bufferIndex++, 128 | rune & 63);
          } else {
            dart.assert(rune <= _THREE_BYTE_LIMIT);
            if (this._bufferIndex + 2 >= this._buffer.length)
              break;
            this._buffer.set(this._bufferIndex++, 224 | rune >> 12);
            this._buffer.set(this._bufferIndex++, 128 | rune >> 6 & 63);
            this._buffer.set(this._bufferIndex++, 128 | rune & 63);
          }
        }
      }
      return stringIndex;
    }
  }
  dart.defineNamedConstructor(_Utf8Encoder, 'withBufferSize');
  _Utf8Encoder._DEFAULT_BYTE_BUFFER_SIZE = 1024;
  class _Utf8EncoderSink extends dart.mixin(_Utf8Encoder, StringConversionSinkMixin) {
    _Utf8EncoderSink(_sink) {
      this._sink = _sink;
      super._Utf8Encoder();
    }
    close() {
      if (this._carry !== 0) {
        this.addSlice("", 0, 0, true);
        return;
      }
      this._sink.close();
    }
    addSlice(str, start, end, isLast) {
      this._bufferIndex = 0;
      if (dart.notNull(start === end) && dart.notNull(!dart.notNull(isLast))) {
        return;
      }
      if (this._carry !== 0) {
        let nextCodeUnit = 0;
        if (start !== end) {
          nextCodeUnit = str.codeUnitAt(start);
        } else {
          dart.assert(isLast);
        }
        let wasCombined = this._writeSurrogate(this._carry, nextCodeUnit);
        dart.assert(dart.notNull(!dart.notNull(wasCombined)) || dart.notNull(start !== end));
        if (wasCombined)
          start++;
        this._carry = 0;
      }
      do {
        start = this._fillBuffer(str, start, end);
        let isLastSlice = dart.notNull(isLast) && dart.notNull(start === end);
        if (dart.notNull(start === end - 1) && dart.notNull(_isLeadSurrogate(str.codeUnitAt(start)))) {
          if (dart.notNull(isLast) && dart.notNull(this._bufferIndex < this._buffer.length - 3)) {
            let hasBeenCombined = this._writeSurrogate(str.codeUnitAt(start), 0);
            dart.assert(!dart.notNull(hasBeenCombined));
          } else {
            this._carry = str.codeUnitAt(start);
          }
          start++;
        }
        this._sink.addSlice(this._buffer, 0, this._bufferIndex, isLastSlice);
        this._bufferIndex = 0;
      } while (start < end);
      if (isLast)
        this.close();
    }
  }
  class Utf8Decoder extends Converter$(core.List$(core.int), core.String) {
    Utf8Decoder(opt$) {
      let allowMalformed = opt$.allowMalformed === void 0 ? false : opt$.allowMalformed;
      this._allowMalformed = allowMalformed;
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
      let decoder = new _Utf8Decoder(buffer, this._allowMalformed);
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
      return stringSink.asUtf8Sink(this._allowMalformed);
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
    return (codeUnit & _SURROGATE_MASK) === _LEAD_SURROGATE_MIN;
  }
  // Function _isLeadSurrogate: (int) → bool
  function _isLeadSurrogate(codeUnit) {
    return (codeUnit & _SURROGATE_TAG_MASK) === _LEAD_SURROGATE_MIN;
  }
  // Function _isTailSurrogate: (int) → bool
  function _isTailSurrogate(codeUnit) {
    return (codeUnit & _SURROGATE_TAG_MASK) === _TAIL_SURROGATE_MIN;
  }
  // Function _combineSurrogatePair: (int, int) → int
  function _combineSurrogatePair(lead, tail) {
    return 65536 + ((lead & _SURROGATE_VALUE_MASK) << 10) | tail & _SURROGATE_VALUE_MASK;
  }
  class _Utf8Decoder extends dart.Object {
    _Utf8Decoder(_stringSink, _allowMalformed) {
      this._stringSink = _stringSink;
      this._allowMalformed = _allowMalformed;
      this._isFirstCharacter = true;
      this._value = 0;
      this._expectedUnits = 0;
      this._extraUnits = 0;
    }
    get hasPartialInput() {
      return this._expectedUnits > 0;
    }
    close() {
      this.flush();
    }
    flush() {
      if (this.hasPartialInput) {
        if (!dart.notNull(this._allowMalformed)) {
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
          if (!dart.equals(dart.dbinary(unit, '&', mask), unit))
            return i - from;
        }
        return to - from;
      }
      // Function addSingleBytes: (int, int) → void
      function addSingleBytes(from, to) {
        dart.assert(dart.notNull(from >= startIndex) && dart.notNull(from <= endIndex));
        dart.assert(dart.notNull(to >= startIndex) && dart.notNull(to <= endIndex));
        this._stringSink.write(new core.String.fromCharCodes(codeUnits, from, to));
      }
      let i = startIndex;
      loop:
        while (true) {
          multibyte:
            if (expectedUnits > 0) {
              do {
                if (i === endIndex) {
                  break loop;
                }
                let unit = codeUnits.get(i);
                if ((unit & 192) !== 128) {
                  expectedUnits = 0;
                  if (!dart.notNull(this._allowMalformed)) {
                    throw new core.FormatException(`Bad UTF-8 encoding 0x${unit.toRadixString(16)}`);
                  }
                  this._isFirstCharacter = false;
                  this._stringSink.writeCharCode(UNICODE_REPLACEMENT_CHARACTER_RUNE);
                  break multibyte;
                } else {
                  value = value << 6 | unit & 63;
                  expectedUnits--;
                  i++;
                }
              } while (expectedUnits > 0);
              if (value <= _LIMITS.get(extraUnits - 1)) {
                if (!dart.notNull(this._allowMalformed)) {
                  throw new core.FormatException(`Overlong encoding of 0x${value.toRadixString(16)}`);
                }
                expectedUnits = extraUnits = 0;
                value = UNICODE_REPLACEMENT_CHARACTER_RUNE;
              }
              if (value > _FOUR_BYTE_LIMIT) {
                if (!dart.notNull(this._allowMalformed)) {
                  throw new core.FormatException("Character outside valid Unicode range: " + `0x${value.toRadixString(16)}`);
                }
                value = UNICODE_REPLACEMENT_CHARACTER_RUNE;
              }
              if (dart.notNull(!dart.notNull(this._isFirstCharacter)) || dart.notNull(value !== UNICODE_BOM_CHARACTER_RUNE)) {
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
              if (i === endIndex)
                break;
            }
            let unit = codeUnits.get(i++);
            if (unit < 0) {
              if (!dart.notNull(this._allowMalformed)) {
                throw new core.FormatException(`Negative UTF-8 code unit: -0x${(-unit).toRadixString(16)}`);
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
              if (dart.notNull((unit & 248) === 240) && dart.notNull(unit < 245)) {
                value = unit & 7;
                expectedUnits = extraUnits = 3;
                continue loop;
              }
              if (!dart.notNull(this._allowMalformed)) {
                throw new core.FormatException(`Bad UTF-8 encoding 0x${unit.toRadixString(16)}`);
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
