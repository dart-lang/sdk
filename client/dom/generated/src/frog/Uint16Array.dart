
class Uint16Array extends ArrayBufferView implements List<int> native "Uint16Array" {

  factory Uint16Array(int length) =>  _construct(length);

  factory Uint16Array.fromList(List<int> list) => _construct(list);

  factory Uint16Array.fromBuffer(ArrayBuffer buffer) => _construct(buffer);

  static _construct(arg) native 'return new Uint16Array(arg);';

  static final int BYTES_PER_ELEMENT = 2;

  int length;

  int operator[](int index) native;

  void operator[]=(int index, int value) native;

  Uint16Array subarray(int start, [int end = null]) native;
}
