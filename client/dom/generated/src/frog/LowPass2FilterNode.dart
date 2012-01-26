
class LowPass2FilterNodeJs extends AudioNodeJs implements LowPass2FilterNode native "*LowPass2FilterNode" {

  AudioParamJs get cutoff() native "return this.cutoff;";

  AudioParamJs get resonance() native "return this.resonance;";
}
