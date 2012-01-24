
class Int32ArrayJs extends ArrayBufferViewJs implements Int32Array, List<int> native "*Int32Array" {

  factory Int32Array(int length) =>  _construct(length);

  factory Int32Array.fromList(List<int> list) => _construct(list);

  factory Int32Array.fromBuffer(ArrayBuffer buffer) => _construct(buffer);

  static _construct(arg) native 'return new Int32Array(arg);';

  static final int BYTES_PER_ELEMENT = 4;

  int get length() native "return this.length;";

  int operator[](int index) native;

  void operator[]=(int index, int value) native;

  void setElements(Object array, [int offset = null]) native;

  Int32ArrayJs subarray(int start, [int end = null]) native;
}
