
class DOMURLJS implements DOMURL native "*DOMURL" {

  String createObjectURL(BlobJS blob) native;

  void revokeObjectURL(String url) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}
