
class Float64Array extends ArrayBufferView native "*Float64Array" {

  int length;

  Float64Array subarray(int start, [int end = null]) native;
}
