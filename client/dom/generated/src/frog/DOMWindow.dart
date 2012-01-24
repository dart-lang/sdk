
class DOMWindowJS implements DOMWindow native "@*DOMWindow" {

  static final int PERSISTENT = 1;

  static final int TEMPORARY = 0;

  DOMApplicationCacheJS get applicationCache() native "return this.applicationCache;";

  NavigatorJS get clientInformation() native "return this.clientInformation;";

  void set clientInformation(NavigatorJS value) native "this.clientInformation = value;";

  bool get closed() native "return this.closed;";

  ConsoleJS get console() native "return this.console;";

  void set console(ConsoleJS value) native "this.console = value;";

  CryptoJS get crypto() native "return this.crypto;";

  String get defaultStatus() native "return this.defaultStatus;";

  void set defaultStatus(String value) native "this.defaultStatus = value;";

  String get defaultstatus() native "return this.defaultstatus;";

  void set defaultstatus(String value) native "this.defaultstatus = value;";

  num get devicePixelRatio() native "return this.devicePixelRatio;";

  void set devicePixelRatio(num value) native "this.devicePixelRatio = value;";

  DocumentJS get document() native "return this.document;";

  EventJS get event() native "return this.event;";

  void set event(EventJS value) native "this.event = value;";

  ElementJS get frameElement() native "return this.frameElement;";

  DOMWindowJS get frames() native "return this.frames;";

  void set frames(DOMWindowJS value) native "this.frames = value;";

  HistoryJS get history() native "return this.history;";

  void set history(HistoryJS value) native "this.history = value;";

  int get innerHeight() native "return this.innerHeight;";

  void set innerHeight(int value) native "this.innerHeight = value;";

  int get innerWidth() native "return this.innerWidth;";

  void set innerWidth(int value) native "this.innerWidth = value;";

  int get length() native "return this.length;";

  void set length(int value) native "this.length = value;";

  StorageJS get localStorage() native "return this.localStorage;";

  LocationJS get location() native "return this.location;";

  void set location(LocationJS value) native "this.location = value;";

  BarInfoJS get locationbar() native "return this.locationbar;";

  void set locationbar(BarInfoJS value) native "this.locationbar = value;";

  BarInfoJS get menubar() native "return this.menubar;";

  void set menubar(BarInfoJS value) native "this.menubar = value;";

  String get name() native "return this.name;";

  void set name(String value) native "this.name = value;";

  NavigatorJS get navigator() native "return this.navigator;";

  void set navigator(NavigatorJS value) native "this.navigator = value;";

  bool get offscreenBuffering() native "return this.offscreenBuffering;";

  void set offscreenBuffering(bool value) native "this.offscreenBuffering = value;";

  DOMWindowJS get opener() native "return this.opener;";

  void set opener(DOMWindowJS value) native "this.opener = value;";

  int get outerHeight() native "return this.outerHeight;";

  void set outerHeight(int value) native "this.outerHeight = value;";

  int get outerWidth() native "return this.outerWidth;";

  void set outerWidth(int value) native "this.outerWidth = value;";

  int get pageXOffset() native "return this.pageXOffset;";

  int get pageYOffset() native "return this.pageYOffset;";

  DOMWindowJS get parent() native "return this.parent;";

  void set parent(DOMWindowJS value) native "this.parent = value;";

  PerformanceJS get performance() native "return this.performance;";

  void set performance(PerformanceJS value) native "this.performance = value;";

  BarInfoJS get personalbar() native "return this.personalbar;";

  void set personalbar(BarInfoJS value) native "this.personalbar = value;";

  ScreenJS get screen() native "return this.screen;";

  void set screen(ScreenJS value) native "this.screen = value;";

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

  BarInfoJS get scrollbars() native "return this.scrollbars;";

  void set scrollbars(BarInfoJS value) native "this.scrollbars = value;";

  DOMWindowJS get self() native "return this.self;";

  void set self(DOMWindowJS value) native "this.self = value;";

  StorageJS get sessionStorage() native "return this.sessionStorage;";

  String get status() native "return this.status;";

  void set status(String value) native "this.status = value;";

  BarInfoJS get statusbar() native "return this.statusbar;";

  void set statusbar(BarInfoJS value) native "this.statusbar = value;";

  StyleMediaJS get styleMedia() native "return this.styleMedia;";

  BarInfoJS get toolbar() native "return this.toolbar;";

  void set toolbar(BarInfoJS value) native "this.toolbar = value;";

  DOMWindowJS get top() native "return this.top;";

  void set top(DOMWindowJS value) native "this.top = value;";

  IDBFactoryJS get webkitIndexedDB() native "return this.webkitIndexedDB;";

  NotificationCenterJS get webkitNotifications() native "return this.webkitNotifications;";

  StorageInfoJS get webkitStorageInfo() native "return this.webkitStorageInfo;";

  DOMURLJS get webkitURL() native "return this.webkitURL;";

  DOMWindowJS get window() native "return this.window;";

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

  bool dispatchEvent(EventJS evt) native;

  bool find(String string, bool caseSensitive, bool backwards, bool wrap, bool wholeWord, bool searchInFrames, bool showDialog) native;

  void focus() native;

  CSSStyleDeclarationJS getComputedStyle(ElementJS element, String pseudoElement) native;

  CSSRuleListJS getMatchedCSSRules(ElementJS element, String pseudoElement) native;

  DOMSelectionJS getSelection() native;

  MediaQueryListJS matchMedia(String query) native;

  void moveBy(num x, num y) native;

  void moveTo(num x, num y) native;

  DOMWindowJS open(String url, String name, [String options = null]) native;

  void postMessage(String message, String targetOrigin, [List messagePorts = null]) native;

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

  WebKitPointJS webkitConvertPointFromNodeToPage(NodeJS node, WebKitPointJS p) native;

  WebKitPointJS webkitConvertPointFromPageToNode(NodeJS node, WebKitPointJS p) native;

  void webkitPostMessage(String message, String targetOrigin, [List transferList = null]) native;

  int webkitRequestAnimationFrame(RequestAnimationFrameCallback callback, ElementJS element) native;

  void webkitRequestFileSystem(int type, int size, FileSystemCallback successCallback, [ErrorCallback errorCallback = null]) native;

  void webkitResolveLocalFileSystemURL(String url, [EntryCallback successCallback = null, ErrorCallback errorCallback = null]) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}
