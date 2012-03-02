
class _FileEntrySyncImpl extends _EntrySyncImpl implements FileEntrySync {
  _FileEntrySyncImpl._wrap(ptr) : super._wrap(ptr);

  FileWriterSync createWriter() {
    return _wrap(_ptr.createWriter());
  }

  File file() {
    return _wrap(_ptr.file());
  }
}
