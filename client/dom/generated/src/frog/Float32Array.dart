
class Float32Array extends ArrayBufferView native "*Float32Array" {

  static final int BYTES_PER_ELEMENT = 4;

  int length;

  Float32Array subarray(int start, [int end = null]) native;
}
