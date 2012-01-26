
class WebKitAnimationListJs extends DOMTypeJs implements WebKitAnimationList native "*WebKitAnimationList" {

  int get length() native "return this.length;";

  WebKitAnimationJs item(int index) native;
}
