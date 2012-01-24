
class ArrayBufferViewJS implements ArrayBufferView native "*ArrayBufferView" {

  ArrayBufferJS get buffer() native "return this.buffer;";

  int get byteLength() native "return this.byteLength;";

  int get byteOffset() native "return this.byteOffset;";

  var dartObjectLocalStorage;

  String get typeName() native;
}
