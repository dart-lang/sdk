class F {
  /* notice the braces at the end instead of parenthesis! */
  final Set<Undefined> foo1 = Set<List<int>>{};

  // variation #1: OK.
  final Set<Undefined> foo2 = <List<int>>{};

  // variation #2: Bad.
  final Set<Undefined> foo3 = Set{};

  // variation #3: OK.
  final Set<Undefined> foo4 = Set<List<int>>();

  // variation #4: OK.
  final Set<Undefined> foo5 = Set();

  // variation #5: Bad.
  final Set<Undefined> foo6 = Set<List<int>>{null};

  // variation #6: Bad.
  final Set<Undefined> foo7 = Set{null};

  // variation #7: OK.
  final Set<Undefined> foo8 = <List<int>>{null};

  // variation #8: OK.
  final Set<Undefined> foo9 = {null};
}