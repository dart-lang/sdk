
class Uint32Array extends ArrayBufferView native "*Uint32Array" {

  static final int BYTES_PER_ELEMENT = 4;

  int length;

  Uint32Array subarray(int start, [int end = null]) native;
}
