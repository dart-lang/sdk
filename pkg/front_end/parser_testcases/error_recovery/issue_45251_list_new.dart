class F {
  /* notice the bracket at the end instead of parenthesis! */
  final List<Undefined> foo1 = new List<List<int>>[];

  // variation #1: new makes it bad.
  final List<Undefined> foo2 = new <List<int>>[];

  // variation #2: Bad.
  final List<Undefined> foo3 = new List[];

  // variation #3: OK.
  final List<Undefined> foo4 = new List<List<int>>();

  // variation #4: OK.
  final List<Undefined> foo5 = new List();

  // variation #5: Bad.
  final List<Undefined> foo6 = new List<List<int>>[null];

  // variation #6: new makes it bad. Without new it would be an indexed
  // expression; We should probably recover as `[null]`.
  final List<Undefined> foo7 = new List[null];

  // variation #7: new makes it bad.
  final List<Undefined> foo8 = new <List<int>>[null];

  // variation #8: new makes it bad.
  final List<Undefined> foo9 = new [null];
}