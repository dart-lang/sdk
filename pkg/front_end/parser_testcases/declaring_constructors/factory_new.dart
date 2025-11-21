// TODO(johnniwinther): Improve error recovery.
class C {
  factory new();
  const factory new();
  factory new() => 0;
  const factory new() => 0;
  factory new() = C;
  const factory new() = C;
}