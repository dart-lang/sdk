
class StorageEvent extends Event native "*StorageEvent" {

  String key;

  String newValue;

  String oldValue;

  Storage storageArea;

  String url;

  void initStorageEvent(String typeArg, bool canBubbleArg, bool cancelableArg, String keyArg, String oldValueArg, String newValueArg, String urlArg, Storage storageAreaArg) native;
}
