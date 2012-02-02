
class _SVGDocumentJs extends _DocumentJs implements SVGDocument native "*SVGDocument" {

  _SVGSVGElementJs get rootElement() native "return this.rootElement;";

  _EventJs createEvent(String eventType) native;
}
