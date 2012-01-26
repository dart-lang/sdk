
class DOMParserJs extends DOMTypeJs implements DOMParser native "*DOMParser" {

  DocumentJs parseFromString(String str, String contentType) native;
}
