
class HighPass2FilterNode extends AudioNode native "*HighPass2FilterNode" {

  AudioParam get cutoff() native "return this.cutoff;";

  AudioParam get resonance() native "return this.resonance;";
}
