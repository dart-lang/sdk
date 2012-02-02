
class _ArrayBufferViewJs extends _DOMTypeJs implements ArrayBufferView native "*ArrayBufferView" {

  _ArrayBufferJs get buffer() native "return this.buffer;";

  int get byteLength() native "return this.byteLength;";

  int get byteOffset() native "return this.byteOffset;";
}
