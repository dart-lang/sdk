
class ProgressEvent extends Event native "ProgressEvent" {

  bool lengthComputable;

  int loaded;

  int total;

  void initProgressEvent(String typeArg, bool canBubbleArg, bool cancelableArg, bool lengthComputableArg, int loadedArg, int totalArg) native;
}
