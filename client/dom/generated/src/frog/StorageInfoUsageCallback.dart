
class StorageInfoUsageCallback native "*StorageInfoUsageCallback" {

  bool handleEvent(int currentUsageInBytes, int currentQuotaInBytes) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}
