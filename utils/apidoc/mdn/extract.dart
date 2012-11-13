import 'dart:html';
import 'dart:json';

// Workaround for HTML lib missing feature.
Range newRange() {
  return document.createRange();
}

// Temporary range object to optimize performance computing client rects
// from text nodes.
Range _tempRange;
// Hacks because ASYNC measurement is annoying when just writing a script.
ClientRect getClientRect(Node n) {
  if (n is Element) {
    return n.$dom_getBoundingClientRect();
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

/**
 * CSS class that is added to elements in the DOM to indicate that they should
 * be removed when extracting blocks of documentation.  This is helpful when
 * running this script in a web browser as it is easy to visually see what
 * blocks of information were extracted when using CSS such as DEBUG_CSS
 * which highlights elements that should be removed.
 */
const DART_REMOVED = "dart-removed";

const DEBUG_CSS = """
<style type="text/css">
  .dart-removed {
    background-color: rgba(255, 0, 0, 0.5);
   }
</style>""";

const MIN_PIXELS_DIFFERENT_LINES = 10;

const IDL_SELECTOR = "pre.eval, pre.idl";

Map data;

// TODO(rnystrom): Hack! Copied from domTypes.json. Instead of hard-coding
// these, should use the same mapping that the DOM/HTML code generators use.
var domTypes;
const domTypesRaw = const [
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

Map get dartIdl => data['dartIdl'];
String get currentType => data['type'];

String _currentTypeShort;
String get currentTypeShort {
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
String get currentTypeTiny {
  if (_currentTypeTiny == null) {
    _currentTypeTiny = currentTypeShort;
    _currentTypeTiny = trimEnd(_currentTypeTiny, "Element");
  }
  return _currentTypeTiny;
}

Map get searchResult => data['searchResult'];
String get pageUrl => searchResult['link'];

String _pageDomain;
String get pageDomain {
  if (_pageDomain == null) {
    _pageDomain = pageUrl.substring(0, pageUrl.indexOf("/", "https://".length));
  }
  return _pageDomain;
}

String get pageDir {
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
  while (n != null) {
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
  final nodes = <Text>[];
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

  for (final child in n.nodes) {
    if (!isSkippableType(child)) {
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

  // Use postMessage to end the JSON to JavaScript. TODO(jacobr): use a simple
  // isolate based Dart-JS interop solution in the future.
  window.postMessage("START_DART_MESSAGE_UNIQUE_IDENTIFIER$dbJson", "*");
}

class SectionParseResult {
  final String html;
  final String url;
  final String idl;
  SectionParseResult(this.html, this.url, this.idl);
}

String genCleanHtml(Element root) {
  for (final e in root.queryAll(".$DART_REMOVED")) {
    e.classes.remove(DART_REMOVED);
  }

  // Ditch inline styles.
  for (final e in root.queryAll('[style]')) {
    e.attributes.remove('style');
  }

  // These elements are just tags that we should suppress.
  for (final e in root.queryAll(".lang.lang-en")) {
    e.remove();
  }

  Element parametersHeader;
  Element returnValueHeader;
  for (final e in root.queryAll("h6")) {
    if (e.text == 'Parameters') {
      parametersHeader = e;
    } else if (e.text == 'Return value') {
      returnValueHeader = e;
    }
  }

  if (parametersHeader != null) {
    int numEmptyParameters = 0;
    final parameterDescriptions = root.queryAll("dd");
    for (Element parameterDescription in parameterDescriptions) {
      if (parameterDescription.text.trim().length == 0) {
        numEmptyParameters++;
      }
    }
    if (numEmptyParameters > 0 &&
        numEmptyParameters == parameterDescriptions.length) {
      // Remove the parameter list as it adds zero value as all descriptions
      // are empty.
      parametersHeader.remove();
      for (final e in root.queryAll("dl")) {
        e.remove();
      }
    } else if (parameterDescriptions.length == 0 &&
        parametersHeader.nextElementSibling != null &&
        parametersHeader.nextElementSibling.text.trim() == 'None.') {
      // No need to display that the function takes 0 parameters.
      parametersHeader.nextElementSibling.remove();
      parametersHeader.remove();
    }
  }

  // Heuristic: if the return value is a single word it is a type name not a
  // useful text description so suppress it.
  if (returnValueHeader != null &&
      returnValueHeader.nextElementSibling != null &&
      returnValueHeader.nextElementSibling.text.trim().split(' ').length < 2) {
    returnValueHeader.nextElementSibling.remove();
    returnValueHeader.remove();
  }

  bool changed = true;
  while (changed) {
    changed = false;
    while (root.nodes.length == 1 && root.nodes.first is Element) {
      root = root.nodes.first;
      changed = true;
    }

    // Trim useless nodes from the front.
    while (root.nodes.length > 0 &&
        isSkippable(root.nodes.first)) {
      root.nodes.first.remove();
      changed = true;
    }

    // Trim useless nodes from the back.
    while (root.nodes.length > 0 &&
        isSkippable(root.nodes.last)) {
      root.nodes.last.remove();
      changed = true;
    }
  }
  return JSONFIXUPHACK(root.innerHTML);
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

  bool get hasNext => _next != null;

  Node next() {
    if (_next == null) return null;
    final ret = _next;
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

/**
 * Estimate what content represents the first line of text within the [section]
 * range returning null if there isn't a plausible first line of text that
 * contains the string [prop].  We measure the actual rendered client rectangle
 * for the text and use heuristics defining how many pixels text can vary by
 * and still be viewed as being on the same line.
 */
Range findFirstLine(Range section, String prop) {
  final firstLine = newRange();
  firstLine.setStart(section.startContainer, section.startOffset);

  num maxBottom = null;
  for (final n in new PostOrderTraversal(section.startContainer)) {
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
      if (maxBottom != null &&
          maxBottom + MIN_PIXELS_DIFFERENT_LINES < bottom) {
        break;
      } else if (maxBottom == null || maxBottom > bottom) {
        maxBottom = bottom;
      }
    }

    firstLine.setEndAfter(n);
  }

  // If the first line of text in the section does not contain the property
  // name then we're not confident we are able to extract a high accuracy match
  // so we should not return anything.
  if (!firstLine.toString().contains(stripWebkit(prop))) {
    return null;
  }
  return firstLine;
}

/** Find child anchor elements that contain the text [prop]. */
AnchorElement findAnchorElement(Element root, String prop) {
  for (AnchorElement a in root.queryAll("a")) {
    if (a.text.contains(prop)) {
      return a;
    }
  }
  return null;
}

// First surrounding element with an ID is safe enough.
Element findTighterRoot(Element elem, Element root) {
  Element candidate = elem;
  while (root != candidate) {
    candidate = candidate.parent;
    if (candidate.id.length > 0 && candidate.id.indexOf("section_") != 0) {
      break;
    }
  }
  return candidate;
}

// TODO(jacobr): this is very slow and ugly.. consider rewriting or at least
// commenting carefully.
SectionParseResult filteredHtml(Element elem, Element root, String prop,
    Function fragmentGeneratedCallback) {
  // Using a tighter root avoids false positives at the risk of trimming
  // text we shouldn't.
  root = findTighterRoot(elem, root);
  final range = newRange();
  range.setStartBefore(elem);

  Element current = elem;
  while (current != null) {
    range.setEndBefore(current);
    if (current.classes.contains(DART_REMOVED) &&
        range.toString().trim().length > 0) {
      break;
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
  final fragment = range.cloneContents();
  if (fragmentGeneratedCallback != null) {
    fragmentGeneratedCallback(fragment);
  }
  // Strip tags we don't want
  for (Element e in fragment.queryAll("script, object, style")) {
    e.remove();
  }

  // Extract idl
  final idl = new StringBuffer();
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
      if (likelyIdl.hasMatch(txt) && txt.contains("\n") && txt.contains(")")) {
        idl.add(e.outerHTML);
        e.remove();
      }
    }
  }
  return new SectionParseResult(genCleanHtml(fragment), url, idl.toString());
}

/**
 * Find the best child element of [root] that appears to be an API definition
 * for [prop].  [allText] is a list of all text nodes under root computed by
 * the caller to improve performance.
 */
Element findBest(Element root, List<Text> allText, String prop,
    String propType) {
  // Best bet: find a child of root where the id matches the property name.
  Element cand = root.query("#$prop");

  if (cand == null && propType == "methods") {
    cand = root.query("[id=$prop\\(\\)]");
  }
  while (cand != null && cand.text.trim().length == 0) {
    // We found the bookmark for the element but sadly it is just an empty
    // placeholder. Find the first real element.
    cand = cand.nextElementSibling;
  }
  if (cand != null) {
    return cand;
  }

  // If we are at least 70 pixels from the left, something is definitely
  // fishy and we shouldn't even consider this candidate as nobody visually
  // formats API docs like that.
  num candLeft = 70;

  for (Text text in allText) {
    Element proposed = null;

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

/**
 * Checks whether [e] is tagged as obsolete or deprecated using heuristics
 * for what these tags look like in the MDN docs.
 */
bool isObsolete(Element e) {
  RegExp obsoleteRegExp = new RegExp(r"(^|\s)obsolete(?=\s|$)");
  RegExp deprecatedRegExp = new RegExp(r"(^|\s)deprecated(?=\s|$)");
  for (Element child in e.queryAll("span")) {
    String t = child.text.toLowerCase();
    if (t.startsWith("obsolete") || t.startsWith("deprecated")) return true;
  }

  String text = e.text.toLowerCase();
  return obsoleteRegExp.hasMatch(text) || deprecatedRegExp.hasMatch(text);
}

bool isFirstCharLowerCase(String str) {
  return const RegExp("^[a-z]").hasMatch(str);
}

/**
 * Extracts information from a fragment of HTML only searching under the [root]
 * html node.  [secitonSelector] specifies the query to use to find candidate
 * sections of the document to consider (there may be more than one).
 * [currentType] specifies the name of the current class. [members] specifies
 * the known class members for this class that we are attempting to find
 * documentation for.  [propType] indicates whether we are searching for
 * methods, properties, constants, or constructors.
 */
void scrapeSection(Element root, String sectionSelector, String currentType,
    List members, String propType) {
  Map expectedProps = dartIdl[propType];

  Set<String> alreadyMatchedProperties = new Set<String>();
  bool onlyConsiderTables = false;
  ElementList allMatches = root.queryAll(sectionSelector);
  if (allMatches.length == 0) {
    // If we can't find any matches to the sectionSelector, we fall back to
    // considering all tables in the document.  This is dangerous so we only
    // allow the safer table matching extraction rules for this case.
    allMatches = root.queryAll(".fullwidth-table");
    onlyConsiderTables = true;
  }
  for (Element matchElement in allMatches) {
    final match = matchElement.parent;
    if (!match.id.startsWith("section") && match.id != "pageText") {
      throw "Unexpected element $match";
    }
    // We don't want to later display this text a second time while for example
    // displaying class level summary information as then we would display
    // the same documentation twice.
    match.classes.add(DART_REMOVED);

    bool foundProps = false;

    // TODO(jacobr): we should really look for the table tag instead
    // add an assert if we are missing something that is a table...
    // TODO(jacobr) ignore tables in tables.
    for (Element t in match.queryAll('.standard-table, .fullwidth-table')) {
      int helpIndex = -1;
      num i = 0;
      for (Element r in t.queryAll("th, td.header")) {
        final txt = r.text.trim().split(" ")[0].toLowerCase();
        if (txt == "description") {
          helpIndex = i;
          break;
        }
        i++;
      }

      // Figure out which column in the table contains member names by
      // tracking how many member names each column contains.
      final numMatches = new List<int>(i);
      for (int j = 0; j < i; j++) {
        numMatches[j] = 0;
      }

      // Find the column that seems to have the most names that look like
      // expected properties.
      for (Element r in t.queryAll("tbody tr")) {
        ElementList row = r.elements;
        if (row.length == 0 || row.first.classes.contains(".header")) {
          continue;
        }

        for (int k = 0; k < numMatches.length && k < row.length; k++) {
          if (expectedProps.containsKey(fullNameCleanup(row[k].text))) {
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
        final row = r.elements;
        if (row.length > propNameIndex && row.length > helpIndex) {
          if (row.first.classes.contains(".header")) {
            continue;
          }
          // TODO(jacobr): this code for determining the namestr is needlessly
          // messy.
          final nameRow = row[propNameIndex];
          AnchorElement a = nameRow.query("a");
          String goodName = '';
          if (a != null) {
            goodName = a.text.trim();
          }
          String nameStr = nameRow.text;

          Map entry = new Map<String, String>();

          entry["name"] = fullNameCleanup(nameStr.length > 0 ?
              nameStr : goodName);

          final parse = filteredHtml(nameRow, nameRow, entry["name"], null);
          String altHelp = parse.html;

          entry["help"] = (helpIndex == -1 || row[helpIndex] == null) ?
              altHelp : genPrettyHtmlFromElement(row[helpIndex]);
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
    // rudimentary page segmentation.  This approach is much more error-prone
    // than using tables because the HTML is far less clearly structured.

    final allText = getAllTextNodes(match);

    final pmap = new Map<String, Element>();
    for (final prop in expectedProps.keys) {
      if (alreadyMatchedProperties.contains(prop)) {
        continue;
      }
      final e = findBest(match, allText, prop, propType);
      if (e != null && !inTable(e)) {
        pmap[prop] = e;
      }
    }

    for (final prop in pmap.keys) {
      pmap[prop].classes.add(DART_REMOVED);
    }

    // The problem is the MDN docs do place documentation for each method in a
    // nice self contained subtree. Instead you will see something like:

    // <h3>drawImage</h3>
    // <p>Draw image is an awesome method</p>
    // some more info on drawImage here
    // <h3>mozDrawWindow</h3>
    // <p>This API cannot currently be used by Web content.
    // It is chrome only.</p>
    // <h3>drawRect</h3>
    // <p>Always call drawRect instead of drawImage</p>
    // some more info on drawRect here...

    // The trouble is we will easily detect that the drawImage and drawRect
    // entries are method definitions because we know to search for these
    // method names but we will not detect that mozDrawWindow is a method
    // definition as that method doesn't exist in our IDL.  Thus if we are not
    // careful the definition for the drawImage method will contain the
    // definition for the mozDrawWindow method as well which would result in
    // broken docs.  We solve this problem by finding all content with similar
    // visual structure to the already found method definitions.  It turns out
    // that using the visual position of each element on the page is much
    // more reliable than using the DOM structure
    // (e.g. section_root > div > h3) for the MDN docs because MDN authors
    // carefully check that the documentation for each method comment is
    // visually consistent but take less care to check that each
    // method comment has identical markup structure.
    for (String prop in pmap.keys) {
      Element e = pmap[prop];
      ClientRect r = getClientRect(e);
      // TODO(jacobr): a lot of these queries are identical and this code
      // could easily be optimized.
      for (final cand in match.queryAll(e.tagName)) {
        // TODO(jacobr): use a negative selector instead.
        if (!cand.classes.contains(DART_REMOVED) && !inTable(cand)) {
          final candRect = getClientRect(cand);
          // Only consider matches that have similar heights and identical left
          // coordinates.
          if (candRect.left == r.left &&
            (candRect.height - r.height).abs() < 5) {
            String propName = fullNameCleanup(cand.text);
            if (isFirstCharLowerCase(propName) && !pmap.containsKey(propName)
                && !alreadyMatchedProperties.contains(propName)) {
              pmap[propName] = cand;
            }
          }
        }
      }
    }

    // We mark these elements in batch to reduce the number of layouts
    // triggered. TODO(jacobr): use new batch based async measurement to make
    // this code flow simpler.
    for (String prop in pmap.keys) {
      Element e = pmap[prop];
      e.classes.add(DART_REMOVED);
    }

    // Find likely "subsections" of the main section and mark them with
    // DART_REMOVED so we don't include them in member descriptions... which
    // would suck.
    for (Element e in match.queryAll("[id]")) {
      if (e.id.contains(matchElement.id)) {
        e.classes.add(DART_REMOVED);
      }
    }

    for (String prop in pmap.keys) {
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
      };
      if (parse.idl.length > 0) {
        entry["idl"] = parse.idl;
      }
      cleanupEntry(members, entry);
    }
  }
}

String trimHtml(String html) {
  // TODO(jacobr): implement this.  Remove spurious enclosing HTML tags, etc.
  return html;
}

bool maybeName(String name) {
  return const RegExp("^[a-z][a-z0-9A-Z]+\$").hasMatch(name) ||
      const RegExp("^[A-Z][A-Z_]*\$").hasMatch(name);
}

// TODO(jacobr): this element is ugly at the moment but will become easier to
// read once ElementList supports most of the Element functionality.
void markRemoved(var e) {
  if (e != null) {
    if (e is Element) {
      e.classes.add(DART_REMOVED);
    } else {
      for (Element el in e) {
        el.classes.add(DART_REMOVED);
      }
    }
  }
}

// TODO(jacobr): remove this when the dartium JSON parser handles \n correctly.
String JSONFIXUPHACK(String value) {
  return value.replaceAll("\n", "ZDARTIUMDOESNTESCAPESLASHNJXXXX");
}

String mozToWebkit(String name) {
  return name.replaceFirst(const RegExp("^moz"), "webkit");
}

String stripWebkit(String name) {
  return trimPrefix(name, "webkit");
}

// TODO(jacobr): be more principled about this.
String fullNameCleanup(String name) {
  int parenIndex = name.indexOf('(');
  if (parenIndex != -1) {
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

// Less agressive than the full name cleanup to avoid overeager matching.
// TODO(jacobr): be more principled about this.
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

/**
 * Remove h1, h2, and h3 headers.
 */
void removeHeaders(DocumentFragment fragment) {
  for (Element e in fragment.queryAll("h1, h2, h3")) {
    e.remove();
  }
}

/**
 * Given an [entry] representing a single method or property cleanup the
 * values performing some simple normalization and only adding the entry to
 * [members] if it has a valid name.
 */
void cleanupEntry(List members, Map entry) {
  if (entry.containsKey('help')) {
    entry['help'] = trimHtml(entry['help']);
  }
  String name = fullNameCleanup(entry['name']);
  entry['name'] = name;
  if (maybeName(name)) {
    for (String key in entry.keys) {
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

/**
 * Extract a section with name [key] using [selector] to find start points for
 * the section in the document.
 */
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
  // Inject CSS to ensure lines don't wrap unless they were intended to.
  // This is needed to make the logic to determine what is a single line
  // behave consistently even for very long method names.
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
  // TODO(jacobr): move this to right before we extract HTML.

  // Remove the "Introduced in HTML <version>" boxes.
  for (Element e in document.queryAll('.htmlVersionHeaderTemplate')) {
    e.remove();
  }

  // Flatten the list of known DOM types into a faster and case-insensitive
  // map.
  domTypes = {};
  for (final domType in domTypesRaw) {
    domTypes[domType.toLowerCase()] = domType;
  }

  // Fix up links.
  const SHORT_LINK = const RegExp(r'^[\w/]+$');
  const INNER_LINK = const RegExp(r'[Ee]n/(?:[\w/]+/|)([\w#.]+)(?:\(\))?$');
  const MEMBER_LINK = const RegExp(r'(\w+)[.#](\w+)');
  const RELATIVE_LINK = const RegExp(r'^(?:../)*/?[Ee][Nn]/(.+)');

  // - Make relative links absolute.
  // - If we can, take links that point to other MDN pages and retarget them
  //   to appropriate pages in our docs.
  // TODO(rnystrom): Add rel external to links we didn't fix.
  for (AnchorElement a in document.queryAll('a')) {
    // Get the raw attribute because we *don't* want the browser to fully-
    // qualify the name for us since it has the wrong base address for the
    // page.
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

  if (!title.toLowerCase().contains(currentTypeTiny.toLowerCase())) {
    bool foundMatch = false;
    // Test out if the title is really an HTML tag that matches the
    // current class name.
    for (String tag in [title.split(" ")[0], title.split(".").last]) {
      try {
        Element element = new Element.tag(tag);
        // TODO(jacobr): this is a really ugly way of doing this that will
        // stop working at some point soon.
        if (element.typeName == currentType) {
          foundMatch = true;
          break;
        }
      } catch (e) {}
    }
    if (!foundMatch) {
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

  // This is a laundry list of CSS selectors for boilerplate content on the
  // MDN pages that we should ignore for the purposes of extracting
  // documentation.
  markRemoved(document.queryAll(".pageToc, footer, header, #nav-toolbar"));
  markRemoved(document.queryAll("#article-nav"));
  markRemoved(document.queryAll(".hideforedit"));
  markRemoved(document.queryAll(".navbox"));
  markRemoved(document.query("#Method_overview"));
  markRemoved(document.queryAll("h1, h2"));

  scrapeSection(root, "#Methods", currentType, members, 'methods');
  scrapeSection(root, "#Constants, #Error_codes, #State_constants",
      currentType, members, 'constants');
  // TODO(jacobr): infer tables based on multiple matches rather than
  // using a hard coded list of section ids.
  scrapeSection(root,
      "[id^=Properties], #Notes, [id^=Other_properties], #Attributes, " +
      "#DOM_properties, #Event_handlers, #Event_Handlers",
      currentType, members, 'properties');

  // Avoid doing this till now to avoid messing up the section scrape.
  markRemoved(document.queryAll("h3"));

  ElementList examples = root.queryAll("span[id^=example], span[id^=Example]");

  extractSection("#See_also", 'seeAlso');
  extractSection("#Specification, #Specifications", "specification");

  // TODO(jacobr): actually extract the constructor(s)
  extractSection("#Constructor, #Constructors", 'constructor');
  extractSection("#Browser_compatibility, #Compatibility", 'compatibility');

  // Extract examples.
  List<String> exampleHtml = [];
  for (Element e in examples) {
    e.classes.add(DART_REMOVED);
  }
  for (Element e in examples) {
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

  // Extract the class summary.
  // Basically everything left over after the #Summary or #Description tag is
  // safe to include in the summary.
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
  // We could avoid doing this if we know we are not running in a browser..
  document.head.nodes.add(new Element.html(DEBUG_CSS));

  onEnd();
}

void main() {
  window.on.load.add(documentLoaded);
}

void documentLoaded(event) {
  // Load the database of expected methods and properties with an HttpRequest.
  new HttpRequest.get('${window.location}.json', (req) {
    data = JSON.parse(req.responseText);
    dbEntry = {'members': [], 'srcUrl': pageUrl};
    run();
  });
}
