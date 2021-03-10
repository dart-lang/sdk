// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This test contains a test case for each condition that can lead to the front
// end's `NullableSpreadError` error, for which we wish to report "why not
// promoted" context information.

class C {
  List<int>? listQuestion;
  Object? objectQuestion;
  Set<int>? setQuestion;
  Map<int, int>? mapQuestion;
}

list_from_list_question(C c) {
  if (c.listQuestion == null) return;
  return [
    ... /*analyzer.notPromoted(propertyNotPromoted(target: member:C.listQuestion, type: List<int>?))*/ c
        . /*cfe.notPromoted(propertyNotPromoted(target: member:C.listQuestion, type: List<int>?))*/ listQuestion
  ];
}

list_from_set_question(C c) {
  if (c.setQuestion == null) return;
  return [
    ... /*analyzer.notPromoted(propertyNotPromoted(target: member:C.setQuestion, type: Set<int>?))*/ c
        . /*cfe.notPromoted(propertyNotPromoted(target: member:C.setQuestion, type: Set<int>?))*/ setQuestion
  ];
}

list_from_map_question(C c) {
  if (c.mapQuestion == null) return;
  return [
    ... /*analyzer.notPromoted(propertyNotPromoted(target: member:C.mapQuestion, type: Map<int, int>?))*/ c
        . /*cfe.notPromoted(propertyNotPromoted(target: member:C.mapQuestion, type: Map<int, int>?))*/ mapQuestion
  ];
}

list_from_object_question(C c) {
  if (c.objectQuestion is! List<int>) return;
  return [
    ... /*analyzer.notPromoted(propertyNotPromoted(target: member:C.objectQuestion, type: Object?))*/ c
        . /*cfe.notPromoted(propertyNotPromoted(target: member:C.objectQuestion, type: Object?))*/ objectQuestion
  ];
}

set_from_list_question(C c) {
  if (c.listQuestion == null) return;
  return {
    ... /*analyzer.notPromoted(propertyNotPromoted(target: member:C.listQuestion, type: List<int>?))*/ c
        . /*cfe.notPromoted(propertyNotPromoted(target: member:C.listQuestion, type: List<int>?))*/ listQuestion
  };
}

set_from_set_question(C c) {
  if (c.setQuestion == null) return;
  return {
    ... /*analyzer.notPromoted(propertyNotPromoted(target: member:C.setQuestion, type: Set<int>?))*/ c
        . /*cfe.notPromoted(propertyNotPromoted(target: member:C.setQuestion, type: Set<int>?))*/ setQuestion
  };
}

set_from_map_question(C c) {
  if (c.mapQuestion == null) return;
  return {
    ... /*analyzer.notPromoted(propertyNotPromoted(target: member:C.mapQuestion, type: Map<int, int>?))*/ c
        . /*cfe.notPromoted(propertyNotPromoted(target: member:C.mapQuestion, type: Map<int, int>?))*/ mapQuestion
  };
}

set_from_object_question_type_disambiguate_by_entry(C c) {
  if (c.objectQuestion is! Set<int>) return;
  return {
    null,
    ... /*analyzer.notPromoted(propertyNotPromoted(target: member:C.objectQuestion, type: Object?))*/ c
        . /*cfe.notPromoted(propertyNotPromoted(target: member:C.objectQuestion, type: Object?))*/ objectQuestion
  };
}

set_from_object_question_type_disambiguate_by_previous_spread(C c) {
  if (c.objectQuestion is! Set<int>) return;
  return {
    ...<int>{},
    ... /*analyzer.notPromoted(propertyNotPromoted(target: member:C.objectQuestion, type: Object?))*/ c
        . /*cfe.notPromoted(propertyNotPromoted(target: member:C.objectQuestion, type: Object?))*/ objectQuestion
  };
}

set_from_object_question_type_disambiguate_by_literal_args(C c) {
  if (c.objectQuestion is! Set<int>) return;
  return <int>{
    ... /*analyzer.notPromoted(propertyNotPromoted(target: member:C.objectQuestion, type: Object?))*/ c
        . /*cfe.notPromoted(propertyNotPromoted(target: member:C.objectQuestion, type: Object?))*/ objectQuestion
  };
}

map_from_list_question(C c) {
  if (c.listQuestion == null) return;
  return {
    ... /*analyzer.notPromoted(propertyNotPromoted(target: member:C.listQuestion, type: List<int>?))*/ c
        . /*cfe.notPromoted(propertyNotPromoted(target: member:C.listQuestion, type: List<int>?))*/ listQuestion
  };
}

map_from_set_question(C c) {
  if (c.setQuestion == null) return;
  return {
    ... /*analyzer.notPromoted(propertyNotPromoted(target: member:C.setQuestion, type: Set<int>?))*/ c
        . /*cfe.notPromoted(propertyNotPromoted(target: member:C.setQuestion, type: Set<int>?))*/ setQuestion
  };
}

map_from_map_question(C c) {
  if (c.mapQuestion == null) return;
  return {
    ... /*analyzer.notPromoted(propertyNotPromoted(target: member:C.mapQuestion, type: Map<int, int>?))*/ c
        . /*cfe.notPromoted(propertyNotPromoted(target: member:C.mapQuestion, type: Map<int, int>?))*/ mapQuestion
  };
}

map_from_object_question_type_disambiguate_by_key_value_pair(C c) {
  if (c.objectQuestion is! Map<int, int>) return;
  return {
    null: null,
    ... /*analyzer.notPromoted(propertyNotPromoted(target: member:C.objectQuestion, type: Object?))*/ c
        . /*cfe.notPromoted(propertyNotPromoted(target: member:C.objectQuestion, type: Object?))*/ objectQuestion
  };
}

map_from_object_question_type_disambiguate_by_previous_spread(C c) {
  if (c.objectQuestion is! Map<int, int>) return;
  return {
    ...<int, int>{},
    ... /*analyzer.notPromoted(propertyNotPromoted(target: member:C.objectQuestion, type: Object?))*/ c
        . /*cfe.notPromoted(propertyNotPromoted(target: member:C.objectQuestion, type: Object?))*/ objectQuestion
  };
}

map_from_set_question_type_disambiguate_by_literal_args(C c) {
  // Note: analyzer shows "why not promoted" information here, but CFE doesn't.
  // That's probably ok, since there are two problems here (set/map mismatch and
  // null safety); it's a matter of interpretation whether to prioritize one or
  // the other.
  if (c.setQuestion == null) return;
  return <int, int>{
    ...
    /*analyzer.notPromoted(propertyNotPromoted(target: member:C.setQuestion, type: Set<int>?))*/ c
        .setQuestion
  };
}
