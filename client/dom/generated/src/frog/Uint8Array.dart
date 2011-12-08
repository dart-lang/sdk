
class Uint8Array extends ArrayBufferView implements List<int> native "Uint8Array" {

  factory Uint8Array(int length) =>  _construct(length);

  factory Uint8Array.fromList(List<int> list) => _construct(list);

  factory Uint8Array.fromBuffer(ArrayBuffer buffer) => _construct(buffer);

  static _construct(arg) native 'return new Uint8Array(arg);';

  static final int BYTES_PER_ELEMENT = 1;

  int length;

  int operator[](int index) native;

  void operator[]=(int index, int value) native;

  Uint8Array subarray(int start, [int end = null]) native;
}
