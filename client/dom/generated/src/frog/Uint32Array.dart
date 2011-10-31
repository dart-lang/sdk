
class Uint32Array extends ArrayBufferView native "Uint32Array" {

  int length;

  Uint32Array subarray(int start, [int end = null]) native;
}
