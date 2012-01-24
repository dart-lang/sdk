
class HighPass2FilterNodeJS extends AudioNodeJS implements HighPass2FilterNode native "*HighPass2FilterNode" {

  AudioParamJS get cutoff() native "return this.cutoff;";

  AudioParamJS get resonance() native "return this.resonance;";
}
