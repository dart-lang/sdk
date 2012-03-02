
class _EntryArraySyncImpl extends _DOMTypeBase implements EntryArraySync {
  _EntryArraySyncImpl._wrap(ptr) : super._wrap(ptr);

  int get length() => _wrap(_ptr.length);

  EntrySync item(int index) {
    return _wrap(_ptr.item(_unwrap(index)));
  }
}
