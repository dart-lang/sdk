
class TrackEventJs extends EventJs implements TrackEvent native "*TrackEvent" {

  Object get track() native "return this.track;";
}
