
class HashChangeEventJs extends EventJs implements HashChangeEvent native "*HashChangeEvent" {

  String get newURL() native "return this.newURL;";

  String get oldURL() native "return this.oldURL;";

  void initHashChangeEvent(String type, bool canBubble, bool cancelable, String oldURL, String newURL) native;
}
