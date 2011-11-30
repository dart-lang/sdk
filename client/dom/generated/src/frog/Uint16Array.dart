
class Uint16Array extends ArrayBufferView native "*Uint16Array" {

  static final int BYTES_PER_ELEMENT = 2;

  int length;

  Uint16Array subarray(int start, [int end = null]) native;
}
