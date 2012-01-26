
class DOMURLJs extends DOMTypeJs implements DOMURL native "*DOMURL" {

  String createObjectURL(BlobJs blob) native;

  void revokeObjectURL(String url) native;
}
