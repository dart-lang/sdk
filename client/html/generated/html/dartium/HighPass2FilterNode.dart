
class _HighPass2FilterNodeImpl extends _AudioNodeImpl implements HighPass2FilterNode {
  _HighPass2FilterNodeImpl._wrap(ptr) : super._wrap(ptr);

  AudioParam get cutoff() => _wrap(_ptr.cutoff);

  AudioParam get resonance() => _wrap(_ptr.resonance);
}
