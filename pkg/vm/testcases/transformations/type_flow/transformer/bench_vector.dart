import 'dart:typed_data';

class _Vector {
  _Vector(int size)
      : _offset = 0,
        _length = size,
        _elements = new Float64List(size);

  _Vector.fromVOL(List<double> values, int offset, int length)
      : _offset = offset,
        _length = length,
        _elements = values;

  final int _offset;

  final int _length;

  final List<double> _elements;

  double operator [](int i) => _elements[i + _offset];
  void operator []=(int i, double value) {
    _elements[i + _offset] = value;
  }

  double operator *(_Vector a) {
    double result = 0.0;
    for (int i = 0; i < _length; i += 1) result += this[i] * a[i];
    return result;
  }
}

_Vector v = new _Vector(10);
double x = 0.0;

main(List<String> args) {
  Stopwatch timer = new Stopwatch()..start();

  for (int i = 0; i < 100000000; i++) {
    x = x + v * v;
  }

  timer.stop();
  print("Elapsed ${timer.elapsedMilliseconds}ms, result $x");
}
