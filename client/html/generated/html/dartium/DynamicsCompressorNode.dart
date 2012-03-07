
class _DynamicsCompressorNodeImpl extends _AudioNodeImpl implements DynamicsCompressorNode {
  _DynamicsCompressorNodeImpl._wrap(ptr) : super._wrap(ptr);

  AudioParam get knee() => _wrap(_ptr.knee);

  AudioParam get ratio() => _wrap(_ptr.ratio);

  AudioParam get reduction() => _wrap(_ptr.reduction);

  AudioParam get threshold() => _wrap(_ptr.threshold);
}
