
class HashChangeEvent extends Event native "HashChangeEvent" {

  String newURL;

  String oldURL;

  void initHashChangeEvent(String type, bool canBubble, bool cancelable, String oldURL, String newURL) native;
}
