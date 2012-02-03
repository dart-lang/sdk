
class _PopStateEventJs extends _EventJs implements PopStateEvent native "*PopStateEvent" {

  Object get state() native "return this.state;";
}
