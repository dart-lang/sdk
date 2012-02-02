
class _DOMWindowJs extends _DOMTypeJs implements DOMWindow native "@*DOMWindow" {

  static final int PERSISTENT = 1;

  static final int TEMPORARY = 0;

  _DOMApplicationCacheJs get applicationCache() native "return this.applicationCache;";

  _NavigatorJs get clientInformation() native "return this.clientInformation;";

  void set clientInformation(_NavigatorJs value) native "this.clientInformation = value;";

  bool get closed() native "return this.closed;";

  _ConsoleJs get console() native "return this.console;";

  void set console(_ConsoleJs value) native "this.console = value;";

  _CryptoJs get crypto() native "return this.crypto;";

  String get defaultStatus() native "return this.defaultStatus;";

  void set defaultStatus(String value) native "this.defaultStatus = value;";

  String get defaultstatus() native "return this.defaultstatus;";

  void set defaultstatus(String value) native "this.defaultstatus = value;";

  num get devicePixelRatio() native "return this.devicePixelRatio;";

  void set devicePixelRatio(num value) native "this.devicePixelRatio = value;";

  _DocumentJs get document() native "return this.document;";

  _EventJs get event() native "return this.event;";

  void set event(_EventJs value) native "this.event = value;";

  _ElementJs get frameElement() native "return this.frameElement;";

  _DOMWindowJs get frames() native "return this.frames;";

  void set frames(_DOMWindowJs value) native "this.frames = value;";

  _HistoryJs get history() native "return this.history;";

  void set history(_HistoryJs value) native "this.history = value;";

  int get innerHeight() native "return this.innerHeight;";

  void set innerHeight(int value) native "this.innerHeight = value;";

  int get innerWidth() native "return this.innerWidth;";

  void set innerWidth(int value) native "this.innerWidth = value;";

  int get length() native "return this.length;";

  void set length(int value) native "this.length = value;";

  _StorageJs get localStorage() native "return this.localStorage;";

  _LocationJs get location() native "return this.location;";

  void set location(_LocationJs value) native "this.location = value;";

  _BarInfoJs get locationbar() native "return this.locationbar;";

  void set locationbar(_BarInfoJs value) native "this.locationbar = value;";

  _BarInfoJs get menubar() native "return this.menubar;";

  void set menubar(_BarInfoJs value) native "this.menubar = value;";

  String get name() native "return this.name;";

  void set name(String value) native "this.name = value;";

  _NavigatorJs get navigator() native "return this.navigator;";

  void set navigator(_NavigatorJs value) native "this.navigator = value;";

  bool get offscreenBuffering() native "return this.offscreenBuffering;";

  void set offscreenBuffering(bool value) native "this.offscreenBuffering = value;";

  _DOMWindowJs get opener() native "return this.opener;";

  void set opener(_DOMWindowJs value) native "this.opener = value;";

  int get outerHeight() native "return this.outerHeight;";

  void set outerHeight(int value) native "this.outerHeight = value;";

  int get outerWidth() native "return this.outerWidth;";

  void set outerWidth(int value) native "this.outerWidth = value;";

  int get pageXOffset() native "return this.pageXOffset;";

  int get pageYOffset() native "return this.pageYOffset;";

  _DOMWindowJs get parent() native "return this.parent;";

  void set parent(_DOMWindowJs value) native "this.parent = value;";

  _PerformanceJs get performance() native "return this.performance;";

  void set performance(_PerformanceJs value) native "this.performance = value;";

  _BarInfoJs get personalbar() native "return this.personalbar;";

  void set personalbar(_BarInfoJs value) native "this.personalbar = value;";

  _ScreenJs get screen() native "return this.screen;";

  void set screen(_ScreenJs value) native "this.screen = value;";

  int get screenLeft() native "return this.screenLeft;";

  void set screenLeft(int value) native "this.screenLeft = value;";

  int get screenTop() native "return this.screenTop;";

  void set screenTop(int value) native "this.screenTop = value;";

  int get screenX() native "return this.screenX;";

  void set screenX(int value) native "this.screenX = value;";

  int get screenY() native "return this.screenY;";

  void set screenY(int value) native "this.screenY = value;";

  int get scrollX() native "return this.scrollX;";

  void set scrollX(int value) native "this.scrollX = value;";

  int get scrollY() native "return this.scrollY;";

  void set scrollY(int value) native "this.scrollY = value;";

  _BarInfoJs get scrollbars() native "return this.scrollbars;";

  void set scrollbars(_BarInfoJs value) native "this.scrollbars = value;";

  _DOMWindowJs get self() native "return this.self;";

  void set self(_DOMWindowJs value) native "this.self = value;";

  _StorageJs get sessionStorage() native "return this.sessionStorage;";

  String get status() native "return this.status;";

  void set status(String value) native "this.status = value;";

  _BarInfoJs get statusbar() native "return this.statusbar;";

  void set statusbar(_BarInfoJs value) native "this.statusbar = value;";

  _StyleMediaJs get styleMedia() native "return this.styleMedia;";

  _BarInfoJs get toolbar() native "return this.toolbar;";

  void set toolbar(_BarInfoJs value) native "this.toolbar = value;";

  _DOMWindowJs get top() native "return this.top;";

  void set top(_DOMWindowJs value) native "this.top = value;";

  _IDBFactoryJs get webkitIndexedDB() native "return this.webkitIndexedDB;";

  _NotificationCenterJs get webkitNotifications() native "return this.webkitNotifications;";

  _StorageInfoJs get webkitStorageInfo() native "return this.webkitStorageInfo;";

  _DOMURLJs get webkitURL() native "return this.webkitURL;";

  _DOMWindowJs get window() native "return this.window;";

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
