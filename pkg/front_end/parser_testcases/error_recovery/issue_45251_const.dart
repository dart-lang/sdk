class F {
  /* notice the braces at the end instead of parenthesis! */
  final Map<String, Undefined> foo1 = const Map<String, List<int>>{};

  // variation #1: OK.
  final Map<String, Undefined> foo2 = const <String, List<int>>{};

  // variation #2: Bad.
  final Map<String, Undefined> foo3 = const Map{};

  // variation #3: OK.
  final Map<String, Undefined> foo4 = const Map<String, List<int>>();

  // variation #4: OK.
  final Map<String, Undefined> foo5 = const Map();

  // variation #5: Bad.
  final Map<String, Undefined> foo6 = const Map<String, List<int>>{"a": null};

  // variation #6: Bad.
  final Map<String, Undefined> foo7 = const Map{"a": null};

  // variation #7: OK.
  final Map<String, Undefined> foo8 = const <String, List<int>>{"a": null};

  // variation #8: OK.
  final Map<String, Undefined> foo9 = const {"a": null};
}