library meta;

class _Immutable {
  const _Immutable();
}

const _Immutable immutable = const _Immutable();

@immutable
class D {
  D.c1(a) : assert(a.toString() != null);  // OK
  D.c2(a) : assert(a != null);  // LINT
}
