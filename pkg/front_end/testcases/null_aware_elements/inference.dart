// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

test1(int? x) {
  var y1 = [?x];
  expectType<List<int>>(y1);

  var y2 = [1, ?x];
  expectType<List<int>>(y2);

  var y3 = [1.0, ?x];
  expectType<List<num>>(y3);
}

test2(dynamic x) {
  List<String> y1 = [?new TypeExpecter<String?>().checkType(x)];

  List<String> y2 = ["", ?new TypeExpecter<String?>().checkType(x)];

  var y3 = ["", ?new TypeExpecter<dynamic>().checkType(x)];
}

test3(String? key) {
  var y1 = {?key: false};
  expectType<Map<String, bool>>(y1);

  var y2 = {"": false, ?key: false};
  expectType<Map<String, bool>>(y2);

  var y3 = {0: false, ?key: false};
  expectType<Map<Object?, bool>>(y3);
}

test4(dynamic key) {
  Map<Symbol, num> y1 = {?new TypeExpecter<Symbol?>().checkType(key): 1.0};

  Map<Symbol, num> y2 = {#key: 1.0, ?new TypeExpecter<Symbol?>().checkType(key): 1.0};

  var y3 = {#key: 1.0, ?new TypeExpecter<dynamic>().checkType(key): 1.0};
}

test5(String? value) {
  var y1 = {false: ?value};
  expectType<Map<bool, String>>(y1);

  var y2 = {false: "", true: ?value};
  expectType<Map<bool, String>>(y2);

  var y3 = {false: 0, true: ?value};
  expectType<Map<bool, Object?>>(y3);
}

test6(dynamic value) {
  Map<int, Symbol> y1 = {0: ?new TypeExpecter<Symbol?>().checkType(value)};

  Map<int, Symbol> y2 = {0: #key, 1: ?new TypeExpecter<Symbol?>().checkType(value)};

  var y3 = {0: #key, 1: ?new TypeExpecter<dynamic>().checkType(value)};
}

test7(int? key, Symbol? value) {
  var y1 = {?key: ?value};
  expectType<Map<int, Symbol>>(y1);

  var y2 = {0: #value, ?key: ?value};
  expectType<Map<int, Symbol>>(y2);

  var y3 = {0: 1.0, ?key: ?value};
  expectType<Map<int, Object?>>(y3);

  var y4 = {false: #value, ?key: ?value};
  expectType<Map<Object?, Symbol>>(y4);
}

test8(dynamic key, dynamic value) {
  Map<String, double> y1 = {
    ?new TypeExpecter<String?>().checkType(key): ?new TypeExpecter<double?>().checkType(value)
  };

  Map<String, double> y2 = {
    "": 1.0,
    ?new TypeExpecter<String?>().checkType(key): ?new TypeExpecter<double?>().checkType(value)
  };

  var y3 = {
    "": 1.0,
    ?new TypeExpecter<dynamic>().checkType(key): ?new TypeExpecter<dynamic>().checkType(value)
  };
}

main() {
  test1(0);
  test1(null);

  test2("element");
  test2(null);
  expectThrows<TypeError>(() {test2(0);});

  test3("key");
  test3(null);

  test4(#foo);
  test4(null);
  expectThrows<TypeError>(() {test4("foo");});

  test5("value");
  test5(null);

  test6(#foo);
  test6(null);
  expectThrows<TypeError>(() {test6("foo");});

  test7(0, #value);
  test7(0, null);
  test7(null, #value);
  test7(null, null);

  test8("key", 1.0);
  test8("key", null);
  test8(null, 1.0);
  test8(null, null);
  expectThrows<TypeError>(() {test8(#key, 1.0);});
  expectThrows<TypeError>(() {test8("key", "value");});
  expectThrows<TypeError>(() {test8(#key, "value");});
}

expectType<T>(x) {
  if (x is! T) {
    throw "Expected the passed value to be of type 'T', "
      "got '${x.runtimeType}'.";
  }
}

expectThrows<T>(void Function() f) {
  bool hasThrownT = true;
  try {
    f();
    hasThrownT = false;
  } on T {
    hasThrownT = true;
  } on dynamic {
    hasThrownT = false;
  }
  if (!hasThrownT) {
      throw "Expected the passed function to throw.";
  }
}

class TypeExpecter<X> {
  Y checkType<Y>(dynamic value) {
    if (X != Y) {
      throw "Expected the captured type ($Y) "
        "to be the same as the passed type ($X).";
    }
    return value as Y;
  }
}
