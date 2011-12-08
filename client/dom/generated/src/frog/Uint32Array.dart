
class Uint32Array extends ArrayBufferView implements List<int> native "Uint32Array" {

  factory Uint32Array(int length) =>  _construct(length);

  factory Uint32Array.fromList(List<int> list) => _construct(list);

  factory Uint32Array.fromBuffer(ArrayBuffer buffer) => _construct(buffer);

  static _construct(arg) native 'return new Uint32Array(arg);';

  static final int BYTES_PER_ELEMENT = 4;

  int length;

  int operator[](int index) native;

  void operator[]=(int index, int value) native;

  Uint32Array subarray(int start, [int end = null]) native;
}
