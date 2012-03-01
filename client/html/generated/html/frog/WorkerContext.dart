
class _WorkerContextImpl implements WorkerContext native "*WorkerContext" {

  static final int PERSISTENT = 1;

  static final int TEMPORARY = 0;

  final _WorkerLocationImpl location;

  final _WorkerNavigatorImpl navigator;

  EventListener onerror;

  final _WorkerContextImpl self;

  final _IDBFactoryImpl webkitIndexedDB;

  final _NotificationCenterImpl webkitNotifications;

  void addEventListener(String type, EventListener listener, [bool useCapture = null]) native;

  void clearInterval(int handle) native;

  void clearTimeout(int handle) native;

  void close() native;

  bool dispatchEvent(_EventImpl evt) native;

  void importScripts() native;

  _DatabaseImpl openDatabase(String name, String version, String displayName, int estimatedSize, [DatabaseCallback creationCallback = null]) native;

  _DatabaseSyncImpl openDatabaseSync(String name, String version, String displayName, int estimatedSize, [DatabaseCallback creationCallback = null]) native;

  void removeEventListener(String type, EventListener listener, [bool useCapture = null]) native;

  int setInterval(TimeoutHandler handler, int timeout) native;

  int setTimeout(TimeoutHandler handler, int timeout) native;

  void webkitRequestFileSystem(int type, int size, [FileSystemCallback successCallback = null, ErrorCallback errorCallback = null]) native;

  _DOMFileSystemSyncImpl webkitRequestFileSystemSync(int type, int size) native;

  _EntrySyncImpl webkitResolveLocalFileSystemSyncURL(String url) native;

  void webkitResolveLocalFileSystemURL(String url, [EntryCallback successCallback = null, ErrorCallback errorCallback = null]) native;
}
