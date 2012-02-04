
class _DOMWindowJs extends _DOMTypeJs implements DOMWindow native "@*DOMWindow" {

  static final int PERSISTENT = 1;

  static final int TEMPORARY = 0;

  final _DOMApplicationCacheJs applicationCache;

  _NavigatorJs clientInformation;

  final bool closed;

  _ConsoleJs console;

  final _CryptoJs crypto;

  String defaultStatus;

  String defaultstatus;

  num devicePixelRatio;

  final _DocumentJs document;

  _EventJs event;

  final _ElementJs frameElement;

  _DOMWindowJs frames;

  _HistoryJs history;

  int innerHeight;

  int innerWidth;

  int length;

  final _StorageJs localStorage;

  _LocationJs location;

  _BarInfoJs locationbar;

  _BarInfoJs menubar;

  String name;

  _NavigatorJs navigator;

  bool offscreenBuffering;

  _DOMWindowJs opener;

  int outerHeight;

  int outerWidth;

  final int pageXOffset;

  final int pageYOffset;

  _DOMWindowJs parent;

  _PerformanceJs performance;

  _BarInfoJs personalbar;

  _ScreenJs screen;

  int screenLeft;

  int screenTop;

  int screenX;

  int screenY;

  int scrollX;

  int scrollY;

  _BarInfoJs scrollbars;

  _DOMWindowJs self;

  final _StorageJs sessionStorage;

  String status;

  _BarInfoJs statusbar;

  final _StyleMediaJs styleMedia;

  _BarInfoJs toolbar;

  _DOMWindowJs top;

  final _IDBFactoryJs webkitIndexedDB;

  final _NotificationCenterJs webkitNotifications;

  final _StorageInfoJs webkitStorageInfo;

  final _DOMURLJs webkitURL;

  final _DOMWindowJs window;

  void addEventListener(String type, EventListener listener, [bool useCapture = null]) native;

  void alert(String message) native;

  String atob(String string) native;

  void blur() native;

  String btoa(String string) native;

  void captureEvents() native;

  void clearInterval(int handle) native;

  void clearTimeout(int handle) native;

  void close() native;

  bool confirm(String message) native;

  bool dispatchEvent(_EventJs evt) native;

  bool find(String string, bool caseSensitive, bool backwards, bool wrap, bool wholeWord, bool searchInFrames, bool showDialog) native;

  void focus() native;

  _CSSStyleDeclarationJs getComputedStyle(_ElementJs element, String pseudoElement) native;

  _CSSRuleListJs getMatchedCSSRules(_ElementJs element, String pseudoElement) native;

  _DOMSelectionJs getSelection() native;

  _MediaQueryListJs matchMedia(String query) native;

  void moveBy(num x, num y) native;

  void moveTo(num x, num y) native;

  _DOMWindowJs open(String url, String name, [String options = null]) native;

  _DatabaseJs openDatabase(String name, String version, String displayName, int estimatedSize, [DatabaseCallback creationCallback = null]) native;

  void postMessage(Dynamic message, String targetOrigin, [List messagePorts = null]) native;

  void print() native;

  String prompt(String message, String defaultValue) native;

  void releaseEvents() native;

  void removeEventListener(String type, EventListener listener, [bool useCapture = null]) native;

  void resizeBy(num x, num y) native;

  void resizeTo(num width, num height) native;

  void scroll(int x, int y) native;

  void scrollBy(int x, int y) native;

  void scrollTo(int x, int y) native;

  int setInterval(TimeoutHandler handler, int timeout) native;

  int setTimeout(TimeoutHandler handler, int timeout) native;

  Object showModalDialog(String url, [Object dialogArgs = null, String featureArgs = null]) native;

  void stop() native;

  void webkitCancelAnimationFrame(int id) native;

  void webkitCancelRequestAnimationFrame(int id) native;

  _WebKitPointJs webkitConvertPointFromNodeToPage(_NodeJs node, _WebKitPointJs p) native;

  _WebKitPointJs webkitConvertPointFromPageToNode(_NodeJs node, _WebKitPointJs p) native;

  void webkitPostMessage(Dynamic message, String targetOrigin, [List transferList = null]) native;

  int webkitRequestAnimationFrame(RequestAnimationFrameCallback callback, _ElementJs element) native;

  void webkitRequestFileSystem(int type, int size, FileSystemCallback successCallback, [ErrorCallback errorCallback = null]) native;

  void webkitResolveLocalFileSystemURL(String url, [EntryCallback successCallback = null, ErrorCallback errorCallback = null]) native;
}
