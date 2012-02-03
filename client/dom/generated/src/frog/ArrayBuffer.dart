
class _ArrayBufferJs extends _DOMTypeJs implements ArrayBuffer native "*ArrayBuffer" {

  int get byteLength() native "return this.byteLength;";

  _ArrayBufferJs slice(int begin, [int end = null]) native;
}
