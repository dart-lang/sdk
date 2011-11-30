
class DOMURL native "*DOMURL" {

  String createObjectURL(Blob blob) native;

  void revokeObjectURL(String url) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}
