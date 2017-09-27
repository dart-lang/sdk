// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.io;

/**
 * Exposes ZLib options for input parameters.
 *
 * See http://www.zlib.net/manual.html for more documentation.
 */
abstract class ZLibOption {
  /// Minimal value for [ZLibCodec.windowBits], [ZLibEncoder.windowBits]
  /// and [ZLibDecoder.windowBits].
  static const int MIN_WINDOW_BITS = 8;

  /// Maximal value for [ZLibCodec.windowBits], [ZLibEncoder.windowBits]
  /// and [ZLibDecoder.windowBits].
  static const int MAX_WINDOW_BITS = 15;

  /// Default value for [ZLibCodec.windowBits], [ZLibEncoder.windowBits]
  /// and [ZLibDecoder.windowBits].
  static const int DEFAULT_WINDOW_BITS = 15;

  /// Minimal value for [ZLibCodec.level] and [ZLibEncoder.level].
  static const int MIN_LEVEL = -1;

  /// Maximal value for [ZLibCodec.level] and [ZLibEncoder.level]
  static const int MAX_LEVEL = 9;

  /// Default value for [ZLibCodec.level] and [ZLibEncoder.level].
  static const int DEFAULT_LEVEL = 6;

  /// Minimal value for [ZLibCodec.memLevel] and [ZLibEncoder.memLevel].
  static const int MIN_MEM_LEVEL = 1;

  /// Maximal value for [ZLibCodec.memLevel] and [ZLibEncoder.memLevel].
  static const int MAX_MEM_LEVEL = 9;

  /// Default value for [ZLibCodec.memLevel] and [ZLibEncoder.memLevel].
  static const int DEFAULT_MEM_LEVEL = 8;

  /// Recommended strategy for data produced by a filter (or predictor)
  static const int STRATEGY_FILTERED = 1;

  /// Use this strategy to force Huffman encoding only (no string match)
  static const int STRATEGY_HUFFMAN_ONLY = 2;

  /// Use this strategy to limit match distances to one (run-length encoding)
  static const int STRATEGY_RLE = 3;

  /// This strategy prevents the use of dynamic Huffman codes, allowing for a
  /// simpler decoder
  static const int STRATEGY_FIXED = 4;

  /// Recommended strategy for normal data
  static const int STRATEGY_DEFAULT = 0;
}

/**
 * An instance of the default implementation of the [ZLibCodec].
 */
const ZLibCodec ZLIB = const ZLibCodec._default();

/**
 * The [ZLibCodec] encodes raw bytes to ZLib compressed bytes and decodes ZLib
 * compressed bytes to raw bytes.
 */
class ZLibCodec extends Codec<List<int>, List<int>> {
  /**
   * When true, `GZip` frames will be added to the compressed data.
   */
  final bool gzip;

  /**
   * The compression-[level] can be set in the range of `-1..9`, with `6` being
   * the default compression level. Levels above `6` will have higher
   * compression rates at the cost of more CPU and memory usage. Levels below
   * `6` will use less CPU and memory at the cost of lower compression rates.
   */
  final int level;

  /**
   * Specifies how much memory should be allocated for the internal compression
   * state. `1` uses minimum memory but is slow and reduces compression ratio;
   * `9` uses maximum memory for optimal speed. The default value is `8`.
   *
   * The memory requirements for deflate are (in bytes):
   *
   *     (1 << (windowBits + 2)) +  (1 << (memLevel + 9))
   * that is: 128K for windowBits = 15 + 128K for memLevel = 8 (default values)
   */
  final int memLevel;

  /**
   * Tunes the compression algorithm. Use the value STRATEGY_DEFAULT for normal
   * data, STRATEGY_FILTERED for data produced by a filter (or predictor),
   * STRATEGY_HUFFMAN_ONLY to force Huffman encoding only (no string match), or
   * STRATEGY_RLE to limit match distances to one (run-length encoding).
   */
  final int strategy;

  /**
   * Base two logarithm of the window size (the size of the history buffer). It
   * should be in the range 8..15. Larger values result in better compression at
   * the expense of memory usage. The default value is 15
   */
  final int windowBits;

  /**
   * When true, deflate generates raw data with no zlib header or trailer, and
   * will not compute an adler32 check value
   */
  final bool raw;

