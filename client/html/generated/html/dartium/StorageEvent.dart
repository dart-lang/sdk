
class _StorageEventImpl extends _EventImpl implements StorageEvent {
  _StorageEventImpl._wrap(ptr) : super._wrap(ptr);

  String get key() => _wrap(_ptr.key);

  String get newValue() => _wrap(_ptr.newValue);

  String get oldValue() => _wrap(_ptr.oldValue);

  Storage get storageArea() => _wrap(_ptr.storageArea);

  String get url() => _wrap(_ptr.url);

  void initStorageEvent(String typeArg, bool canBubbleArg, bool cancelableArg, String keyArg, String oldValueArg, String newValueArg, String urlArg, Storage storageAreaArg) {
    _ptr.initStorageEvent(_unwrap(typeArg), _unwrap(canBubbleArg), _unwrap(cancelableArg), _unwrap(keyArg), _unwrap(oldValueArg), _unwrap(newValueArg), _unwrap(urlArg), _unwrap(storageAreaArg));
    return;
  }
}
