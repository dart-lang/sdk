#import ("dart:html");
#import ("dart:htmlimpl");
#import ("dart:dom", prefix:"dom");
#import ("dart:json");

// Workaround for HTML lib missing feature.
Range newRange() {
  return LevelDom.wrapRange(dom.document.createRange());
}

// Temporary range object to optimize performance computing client rects
// from text nodes.
Range _tempRange;
// Hacks because ASYNC measurement is annoying when just writing a script.
ClientRect getClientRect(Node n) {
  if (n is Element) {
    Element e = n;
    dom.Element raw = unwrapDomObject(e.dynamic);
    return LevelDom.wrapClientRect(raw.getBoundingClientRect());
  } else {
    // Crazy hacks that works for nodes.... create a range and measure it.
    if (_tempRange == null) {
      _tempRange = newRange();
    }
    _tempRange.setStartBefore(n);
    _tempRange.setEndAfter(n);
     return _tempRange.getBoundingClientRect();
  }
}

final DART_REMOVED = "dart_removed";

final DEBUG_CSS = """
<style type="text/css">
  .dart_removed {
    background-color: rgba(255, 0, 0, 0.5);
   }
</style>""";

final MIN_PIXELS_DIFFERENT_LINES = 10;

final IDL_SELECTOR = "pre.eval, pre.idl";

Map data;