  /**
   * Initial compression dictionary.
   *
   * It should consist of strings (byte sequences) that are likely to be
   * encountered later in the data to be compressed, with the most commonly used
   * strings preferably put towards the end of the dictionary. Using a
   * dictionary is most useful when the data to be compressed is short and can
   * be predicted with good accuracy; the data can then be compressed better
   * than with the default empty dictionary.
   */
  final List<int> dictionary;

  ZLibCodec(
      {this.level: ZLibOption.DEFAULT_LEVEL,
      this.windowBits: ZLibOption.DEFAULT_WINDOW_BITS,
      this.memLevel: ZLibOption.DEFAULT_MEM_LEVEL,
      this.strategy: ZLibOption.STRATEGY_DEFAULT,
      this.dictionary: null,
      this.raw: false,
      this.gzip: false}) {
    _validateZLibeLevel(level);
    _validateZLibMemLevel(memLevel);
    _validateZLibStrategy(strategy);
    _validateZLibWindowBits(windowBits);
  }

  const ZLibCodec._default()
      : level = ZLibOption.DEFAULT_LEVEL,
        windowBits = ZLibOption.DEFAULT_WINDOW_BITS,
        memLevel = ZLibOption.DEFAULT_MEM_LEVEL,
        strategy = ZLibOption.STRATEGY_DEFAULT,
        raw = false,
        gzip = false,
        dictionary = null;

  /**
   * Get a [ZLibEncoder] for encoding to `ZLib` compressed data.
   */
  ZLibEncoder get encoder => new ZLibEncoder(
      gzip: false,
      level: level,
      windowBits: windowBits,
      memLevel: memLevel,
      strategy: strategy,
      dictionary: dictionary,
      raw: raw);

  /**
   * Get a [ZLibDecoder] for decoding `ZLib` compressed data.
   */
  ZLibDecoder get decoder =>
      new ZLibDecoder(windowBits: windowBits, dictionary: dictionary, raw: raw);
}

/**
 * An instance of the default implementation of the [GZipCodec].
 */
const GZipCodec GZIP = const GZipCodec._default();

/**
 * The [GZipCodec] encodes raw bytes to GZip compressed bytes and decodes GZip
 * compressed bytes to raw bytes.
 *
 * The difference between [ZLibCodec] and [GZipCodec] is that the [GZipCodec]
 * wraps the `ZLib` compressed bytes in `GZip` frames.
 */
class GZipCodec extends Codec<List<int>, List<int>> {
  /**
   * When true, `GZip` frames will be added to the compressed data.
   */
  final bool gzip;

  /**
   * The compression-[level] can be set in the range of `-1..9`, with `6` being
   * the default compression level. Levels above `6` will have higher
   * compression rates at the cost of more CPU and memory usage. Levels below
   * `6` will use less CPU and memory at the cost of lower compression rates.
   */
  final int level;

  /**
   * Specifies how much memory should be allocated for the internal compression
   * state. `1` uses minimum memory but is slow and reduces compression ratio;
   * `9` uses maximum memory for optimal speed. The default value is `8`.
   *
   * The memory requirements for deflate are (in bytes):
   *
   *     (1 << (windowBits + 2)) +  (1 << (memLevel + 9))
   * that is: 128K for windowBits = 15 + 128K for memLevel = 8 (default values)
   */
  final int memLevel;

  /**
   * Tunes the compression algorithm. Use the value
   * [ZLibOption.STRATEGY_DEFAULT] for normal data,
   * [ZLibOption.STRATEGY_FILTERED] for data produced by a filter
   * (or predictor), [ZLibOption.STRATEGY_HUFFMAN_ONLY] to force Huffman
   * encoding only (no string match), or [ZLibOption.STRATEGY_RLE] to limit
   * match distances to one (run-length encoding).
   */
  final int strategy;

  /**
   * Base two logarithm of the window size (the size of the history buffer). It
   * should be in the range `8..15`. Larger values result in better compression
   * at the expense of memory usage. The default value is `15`
   */
  final int windowBits;

  /**
   * Initial compression dictionary.
   *
   * It should consist of strings (byte sequences) that are likely to be
   * encountered later in the data to be compressed, with the most commonly used
   * strings preferably put towards the end of the dictionary. Using a
   * dictionary is most useful when the data to be compressed is short and can
   * be predicted with good accuracy; the data can then be compressed better
   * than with the default empty dictionary.
   */
  final List<int> dictionary;

  /**
   * When true, deflate generates raw data with no zlib header or trailer, and
   * will not compute an adler32 check value
   */
  final bool raw;

