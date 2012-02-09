
class _ArrayBufferJs extends _DOMTypeJs implements ArrayBuffer native "*ArrayBuffer" {

  final int byteLength;

  _ArrayBufferJs slice(int begin, [int end = null]) native;
}