// TODO(rnystrom): Hack! Copied from domTypes.json. Instead of hard-coding
// these, should use the same mapping that the DOM/HTML code generators use.
var domTypes;
final domTypesRaw = const [
  "AbstractWorker", "ArrayBuffer", "ArrayBufferView", "Attr",
  "AudioBuffer", "AudioBufferSourceNode", "AudioChannelMerger",
  "AudioChannelSplitter", "AudioContext", "AudioDestinationNode",
  "AudioGain", "AudioGainNode", "AudioListener", "AudioNode",
  "AudioPannerNode", "AudioParam", "AudioProcessingEvent",
  "AudioSourceNode", "BarInfo", "BeforeLoadEvent", "BiquadFilterNode",
  "Blob", "CDATASection", "CSSCharsetRule", "CSSFontFaceRule",
  "CSSImportRule", "CSSMediaRule", "CSSPageRule", "CSSPrimitiveValue",
  "CSSRule", "CSSRuleList", "CSSStyleDeclaration", "CSSStyleRule",
  "CSSStyleSheet", "CSSUnknownRule", "CSSValue", "CSSValueList",
  "CanvasGradient", "CanvasPattern", "CanvasPixelArray",
  "CanvasRenderingContext", "CanvasRenderingContext2D",
  "CharacterData", "ClientRect", "ClientRectList", "Clipboard",
  "CloseEvent", "Comment", "CompositionEvent", "Console",
  "ConvolverNode", "Coordinates", "Counter", "Crypto", "CustomEvent",
  "DOMApplicationCache", "DOMException", "DOMFileSystem",
  "DOMFileSystemSync", "DOMFormData", "DOMImplementation",
  "DOMMimeType", "DOMMimeTypeArray", "DOMParser", "DOMPlugin",
  "DOMPluginArray", "DOMSelection", "DOMSettableTokenList",
  "DOMTokenList", "DOMURL", "DOMWindow", "DataTransferItem",
  "DataTransferItemList", "DataView", "Database", "DatabaseSync",
  "DedicatedWorkerContext", "DelayNode", "DeviceMotionEvent",
  "DeviceOrientationEvent", "DirectoryEntry", "DirectoryEntrySync",
  "DirectoryReader", "DirectoryReaderSync", "Document",
  "DocumentFragment", "DocumentType", "DynamicsCompressorNode",
  "Element", "ElementTimeControl", "ElementTraversal", "Entity",
  "EntityReference", "Entry", "EntryArray", "EntryArraySync",
  "EntrySync", "ErrorEvent", "Event", "EventException", "EventSource",
  "EventTarget", "File", "FileEntry", "FileEntrySync", "FileError",
  "FileException", "FileList", "FileReader", "FileReaderSync",
  "FileWriter", "FileWriterSync", "Float32Array", "Float64Array",
  "Geolocation", "Geoposition", "HTMLAllCollection",
  "HTMLAnchorElement", "HTMLAppletElement", "HTMLAreaElement",
  "HTMLAudioElement", "HTMLBRElement", "HTMLBaseElement",
  "HTMLBaseFontElement", "HTMLBodyElement", "HTMLButtonElement",
  "HTMLCanvasElement", "HTMLCollection", "HTMLDListElement",
  "HTMLDataListElement", "HTMLDetailsElement", "HTMLDirectoryElement",
  "HTMLDivElement", "HTMLDocument", "HTMLElement", "HTMLEmbedElement",
  "HTMLFieldSetElement", "HTMLFontElement", "HTMLFormElement",
  "HTMLFrameElement", "HTMLFrameSetElement", "HTMLHRElement",
  "HTMLHeadElement", "HTMLHeadingElement", "HTMLHtmlElement",
  "HTMLIFrameElement", "HTMLImageElement", "HTMLInputElement",
  "HTMLIsIndexElement", "HTMLKeygenElement", "HTMLLIElement",
  "HTMLLabelElement", "HTMLLegendElement", "HTMLLinkElement",
  "HTMLMapElement", "HTMLMarqueeElement", "HTMLMediaElement",
  "HTMLMenuElement", "HTMLMetaElement", "HTMLMeterElement",
  "HTMLModElement", "HTMLOListElement", "HTMLObjectElement",
  "HTMLOptGroupElement", "HTMLOptionElement", "HTMLOptionsCollection",
  "HTMLOutputElement", "HTMLParagraphElement", "HTMLParamElement",
  "HTMLPreElement", "HTMLProgressElement", "HTMLQuoteElement",
  "HTMLScriptElement", "HTMLSelectElement", "HTMLSourceElement",
  "HTMLSpanElement", "HTMLStyleElement", "HTMLTableCaptionElement",
  "HTMLTableCellElement", "HTMLTableColElement", "HTMLTableElement",
  "HTMLTableRowElement", "HTMLTableSectionElement",
  "HTMLTextAreaElement", "HTMLTitleElement", "HTMLTrackElement",
  "HTMLUListElement", "HTMLUnknownElement", "HTMLVideoElement",
  "HashChangeEvent", "HighPass2FilterNode", "History", "IDBAny",
  "IDBCursor", "IDBCursorWithValue", "IDBDatabase",
  "IDBDatabaseError", "IDBDatabaseException", "IDBFactory",
  "IDBIndex", "IDBKey", "IDBKeyRange", "IDBObjectStore", "IDBRequest",
  "IDBTransaction", "IDBVersionChangeEvent",
  "IDBVersionChangeRequest", "ImageData", "InjectedScriptHost",
  "InspectorFrontendHost", "Int16Array", "Int32Array", "Int8Array",
  "JavaScriptAudioNode", "JavaScriptCallFrame", "KeyboardEvent",
  "Location", "LowPass2FilterNode", "MediaElementAudioSourceNode",
  "MediaError", "MediaList", "MediaQueryList",
  "MediaQueryListListener", "MemoryInfo", "MessageChannel",
  "MessageEvent", "MessagePort", "Metadata", "MouseEvent",
  "MutationCallback", "MutationEvent", "MutationRecord",
  "NamedNodeMap", "Navigator", "NavigatorUserMediaError",
  "NavigatorUserMediaSuccessCallback", "Node", "NodeFilter",
  "NodeIterator", "NodeList", "NodeSelector", "Notation",
  "Notification", "NotificationCenter", "OESStandardDerivatives",
  "OESTextureFloat", "OESVertexArrayObject",
  "OfflineAudioCompletionEvent", "OperationNotAllowedException",
  "OverflowEvent", "PageTransitionEvent", "Performance",
  "PerformanceNavigation", "PerformanceTiming", "PopStateEvent",
  "PositionError", "ProcessingInstruction", "ProgressEvent",
  "RGBColor", "Range", "RangeException", "RealtimeAnalyserNode",
  "Rect", "SQLError", "SQLException", "SQLResultSet",
  "SQLResultSetRowList", "SQLTransaction", "SQLTransactionSync",
  "SVGAElement", "SVGAltGlyphDefElement", "SVGAltGlyphElement",
  "SVGAltGlyphItemElement", "SVGAngle", "SVGAnimateColorElement",
  "SVGAnimateElement", "SVGAnimateMotionElement",
  "SVGAnimateTransformElement", "SVGAnimatedAngle",
  "SVGAnimatedBoolean", "SVGAnimatedEnumeration",
  "SVGAnimatedInteger", "SVGAnimatedLength", "SVGAnimatedLengthList",
  "SVGAnimatedNumber", "SVGAnimatedNumberList",
  "SVGAnimatedPreserveAspectRatio", "SVGAnimatedRect",
  "SVGAnimatedString", "SVGAnimatedTransformList",
  "SVGAnimationElement", "SVGCircleElement", "SVGClipPathElement",
  "SVGColor", "SVGComponentTransferFunctionElement",
  "SVGCursorElement", "SVGDefsElement", "SVGDescElement",
  "SVGDocument", "SVGElement", "SVGElementInstance",
  "SVGElementInstanceList", "SVGEllipseElement", "SVGException",
  "SVGExternalResourcesRequired", "SVGFEBlendElement",
  "SVGFEColorMatrixElement", "SVGFEComponentTransferElement",
  "SVGFECompositeElement", "SVGFEConvolveMatrixElement",
  "SVGFEDiffuseLightingElement", "SVGFEDisplacementMapElement",
  "SVGFEDistantLightElement", "SVGFEDropShadowElement",
  "SVGFEFloodElement", "SVGFEFuncAElement", "SVGFEFuncBElement",
  "SVGFEFuncGElement", "SVGFEFuncRElement",
  "SVGFEGaussianBlurElement", "SVGFEImageElement",
  "SVGFEMergeElement", "SVGFEMergeNodeElement",
  "SVGFEMorphologyElement", "SVGFEOffsetElement",
  "SVGFEPointLightElement", "SVGFESpecularLightingElement",
  "SVGFESpotLightElement", "SVGFETileElement",
  "SVGFETurbulenceElement", "SVGFilterElement",
  "SVGFilterPrimitiveStandardAttributes", "SVGFitToViewBox",
  "SVGFontElement", "SVGFontFaceElement", "SVGFontFaceFormatElement",
  "SVGFontFaceNameElement", "SVGFontFaceSrcElement",
  "SVGFontFaceUriElement", "SVGForeignObjectElement", "SVGGElement",
  "SVGGlyphElement", "SVGGlyphRefElement", "SVGGradientElement",
  "SVGHKernElement", "SVGImageElement", "SVGLangSpace", "SVGLength",
  "SVGLengthList", "SVGLineElement", "SVGLinearGradientElement",
  "SVGLocatable", "SVGMPathElement", "SVGMarkerElement",
  "SVGMaskElement", "SVGMatrix", "SVGMetadataElement",
  "SVGMissingGlyphElement", "SVGNumber", "SVGNumberList", "SVGPaint",
  "SVGPathElement", "SVGPathSeg", "SVGPathSegArcAbs",
  "SVGPathSegArcRel", "SVGPathSegClosePath",
  "SVGPathSegCurvetoCubicAbs", "SVGPathSegCurvetoCubicRel",
  "SVGPathSegCurvetoCubicSmoothAbs",
  "SVGPathSegCurvetoCubicSmoothRel", "SVGPathSegCurvetoQuadraticAbs",
  "SVGPathSegCurvetoQuadraticRel",
  "SVGPathSegCurvetoQuadraticSmoothAbs",
  "SVGPathSegCurvetoQuadraticSmoothRel", "SVGPathSegLinetoAbs",
  "SVGPathSegLinetoHorizontalAbs", "SVGPathSegLinetoHorizontalRel",
  "SVGPathSegLinetoRel", "SVGPathSegLinetoVerticalAbs",
  "SVGPathSegLinetoVerticalRel", "SVGPathSegList",
  "SVGPathSegMovetoAbs", "SVGPathSegMovetoRel", "SVGPatternElement",
  "SVGPoint", "SVGPointList", "SVGPolygonElement",
  "SVGPolylineElement", "SVGPreserveAspectRatio",
  "SVGRadialGradientElement", "SVGRect", "SVGRectElement",
  "SVGRenderingIntent", "SVGSVGElement", "SVGScriptElement",
  "SVGSetElement", "SVGStopElement", "SVGStringList", "SVGStylable",
  "SVGStyleElement", "SVGSwitchElement", "SVGSymbolElement",
  "SVGTRefElement", "SVGTSpanElement", "SVGTests",
  "SVGTextContentElement", "SVGTextElement", "SVGTextPathElement",
  "SVGTextPositioningElement", "SVGTitleElement", "SVGTransform",
  "SVGTransformList", "SVGTransformable", "SVGURIReference",
  "SVGUnitTypes", "SVGUseElement", "SVGVKernElement",
  "SVGViewElement", "SVGViewSpec", "SVGZoomAndPan", "SVGZoomEvent",
  "Screen", "ScriptProfile", "ScriptProfileNode", "SharedWorker",
  "SharedWorkercontext", "SpeechInputEvent", "SpeechInputResult",
  "SpeechInputResultList", "Storage", "StorageEvent", "StorageInfo",
  "StyleMedia", "StyleSheet", "StyleSheetList", "Text", "TextEvent",
  "TextMetrics", "TextTrack", "TextTrackCue", "TextTrackCueList",
  "TimeRanges", "Touch", "TouchEvent", "TouchList", "TreeWalker",
  "UIEvent", "Uint16Array", "Uint32Array", "Uint8Array",
  "ValidityState", "VoidCallback", "WaveShaperNode",
  "WebGLActiveInfo", "WebGLBuffer", "WebGLContextAttributes",
  "WebGLContextEvent", "WebGLDebugRendererInfo", "WebGLDebugShaders",
  "WebGLFramebuffer", "WebGLProgram", "WebGLRenderbuffer",
  "WebGLRenderingContext", "WebGLShader", "WebGLTexture",
  "WebGLUniformLocation", "WebGLVertexArrayObjectOES",
  "WebKitAnimation", "WebKitAnimationEvent", "WebKitAnimationList",
  "WebKitBlobBuilder", "WebKitCSSFilterValue",
  "WebKitCSSKeyframeRule", "WebKitCSSKeyframesRule",
  "WebKitCSSMatrix", "WebKitCSSTransformValue", "WebKitFlags",
  "WebKitLoseContext", "WebKitMutationObserver", "WebKitPoint",
  "WebKitTransitionEvent", "WebSocket", "WheelEvent", "Worker",
  "WorkerContext", "WorkerLocation", "WorkerNavigator",
  "XMLHttpRequest", "XMLHttpRequestException",
  "XMLHttpRequestProgressEvent", "XMLHttpRequestUpload",
  "XMLSerializer", "XPathEvaluator", "XPathException",
  "XPathExpression", "XPathNSResolver", "XPathResult",
  "XSLTProcessor", "AudioBufferCallback", "DatabaseCallback",
  "EntriesCallback", "EntryCallback", "ErrorCallback", "FileCallback",
  "FileSystemCallback", "FileWriterCallback", "MetadataCallback",
  "NavigatorUserMediaErrorCallback", "PositionCallback",
  "PositionErrorCallback", "SQLStatementCallback",
  "SQLStatementErrorCallback", "SQLTransactionCallback",
  "SQLTransactionErrorCallback", "SQLTransactionSyncCallback",
  "StorageInfoErrorCallback", "StorageInfoQuotaCallback",
  "StorageInfoUsageCallback", "StringCallback"
];

