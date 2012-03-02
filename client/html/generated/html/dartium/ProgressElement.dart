
class _ProgressElementImpl extends _ElementImpl implements ProgressElement {
  _ProgressElementImpl._wrap(ptr) : super._wrap(ptr);

  FormElement get form() => _wrap(_ptr.form);

  NodeList get labels() => _wrap(_ptr.labels);

  num get max() => _wrap(_ptr.max);

  void set max(num value) { _ptr.max = _unwrap(value); }

  num get position() => _wrap(_ptr.position);

  num get value() => _wrap(_ptr.value);

  void set value(num value) { _ptr.value = _unwrap(value); }
}
