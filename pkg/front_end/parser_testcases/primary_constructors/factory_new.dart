class C {
  external factory new();
  external const factory new();
  factory new() => 0;
  const factory new() => 0;
  factory new() = C;
  const factory new() = C;

  external factory new.named();
  external const factory new.named();
  factory new.named() => 0;
  const factory new.named() => 0;
  factory new.named() = C;
  const factory new.named() = C;
}