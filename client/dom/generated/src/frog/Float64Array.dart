
class Float64Array extends ArrayBufferView implements List<num> native "Float64Array" {

  factory Float64Array(int length) =>  _construct(length);

  factory Float64Array.fromList(List<num> list) => _construct(list);

  factory Float64Array.fromBuffer(ArrayBuffer buffer) => _construct(buffer);

  static _construct(arg) native 'return new Float64Array(arg);';

  static final int BYTES_PER_ELEMENT = 8;

  int length;

  num operator[](int index) native;

  void operator[]=(int index, num value) native;

  Float64Array subarray(int start, [int end = null]) native;
}