Map dbEntry;

Map get dartIdl() => data['dartIdl'];
String get currentType() => data['type'];

String _currentTypeShort;
String get currentTypeShort() {
  if (_currentTypeShort == null) {
    _currentTypeShort = currentType;
    _currentTypeShort = trimPrefix(_currentTypeShort, "HTML");
    _currentTypeShort = trimPrefix(_currentTypeShort, "SVG");
    _currentTypeShort = trimPrefix(_currentTypeShort, "DOM");
    _currentTypeShort = trimPrefix(_currentTypeShort, "WebKit");
    _currentTypeShort = trimPrefix(_currentTypeShort, "Webkit");
  }
  return _currentTypeShort;
}

String _currentTypeTiny;
String get currentTypeTiny() {
  if (_currentTypeTiny == null) {
    _currentTypeTiny = currentTypeShort;
    _currentTypeTiny = trimEnd(_currentTypeTiny, "Element");
  }
  return _currentTypeTiny;
}

Map get searchResult() => data['searchResult'];
String get pageUrl() => searchResult['link'];

String _pageDomain;
String get pageDomain() {
  if (_pageDomain == null) {
    _pageDomain = pageUrl.substring(0, pageUrl.indexOf("/", "https://".length));
  }
  return _pageDomain;
}

String get pageDir() {
  return pageUrl.substring(0, pageUrl.lastIndexOf('/') + 1);
}

