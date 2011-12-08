
class Uint8Array extends ArrayBufferView native "*Uint8Array" {

  static final int BYTES_PER_ELEMENT = 1;

  int length;

  Uint8Array subarray(int start, [int end = null]) native;
}
