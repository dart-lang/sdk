class F {
  /* notice the braces at the end instead of parenthesis! */
  final Set<Undefined> foo1 = new Set<List<int>>{};

  // variation #1: new makes it bad.
  final Set<Undefined> foo2 = new <List<int>>{};

  // variation #2: Bad.
  final Set<Undefined> foo3 = new Set{};

  // variation #3: OK.
  final Set<Undefined> foo4 = new Set<List<int>>();

  // variation #4: OK.
  final Set<Undefined> foo5 = new Set();

  // variation #5: Bad.
  final Set<Undefined> foo6 = new Set<List<int>>{null};

  // variation #6: Bad.
  final Set<Undefined> foo7 = new Set{null};

  // variation #7: new makes it bad.
  final Set<Undefined> foo8 = new <List<int>>{null};

  // variation #8: new makes it bad.
  final Set<Undefined> foo9 = new {null};
}