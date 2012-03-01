
class _AudioGainNodeImpl extends _AudioNodeImpl implements AudioGainNode {
  _AudioGainNodeImpl._wrap(ptr) : super._wrap(ptr);

  AudioGain get gain() => _wrap(_ptr.gain);
}
