
class _WebKitAnimationListJs extends _DOMTypeJs implements WebKitAnimationList native "*WebKitAnimationList" {

  int get length() native "return this.length;";

  _WebKitAnimationJs item(int index) native;
}
