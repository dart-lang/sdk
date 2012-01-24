
class Int8ArrayJS extends ArrayBufferViewJS implements Int8Array, List<int> native "*Int8Array" {

  factory Int8Array(int length) =>  _construct(length);

  factory Int8Array.fromList(List<int> list) => _construct(list);

  factory Int8Array.fromBuffer(ArrayBuffer buffer) => _construct(buffer);

  static _construct(arg) native 'return new Int8Array(arg);';

  static final int BYTES_PER_ELEMENT = 1;

  int get length() native "return this.length;";

  int operator[](int index) native;

  void operator[]=(int index, int value) native;

  void setElements(Object array, [int offset = null]) native;

  Int8ArrayJS subarray(int start, [int end = null]) native;
}
