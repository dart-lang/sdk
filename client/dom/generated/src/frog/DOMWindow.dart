
class _DOMWindowJs extends _EventTargetJs implements DOMWindow native "@*DOMWindow" {

  static final int PERSISTENT = 1;

  static final int TEMPORARY = 0;

  final _DOMApplicationCacheJs applicationCache;

  final _NavigatorJs clientInformation;

  final bool closed;

  final _ConsoleJs console;

  final _CryptoJs crypto;

  String defaultStatus;

  String defaultstatus;

  final num devicePixelRatio;

  final _DocumentJs document;

  final _EventJs event;

  final _ElementJs frameElement;

  final _DOMWindowJs frames;

  final _HistoryJs history;

  final int innerHeight;

  final int innerWidth;

  final int length;

  final _StorageJs localStorage;

  _LocationJs location;

  final _BarInfoJs locationbar;

  final _BarInfoJs menubar;

  String name;

  final _NavigatorJs navigator;

  final bool offscreenBuffering;

  final _DOMWindowJs opener;

  final int outerHeight;

  final int outerWidth;

  final int pageXOffset;

  final int pageYOffset;

  final _DOMWindowJs parent;

  final _PerformanceJs performance;

  final _BarInfoJs personalbar;

  final _ScreenJs screen;

  final int screenLeft;

  final int screenTop;

  final int screenX;

  final int screenY;

  final int scrollX;

  final int scrollY;

  final _BarInfoJs scrollbars;

  final _DOMWindowJs self;

  final _StorageJs sessionStorage;

  String status;

  final _BarInfoJs statusbar;

  final _StyleMediaJs styleMedia;

  final _BarInfoJs toolbar;

  final _DOMWindowJs top;

  final _IDBFactoryJs webkitIndexedDB;

  final _NotificationCenterJs webkitNotifications;

  final _StorageInfoJs webkitStorageInfo;

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
