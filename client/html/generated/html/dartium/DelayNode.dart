
class _DelayNodeImpl extends _AudioNodeImpl implements DelayNode {
  _DelayNodeImpl._wrap(ptr) : super._wrap(ptr);

  AudioParam get delayTime() => _wrap(_ptr.delayTime);
}