  GZipCodec(
      {this.level: ZLibOption.DEFAULT_LEVEL,
      this.windowBits: ZLibOption.DEFAULT_WINDOW_BITS,
      this.memLevel: ZLibOption.DEFAULT_MEM_LEVEL,
      this.strategy: ZLibOption.STRATEGY_DEFAULT,
      this.dictionary: null,
      this.raw: false,
      this.gzip: true}) {
    _validateZLibeLevel(level);
    _validateZLibMemLevel(memLevel);
    _validateZLibStrategy(strategy);
    _validateZLibWindowBits(windowBits);
  }

  const GZipCodec._default()
      : level = ZLibOption.DEFAULT_LEVEL,
        windowBits = ZLibOption.DEFAULT_WINDOW_BITS,
        memLevel = ZLibOption.DEFAULT_MEM_LEVEL,
        strategy = ZLibOption.STRATEGY_DEFAULT,
        raw = false,
        gzip = true,
        dictionary = null;

  /**
   * Get a [ZLibEncoder] for encoding to `GZip` compressed data.
   */
  ZLibEncoder get encoder => new ZLibEncoder(
      gzip: true,
      level: level,
      windowBits: windowBits,
      memLevel: memLevel,
      strategy: strategy,
      dictionary: dictionary,
      raw: raw);

  /**
   * Get a [ZLibDecoder] for decoding `GZip` compressed data.
   */
  ZLibDecoder get decoder =>
      new ZLibDecoder(windowBits: windowBits, dictionary: dictionary, raw: raw);
}

/**
 * The [ZLibEncoder] encoder is used by [ZLibCodec] and [GZipCodec] to compress
 * data.
 */
class ZLibEncoder extends Converter<List<int>, List<int>> {
  /**
   * When true, `GZip` frames will be added to the compressed data.
   */
  final bool gzip;

  /**
   * The compression-[level] can be set in the range of `-1..9`, with `6` being
   * the default compression level. Levels above `6` will have higher
   * compression rates at the cost of more CPU and memory usage. Levels below
   * `6` will use less CPU and memory at the cost of lower compression rates.
   */
  final int level;

  /**
   * Specifies how much memory should be allocated for the internal compression
   * state. `1` uses minimum memory but is slow and reduces compression ratio;
   * `9` uses maximum memory for optimal speed. The default value is `8`.
   *
   * The memory requirements for deflate are (in bytes):
   *
   *     (1 << (windowBits + 2)) +  (1 << (memLevel + 9))
   * that is: 128K for windowBits = 15 + 128K for memLevel = 8 (default values)
   */
  final int memLevel;

  /**
   * Tunes the compression algorithm. Use the value
   * [ZLibOption.STRATEGY_DEFAULT] for normal data,
   * [ZLibOption.STRATEGY_FILTERED] for data produced by a filter
   * (or predictor), [ZLibOption.STRATEGY_HUFFMAN_ONLY] to force Huffman
   * encoding only (no string match), or [ZLibOption.STRATEGY_RLE] to limit
   * match distances to one (run-length encoding).
   */
  final int strategy;

  /**
   * Base two logarithm of the window size (the size of the history buffer). It
   * should be in the range `8..15`. Larger values result in better compression
   * at the expense of memory usage. The default value is `15`
   */
  final int windowBits;

  /**
   * Initial compression dictionary.
   *
   * It should consist of strings (byte sequences) that are likely to be
   * encountered later in the data to be compressed, with the most commonly used
   * strings preferably put towards the end of the dictionary. Using a
   * dictionary is most useful when the data to be compressed is short and can
   * be predicted with good accuracy; the data can then be compressed better
   * than with the default empty dictionary.
   */
  final List<int> dictionary;

  /**
   * When true, deflate generates raw data with no zlib header or trailer, and
   * will not compute an adler32 check value
   */
  final bool raw;

  ZLibEncoder(
      {this.gzip: false,
      this.level: ZLibOption.DEFAULT_LEVEL,
      this.windowBits: ZLibOption.DEFAULT_WINDOW_BITS,
      this.memLevel: ZLibOption.DEFAULT_MEM_LEVEL,
      this.strategy: ZLibOption.STRATEGY_DEFAULT,
      this.dictionary: null,
      this.raw: false}) {
    _validateZLibeLevel(level);
    _validateZLibMemLevel(memLevel);
    _validateZLibStrategy(strategy);
    _validateZLibWindowBits(windowBits);
  }

