
class ErrorEvent extends Event native "*ErrorEvent" {

  String filename;

  int lineno;

  String message;

  void initErrorEvent(String typeArg, bool canBubbleArg, bool cancelableArg, String messageArg, String filenameArg, int linenoArg) native;
}
