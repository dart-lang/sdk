
class _EntrySyncJs extends _DOMTypeJs implements EntrySync native "*EntrySync" {

  final _DOMFileSystemSyncJs filesystem;

  final String fullPath;

  final bool isDirectory;

  final bool isFile;

  final String name;

  _EntrySyncJs copyTo(_DirectoryEntrySyncJs parent, String name) native;

  _MetadataJs getMetadata() native;

  _DirectoryEntrySyncJs getParent() native;

  _EntrySyncJs moveTo(_DirectoryEntrySyncJs parent, String name) native;

  void remove() native;

  String toURL() native;
}