String getAbsoluteUrl(AnchorElement anchor) {
  if (anchor == null || anchor.href.length == 0) return '';
  String path = anchor.href;
  RegExp fullUrlRegExp = new RegExp("^https?://");
  if (fullUrlRegExp.hasMatch(path)) return path;
  if (path.startsWith('/')) {
    return "$pageDomain$path";
  } else if (path.startsWith("#")) {
    return "$pageUrl$path";
  } else {
    return "$pageDir$path";
  }
}

bool inTable(Node n) {
  while(n != null) {
    if (n is TableElement) return true;
    n = n.parent;
  }
  return false;
}

String escapeHTML(str) {
  Element e = new Element.tag("div");
  e.text = str;
  return e.innerHTML;
}

List<Text> getAllTextNodes(Element elem) {
  List<Text> nodes = <Text>[];
  helper(Node n) {
    if (n is Text) {
      nodes.add(n);
    } else {
      for (Node child in n.nodes) {
        helper(child);
      }
    }
  };

  helper(elem);
  return nodes;
}

/**
 * Whether a node and its children are all types that are safe to skip if the
 * nodes have no text content.
 */
bool isSkippableType(Node n) {
  // TODO(jacobr): are there any types we don't want to skip even if they
  // have no text content?
  if (n is ImageElement || n is CanvasElement || n is InputElement
      || n is ObjectElement) {
    return false;
  }
  if (n is Text) return true;

  for (Node child in n.nodes) {
    if (isSkippableType(child) == false) {
      return false;
    }
  }
  return true;
}

bool isSkippable(Node n) {
  if (!isSkippableType(n)) return false;
  return n.text.trim().length == 0;
}

void onEnd() {
  // Hideous hack to send JSON back to JS.
  String dbJson = JSON.stringify(dbEntry);
  // workaround bug in JSON parser.
  dbJson = dbJson.replaceAll("ZDARTIUMDOESNTESCAPESLASHNJXXXX", "\\n");

  window.postMessage("START_DART_MESSAGE_UNIQUE_IDENTIFIER$dbJson", "*");
}

class SectionParseResult {
  final String html;
  final String url;
  final String idl;
  SectionParseResult(this.html, this.url, this.idl);
}

String genCleanHtml(Element root) {
  for (Element e in root.queryAll(".$DART_REMOVED")) {
    e.classes.remove(DART_REMOVED);
  }

  // Ditch inline styles.
  for (Element e in root.queryAll('[style]')) {
    e.attributes.remove('style');
  }

  // These elements are just tags that we should suppress.
  for (Element e in root.queryAll(".lang.lang-en")) {
    e.remove();
  }

  bool changed = true;
  while (changed) {
    changed = false;
    while (root.nodes.length == 1) {
      Node child = root.nodes.first;
      if (child is Element) {
        root = child;
        changed = true;
      } else {
        // Just calling innerHTML on the parent will be sufficient...
        // and insures the output is properly escaped.
        break;
      }
    }

    // Trim useless nodes from the front.
    while(root.nodes.length > 0 &&
        isSkippable(root.nodes.first)) {
      root.nodes.first.remove();
      changed = true;
    }

    // Trim useless nodes from the back.
    while(root.nodes.length > 0 &&
        isSkippable(root.nodes.last())) {
      root.nodes.last().remove();
      changed = true;
    }
  }
  return JSONFIXUPHACK(root.innerHTML);
}

String genPrettyHtml(DocumentFragment fragment) {
  return genCleanHtml(fragment);
}

String genPrettyHtmlFromElement(Element e) {
  e = e.clone(true);
  return genCleanHtml(e);
}

class PostOrderTraversalIterator implements Iterator<Node> {

  Node _next;

  PostOrderTraversalIterator(Node start) {
    _next = _leftMostDescendent(start);
  }

  bool hasNext() => _next != null;

  Node next() {
    if (_next == null) return null;
    Node ret = _next;
    if (_next.nextNode != null) {
      _next = _leftMostDescendent(_next.nextNode);
    } else {
      _next = _next.parent;
    }
    return ret;
  }

  static Node _leftMostDescendent(Node n) {
    while (n.nodes.length > 0) {
      n = n.nodes.first;
    }
    return n;
  }
}

class PostOrderTraversal implements Iterable<Node> {
  final Node _node;
  PostOrderTraversal(this._node);

  Iterator<Node> iterator() => new PostOrderTraversalIterator(_node);
}

Range findFirstLine(Range section, String prop) {
  Range firstLine = newRange();
  firstLine.setStart(section.startContainer, section.startOffset);

  num maxBottom = null;
  for (Node n in new PostOrderTraversal(section.startContainer)) {
    int compareResult = section.comparePoint(n, 0);
    if (compareResult == -1) {
      // before range so skip.
      continue;
    } else if (compareResult > 0) {
      // After range so exit.
      break;
    }

    final rect = getClientRect(n);
    num bottom = rect.bottom;
    if (rect.height > 0 && rect.width > 0) {
      if (maxBottom != null && (
        maxBottom + MIN_PIXELS_DIFFERENT_LINES < bottom
        )) {
        break;
      } else if (maxBottom == null || maxBottom > bottom) {
        maxBottom = bottom;
      }
    }

    firstLine.setEndAfter(n);
  }

  if (firstLine.toString().indexOf(stripWebkit(prop)) == -1) {
    return null;
  }
  return firstLine;
}

