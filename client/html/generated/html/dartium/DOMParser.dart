
class _DOMParserImpl extends _DOMTypeBase implements DOMParser {
  _DOMParserImpl._wrap(ptr) : super._wrap(ptr);

  Document parseFromString(String str, String contentType) {
    return _FixHtmlDocumentReference(_wrap(_ptr.parseFromString(_unwrap(str), _unwrap(contentType))));
  }
}
