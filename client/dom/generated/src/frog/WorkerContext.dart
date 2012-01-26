
class WorkerContextJs extends DOMTypeJs implements WorkerContext native "*WorkerContext" {

  static final int PERSISTENT = 1;

  static final int TEMPORARY = 0;

  WorkerLocationJs get location() native "return this.location;";

  void set location(WorkerLocationJs value) native "this.location = value;";

  WorkerNavigatorJs get navigator() native "return this.navigator;";

  void set navigator(WorkerNavigatorJs value) native "this.navigator = value;";

  EventListener get onerror() native "return this.onerror;";

  void set onerror(EventListener value) native "this.onerror = value;";

  WorkerContextJs get self() native "return this.self;";

  void set self(WorkerContextJs value) native "this.self = value;";

  IDBFactoryJs get webkitIndexedDB() native "return this.webkitIndexedDB;";

  NotificationCenterJs get webkitNotifications() native "return this.webkitNotifications;";

  DOMURLJs get webkitURL() native "return this.webkitURL;";

  void addEventListener(String type, EventListener listener, [bool useCapture = null]) native;

  void clearInterval(int handle) native;

  void clearTimeout(int handle) native;

  void close() native;

  bool dispatchEvent(EventJs evt) native;

  void importScripts() native;

  DatabaseJs openDatabase(String name, String version, String displayName, int estimatedSize, [DatabaseCallback creationCallback = null]) native;

  DatabaseSyncJs openDatabaseSync(String name, String version, String displayName, int estimatedSize, [DatabaseCallback creationCallback = null]) native;

  void removeEventListener(String type, EventListener listener, [bool useCapture = null]) native;

  int setInterval(TimeoutHandler handler, int timeout) native;

  int setTimeout(TimeoutHandler handler, int timeout) native;

  void webkitRequestFileSystem(int type, int size, [FileSystemCallback successCallback = null, ErrorCallback errorCallback = null]) native;

  DOMFileSystemSyncJs webkitRequestFileSystemSync(int type, int size) native;

  EntrySyncJs webkitResolveLocalFileSystemSyncURL(String url) native;

  void webkitResolveLocalFileSystemURL(String url, [EntryCallback successCallback = null, ErrorCallback errorCallback = null]) native;
}
