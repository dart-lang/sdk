
class Int16Array extends ArrayBufferView native "Int16Array" {

  int length;

  Int16Array subarray(int start, [int end = null]) native;
}
