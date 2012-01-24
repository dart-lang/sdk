
class HighPass2FilterNodeJs extends AudioNodeJs implements HighPass2FilterNode native "*HighPass2FilterNode" {

  AudioParamJs get cutoff() native "return this.cutoff;";

  AudioParamJs get resonance() native "return this.resonance;";
}
