
class _DOMURLJs extends _DOMTypeJs implements DOMURL native "*DOMURL" {

  String createObjectURL(_BlobJs blob) native;

  void revokeObjectURL(String url) native;
}
