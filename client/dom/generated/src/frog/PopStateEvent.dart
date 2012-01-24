
class PopStateEventJS extends EventJS implements PopStateEvent native "*PopStateEvent" {

  Object get state() native "return this.state;";
}
