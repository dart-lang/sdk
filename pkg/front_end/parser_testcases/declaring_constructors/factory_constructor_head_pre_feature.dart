// @dart=3.10
class C {
  external factory ();
  external factory C();
  external factory name();
  external factory C.name();
  factory () => C();
  factory C() => C();
  factory name() => C();
  factory C.name() => C();
  factory () {}
  factory C() {}
  factory name() {}
  factory C.name() {}
  factory () = C;
  factory C() = C;
  factory name() = C;
  factory C.name() = C;
  external const factory ();
  external const factory C();
  external const factory name();
  external const factory C.name();
  const factory () => C();
  const factory C() => C();
  const factory name() => C();
  const factory C.name() => C();
  const factory () {}
  const factory C() {}
  const factory name() {}
  const factory C.name() {}
  const factory () = C;
  const factory C() = C;
  const factory name() = C;
  const factory C.name() = C;

  void factory() => C(); // Not a factory constructor.
}