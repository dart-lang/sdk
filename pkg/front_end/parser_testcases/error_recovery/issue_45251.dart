class F {
  /* notice the braces at the end instead of parenthesis! */
  final Map<String, Undefined> foo1 = Map<String, List<int>>{};

  // variation #1: OK.
  final Map<String, Undefined> foo2 = <String, List<int>>{};

  // variation #2: Bad.
  final Map<String, Undefined> foo3 = Map{};

  // variation #3: OK.
  final Map<String, Undefined> foo4 = Map<String, List<int>>();

  // variation #4: OK.
  final Map<String, Undefined> foo5 = Map();

  // variation #5: Bad.
  final Map<String, Undefined> foo6 = Map<String, List<int>>{"a": null};

  // variation #6: Bad.
  final Map<String, Undefined> foo7 = Map{"a": null};

  // variation #7: OK.
  final Map<String, Undefined> foo8 = <String, List<int>>{"a": null};

  // variation #8: OK.
  final Map<String, Undefined> foo9 = {"a": null};
}