  /**
   * Convert a list of bytes using the options given to the ZLibEncoder
   * constructor.
   */
  List<int> convert(List<int> bytes) {
    _BufferSink sink = new _BufferSink();
    startChunkedConversion(sink)
      ..add(bytes)
      ..close();
    return sink.builder.takeBytes();
  }

  /**
   * Start a chunked conversion using the options given to the [ZLibEncoder]
   * constructor. While it accepts any [Sink] taking [List<int>]'s,
   * the optimal sink to be passed as [sink] is a [ByteConversionSink].
   */
  ByteConversionSink startChunkedConversion(Sink<List<int>> sink) {
    if (sink is! ByteConversionSink) {
      sink = new ByteConversionSink.from(sink);
    }
    return new _ZLibEncoderSink(
        sink, gzip, level, windowBits, memLevel, strategy, dictionary, raw);
  }
}

/**
 * The [ZLibDecoder] is used by [ZLibCodec] and [GZipCodec] to decompress data.
 */
class ZLibDecoder extends Converter<List<int>, List<int>> {
  /**
   * Base two logarithm of the window size (the size of the history buffer). It
   * should be in the range `8..15`. Larger values result in better compression
   * at the expense of memory usage. The default value is `15`.
   */
  final int windowBits;

  /**
   * Initial compression dictionary.
   *
   * It should consist of strings (byte sequences) that are likely to be
   * encountered later in the data to be compressed, with the most commonly used
   * strings preferably put towards the end of the dictionary. Using a
   * dictionary is most useful when the data to be compressed is short and can
   * be predicted with good accuracy; the data can then be compressed better
   * than with the default empty dictionary.
   */
  final List<int> dictionary;

  /**
   * When true, deflate generates raw data with no zlib header or trailer, and
   * will not compute an adler32 check value
   */
  final bool raw;

  ZLibDecoder(
      {this.windowBits: ZLibOption.DEFAULT_WINDOW_BITS,
      this.dictionary: null,
      this.raw: false}) {
    _validateZLibWindowBits(windowBits);
  }

  /**
   * Convert a list of bytes using the options given to the [ZLibDecoder]
   * constructor.
   */
  List<int> convert(List<int> bytes) {
    _BufferSink sink = new _BufferSink();
    startChunkedConversion(sink)
      ..add(bytes)
      ..close();
    return sink.builder.takeBytes();
  }

  /**
   * Start a chunked conversion. While it accepts any [Sink]
   * taking [List<int>]'s, the optimal sink to be passed as [sink] is a
   * [ByteConversionSink].
   */
  ByteConversionSink startChunkedConversion(Sink<List<int>> sink) {
    if (sink is! ByteConversionSink) {
      sink = new ByteConversionSink.from(sink);
    }
    return new _ZLibDecoderSink(sink, windowBits, dictionary, raw);
  }
}

/**
 * The [RawZLibFilter] class provides a low-level interface to zlib.
 */
abstract class RawZLibFilter {
  /**
   * Returns a a [RawZLibFilter] whose [process] and [processed] methods
   * compress data.
   */
  factory RawZLibFilter.deflateFilter({
    bool gzip: false,
    int level: ZLibOption.DEFAULT_LEVEL,
    int windowBits: ZLibOption.DEFAULT_WINDOW_BITS,
    int memLevel: ZLibOption.DEFAULT_MEM_LEVEL,
    int strategy: ZLibOption.STRATEGY_DEFAULT,
    List<int> dictionary,
    bool raw: false,
  }) {
    return _makeZLibDeflateFilter(
        gzip, level, windowBits, memLevel, strategy, dictionary, raw);
  }

  /**
   * Returns a a [RawZLibFilter] whose [process] and [processed] methods
   * decompress data.
   */
  factory RawZLibFilter.inflateFilter({
    int windowBits: ZLibOption.DEFAULT_WINDOW_BITS,
    List<int> dictionary,
    bool raw: false,
  }) {
    return _makeZLibInflateFilter(windowBits, dictionary, raw);
  }

  /**
   * Call to process a chunk of data. A call to [process] should only be made
   * when [processed] returns [:null:].
   */
  void process(List<int> data, int start, int end);

  /**
   * Get a chunk of processed data. When there are no more data available,
   * [processed] will return [:null:]. Set [flush] to [:false:] for non-final
   * calls to improve performance of some filters.
   *
   * The last call to [processed] should have [end] set to [:true:]. This will
   * make sure an 'end' packet is written on the stream.
   */
  List<int> processed({bool flush: true, bool end: false});

