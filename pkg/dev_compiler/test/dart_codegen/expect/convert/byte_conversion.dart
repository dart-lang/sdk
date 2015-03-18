part of dart.convert;
 abstract class ByteConversionSink extends ChunkedConversionSink<List<int>> {ByteConversionSink();
 factory ByteConversionSink.withCallback(void callback(List<int> accumulated)) = _ByteCallbackSink;
 factory ByteConversionSink.from(Sink<List<int>> sink) = _ByteAdapterSink;
 void addSlice(List<int> chunk, int start, int end, bool isLast);
}
 abstract class ByteConversionSinkBase extends ByteConversionSink {void add(List<int> chunk);
 void close();
 void addSlice(List<int> chunk, int start, int end, bool isLast) {
add(chunk.sublist(start, end));
 if (isLast) close();
}
}
 class _ByteAdapterSink extends ByteConversionSinkBase {final Sink<List<int>> _sink;
 _ByteAdapterSink(this._sink);
 void add(List<int> chunk) => _sink.add(chunk);
 void close() => _sink.close();
}
 class _ByteCallbackSink extends ByteConversionSinkBase {static const _INITIAL_BUFFER_SIZE = 1024;
 final _ChunkedConversionCallback<List<int>> _callback;
 List<int> _buffer = new Uint8List(_INITIAL_BUFFER_SIZE);
 int _bufferIndex = 0;
 _ByteCallbackSink(void callback(List<int> accumulated)) : this._callback = callback;
 void add(Iterable<int> chunk) {
int freeCount = _buffer.length - _bufferIndex;
 if (chunk.length > freeCount) {
int oldLength = _buffer.length;
 int newLength = _roundToPowerOf2(chunk.length + oldLength) * 2;
 List<int> grown = new Uint8List(newLength);
 grown.setRange(0, _buffer.length, _buffer);
 _buffer = grown;
}
 _buffer.setRange(_bufferIndex, _bufferIndex + chunk.length, chunk);
 _bufferIndex += chunk.length;
}
 static int _roundToPowerOf2(int v) {
assert (v > 0); v--;
 v |= v >> 1;
 v |= v >> 2;
 v |= v >> 4;
 v |= v >> 8;
 v |= v >> 16;
 v++;
 return v;
}
 void close() {
_callback(_buffer.sublist(0, _bufferIndex));
}
}
