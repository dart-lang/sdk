
class Int16Array extends ArrayBufferView native "*Int16Array" {

  static final int BYTES_PER_ELEMENT = 2;

  int length;

  Int16Array subarray(int start, [int end = null]) native;
}
