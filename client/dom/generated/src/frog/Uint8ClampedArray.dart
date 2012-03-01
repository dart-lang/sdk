
class _Uint8ClampedArrayJs extends _Uint8ArrayJs implements Uint8ClampedArray, List<int> native "*Uint8ClampedArray" {

  factory Uint8ClampedArray(int length) =>  _construct_Uint8ClampedArray(length);

  factory Uint8ClampedArray.fromList(List<int> list) => _construct_Uint8ClampedArray(list);

  factory Uint8ClampedArray.fromBuffer(ArrayBuffer buffer) => _construct_Uint8ClampedArray(buffer);

  static _construct_Uint8ClampedArray(arg) native 'return new Uint8ClampedArray(arg);';

  // Use implementation from Uint8Array.
  // final int length;

  void setElements(Object array, [int offset = null]) native '''
if (offset == null) return this.set(array);
return this.set(array, offset);''';

  _Uint8ClampedArrayJs subarray(int start, [int end = null]) native;
}
