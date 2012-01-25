
class Uint16ArrayJs extends ArrayBufferViewJs implements Uint16Array, List<int> native "*Uint16Array" {

  factory Uint16Array(int length) =>  _construct(length);

  factory Uint16Array.fromList(List<int> list) => _construct(list);

  factory Uint16Array.fromBuffer(ArrayBuffer buffer) => _construct(buffer);

  static _construct(arg) native 'return new Uint16Array(arg);';

  static final int BYTES_PER_ELEMENT = 2;

  int get length() native "return this.length;";

  int operator[](int index) native;

  void operator[]=(int index, int value) native;

  void setElements(Object array, [int offset = null]) native;

  Uint16ArrayJs subarray(int start, [int end = null]) native;
}
