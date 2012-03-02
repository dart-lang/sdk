
class _DOMParserImpl implements DOMParser native "*DOMParser" {

  _DocumentImpl parseFromString(String str, String contentType) => _FixHtmlDocumentReference(_parseFromString(str, contentType));

  _EventTargetImpl _parseFromString(String str, String contentType) native "return this.parseFromString(str, contentType);";
}
