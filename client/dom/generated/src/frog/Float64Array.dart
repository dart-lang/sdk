
class Float64Array extends ArrayBufferView native "*Float64Array" {

  static final int BYTES_PER_ELEMENT = 8;

  int length;

  Float64Array subarray(int start, [int end = null]) native;
}
