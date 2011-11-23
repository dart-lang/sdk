
class SVGElementInstance native "*SVGElementInstance" {

  SVGElementInstanceList childNodes;

  SVGElement correspondingElement;

  SVGUseElement correspondingUseElement;

  SVGElementInstance firstChild;

  SVGElementInstance lastChild;

  SVGElementInstance nextSibling;

  EventListener onabort;

  EventListener onbeforecopy;

  EventListener onbeforecut;

  EventListener onbeforepaste;

  EventListener onblur;

  EventListener onchange;

  EventListener onclick;

  EventListener oncontextmenu;

  EventListener oncopy;

  EventListener oncut;

  EventListener ondblclick;

  EventListener ondrag;

  EventListener ondragend;

  EventListener ondragenter;

  EventListener ondragleave;

  EventListener ondragover;

  EventListener ondragstart;

  EventListener ondrop;

  EventListener onerror;

  EventListener onfocus;

  EventListener oninput;

  EventListener onkeydown;

  EventListener onkeypress;

  EventListener onkeyup;

  EventListener onload;

  EventListener onmousedown;

  EventListener onmousemove;

  EventListener onmouseout;

  EventListener onmouseover;

  EventListener onmouseup;

  EventListener onmousewheel;

  EventListener onpaste;

  EventListener onreset;

  EventListener onresize;

  EventListener onscroll;

  EventListener onsearch;

  EventListener onselect;

  EventListener onselectstart;

  EventListener onsubmit;

  EventListener onunload;

  SVGElementInstance parentNode;

  SVGElementInstance previousSibling;

  void addEventListener(String type, EventListener listener, [bool useCapture = null]) native;

  bool dispatchEvent(Event event) native;

  void removeEventListener(String type, EventListener listener, [bool useCapture = null]) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}
