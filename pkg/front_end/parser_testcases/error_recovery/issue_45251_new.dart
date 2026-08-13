class F {
  /* notice the braces at the end instead of parenthesis! */
  final Map<String, Undefined> foo1 = new Map<String, List<int>>{};

  // variation #1: new makes it bad.
  final Map<String, Undefined> foo2 = new <String, List<int>>{};

  // variation #2: Bad.
  final Map<String, Undefined> foo3 = new Map{};

  // variation #3: OK.
  final Map<String, Undefined> foo4 = new Map<String, List<int>>();

  // variation #4: OK.
  final Map<String, Undefined> foo5 = new Map();

  // variation #5: Bad.
  final Map<String, Undefined> foo6 = new Map<String, List<int>>{"a": null};

  // variation #6: Bad.
  final Map<String, Undefined> foo7 = new Map{"a": null};

  // variation #7: OK.
  final Map<String, Undefined> foo8 = new <String, List<int>>{"a": null};

  // variation #8: new makes it bad.
  final Map<String, Undefined> foo9 = new {"a": null};
}