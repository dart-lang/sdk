
class _DOMURLJs extends _DOMTypeJs implements DOMURL native "*DOMURL" {

  String createObjectURL(var blob_OR_stream) native;

  void revokeObjectURL(String url) native;
}
