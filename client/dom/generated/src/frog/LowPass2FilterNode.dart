
class LowPass2FilterNodeJS extends AudioNodeJS implements LowPass2FilterNode native "*LowPass2FilterNode" {

  AudioParamJS get cutoff() native "return this.cutoff;";

  AudioParamJS get resonance() native "return this.resonance;";
}
