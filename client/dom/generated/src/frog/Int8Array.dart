
class Int8Array extends ArrayBufferView native "*Int8Array" {

  int length;

  Int8Array subarray(int start, [int end = null]) native;
}
