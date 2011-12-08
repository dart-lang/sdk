
class Float32Array extends ArrayBufferView implements List<num> native "Float32Array" {

  factory Float32Array(int length) =>  _construct(length);

  factory Float32Array.fromList(List<num> list) => _construct(list);

  factory Float32Array.fromBuffer(ArrayBuffer buffer) => _construct(buffer);

  static _construct(arg) native 'return new Float32Array(arg);';

  static final int BYTES_PER_ELEMENT = 4;

  int length;

  num operator[](int index) native;

  void operator[]=(int index, num value) native;

  Float32Array subarray(int start, [int end = null]) native;
}
