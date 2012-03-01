
class _EntrySyncImpl implements EntrySync native "*EntrySync" {

  final _DOMFileSystemSyncImpl filesystem;

  final String fullPath;

  final bool isDirectory;

  final bool isFile;

  final String name;

  _EntrySyncImpl copyTo(_DirectoryEntrySyncImpl parent, String name) native;

  _MetadataImpl getMetadata() native;

  _DirectoryEntrySyncImpl getParent() native;

  _EntrySyncImpl moveTo(_DirectoryEntrySyncImpl parent, String name) native;

  void remove() native;

  String toURL() native;
}
