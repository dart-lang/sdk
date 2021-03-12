class F {
  /* notice the braces at the end instead of parenthesis! */
  final Set<Undefined> foo1 = const Set<List<int>>{};

  // variation #1: OK.
  final Set<Undefined> foo2 = const <List<int>>{};

  // variation #2: Bad.
  final Set<Undefined> foo3 = const Set{};

  // variation #3: OK.
  final Set<Undefined> foo4 = const Set<List<int>>();

  // variation #4: OK.
  final Set<Undefined> foo5 = const Set();

  // variation #5: Bad.
  final Set<Undefined> foo6 = const Set<List<int>>{null};

  // variation #6: Bad.
  final Set<Undefined> foo7 = const Set{null};

  // variation #7: OK.
  final Set<Undefined> foo8 = const <List<int>>{null};

  // variation #8: OK.
  final Set<Undefined> foo9 = const {null};
}