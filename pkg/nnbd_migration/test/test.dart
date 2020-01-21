class B<T extends Object> {
  B([C<T> t]);
}

abstract class C<T extends Object> {
  void f(T t);
}

class E {
  final C<Object> _base;
  E([C base]) : _base = base;
  f(Object t) {
    _base.f(t);
  }
}

void main() {
  E e = E();
  e.f(null);
}
