// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

foo1(int? x) => <int>[?x];
foo2(String? x) => <String>{?x};
foo3(bool? x, num y) => <bool, num>{?x: y};

bar1(int? x) => <int>[?x];
bar2(int? x, bool b) => <int>{ if (b) ?x };
bar3(int? x, List<String> y) => <int>{ for (var _ in y) ?x };
bar4(String x, bool? y) => <String, bool>{x: ?y};
bar5(int? x, num y) => <int, num>{?x: y};
bar6(Symbol? x, String? y) => <Symbol, String>{?x: ?y};
bar7(int? x, double? y, bool b) => <int, double>{ if (b) ?x: ?y };
bar8(bool? x, Symbol? y, List<num> z) => <bool, Symbol>{ for (var _ in z) ?x: ?y };

main() {
  expectShallowEqualLists(foo1(0), <int>[0]);
  expectShallowEqualLists(foo1(null), <int>[]);
  expectShallowEqualSets(foo2(""), <String>{""});
  expectShallowEqualSets(foo2(null), <String>{});
  expectShallowEqualMaps(foo3(false, 0), <bool, num>{false: 0});
  expectShallowEqualMaps(foo3(null, 0), <bool, num>{});

  expectShallowEqualLists(bar1(0), <int>[0]);
  expectShallowEqualLists(bar1(null), <int>[]);
  expectShallowEqualSets(bar2(0, true), <int>{0});
  expectShallowEqualSets(bar2(0, false), <int>{});
  expectShallowEqualSets(bar2(null, true), <int>{});
  expectShallowEqualSets(bar2(null, false), <int>{});
  expectShallowEqualSets(bar3(0, ["", ""]), <int>{0});
  expectShallowEqualSets(bar3(null, ["", ""]), <int>{});
  expectShallowEqualSets(bar3(0, []), <int>{});
  expectShallowEqualSets(bar3(null, []), <int>{});
  expectShallowEqualMaps(bar4("", false), <String, bool>{"": false});
  expectShallowEqualMaps(bar4("", null), <String, bool>{});
  expectShallowEqualMaps(bar5(0, 1.0), <int, num>{0: 1.0});
  expectShallowEqualMaps(bar5(null, 1.0), <int, num>{});
  expectShallowEqualMaps(bar6(#key, ""), <Symbol, String>{#key: ""});
  expectShallowEqualMaps(bar6(#key, null), <Symbol, String>{});
  expectShallowEqualMaps(bar6(null, ""), <Symbol, String>{});
  expectShallowEqualMaps(bar6(null, null), <Symbol, String>{});
  expectShallowEqualMaps(bar7(0, 1.0, true), <int, double>{0: 1.0});
  expectShallowEqualMaps(bar7(0, 1.0, false), <int, double>{});
  expectShallowEqualMaps(bar7(0, null, true), <int, double>{});
  expectShallowEqualMaps(bar7(0, null, false), <int, double>{});
  expectShallowEqualMaps(bar7(null, 1.0, true), <int, double>{});
  expectShallowEqualMaps(bar7(null, 1.0, false), <int, double>{});
  expectShallowEqualMaps(bar7(null, null, true), <int, double>{});
  expectShallowEqualMaps(bar7(null, null, false), <int, double>{});
  expectShallowEqualMaps(bar8(false, #value, [1.0]), <bool, Symbol>{false: #value});
  expectShallowEqualMaps(bar8(false, #value, []), <int, double>{});
  expectShallowEqualMaps(bar8(false, null, [1.0]), <int, double>{});
  expectShallowEqualMaps(bar8(false, null, []), <int, double>{});
  expectShallowEqualMaps(bar8(null, #value, [1.0]), <int, double>{});
  expectShallowEqualMaps(bar8(null, #value, []), <int, double>{});
  expectShallowEqualMaps(bar8(null, null, [1.0]), <int, double>{});
  expectShallowEqualMaps(bar8(null, null, []), <int, double>{});
}

void expectShallowEqualLists(List x, List y) {
  bool equals = true;
  if (x.length != y.length) {
    equals = false;
  } else {
    for (int i = 0; i < x.length; i++) {
      if (x[i] != y[i]) {
        equals = false;
        break;
      }
    }
  }
  if (!equals) {
    throw "Expected the values to be equal, got '${x}' != '${y}'.";
  }
}

void expectShallowEqualSets(Set x, Set y) {
  if (!x.containsAll(y) || !y.containsAll(x)) {
    throw "Expected the values to be equal, got '${x}' != '${y}'.";
  }
}

void expectShallowEqualMaps(Map x, Map y) {
  bool equals = true;
  for (dynamic key in x.keys) {
    if (!y.containsKey(key)) {
      equals = false;
      break;
    } else {
      if (x[key] != y[key]) {
        equals = false;
        break;
      }
    }
  }
  if (!x.keys.toSet().containsAll(y.keys)) {
    equals = false;
  }
  if (!equals) {
    throw "Expected the values to be equal, got '${x}' != '${y}'.";
  }
}
