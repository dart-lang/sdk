
class _SVGDocumentImpl extends _DocumentImpl implements SVGDocument {
  _SVGDocumentImpl._wrap(ptr) : super._wrap(ptr);

  SVGSVGElement get rootElement() => _wrap(_ptr.rootElement);

  Event _createEvent(String eventType) {
    return _wrap(_ptr.createEvent(_unwrap(eventType)));
  }
}
