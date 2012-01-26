
class StorageEventJs extends EventJs implements StorageEvent native "*StorageEvent" {

  String get key() native "return this.key;";

  String get newValue() native "return this.newValue;";

  String get oldValue() native "return this.oldValue;";

  StorageJs get storageArea() native "return this.storageArea;";

  String get url() native "return this.url;";

  void initStorageEvent(String typeArg, bool canBubbleArg, bool cancelableArg, String keyArg, String oldValueArg, String newValueArg, String urlArg, StorageJs storageAreaArg) native;
}
