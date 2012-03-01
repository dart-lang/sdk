
class _MeterElementImpl extends _ElementImpl implements MeterElement {
  _MeterElementImpl._wrap(ptr) : super._wrap(ptr);

  FormElement get form() => _wrap(_ptr.form);

  num get high() => _wrap(_ptr.high);

  void set high(num value) { _ptr.high = _unwrap(value); }

  NodeList get labels() => _wrap(_ptr.labels);

  num get low() => _wrap(_ptr.low);

  void set low(num value) { _ptr.low = _unwrap(value); }

  num get max() => _wrap(_ptr.max);

  void set max(num value) { _ptr.max = _unwrap(value); }

  num get min() => _wrap(_ptr.min);

  void set min(num value) { _ptr.min = _unwrap(value); }

  num get optimum() => _wrap(_ptr.optimum);

  void set optimum(num value) { _ptr.optimum = _unwrap(value); }

  num get value() => _wrap(_ptr.value);

  void set value(num value) { _ptr.value = _unwrap(value); }
}
