
class BeforeLoadEvent extends Event native "*BeforeLoadEvent" {

  String url;

  void initBeforeLoadEvent(String type, bool canBubble, bool cancelable, String url) native;
}
