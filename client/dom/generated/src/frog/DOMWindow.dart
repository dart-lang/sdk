
class DOMWindowJs extends DOMTypeJs implements DOMWindow native "@*DOMWindow" {

  static final int PERSISTENT = 1;

  static final int TEMPORARY = 0;

  DOMApplicationCacheJs get applicationCache() native "return this.applicationCache;";

  NavigatorJs get clientInformation() native "return this.clientInformation;";

  void set clientInformation(NavigatorJs value) native "this.clientInformation = value;";

  bool get closed() native "return this.closed;";

  ConsoleJs get console() native "return this.console;";

  void set console(ConsoleJs value) native "this.console = value;";

  CryptoJs get crypto() native "return this.crypto;";

  String get defaultStatus() native "return this.defaultStatus;";

  void set defaultStatus(String value) native "this.defaultStatus = value;";

  String get defaultstatus() native "return this.defaultstatus;";

  void set defaultstatus(String value) native "this.defaultstatus = value;";

  num get devicePixelRatio() native "return this.devicePixelRatio;";

  void set devicePixelRatio(num value) native "this.devicePixelRatio = value;";

  DocumentJs get document() native "return this.document;";

  EventJs get event() native "return this.event;";

  void set event(EventJs value) native "this.event = value;";

  ElementJs get frameElement() native "return this.frameElement;";

  DOMWindowJs get frames() native "return this.frames;";

  void set frames(DOMWindowJs value) native "this.frames = value;";

  HistoryJs get history() native "return this.history;";

  void set history(HistoryJs value) native "this.history = value;";

  int get innerHeight() native "return this.innerHeight;";

  void set innerHeight(int value) native "this.innerHeight = value;";

  int get innerWidth() native "return this.innerWidth;";

  void set innerWidth(int value) native "this.innerWidth = value;";

  int get length() native "return this.length;";

  void set length(int value) native "this.length = value;";

  StorageJs get localStorage() native "return this.localStorage;";

  LocationJs get location() native "return this.location;";

  void set location(LocationJs value) native "this.location = value;";

  BarInfoJs get locationbar() native "return this.locationbar;";

  void set locationbar(BarInfoJs value) native "this.locationbar = value;";

  BarInfoJs get menubar() native "return this.menubar;";

  void set menubar(BarInfoJs value) native "this.menubar = value;";

  String get name() native "return this.name;";

  void set name(String value) native "this.name = value;";

  NavigatorJs get navigator() native "return this.navigator;";

  void set navigator(NavigatorJs value) native "this.navigator = value;";

  bool get offscreenBuffering() native "return this.offscreenBuffering;";

  void set offscreenBuffering(bool value) native "this.offscreenBuffering = value;";

  DOMWindowJs get opener() native "return this.opener;";

  void set opener(DOMWindowJs value) native "this.opener = value;";

  int get outerHeight() native "return this.outerHeight;";

  void set outerHeight(int value) native "this.outerHeight = value;";

  int get outerWidth() native "return this.outerWidth;";

  void set outerWidth(int value) native "this.outerWidth = value;";

  int get pageXOffset() native "return this.pageXOffset;";

  int get pageYOffset() native "return this.pageYOffset;";

  DOMWindowJs get parent() native "return this.parent;";

  void set parent(DOMWindowJs value) native "this.parent = value;";

  PerformanceJs get performance() native "return this.performance;";

  void set performance(PerformanceJs value) native "this.performance = value;";

  BarInfoJs get personalbar() native "return this.personalbar;";

  void set personalbar(BarInfoJs value) native "this.personalbar = value;";

  ScreenJs get screen() native "return this.screen;";

  void set screen(ScreenJs value) native "this.screen = value;";

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

  BarInfoJs get scrollbars() native "return this.scrollbars;";

  void set scrollbars(BarInfoJs value) native "this.scrollbars = value;";

  DOMWindowJs get self() native "return this.self;";

  void set self(DOMWindowJs value) native "this.self = value;";

  StorageJs get sessionStorage() native "return this.sessionStorage;";

  String get status() native "return this.status;";

  void set status(String value) native "this.status = value;";

  BarInfoJs get statusbar() native "return this.statusbar;";

  void set statusbar(BarInfoJs value) native "this.statusbar = value;";

  StyleMediaJs get styleMedia() native "return this.styleMedia;";

  BarInfoJs get toolbar() native "return this.toolbar;";

  void set toolbar(BarInfoJs value) native "this.toolbar = value;";

  DOMWindowJs get top() native "return this.top;";

  void set top(DOMWindowJs value) native "this.top = value;";

  IDBFactoryJs get webkitIndexedDB() native "return this.webkitIndexedDB;";

  NotificationCenterJs get webkitNotifications() native "return this.webkitNotifications;";

  StorageInfoJs get webkitStorageInfo() native "return this.webkitStorageInfo;";

  DOMURLJs get webkitURL() native "return this.webkitURL;";

  DOMWindowJs get window() native "return this.window;";

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

  bool dispatchEvent(EventJs evt) native;

  bool find(String string, bool caseSensitive, bool backwards, bool wrap, bool wholeWord, bool searchInFrames, bool showDialog) native;

  void focus() native;

  CSSStyleDeclarationJs getComputedStyle(ElementJs element, String pseudoElement) native;

  CSSRuleListJs getMatchedCSSRules(ElementJs element, String pseudoElement) native;

  DOMSelectionJs getSelection() native;

  MediaQueryListJs matchMedia(String query) native;

  void moveBy(num x, num y) native;

  void moveTo(num x, num y) native;

  DOMWindowJs open(String url, String name, [String options = null]) native;

  DatabaseJs openDatabase(String name, String version, String displayName, int estimatedSize, [DatabaseCallback creationCallback = null]) native;

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

  WebKitPointJs webkitConvertPointFromNodeToPage(NodeJs node, WebKitPointJs p) native;

  WebKitPointJs webkitConvertPointFromPageToNode(NodeJs node, WebKitPointJs p) native;

  void webkitPostMessage(Dynamic message, String targetOrigin, [List transferList = null]) native;

  int webkitRequestAnimationFrame(RequestAnimationFrameCallback callback, ElementJs element) native;

  void webkitRequestFileSystem(int type, int size, FileSystemCallback successCallback, [ErrorCallback errorCallback = null]) native;

  void webkitResolveLocalFileSystemURL(String url, [EntryCallback successCallback = null, ErrorCallback errorCallback = null]) native;
}
