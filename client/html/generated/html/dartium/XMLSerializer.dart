
class _XMLSerializerImpl extends _DOMTypeBase implements XMLSerializer {
  _XMLSerializerImpl._wrap(ptr) : super._wrap(ptr);

  String serializeToString(Node node) {
    return _wrap(_ptr.serializeToString(_unwrap(node)));
  }
}
