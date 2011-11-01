
class PageTransitionEvent extends Event native "PageTransitionEvent" {

  bool persisted;

  void initPageTransitionEvent(String typeArg, bool canBubbleArg, bool cancelableArg, bool persisted) native;
}
