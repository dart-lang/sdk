
class Float32Array extends ArrayBufferView native "Float32Array" {

  int length;

  Float32Array subarray(int start, [int end = null]) native;
}
