class C {
  static final Expando<int> _debugIds = new Expando<int>();

  static int _nextDebugId = 0;

  @override
  String toString() {
    int id = _debugIds[this] ??= _nextDebugId++;
    return 'C$id';
  }
}

main() {
  print(C());
}
