
class CloseEvent extends Event native "*CloseEvent" {

  int code;

  String reason;

  bool wasClean;

  void initCloseEvent(String typeArg, bool canBubbleArg, bool cancelableArg, bool wasCleanArg, int codeArg, String reasonArg) native;
}
