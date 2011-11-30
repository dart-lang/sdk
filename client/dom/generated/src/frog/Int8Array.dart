
class Int8Array extends ArrayBufferView native "*Int8Array" {

  static final int BYTES_PER_ELEMENT = 1;

  int length;

  Int8Array subarray(int start, [int end = null]) native;
}
