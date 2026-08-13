class F {
  /* notice the bracket at the end instead of parenthesis! */
  final List<Undefined> foo1 = const List<List<int>>[];

  // variation #1: OK.
  final List<Undefined> foo2 = const <List<int>>[];

  // variation #2: Bad.
  final List<Undefined> foo3 = const List[];

  // variation #3: OK.
  final List<Undefined> foo4 = const List<List<int>>();

  // variation #4: OK.
  final List<Undefined> foo5 = const List();

  // variation #5: Bad.
  final List<Undefined> foo6 = const List<List<int>>[null];

  // variation #6: const makes it bad. Without const it would be an indexed
  // expression; We should probably recover as `const [null]`.
  final List<Undefined> foo7 = const List[null];

  // variation #7: OK.
  final List<Undefined> foo8 = const <List<int>>[null];

  // variation #8: OK.
  final List<Undefined> foo9 = const [null];
}