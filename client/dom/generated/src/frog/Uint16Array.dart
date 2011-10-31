
class Uint16Array extends ArrayBufferView native "Uint16Array" {

  int length;

  Uint16Array subarray(int start, [int end = null]) native;
}
