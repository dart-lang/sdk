
class PopStateEventJs extends EventJs implements PopStateEvent native "*PopStateEvent" {

  Object get state() native "return this.state;";
}
