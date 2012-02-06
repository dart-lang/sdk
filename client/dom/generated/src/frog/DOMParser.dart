
class _DOMParserJs extends _DOMTypeJs implements DOMParser native "*DOMParser" {
  DOMParser() native;

  _DocumentJs parseFromString(String str, String contentType) native;
}