AnchorElement findAnchorElement(Element root, String prop) {
  for (AnchorElement a in root.queryAll("a")) {
    if (a.text.indexOf(prop) != -1) {
      return a;
    }
  }
  return null;
}

// First surrounding element with an ID is safe enough.
Element findTigherRoot(Element elem, Element root) {
  Element candidate = elem;
  while(root != candidate) {
    candidate = candidate.parent;
    if (candidate.id.length > 0 && candidate.id.indexOf("section_") != 0) {
      break;
    }
  }
  return candidate;
}

// this is very slow and ugly.. consider rewriting.
SectionParseResult filteredHtml(Element elem, Element root, String prop,
    Function fragmentGeneratedCallback) {
  // Using a tighter root avoids false positives at the risk of trimming
  // text we shouldn't.
  root = findTigherRoot(elem, root);
  Range range = newRange();
  range.setStartBefore(elem);

  Element current = elem;
  while (current != null) {
    range.setEndBefore(current);
    if (current.classes.contains(DART_REMOVED)) {
      if (range.toString().trim().length > 0) {
        break;
      }
    }
    if (current.firstElementChild != null) {
      current = current.firstElementChild;
    } else {
      while (current != null) {
        range.setEndAfter(current);
        if (current == root) {
          current = null;
          break;
        }
        if (current.nextElementSibling != null) {
          current = current.nextElementSibling;
          break;
        }
        current = current.parent;
      }
    }
  }
  String url = null;
  if (prop != null) {
    Range firstLine = findFirstLine(range, prop);
    if (firstLine != null) {
      range.setStart(firstLine.endContainer, firstLine.endOffset);
      DocumentFragment firstLineClone = firstLine.cloneContents();
      AnchorElement anchor = findAnchorElement(firstLineClone, prop);
      if (anchor != null) {
        url = getAbsoluteUrl(anchor);
      }
    }
  }
  DocumentFragment fragment = range.cloneContents();
  if (fragmentGeneratedCallback != null) {
    fragmentGeneratedCallback(fragment);
  }
  // Strip tags we don't want
  for (Element e in fragment.queryAll("script, object, style")) {
    e.remove();
  }

  // Extract idl
  StringBuffer idl = new StringBuffer();
  if (prop != null && prop.length > 0) {
    // Only expect properties to have HTML.
    for(Element e in fragment.queryAll(IDL_SELECTOR)) {
      idl.add(e.outerHTML);
      e.remove();
    }
    // TODO(jacobr) this is a very basic regex to see if text looks like IDL
    RegExp likelyIdl = new RegExp(" $prop\\w*\\(");

    for (Element e in fragment.queryAll("pre")) {
      // Check if it looks like idl...
      String txt = e.text.trim();
      if (likelyIdl.hasMatch(txt) && txt.indexOf("\n") != -1
          && txt.indexOf(")") != -1) {
        idl.add(e.outerHTML);
        e.remove();
      }
    }
  }
  return new SectionParseResult(genPrettyHtml(fragment), url, idl.toString());
}

Element findBest(Element root, List<Text> allText, String prop, String propType) {
  // Best bet: match an id
  Element cand;
  cand = root.query("#" + prop);

  if (cand == null && propType == "methods") {
    cand = root.query("[id=" + prop + "\\(\\)]");
  }
  if (cand != null) {
    while (cand != null && cand.text.trim().length == 0) {
      // We found the bookmark for the element but sadly it is just an empty
      // placeholder. Find the first real element.
      cand = cand.nextElementSibling;
    }
    if (cand != null) {
      return cand;
    }
  }

  // If you are at least 70 pixels from the left, something is definitely fishy and we shouldn't even consider this candidate.
  num candLeft = 70;

  for (Text text in allText) {
    Element proposed = null;

//    var t = safeNameCleanup(text.text);
// TODO(jacobr): does it hurt precision to use the full cleanup?
    String t = fullNameCleanup(text.text);
    if (t == prop) {
      proposed = text.parent;
      ClientRect candRect = getClientRect(proposed);

      // TODO(jacobr): this is a good heuristic
      // if (selObj.selector.indexOf(" > DD ") == -1
      if (candRect.left < candLeft) {
        cand = proposed;
        candLeft = candRect.left;
      }
    }
  }
  return cand;
}

bool isObsolete(Element e) {
  RegExp obsoleteRegExp = new RegExp(@"(^|\s)obsolete(?=\s|$)");
  RegExp deprecatedRegExp = new RegExp(@"(^|\s)deprecated(?=\s|$)");
  for (Element child in e.queryAll("span")) {
    String t = child.text.toLowerCase();
    if (t.startsWith("obsolete") || t.startsWith("deprecated")) return true;
  }

  String text = e.text.toLowerCase();
  return obsoleteRegExp.hasMatch(text) || deprecatedRegExp.hasMatch(text);
}

bool isFirstCharLowerCase(String str) {
  RegExp firstLower = new RegExp("^[a-z]");
  return firstLower.hasMatch(str);
}

