
class Uint8ArrayJs extends ArrayBufferViewJs implements Uint8Array, List<int> native "*Uint8Array" {

  factory Uint8Array(int length) =>  _construct(length);

  factory Uint8Array.fromList(List<int> list) => _construct(list);

  factory Uint8Array.fromBuffer(ArrayBuffer buffer) => _construct(buffer);

  static _construct(arg) native 'return new Uint8Array(arg);';

  static final int BYTES_PER_ELEMENT = 1;

  int get length() native "return this.length;";

  int operator[](int index) native;

  void operator[]=(int index, int value) native;

  void setElements(Object array, [int offset = null]) native;

  Uint8ArrayJs subarray(int start, [int end = null]) native;
}
