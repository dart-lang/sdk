
class _ArrayBufferImpl implements ArrayBuffer native "*ArrayBuffer" {

  final int byteLength;

  _ArrayBufferImpl slice(int begin, [int end = null]) native;
}
