
class Int32Array extends ArrayBufferView native "*Int32Array" {

  static final int BYTES_PER_ELEMENT = 4;

  int length;

  Int32Array subarray(int start, [int end = null]) native;
}
