
class _IDBVersionChangeRequestImpl extends _IDBRequestImpl implements IDBVersionChangeRequest {
  _IDBVersionChangeRequestImpl._wrap(ptr) : super._wrap(ptr);

  EventListener get onblocked() => _wrap(_ptr.onblocked);

  void set onblocked(EventListener value) { _ptr.onblocked = _unwrap(value); }
}
