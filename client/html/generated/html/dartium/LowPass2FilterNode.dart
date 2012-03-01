
class _LowPass2FilterNodeImpl extends _AudioNodeImpl implements LowPass2FilterNode {
  _LowPass2FilterNodeImpl._wrap(ptr) : super._wrap(ptr);

  AudioParam get cutoff() => _wrap(_ptr.cutoff);

  AudioParam get resonance() => _wrap(_ptr.resonance);
}
