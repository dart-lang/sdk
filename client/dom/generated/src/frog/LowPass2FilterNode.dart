
class _LowPass2FilterNodeJs extends _AudioNodeJs implements LowPass2FilterNode native "*LowPass2FilterNode" {

  _AudioParamJs get cutoff() native "return this.cutoff;";

  _AudioParamJs get resonance() native "return this.resonance;";
}
