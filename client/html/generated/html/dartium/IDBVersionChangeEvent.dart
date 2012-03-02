
class _IDBVersionChangeEventImpl extends _EventImpl implements IDBVersionChangeEvent {
  _IDBVersionChangeEventImpl._wrap(ptr) : super._wrap(ptr);

  String get version() => _wrap(_ptr.version);
}
