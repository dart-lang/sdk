import 'dart:io';

import '../../compiler_api.dart' as api;

/// Implementation of [api.BinaryOutputSink] that writes to a provided file.
class FileBinaryOutputSink extends api.BinaryOutputSink {
  final RandomAccessFile _fileOut;
  void Function(int bytesWritten)? onClose;
  int _bytesWritten = 0;

  FileBinaryOutputSink(this._fileOut, {this.onClose});

  @override
  void add(List<int> data, [int start = 0, int? end]) {
    _fileOut.writeFromSync(data, start, end);
    _bytesWritten += (end ?? data.length) - start;
  }

  @override
  void close() {
    _fileOut.closeSync();
    if (onClose != null) {
      onClose!(_bytesWritten);
    }
  }
}

/// Implementation of [api.OutputSink] that writes to a provided file.
class FileStringOutputSink implements api.OutputSink {
  final RandomAccessFile _fileOut;
  void Function(int charactersWritten)? onClose;
  int _charactersWritten = 0;

  FileStringOutputSink(this._fileOut, {this.onClose});

  @override
  void add(String text) {
    _fileOut.writeStringSync(text);
    _charactersWritten += text.length;
  }

  @override
  void close() {
    _fileOut.closeSync();
    if (onClose != null) {
      onClose!(_charactersWritten);
    }
  }
}

/// [StringSink] that buffers data written to the underlying [api.OutputSink].
///
/// Useful for strings that are built slowly over many writes, avoids keeping
/// the entire string in memory. Each write operation checks if the internal
/// buffer is longer than a maximum length and writes the contents to the
/// underlying [api.OutputSink] if so. Chunks large writes to prevent OOM
/// issues.
///
/// When wrapping an [api.OutputSink], will check if the provided sink is itself
/// a [BufferedStringSinkWrapper]. If it is the same object will be returned,
/// otherwise returns a new [BufferedStringSinkWrapper] wrapping the provided
/// sink.
///
/// Avoid large writes to a [BufferedStringSinkWrapper] to ensure the buffer is
/// effective.
class BufferedStringSinkWrapper implements api.OutputSink, StringSink {
  static const _maxBufferSize = 1024;

  /// This should be at most 8kb, otherwise we risk running OOM. If
  /// [_maxBufferSize] is less than [_maxChunkSize] then this chunking will only
  /// be used if a single write exceeds this size.
  static const _maxChunkSize = 8 * 1024;

  final _buffer = StringBuffer();
  final api.OutputSink _outputSink;

  BufferedStringSinkWrapper._(this._outputSink);

  factory BufferedStringSinkWrapper(api.OutputSink _outputSink) {
    return _outputSink is BufferedStringSinkWrapper
        ? _outputSink
        : BufferedStringSinkWrapper._(_outputSink);
  }

  static bool _isLeadSurrogate(int codeUnit) => (codeUnit & 0xFC00) == 0xD800;

  /// Write the data in chunks if it is too large for a single write.
  void _flushChunked(String data) {
    int offset = 0;
    while (offset < data.length) {
      String chunk;
      int cut = offset + _maxChunkSize;
      if (cut < data.length) {
        // Don't break the string in the middle of a code point encoded as two
        // surrogate pairs since `writeStringSync` will encode the unpaired
        // surrogates as U+FFFD REPLACEMENT CHARACTER.
        int lastCodeUnit = data.codeUnitAt(cut - 1);
        if (_isLeadSurrogate(lastCodeUnit)) {
          cut -= 1;
        }
        chunk = data.substring(offset, cut);
      } else {
        chunk = offset == 0 ? data : data.substring(offset);
      }
      _outputSink.add(chunk);
      offset += chunk.length;
    }
  }

  void _flush() {
    final data = _buffer.toString();
    if (data.length > _maxChunkSize) {
      _flushChunked(data);
    } else {
      _outputSink.add(data);
    }
    _buffer.clear();
  }

  void _flushIfNecessary() {
    if (_buffer.length >= _maxBufferSize) {
      _flush();
    }
  }

  @override
  void add(String data) {
    _buffer.write(data);
    _flushIfNecessary();
  }

  @override
  void close() {
    _flush();
    _outputSink.close();
  }

  @override
  void write(Object? object) {
    _buffer.write(object);
    _flushIfNecessary();
  }

  @override
  void writeAll(Iterable objects, [String separator = ""]) {
    _buffer.writeAll(objects, separator);
    _flushIfNecessary();
  }

  @override
  void writeCharCode(int charCode) {
    _buffer.writeCharCode(charCode);
    _flushIfNecessary();
  }

  @override
  void writeln([Object? object = ""]) {
    _buffer.writeln(object);
    _flushIfNecessary();
  }
}
