
class _StorageEventImpl extends _EventImpl implements StorageEvent native "*StorageEvent" {

  final String key;

  final String newValue;

  final String oldValue;

  final _StorageImpl storageArea;

  final String url;

  void initStorageEvent(String typeArg, bool canBubbleArg, bool cancelableArg, String keyArg, String oldValueArg, String newValueArg, String urlArg, _StorageImpl storageAreaArg) native;
}
