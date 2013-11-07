// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.io;


/**
 * An instance of the default implementation of the [ZLibCodec].
 */
const ZLibCodec ZLIB = const ZLibCodec();


/**
 * The [ZLibCodec] encodes raw bytes to ZLib compressed bytes and decodes ZLib
 * compressed bytes to raw bytes.
 */
class ZLibCodec extends Codec<List<int>, List<int>> {
  /**
   * The compression level of the [ZLibCodec].
   */
  final int level;

  /**
   * Get a [Converter] for encoding to `ZLib` compressed data.
   */
  Converter<List<int>, List<int>> get encoder =>
      new ZLibEncoder(gzip: false, level: level);

  /**
   * Get a [Converter] for decoding `ZLib` compressed data.
   */
  Converter<List<int>, List<int>> get decoder => const ZLibDecoder();

  /**
   * The compression-[level] can be set in the range of `1..10`, with `6` being
   * the default compression level. Levels above 6 will have higher compression
   * rates at the cost of more CPU and memory usage. Levels below 6 will use
   * less CPU and memory, but at the cost of lower compression rates.
   */
  const ZLibCodec({this.level: 6});
}


/**
 * An instance of the default implementation of the [GZipCodec].
 */
const GZipCodec GZIP = const GZipCodec();


/**
 * The [GZipCodec] encodes raw bytes to GZip compressed bytes and decodes GZip
 * compressed bytes to raw bytes.
 *
 * The difference between [ZLibCodec] and [GZipCodec] is that the [GZipCodec]
 * wraps the `ZLib` compressed bytes in `GZip` frames.
 */
class GZipCodec extends Codec<List<int>, List<int>> {
  /**
   * The compression level of the [ZLibCodec].
   */
  final int level;

  /**
   * Get a [Converter] for encoding to `GZip` compressed data.
   */
  Converter<List<int>, List<int>> get encoder =>
      new ZLibEncoder(gzip: true, level: level);

  /**
   * Get a [Converter] for decoding `GZip` compressed data.
   */
  Converter<List<int>, List<int>> get decoder => const ZLibDecoder();

  /**
   * The compression-[level] can be set in the range of `1..10`, with `6` being
   * the default compression level. Levels above 6 will have higher compression
   * rates at the cost of more CPU and memory usage. Levels below 6 will use
   * less CPU and memory, but at the cost of lower compression rates.
   */
  const GZipCodec({this.level: 6});
}


/**
 * The [ZLibEncoder] is the encoder used by [ZLibCodec] and [GZipCodec] to
 * compress data.
 */
class ZLibEncoder extends Converter<List<int>, List<int>> {
  /**
   * If [gzip] is true, `GZip` frames will be added to the compressed data.
   */
  final bool gzip;

  /**
   * The compression level used by the encoder.
   */
  final int level;

  /**
   * Create a new [ZLibEncoder] converter. If the [gzip] flag is set, the
   * encoder will wrap the encoded ZLib data in GZip frames.
   */
  const ZLibEncoder({this.gzip: false, this.level: 6});


  /**
   * Convert a list of bytes using the options given to the [ZLibEncoder]
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
   * constructor. While it accepts any [ChunkedConversionSink] taking
   * [List<int>]'s, the optimal sink to be passed as [sink] is a
   * [ByteConversionSink].
   */
  ByteConversionSink startChunkedConversion(
      ChunkedConversionSink<List<int>> sink) {
    if (sink is! ByteConversionSink) {
      sink = new ByteConversionSink.from(sink);
    }
    return new _ZLibEncoderSink(sink, gzip, level);
  }
}


/**
 * The [ZLibDecoder] is the decoder used by [ZLibCodec] and [GZipCodec] to
 * decompress data.
 */
class ZLibDecoder extends Converter<List<int>, List<int>> {

  /**
   * Create a new [ZLibEncoder] converter.
   */
  const ZLibDecoder();

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
   * Start a chunked conversion. While it accepts any [ChunkedConversionSink]
   * taking [List<int>]'s, the optimal sink to be passed as [sink] is a
   * [ByteConversionSink].
   */
  ByteConversionSink startChunkedConversion(
      ChunkedConversionSink<List<int>> sink) {
    if (sink is! ByteConversionSink) {
      sink = new ByteConversionSink.from(sink);
    }
    return new _ZLibDecoderSink(sink);
  }
}


class _BufferSink extends ByteConversionSink {
  final BytesBuilder builder = new BytesBuilder();

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
  _ZLibEncoderSink(ByteConversionSink sink, bool gzip, int level)
      : super(sink, _Filter.newZLibDeflateFilter(gzip, level));
}


class _ZLibDecoderSink extends _FilterSink {
  _ZLibDecoderSink(ByteConversionSink sink)
      : super(sink, _Filter.newZLibInflateFilter());
}


class _FilterSink extends ByteConversionSink {
  final _Filter _filter;
  final ByteConversionSink _sink;
  bool _closed = false;
  bool _empty = true;

  _FilterSink(ByteConversionSink this._sink, _Filter this._filter);

  void add(List<int> data) {
    addSlice(data, 0, data.length, false);
  }

  void addSlice(List<int> data, int start, int end, bool isLast) {
    if (_closed) return;
    if (start < 0 || start > data.length) {
      throw new ArgumentError("Invalid start position");
    }
    if (end < 0 || end > data.length || end < start) {
      throw new ArgumentError("Invalid end position");
    }
    try {
      _empty = false;
      _filter.process(data, start, end);
      var out;
      while ((out = _filter.processed(flush: false)) != null) {
        _sink.add(out);
      }
    } catch (e) {
      _closed = true;
      throw e;
    }

    if (isLast) close();
  }

  void close() {
    if (_closed) return;
    // Be sure to send process an empty chunk of data. Without this, the empty
    // message would not have a GZip frame (if compressed with GZip).
    if (_empty) _filter.process(const [], 0, 0);
    try {
      var out;
      while ((out = _filter.processed(end: true)) != null) {
        _sink.add(out);
      }
    } catch (e) {
      _closed = true;
      throw e;
    }
    if (!_closed) _filter.end();
    _closed = true;
    _sink.close();
  }
}



/**
 * Private helper-class to handle native filters.
 */
abstract class _Filter {
  /**
   * Call to process a chunk of data. A call to [process] should only be made
   * when [processed] returns [null].
   */
  void process(List<int> data, int start, int end);

  /**
   * Get a chunk of processed data. When there are no more data available,
   * [processed] will return [null]. Set [flush] to [false] for non-final
   * calls to improve performance of some filters.
   *
   * The last call to [processed] should have [end] set to [true]. This will make
   * sure a 'end' packet is written on the stream.
   */
  List<int> processed({bool flush: true, bool end: false});

  /**
   * Mark the filter as closed. Always call this method for any filter created
   * to avoid leaking resources. [end] can be called at any time, but any
   * successive calls to [process] or [processed] will fail.
   */
  void end();

  external static _Filter newZLibDeflateFilter(bool gzip, int level);
  external static _Filter newZLibInflateFilter();
}