void scrapeSection(Element root, String sectionSelector,
                   String currentType,
                   List members,
                   String propType) {
  Map expectedProps = dartIdl[propType];

  Set<String> alreadyMatchedProperties = new Set<String>();
  bool onlyConsiderTables = false;
  ElementList allMatches = root.queryAll(sectionSelector);
  if (allMatches.length == 0) {
    allMatches = root.queryAll(".fullwidth-table");
    onlyConsiderTables = true;
  }
  for (Element matchElement in allMatches) {
    DivElement match = matchElement.parent;
    if (!match.id.startsWith("section") && !(match.id == "pageText")) {
      throw "Enexpected element $match";
    }
    match.classes.add(DART_REMOVED);

    bool foundProps = false;

    // TODO(jacobr): we should really look for the table tag instead
    // add an assert if we are missing something that is a table...
    // TODO(jacobr) ignore tables in tables....
    for (Element t in match.queryAll('.standard-table, .fullwidth-table')) {
      int helpIndex = -1;
      num i = 0;
      for (Element r in t.queryAll("th, td.header")) {
        var txt = r.text.trim().split(" ")[0].toLowerCase();
        if (txt == "description") {
          helpIndex = i;
          break;
        }
        i++;
      }

      List<int> numMatches = new List<int>(i);
      for (int j = 0; j < i; j++) {
        numMatches[j] = 0;
      }

      // Find the row that seems to have the most names that look like
      // expected properties.
      for (Element r in t.queryAll("tbody tr")) {
        ElementList $row = r.elements;
        if ($row.length == 0 || $row.first.classes.contains(".header")) {
          continue;
        }

        for (int k = 0; k < numMatches.length && k < $row.length; k++) {
          Element e = $row[k];
          if (expectedProps.containsKey(fullNameCleanup(e.text))) {
            numMatches[k]++;
            break;
          }
        }
      }

      int propNameIndex = 0;
      {
        int bestCount = numMatches[0];
        for (int k = 1; k < numMatches.length; k++) {
          if (numMatches[k] > bestCount) {
            bestCount = numMatches[k];
            propNameIndex = k;
          }
        }
      }

      for (Element r in t.queryAll("tbody tr")) {
        ElementList $row = r.elements;
        if ($row.length > propNameIndex && $row.length > helpIndex ) {
          if ($row.first.classes.contains(".header")) {
            continue;
          }
          // TODO(jacobr): this code for determining the namestr is needlessly
          // messy.
          Element nameRow = $row[propNameIndex];
          AnchorElement a = nameRow.query("a");
          String goodName = '';
          if (a != null) {
            goodName = a.text.trim();
          }
          String nameStr = nameRow.text;

          Map entry = new Map<String, String>();

  //        "currentType": $($row[1]).text().trim(), // find("code") ?
          entry["name"] = fullNameCleanup(nameStr.length > 0 ? nameStr : goodName);

          final parse = filteredHtml(nameRow, nameRow, entry["name"], null);
          String altHelp = parse.html;

         // "jsSignature": nameStr,
          entry["help"] = (helpIndex == -1 || $row[helpIndex] == null) ? altHelp : genPrettyHtmlFromElement($row[helpIndex]);
        //  "altHelp" : altHelp,
          if (parse.url != null) {
            entry["url"] = parse.url;
          }

          if (parse.idl.length > 0) {
            entry["idl"] = parse.idl;
          }

          entry["obsolete"] = isObsolete(r);

          if (entry["name"].length > 0) {
            cleanupEntry(members, entry);
            alreadyMatchedProperties.add(entry['name']);
            foundProps = true;
          }
        }
      }
    }

    if (onlyConsiderTables) {
      continue;
    }
    // After this point we have higher risk tests that attempt to perform
    // rudimentary page segmentation.

    // Search for expected matching names.
    List<Text> allText = getAllTextNodes(match);

    Map<String, Element> pmap = new Map<String, Element>();
    for (String prop in expectedProps.getKeys()) {
      if (alreadyMatchedProperties.contains(prop)) {
        continue;
      }
      Element e = findBest(match, allText, prop, propType);
      if (e != null && !inTable(e)) {
        pmap[prop] = e;
      }
    }

    for (String prop in pmap.getKeys()) {
      Element e = pmap[prop];
      e.classes.add(DART_REMOVED);
    }

    for (String prop in pmap.getKeys()) {
      Element e = pmap[prop];
      ClientRect r = getClientRect(e);
      // TODO(jacobr): a lot of these queries are identical.
      for (Element cand in match.queryAll(e.tagName)) {
        if (!cand.classes.contains(DART_REMOVED) && !inTable(cand) ) { // XXX use a neg selector.
          ClientRect candRect = getClientRect(cand);
          // TODO(jacobr): this is somewhat loose.
          if (candRect.left == r.left &&
            (candRect.height - r.height).abs() < 5) {
            String propName = fullNameCleanup(cand.text);
            if (isFirstCharLowerCase(propName) && pmap.containsKey(propName) == false && alreadyMatchedProperties.contains(propName) == false) {
              // Don't set here to avoid layouts... cand.classes.add(DART_REMOVED);
              pmap[propName] = cand;
            }
          }
        }
      }
    }

    for (String prop in pmap.getKeys()) {
      Element e = pmap[prop];
      e.classes.add(DART_REMOVED);
    }

    // Find likely "subsections" of the main section and mark them with
    // DART_REMOVED so we don't include them in member descriptions... which
    // would suck.
    for (Element e in match.queryAll("[id]")) {
      if (e.id.indexOf(matchElement.id) != -1) {
        e.classes.add(DART_REMOVED);
      }
    }

    for (String prop in pmap.getKeys()) {
      Element elem = pmap[prop];
      bool obsolete = false;
      final parse = filteredHtml(
        elem, match, prop,
        (Element e) {
          obsolete = isObsolete(e);
        });
      Map entry = {
        "url" : parse.url,
        "name" : prop,
        "help" : parse.html,
        "obsolete" : obsolete
        //"jsSignature" : nameStr
      };
      if (parse.idl.length > 0) {
        entry["idl"] = parse.idl;
      }
      cleanupEntry(members, entry);
    }
  }
}

