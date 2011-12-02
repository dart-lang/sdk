
class DOMWindow native "@*DOMWindow" {

  DOMApplicationCache applicationCache;

  Navigator clientInformation;

  bool closed;

  Console console;

  Crypto crypto;

  String defaultStatus;

  String defaultstatus;

  num devicePixelRatio;

  Document document;

  Event event;

  Element frameElement;

  DOMWindow frames;

  History history;

  int innerHeight;

  int innerWidth;

  int length;

  Storage localStorage;

  Location location;

  BarInfo locationbar;

  BarInfo menubar;

  String name;

  Navigator navigator;

  bool offscreenBuffering;

  DOMWindow opener;

  int outerHeight;

  int outerWidth;

  int pageXOffset;

  int pageYOffset;

  DOMWindow parent;

  Performance performance;

  BarInfo personalbar;

  Screen screen;

  int screenLeft;

  int screenTop;

  int screenX;

  int screenY;

  int scrollX;

  int scrollY;

  BarInfo scrollbars;

  DOMWindow self;

  Storage sessionStorage;

  String status;

  BarInfo statusbar;

  StyleMedia styleMedia;

  BarInfo toolbar;

  DOMWindow top;

  NotificationCenter webkitNotifications;

  DOMURL webkitURL;

  DOMWindow window;

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

  bool dispatchEvent(Event evt) native;

  bool find(String string, bool caseSensitive, bool backwards, bool wrap, bool wholeWord, bool searchInFrames, bool showDialog) native;

  void focus() native;

  CSSStyleDeclaration getComputedStyle(Element element, String pseudoElement) native;

  CSSRuleList getMatchedCSSRules(Element element, String pseudoElement) native;

  DOMSelection getSelection() native;

  MediaQueryList matchMedia(String query) native;

  void moveBy(num x, num y) native;

  void moveTo(num x, num y) native;

  DOMWindow open(String url, String name, [String options = null]) native;

  void postMessage(String message, var messagePorts_OR_targetOrigin, [String targetOrigin = null]) native;

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

  void webkitCancelRequestAnimationFrame(int id) native;

  WebKitPoint webkitConvertPointFromNodeToPage(Node node, WebKitPoint p) native;

  WebKitPoint webkitConvertPointFromPageToNode(Node node, WebKitPoint p) native;

  void webkitPostMessage(String message, var targetOrigin_OR_transferList, [String targetOrigin = null]) native;

  int webkitRequestAnimationFrame(RequestAnimationFrameCallback callback, Element element) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}
