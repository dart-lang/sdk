
class WorkerContextJS implements WorkerContext native "*WorkerContext" {

  static final int PERSISTENT = 1;

  static final int TEMPORARY = 0;

  WorkerLocationJS get location() native "return this.location;";

  void set location(WorkerLocationJS value) native "this.location = value;";

  WorkerNavigatorJS get navigator() native "return this.navigator;";

  void set navigator(WorkerNavigatorJS value) native "this.navigator = value;";

  EventListener get onerror() native "return this.onerror;";

  void set onerror(EventListener value) native "this.onerror = value;";

  WorkerContextJS get self() native "return this.self;";

  void set self(WorkerContextJS value) native "this.self = value;";

  IDBFactoryJS get webkitIndexedDB() native "return this.webkitIndexedDB;";

  NotificationCenterJS get webkitNotifications() native "return this.webkitNotifications;";

  DOMURLJS get webkitURL() native "return this.webkitURL;";

  void addEventListener(String type, EventListener listener, [bool useCapture = null]) native;

  void clearInterval(int handle) native;

  void clearTimeout(int handle) native;

  void close() native;

  bool dispatchEvent(EventJS evt) native;

  void importScripts() native;

  DatabaseJS openDatabase(String name, String version, String displayName, int estimatedSize, [DatabaseCallback creationCallback = null]) native;

  DatabaseSyncJS openDatabaseSync(String name, String version, String displayName, int estimatedSize, [DatabaseCallback creationCallback = null]) native;

  void removeEventListener(String type, EventListener listener, [bool useCapture = null]) native;

  int setInterval(TimeoutHandler handler, int timeout) native;

  int setTimeout(TimeoutHandler handler, int timeout) native;

  void webkitRequestFileSystem(int type, int size, [FileSystemCallback successCallback = null, ErrorCallback errorCallback = null]) native;

  DOMFileSystemSyncJS webkitRequestFileSystemSync(int type, int size) native;

  EntrySyncJS webkitResolveLocalFileSystemSyncURL(String url) native;

  void webkitResolveLocalFileSystemURL(String url, [EntryCallback successCallback = null, ErrorCallback errorCallback = null]) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}