String trimHtml(String html) {
  // TODO(jacobr): impl.
  return html;
}

bool maybeName(String name) {
  RegExp nameRegExp = new RegExp("^[a-z][a-z0-9A-Z]+\$");
  if (nameRegExp.hasMatch(name)) return true;
  RegExp constRegExp = new RegExp("^[A-Z][A-Z_]*\$");
  if (constRegExp.hasMatch(name)) return true;
}

void markRemoved(var e) {
  if (e != null) {
    // TODO( remove)
    if (e is Element) {
      e.classes.add(DART_REMOVED);
    } else {
      for (Element el in e) {
        el.classes.add(DART_REMOVED);
      }
    }
  }
}

String JSONFIXUPHACK(String value) {
  return value.replaceAll("\n", "ZDARTIUMDOESNTESCAPESLASHNJXXXX");
}

String mozToWebkit(String name) {
  RegExp regExp = new RegExp("^moz");
  name = name.replaceFirst(regExp, "webkit");
  return name;
}

String stripWebkit(String name) {
  return trimPrefix(name, "webkit");
}

String fullNameCleanup(String name) {
  int parenIndex = name.indexOf('(');
  if (parenIndex != -1) {
    // TODO(jacobr): workaround bug in:
    // name = name.split("(")[0];
    name = name.substring(0, parenIndex);
  }
  name = name.split(" ")[0];
  name = name.split("\n")[0];
  name = name.split("\t")[0];
  name = name.split("*")[0];
  name = name.trim();
  name = safeNameCleanup(name);
  return name;
}

// Less agressive than the full cleanup to avoid overeager matching of
// everytyhing
String safeNameCleanup(String name) {
  int parenIndex = name.indexOf('(');
  if (parenIndex != -1 && name.indexOf(")") != -1) {
    // TODO(jacobr): workaround bug in:
    // name = name.split("(")[0];
    name = name.substring(0, parenIndex);
  }
  name = name.trim();
  name = trimPrefix(name, currentType + ".");
  name = trimPrefix(name, currentType.toLowerCase() + ".");
  name = trimPrefix(name, currentTypeShort + ".");
  name = trimPrefix(name, currentTypeShort.toLowerCase() + ".");
  name = trimPrefix(name, currentTypeTiny + ".");
  name = trimPrefix(name, currentTypeTiny.toLowerCase() + ".");
  name = name.trim();
  name = mozToWebkit(name);
  return name;
}

void removeHeaders(DocumentFragment fragment) {
  for (Element e in fragment.queryAll("h1, h2, h3")) {
    e.remove();
  }
}

void cleanupEntry(List members, Map entry) {
  if (entry.containsKey('help')) {
    entry['help'] = trimHtml(entry['help']);
  }
  String name = fullNameCleanup(entry['name']);
  entry['name'] = name;
  if (maybeName(name)) {
    for (String key in entry.getKeys()) {
      var value = entry[key];
      if (value == null) {
        entry.remove(key);
        continue;
      }
      if (value is String) {
        entry[key] = JSONFIXUPHACK(value);
      }
    }
    members.add(entry);
  }
}

// TODO(jacobr) dup with trim start....
String trimPrefix(String str, String prefix) {
  if (str.indexOf(prefix) == 0) {
    return str.substring(prefix.length);
  } else {
    return str;
  }
}

void resourceLoaded() {
  if (data != null) run();
}

String trimStart(String str, String start) {
  if (str.startsWith(start) && str.length > start.length) {
    return str.substring(start.length);
  }
  return str;
}

String trimEnd(String str, String end) {
  if (str.endsWith(end) && str.length > end.length) {
    return str.substring(0, str.length - end.length);
  }
  return str;
}

void extractSection(String selector, String key) {
  for (Element e in document.queryAll(selector)) {
    e = e.parent;
    for (Element skip in e.queryAll("h1, h2, $IDL_SELECTOR")) {
      skip.remove();
    }
    String html = filteredHtml(e, e, null, removeHeaders).html;
    if (html.length > 0) {
      if (dbEntry.containsKey(key)) {
        dbEntry[key] += html;
      } else {
        dbEntry[key] = html;
      }
    }
    e.classes.add(DART_REMOVED);
  }
}