  external static RawZLibFilter _makeZLibDeflateFilter(
      bool gzip,
      int level,
      int windowBits,
      int memLevel,
      int strategy,
      List<int> dictionary,
      bool raw);

  external static RawZLibFilter _makeZLibInflateFilter(
      int windowBits, List<int> dictionary, bool raw);
}

class _BufferSink extends ByteConversionSink {
  final BytesBuilder builder = new BytesBuilder(copy: false);

  void add(List<int> chunk) {
    builder.add(chunk);
  }

  void addSlice(List<int> chunk, int start, int end, bool isLast) {
    if (chunk is Uint8List) {
      Uint8List list = chunk;
      builder.add(new Uint8List.view(list.buffer, start, end - start));
    } else {
      builder.add(chunk.sublist(start, end));
    }
  }

  void close() {}
}

class _ZLibEncoderSink extends _FilterSink {
  _ZLibEncoderSink(
      ByteConversionSink sink,
      bool gzip,
      int level,
      int windowBits,
      int memLevel,
      int strategy,
      List<int> dictionary,
      bool raw)
      : super(
            sink,
            RawZLibFilter._makeZLibDeflateFilter(
                gzip, level, windowBits, memLevel, strategy, dictionary, raw));
}

class _ZLibDecoderSink extends _FilterSink {
  _ZLibDecoderSink(
      ByteConversionSink sink, int windowBits, List<int> dictionary, bool raw)
      : super(sink,
            RawZLibFilter._makeZLibInflateFilter(windowBits, dictionary, raw));
}

class _FilterSink extends ByteConversionSink {
  final RawZLibFilter _filter;
  final ByteConversionSink _sink;
  bool _closed = false;
  bool _empty = true;

  _FilterSink(this._sink, this._filter);

  void add(List<int> data) {
    addSlice(data, 0, data.length, false);
  }

  void addSlice(List<int> data, int start, int end, bool isLast) {
    if (_closed) return;
    if (end == null) throw new ArgumentError.notNull("end");
    RangeError.checkValidRange(start, end, data.length);
    try {
      _empty = false;
      _BufferAndStart bufferAndStart =
          _ensureFastAndSerializableByteData(data, start, end);
      _filter.process(bufferAndStart.buffer, bufferAndStart.start,
          end - (start - bufferAndStart.start));
      List<int> out;
      while ((out = _filter.processed(flush: false)) != null) {
        _sink.add(out);
      }
    } catch (e) {
      _closed = true;
      rethrow;
    }

    if (isLast) close();
  }

  void close() {
    if (_closed) return;
    // Be sure to send process an empty chunk of data. Without this, the empty
    // message would not have a GZip frame (if compressed with GZip).
    if (_empty) _filter.process(const [], 0, 0);
    try {
      List<int> out;
      while ((out = _filter.processed(end: true)) != null) {
        _sink.add(out);
      }
    } catch (e) {
      _closed = true;
      throw e;
    }
    _closed = true;
    _sink.close();
  }
}

void _validateZLibWindowBits(int windowBits) {
  if (ZLibOption.MIN_WINDOW_BITS > windowBits ||
      ZLibOption.MAX_WINDOW_BITS < windowBits) {
    throw new RangeError.range(
        windowBits, ZLibOption.MIN_WINDOW_BITS, ZLibOption.MAX_WINDOW_BITS);
  }
}

void _validateZLibeLevel(int level) {
  if (ZLibOption.MIN_LEVEL > level || ZLibOption.MAX_LEVEL < level) {
    throw new RangeError.range(
        level, ZLibOption.MIN_LEVEL, ZLibOption.MAX_LEVEL);
  }
}

void _validateZLibMemLevel(int memLevel) {
  if (ZLibOption.MIN_MEM_LEVEL > memLevel ||
      ZLibOption.MAX_MEM_LEVEL < memLevel) {
    throw new RangeError.range(
        memLevel, ZLibOption.MIN_MEM_LEVEL, ZLibOption.MAX_MEM_LEVEL);
  }
}

void _validateZLibStrategy(int strategy) {
  const strategies = const <int>[
    ZLibOption.STRATEGY_FILTERED,
    ZLibOption.STRATEGY_HUFFMAN_ONLY,
    ZLibOption.STRATEGY_RLE,
    ZLibOption.STRATEGY_FIXED,
    ZLibOption.STRATEGY_DEFAULT
  ];
  if (strategies.indexOf(strategy) == -1) {
    throw new ArgumentError("Unsupported 'strategy'");
  }
}
