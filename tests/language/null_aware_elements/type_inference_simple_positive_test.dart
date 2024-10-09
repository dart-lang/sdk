// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedOptions=--enable-experiment=null-aware-elements

import '../static_type_helper.dart';

// This is a helper function to suggest to the type inference that the argument
// is a map and should be disambiguated as such, without affecting the type
// arguments of the map argument
acceptsMap<X, Y>(Map<X, Y> m) {}

// This is a helper function to suggest to the type inference that the argument
// is a set and should be disambiguated as such, without affecting the type
// argument of the set argument.
acceptsSet<X>(Set<X> m) {}

String? stringQuestion() => null;

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
  // marker, even though the type of `stringQuestion()` is `String?`.

  acceptsMap({?stringQuestion(): 0}..expectStaticType<Exactly<Map<String, int>>>());
  acceptsMap({"": 0, ?stringQuestion(): 0}..expectStaticType<Exactly<Map<String, int>>>());
  acceptsMap({?stringQuestion(): 0, "": 0}..expectStaticType<Exactly<Map<String, int>>>());

  acceptsMap({false: ?stringQuestion()}..expectStaticType<Exactly<Map<bool, String>>>());
  acceptsMap({true: "", false: ?stringQuestion()}..expectStaticType<Exactly<Map<bool, String>>>());
  acceptsMap({false: ?stringQuestion(), true: ""}..expectStaticType<Exactly<Map<bool, String>>>());

  [?stringQuestion()]..expectStaticType<Exactly<List<String>>>();
  ["", ?stringQuestion()]..expectStaticType<Exactly<List<String>>>();
  [?stringQuestion(), ""]..expectStaticType<Exactly<List<String>>>();

  acceptsSet({?stringQuestion()}..expectStaticType<Exactly<Set<String>>>());
  acceptsSet({"", ?stringQuestion()}..expectStaticType<Exactly<Set<String>>>());
  acceptsSet({?stringQuestion(), ""}..expectStaticType<Exactly<Set<String>>>());
}
