
class StorageInfoQuotaCallback native "*StorageInfoQuotaCallback" {

  bool handleEvent(int grantedQuotaInBytes) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}
