library meta;

class _Required {
  const _Required();
}

const _Required required = const _Required();

class A {
  var a;
  A.c({
    @required a, // OK
    b, // LINT
    @required c, // OK
  })
      : assert(a != null),
        assert(b != null);
}
