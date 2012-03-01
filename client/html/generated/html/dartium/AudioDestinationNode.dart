
class _AudioDestinationNodeImpl extends _AudioNodeImpl implements AudioDestinationNode {
  _AudioDestinationNodeImpl._wrap(ptr) : super._wrap(ptr);

  int get numberOfChannels() => _wrap(_ptr.numberOfChannels);
}
