
class SVGElementInstance native "*SVGElementInstance" {

  SVGElementInstanceList get childNodes() native "return this.childNodes;";

  SVGElement get correspondingElement() native "return this.correspondingElement;";

  SVGUseElement get correspondingUseElement() native "return this.correspondingUseElement;";

  SVGElementInstance get firstChild() native "return this.firstChild;";

  SVGElementInstance get lastChild() native "return this.lastChild;";

  SVGElementInstance get nextSibling() native "return this.nextSibling;";

  SVGElementInstance get parentNode() native "return this.parentNode;";

  SVGElementInstance get previousSibling() native "return this.previousSibling;";

  void addEventListener(String type, EventListener listener, [bool useCapture = null]) native;

  bool dispatchEvent(Event event) native;

  void removeEventListener(String type, EventListener listener, [bool useCapture = null]) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}
