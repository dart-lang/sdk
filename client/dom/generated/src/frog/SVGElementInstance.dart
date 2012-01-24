
class SVGElementInstanceJS implements SVGElementInstance native "*SVGElementInstance" {

  SVGElementInstanceListJS get childNodes() native "return this.childNodes;";

  SVGElementJS get correspondingElement() native "return this.correspondingElement;";

  SVGUseElementJS get correspondingUseElement() native "return this.correspondingUseElement;";

  SVGElementInstanceJS get firstChild() native "return this.firstChild;";

  SVGElementInstanceJS get lastChild() native "return this.lastChild;";

  SVGElementInstanceJS get nextSibling() native "return this.nextSibling;";

  SVGElementInstanceJS get parentNode() native "return this.parentNode;";

  SVGElementInstanceJS get previousSibling() native "return this.previousSibling;";

  void addEventListener(String type, EventListener listener, [bool useCapture = null]) native;

  bool dispatchEvent(EventJS event) native;

  void removeEventListener(String type, EventListener listener, [bool useCapture = null]) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}
