
class _SVGDocumentImpl extends _DocumentImpl implements SVGDocument native "*SVGDocument" {

  final _SVGSVGElementImpl rootElement;

  _EventImpl _createEvent(String eventType) native "return this.createEvent(eventType);";
}
