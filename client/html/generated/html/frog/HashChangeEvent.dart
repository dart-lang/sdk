
class _HashChangeEventImpl extends _EventImpl implements HashChangeEvent native "*HashChangeEvent" {

  final String newURL;

  final String oldURL;

  void initHashChangeEvent(String type, bool canBubble, bool cancelable, String oldURL, String newURL) native;
}