void run() {
  // Inject CSS to insure lines don't wrap unless it was intentional.
  document.head.nodes.add(new Element.html("""
<style type="text/css">
  body {
    width: 10000px;
  }
</style>"""));

  String title = trimEnd(window.document.title.trim(), " - MDN");
  dbEntry['title'] = title;

  // TODO(rnystrom): Clean up the page a bunch. Not sure if this is the best
  // place to do this...

  // Remove the "Introduced in HTML <version>" boxes.
  for (Element e in document.queryAll('.htmlVersionHeaderTemplate')) {
    e.remove();
  }

  // Flatten the list of known DOM types into a faster and case-insensitive map.
  domTypes = {};
  for (final domType in domTypesRaw) {
    domTypes[domType.toLowerCase()] = domType;
  }

  // Fix up links.
  final SHORT_LINK = const RegExp(@'^[\w/]+$');
  final INNER_LINK = const RegExp(@'[Ee]n/(?:[\w/]+/|)([\w#.]+)(?:\(\))?$');
  final MEMBER_LINK = const RegExp(@'(\w+)[.#](\w+)');
  final RELATIVE_LINK = const RegExp(@'^(?:../)*/?[Ee][Nn]/(.+)');

  // - Make relative links absolute.
  // - If we can, take links that point to other MDN pages and retarget them
  //   to appropriate pages in our docs.
  // TODO(rnystrom): Add rel external to links we didn't fix.
  for (AnchorElement a in document.queryAll('a')) {
    // Get the raw attribute because we *don't* want the browser to fully-
    // qualify the name for us since it has the wrong base address for the page.
    var href = a.attributes['href'];

    // Ignore busted links.
    if (href == null) continue;

    // If we can recognize what it's pointing to, point it to our page instead.
    tryToLinkToRealType(maybeType) {
      // See if we know a type with that name.
      final realType = domTypes[maybeType.toLowerCase()];
      if (realType != null) {
        href = '../html/$realType.html';
      }
    }

    // If it's a relative link (that we know how to root), make it absolute.
    var match = RELATIVE_LINK.firstMatch(href);
    if (match != null) {
      href = 'https://developer.mozilla.org/en/${match[1]}';
    }

    // If it's a word link like "foo" find a type or make it absolute.
    match = SHORT_LINK.firstMatch(href);
    if (match != null) {
      href = 'https://developer.mozilla.org/en/DOM/${match[0]}';
    }

    // TODO(rnystrom): This is a terrible way to do this. Should use the real
    // mapping from DOM names to html class names that we use elsewhere in the
    // DOM scripts.
    match = INNER_LINK.firstMatch(href);
    if (match != null) {
      // See if we're linking to a member ("type.name" or "type#name") or just
      // a type ("type").
      final member = MEMBER_LINK.firstMatch(match[1]);
      if (member != null) {
        tryToLinkToRealType(member[1]);
      } else {
        tryToLinkToRealType(match[1]);
      }
    }

    // Put it back into the element.
    a.attributes['href'] = href;
  }

  if (title.toLowerCase().indexOf(currentTypeTiny.toLowerCase()) == -1) {
    bool foundMatch = false;
    // Test out if the title is really an HTML tag that matches the
    // current class name.
    for (String tag in [title.split(" ")[0], title.split(".").last()]) {
      try {
        dom.Element element = dom.document.createElement(tag);
        if (element.typeName == currentType) {
          foundMatch = true;
          break;
        }
      } catch(e) {}
    }
    if (foundMatch == false) {
      dbEntry['skipped'] = true;
      dbEntry['cause'] = "Suspect title";
      onEnd();
      return;
    }
  }

  Element root = document.query(".pageText");
  if (root == null) {
    dbEntry['cause'] = '.pageText not found';
    onEnd();
    return;
  }

  markRemoved(root.query("#Notes"));
  List members = dbEntry['members'];

  markRemoved(document.queryAll(".pageToc, footer, header, #nav-toolbar"));
  markRemoved(document.queryAll("#article-nav"));
  markRemoved(document.queryAll(".hideforedit"));
  markRemoved(document.queryAll(".navbox"));
  markRemoved(document.query("#Method_overview"));
  markRemoved(document.queryAll("h1, h2"));

  scrapeSection(root, "#Methods", currentType, members, 'methods');
  scrapeSection(root, "#Constants, #Error_codes, #State_constants", currentType, members, 'constants');
  // TODO(jacobr): infer tables based on multiple matches rather than
  // using a hard coded list of section ids.
  scrapeSection(root,
      "[id^=Properties], #Notes, [id^=Other_properties], #Attributes, #DOM_properties, #Event_handlers, #Event_Handlers",
      currentType, members, 'properties');

  // Avoid doing this till now to avoid messing up the section scrape.
  markRemoved(document.queryAll("h3"));

  ElementList $examples = root.queryAll("span[id^=example], span[id^=Example]");

  extractSection("#See_also", 'seeAlso');
  extractSection("#Specification, #Specifications", "specification");
  // $("#Methods").parent().remove(); // not safe (e.g. Document)

  // TODO(jacobr): actually extract the constructor(s)
  extractSection("#Constructor, #Constructors", 'constructor');
  extractSection("#Browser_compatibility, #Compatibility", 'compatibility');

  List<String> exampleHtml = [];
  for (Element e in $examples) {
    e.classes.add(DART_REMOVED);
  }
  for (Element e in $examples) {
    String html = filteredHtml(e, root, null,
      (DocumentFragment fragment) {
        removeHeaders(fragment);
        if (fragment.text.trim().toLowerCase() == "example") {
          // Degenerate example.
          fragment.nodes.clear();
        }
      }).html;
    if (html.length > 0) {
      exampleHtml.add(html);
    }
  }
  if (exampleHtml.length > 0) {
    dbEntry['examples'] = exampleHtml;
  }

  StringBuffer summary = new StringBuffer();

  for (Element e in root.queryAll("#Summary, #Description")) {
    summary.add(filteredHtml(root, e, null, removeHeaders).html);
  }

  if (summary.length == 0) {
    // Remove the "Gecko DOM Reference text"
    Element ref = root.query(".lang.lang-en");
    if (ref != null) {
      ref = ref.parent;
      String refText = ref.text.trim();
      if (refText == "Gecko DOM Reference" ||
          refText == "« Gecko DOM Reference") {
        ref.remove();
      }
    }
    // Risky... this might add stuff we shouldn't.
    summary.add(filteredHtml(root, root, null, removeHeaders).html);
  }

  if (summary.length > 0) {
    dbEntry['summary'] = summary.toString();
  }

  // Inject CSS to aid debugging in the browser.
  document.head.nodes.add(new Element.html(DEBUG_CSS));

  onEnd();
}

void main() {
  window.on.load.add(documentLoaded);
}

void documentLoaded(event) {
  new XMLHttpRequest.getTEMPNAME('${window.location}.json', (req) {
    data = JSON.parse(req.responseText);
    dbEntry = {'members': [], 'srcUrl': pageUrl};
    resourceLoaded();
  });
}
