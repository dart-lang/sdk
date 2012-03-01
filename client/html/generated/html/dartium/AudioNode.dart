
class _AudioNodeImpl extends _DOMTypeBase implements AudioNode {
  _AudioNodeImpl._wrap(ptr) : super._wrap(ptr);

  AudioContext get context() => _wrap(_ptr.context);

  int get numberOfInputs() => _wrap(_ptr.numberOfInputs);

  int get numberOfOutputs() => _wrap(_ptr.numberOfOutputs);

  void connect(AudioNode destination, int output, int input) {
    _ptr.connect(_unwrap(destination), _unwrap(output), _unwrap(input));
    return;
  }

  void disconnect(int output) {
    _ptr.disconnect(_unwrap(output));
    return;
  }
}
