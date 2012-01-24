
class TrackEventJS extends EventJS implements TrackEvent native "*TrackEvent" {

  Object get track() native "return this.track;";
}
