
class _DirectoryReaderSyncImpl extends _DOMTypeBase implements DirectoryReaderSync {
  _DirectoryReaderSyncImpl._wrap(ptr) : super._wrap(ptr);

  EntryArraySync readEntries() {
    return _wrap(_ptr.readEntries());
  }
}
