
class _HighPass2FilterNodeJs extends _AudioNodeJs implements HighPass2FilterNode native "*HighPass2FilterNode" {

  _AudioParamJs get cutoff() native "return this.cutoff;";

  _AudioParamJs get resonance() native "return this.resonance;";
}
