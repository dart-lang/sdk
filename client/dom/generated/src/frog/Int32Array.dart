
class Int32Array extends ArrayBufferView native "Int32Array" {

  int length;

  Int32Array subarray(int start, [int end = null]) native;
}
