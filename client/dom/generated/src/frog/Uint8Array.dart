
class Uint8Array extends ArrayBufferView native "Uint8Array" {

  int length;

  Uint8Array subarray(int start, [int end = null]) native;
}
