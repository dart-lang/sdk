// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This is a helper function to suggest to the type inference that the argument
// is a map and should be disambiguated as such, without affecting the type
// arguments of the map argument
acceptsMap<X, Y>(Map<X, Y> m) {}

// This is a helper function to suggest to the type inference that the argument
// is a set and should be disambiguated as such, without affecting the type
// argument of the set argument.
acceptsSet<X>(Set<X> m) {}

String? foo() => null;

main() {
  // 1. Downwards inference.

  // The type context for the expression under `?` is the nullable version of
  // the downwards inference context, so `contextType` should capture `num?`
  // instead of `num`.
  <num>[?contextType(null)..expectStaticType<Exactly<num?>>()];
  <num>[0, ?contextType(null)..expectStaticType<Exactly<num?>>()];
  <num>[?contextType(null)..expectStaticType<Exactly<num?>>(), 0];

  <num>{?contextType(null)..expectStaticType<Exactly<num?>>()};
  <num>{0, ?contextType(null)..expectStaticType<Exactly<num?>>()};
  <num>{?contextType(null)..expectStaticType<Exactly<num?>>(), 0};

  <num, String>{
    ?contextType(null)..expectStaticType<Exactly<num?>>():
    contextType("")..expectStaticType<Exactly<String>>()};
  <num, String>{
    0: "",
    ?contextType(null)..expectStaticType<Exactly<num?>>():
    contextType("")..expectStaticType<Exactly<String>>()};
  <num, String>{
    ?contextType(null)..expectStaticType<Exactly<num?>>():
    contextType("")..expectStaticType<Exactly<String>>(),
    0: ""};

  <bool, num>{
    contextType(false)..expectStaticType<Exactly<bool>>():
    ?contextType(null)..expectStaticType<Exactly<num?>>()};
  <bool, num>{
    false: 0,
    contextType(false)..expectStaticType<Exactly<bool>>():
    ?contextType(null)..expectStaticType<Exactly<num?>>()};
  <bool, num>{
    contextType(false)..expectStaticType<Exactly<bool>>():
    ?contextType(null)..expectStaticType<Exactly<num?>>(),
    false: 0};

  // 2. Upwards inference.

  // The type argument should be inferred as `String` due to the null-aware
  // marker, even though the type of `foo()` is `String?`.

  acceptsMap({?foo(): 0}..expectStaticType<Exactly<Map<String, int>>>());
  acceptsMap({"": 0, ?foo(): 0}..expectStaticType<Exactly<Map<String, int>>>());
  acceptsMap({?foo(): 0, "": 0}..expectStaticType<Exactly<Map<String, int>>>());

  acceptsMap({false: ?foo()}..expectStaticType<Exactly<Map<bool, String>>>());
  acceptsMap({true: "", false: ?foo()}..expectStaticType<Exactly<Map<bool, String>>>());
  acceptsMap({false: ?foo(), true: ""}..expectStaticType<Exactly<Map<bool, String>>>());

  [?foo()]..expectStaticType<Exactly<List<String>>>();
  ["", ?foo()]..expectStaticType<Exactly<List<String>>>();
  [?foo(), ""]..expectStaticType<Exactly<List<String>>>();

  acceptsSet({?foo()}..expectStaticType<Exactly<Set<String>>>());
  acceptsSet({"", ?foo()}..expectStaticType<Exactly<Set<String>>>());
  acceptsSet({?foo(), ""}..expectStaticType<Exactly<Set<String>>>());
}

X contextType<X>(Object? value) => value as X;

typedef Exactly<X> = X Function(X);

extension E<X> on X {
  void expectStaticType<Y extends Exactly<X>>() {}
}
