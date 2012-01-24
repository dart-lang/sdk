
class ArrayBufferJs extends DOMTypeJs implements ArrayBuffer native "*ArrayBuffer" {

  int get byteLength() native "return this.byteLength;";

  ArrayBufferJs slice(int begin, [int end = null]) native;
}
