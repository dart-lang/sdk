import '../../compiler_api.dart' as api;

/// [StringSink] that buffers data written to the underlying [api.OutputSink].
///
/// Useful for string that are built slowly over many writes, avoids keeping the
/// entire string in memory. Each write operation checks if the length of the
/// buffer is above the [maxLength] threshold but a single write can push the
/// buffer above that threshold meaning more than [maxLength] bytes may be
/// forwarded at once. Avoid large writes to ensure the buffer is effective.
class BufferedStringOutputSink implements StringSink {
  StringBuffer buffer = StringBuffer();
  final api.OutputSink outputSink;
  final int maxLength;
  static const int _defaultMaxLength = 1024;

  BufferedStringOutputSink(this.outputSink,
      {this.maxLength = _defaultMaxLength});

  void close() {
    outputSink.add(buffer.toString());
    outputSink.close();
  }

  @override
  void write(Object? object) {
    buffer.write(object);
    if (buffer.length > maxLength) {
      outputSink.add(buffer.toString());
      buffer.clear();
    }
  }

  @override
  void writeAll(Iterable objects, [String separator = ""]) {
    buffer.writeAll(objects, separator);
    if (buffer.length > maxLength) {
      outputSink.add(buffer.toString());
      buffer.clear();
    }
  }

  @override
  void writeCharCode(int charCode) {
    buffer.writeCharCode(charCode);
    if (buffer.length > maxLength) {
      outputSink.add(buffer.toString());
      buffer.clear();
    }
  }

  @override
  void writeln([Object? object = ""]) {
    buffer.writeln(object);
    if (buffer.length > maxLength) {
      outputSink.add(buffer.toString());
      buffer.clear();
    }
  }
}
