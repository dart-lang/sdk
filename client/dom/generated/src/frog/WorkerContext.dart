
class _WorkerContextJs extends _DOMTypeJs implements WorkerContext native "*WorkerContext" {

  static final int PERSISTENT = 1;

  static final int TEMPORARY = 0;

  final _WorkerLocationJs location;

  final _WorkerNavigatorJs navigator;

  EventListener onerror;

  final _WorkerContextJs self;

  final _IDBFactoryJs webkitIndexedDB;

  final _NotificationCenterJs webkitNotifications;

  void addEventListener(String type, EventListener listener, [bool useCapture = null]) native;

  void clearInterval(int handle) native;

  void clearTimeout(int handle) native;

  void close() native;

  bool dispatchEvent(_EventJs evt) native;

  void importScripts() native;

  _DatabaseJs openDatabase(String name, String version, String displayName, int estimatedSize, [DatabaseCallback creationCallback = null]) native;

  _DatabaseSyncJs openDatabaseSync(String name, String version, String displayName, int estimatedSize, [DatabaseCallback creationCallback = null]) native;

  void removeEventListener(String type, EventListener listener, [bool useCapture = null]) native;

  int setInterval(TimeoutHandler handler, int timeout) native;

  int setTimeout(TimeoutHandler handler, int timeout) native;

  void webkitRequestFileSystem(int type, int size, [FileSystemCallback successCallback = null, ErrorCallback errorCallback = null]) native;

  _DOMFileSystemSyncJs webkitRequestFileSystemSync(int type, int size) native;

  _EntrySyncJs webkitResolveLocalFileSystemSyncURL(String url) native;

  void webkitResolveLocalFileSystemURL(String url, [EntryCallback successCallback = null, ErrorCallback errorCallback = null]) native;
}
