
class Int16Array extends ArrayBufferView implements List<int> native "Int16Array" {

  factory Int16Array(int length) =>  _construct(length);

  factory Int16Array.fromList(List<int> list) => _construct(list);

  factory Int16Array.fromBuffer(ArrayBuffer buffer) => _construct(buffer);

  static _construct(arg) native 'return new Int16Array(arg);';

  static final int BYTES_PER_ELEMENT = 2;

  int length;

  int operator[](int index) native;

  void operator[]=(int index, int value) native;

  Int16Array subarray(int start, [int end = null]) native;
}
