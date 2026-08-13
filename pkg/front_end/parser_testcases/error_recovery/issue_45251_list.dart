class F {
  /* notice the bracket at the end instead of parenthesis! */
  final List<Undefined> foo1 = List<List<int>>[];

  // variation #1: OK.
  final List<Undefined> foo2 = <List<int>>[];

  // variation #2: Bad.
  final List<Undefined> foo3 = List[];

  // variation #3: OK.
  final List<Undefined> foo4 = List<List<int>>();

  // variation #4: OK.
  final List<Undefined> foo5 = List();

  // variation #5: Bad.
  final List<Undefined> foo6 = List<List<int>>[null];

  // variation #6: This is actually just an indexed expression.
  final List<Undefined> foo7 = List[null];

  // variation #7: OK.
  final List<Undefined> foo8 = <List<int>>[null];

  // variation #8: OK.
  final List<Undefined> foo9 = [null];
}