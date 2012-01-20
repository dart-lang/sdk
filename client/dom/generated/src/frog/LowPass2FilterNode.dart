
class LowPass2FilterNode extends AudioNode native "*LowPass2FilterNode" {

  AudioParam get cutoff() native "return this.cutoff;";

  AudioParam get resonance() native "return this.resonance;";
}
