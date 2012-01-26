
class PageTransitionEventJs extends EventJs implements PageTransitionEvent native "*PageTransitionEvent" {

  bool get persisted() native "return this.persisted;";
}
