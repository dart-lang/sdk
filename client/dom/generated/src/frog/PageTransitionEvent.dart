
class PageTransitionEventJS extends EventJS implements PageTransitionEvent native "*PageTransitionEvent" {

  bool get persisted() native "return this.persisted;";
}
