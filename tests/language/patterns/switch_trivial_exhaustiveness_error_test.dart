// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedOptions=--enable-experiment=patterns,records

// Flow analysis doesn't do full exhaustiveness analysis of switch statements,
// but it detects if a switch statement is "trivially exhaustive".  A switch
// statement is trivially exhaustive if it has at least one case that fully
// covers the matched value type.
//
// Also, flow analysis understands that after a case that fully covers the
// matched value type, any further cases are unreachable.
//
// We detect whether flow analysis considers the switch exhaustive by assigning
// to a nullable variable in all cases (this promotes the variable to
// non-nullable), and seeing whether the promotion lasts after the switch.

import '../static_type_helper.dart';

void testTwoCasesSecondExhaustive(Object x) {
  // Trivially exhaustive because the second case fully covers the matched type
  bool? y;
  switch (x) {
    case int _:
      y = true;
    case _:
      y = true;
  }
  y.expectStaticType<Exactly<bool>>();
}

void testTwoCasesNotExhaustive(Object x) {
  // Not exhaustive because neither case fully covers the matched type
  bool? y;
  switch (x) {
    case int _:
      y = true;
    case String _:
      y = true;
  }
  y.expectStaticType<Exactly<bool?>>();
}

void testUnreachableCase(Object x) {
  // Not only is this switch trivially exhaustive, but also the second case is
  // unreachable, and hence `y` remains promoted after the switch.
  bool? y;
  switch (x) {
    case _:
      y = true;
    case int _:
//  ^^^^
// [analyzer] HINT.UNREACHABLE_SWITCH_CASE
      y = null;
  }
  y.expectStaticType<Exactly<bool>>();
}

void testCastWhereSubpatternAlwaysMatches(Object x) {
  // Trivially exhaustive
  bool? y;
  switch (x) {
    case _ as int:
      y = true;
  }
  y.expectStaticType<Exactly<bool>>();
}

void testCastWhereSubpatternMatchesCastType(Object x) {
  // Trivially exhaustive
  bool? y;
  switch (x) {
    case bool() as bool:
      y = true;
  }
  y.expectStaticType<Exactly<bool>>();
}

void testCastWhereSubpatternMayFailToMatch(Object x) {
  // Not exhaustive
  bool? y;
  switch (x) {
    case (== 0) as int:
      y = true;
  }
  y.expectStaticType<Exactly<bool?>>();
}

void testListEmpty(List<Object> x) {
  // Not exhaustive
  bool? y;
  switch (x) {
    case []:
      y = true;
  }
  y.expectStaticType<Exactly<bool?>>();
}

void testListContainingNonRestPattern(List<Object> x) {
  // Not exhaustive
  bool? y;
  switch (x) {
    case [_]:
      y = true;
  }
  y.expectStaticType<Exactly<bool?>>();
}

void testListContainingNonRestPatternAndRestPattern(List<Object> x) {
  // Not exhaustive
  bool? y;
  switch (x) {
    case [_, ...]:
      y = true;
  }
  y.expectStaticType<Exactly<bool?>>();
}

void testListContainingRestPatternAndNonRestPattern(List<Object> x) {
  // Not exhaustive
  bool? y;
  switch (x) {
    case [..., _]:
      y = true;
  }
  y.expectStaticType<Exactly<bool?>>();
}

void testListContainingOnlyRestPattern(List<Object> x) {
  // Trivially exhaustive
  bool? y;
  switch (x) {
    case [...]:
      y = true;
  }
  y.expectStaticType<Exactly<bool>>();
}

void testListContainingOnlyRestPatternWithSubpatternWildcard(List<Object> x) {
  // Trivially exhaustive
  bool? y;
  switch (x) {
    case [..._]:
      y = true;
  }
  y.expectStaticType<Exactly<bool>>();
}

void testListContainingOnlyRestPatternWithSubpatternAnyList(List<Object> x) {
  // Trivially exhaustive
  bool? y;
  switch (x) {
    case [...[...]]:
      y = true;
  }
  y.expectStaticType<Exactly<bool>>();
}

void testListContainingOnlyRestPatternWithSubpatternObjectPattern(
    List<Object> x) {
  // Trivially exhaustive
  bool? y;
  switch (x) {
    case [...List()]:
      y = true;
  }
  y.expectStaticType<Exactly<bool>>();
}

void testListContainingOnlyRestPatternWithSubpatternOther(List<Object> x) {
  // Not exhaustive
  bool? y;
  switch (x) {
    case [...List(length: 1)]:
      y = true;
  }
  y.expectStaticType<Exactly<bool?>>();
}

void testListSupertype(List<Object> x) {
  // Trivially exhaustive
  bool? y;
  switch (x) {
    case <Object?>[...]:
      y = true;
  }
  y.expectStaticType<Exactly<bool>>();
}

void testListSubtype(List<Object> x) {
  // Not exhaustive
  bool? y;
  switch (x) {
    case <int>[...]:
      y = true;
  }
  y.expectStaticType<Exactly<bool?>>();
}

void testListSubtypeObject(Object x) {
  // Not exhaustive
  bool? y;
  switch (x) {
    case [...]:
      y = true;
  }
  y.expectStaticType<Exactly<bool?>>();
}

void testListUnrelatedType(List<Object> x) {
  // Not exhaustive
  bool? y;
  switch (x) {
    case <int?>[...]:
      y = true;
  }
  y.expectStaticType<Exactly<bool?>>();
}

void testMap(Map<Object, Object> x) {
  // Not exhaustive
  bool? y;
  switch (x) {
    case {0: _}:
      y = true;
  }
  y.expectStaticType<Exactly<bool?>>();
}

void testLogicalAndBothMatch(Object x) {
  // Trivially exhaustive because both subpatterns always match
  bool? y;
  switch (x) {
    case _ && _:
      y = true;
  }
  y.expectStaticType<Exactly<bool>>();
}

void testLogicalAndLhsMatches(Object x) {
  // Not exhaustive because only the LHS always matches
  bool? y;
  switch (x) {
    case _ && int _:
      y = true;
  }
  y.expectStaticType<Exactly<bool?>>();
}

void testLogicalAndRhsMatches(Object x) {
  // Not exhaustive because only the RHS always matches
  bool? y;
  switch (x) {
    case _ && int _:
      y = true;
  }
  y.expectStaticType<Exactly<bool?>>();
}

void testLogicalAndNeitherMatches(Object x) {
  // Not exhaustive because neither side always matches
  bool? y;
  switch (x) {
    case int _ && String _:
      y = true;
  }
  y.expectStaticType<Exactly<bool?>>();
}

void testLogicalOrBothMatch(Object x) {
  // Trivially exhaustive because both subpatterns always match
  bool? y;
  switch (x) {
    case _ || _:
      y = true;
  }
  y.expectStaticType<Exactly<bool>>();
}

void testLogicalOrLhsMatches(Object x) {
  // Trivially exhaustive because the LHS always matches
  bool? y;
  switch (x) {
    case _ || int _:
      y = true;
  }
  y.expectStaticType<Exactly<bool>>();
}

void testLogicalOrRhsMatches(Object x) {
  // Trivially exhaustive because the RHS always matches
  bool? y;
  switch (x) {
    case _ || int _:
      y = true;
  }
  y.expectStaticType<Exactly<bool>>();
}

void testLogicalOrNeitherMatches(Object x) {
  // Not exhaustive because neither side always matches
  bool? y;
  switch (x) {
    case int _ || String _:
      y = true;
  }
  y.expectStaticType<Exactly<bool?>>();
}

void testNullCheckAlwaysMatches(Object x) {
  // TODO(paulberry): should be trivially exhaustive because the matched value
  // type is non-nullable and the subpattern always matches
  bool? y;
  switch (x) {
    case _?:
      //  ^
      // [analyzer] STATIC_WARNING.UNNECESSARY_NULL_CHECK_PATTERN
      // [cfe] The null-check pattern will have no effect because the matched type isn't nullable.
      y = true;
  }
  y.expectStaticType<Exactly<bool?>>();
}

void testNullCheckNullableMatchedValueType(Object? x) {
  // Not exhaustive because the matched value type is nullable
  bool? y;
  switch (x) {
    case _?:
      y = true;
  }
  y.expectStaticType<Exactly<bool?>>();
}

void testNullCheckSubpatternMayFailToMatch(Object x) {
  // Not exhaustive because the subpattern may fail to match
  bool? y;
  switch (x) {
    case int _?:
      //      ^
      // [analyzer] STATIC_WARNING.UNNECESSARY_NULL_CHECK_PATTERN
      // [cfe] The null-check pattern will have no effect because the matched type isn't nullable.
      y = true;
  }
  y.expectStaticType<Exactly<bool?>>();
}

void testNullAssertSubpatternAlwaysMatches(Object? x) {
  // Trivially exhaustive because the subpattern always matches
  bool? y;
  switch (x) {
    case _!:
      y = true;
  }
  y.expectStaticType<Exactly<bool>>();
}

void testNullAssertSubpatternAlwaysMatchesObjectPattern(bool? x) {
  // Trivially exhaustive because the subpattern always matches
  bool? y;
  switch (x) {
    case bool()!:
      y = true;
  }
  y.expectStaticType<Exactly<bool>>();
}

void testNullAssertSubpatternMayFailToMatch(Object x) {
  // Not exhaustive because the subpattern may fail to match
  bool? y;
  switch (x) {
    case int _!:
      //      ^
      // [analyzer] STATIC_WARNING.UNNECESSARY_NULL_ASSERT_PATTERN
      // [cfe] The null-assert pattern will have no effect because the matched type isn't nullable.
      y = true;
  }
  y.expectStaticType<Exactly<bool?>>();
}

void testObjectSubtype(Object x) {
  // Not exhaustive
  bool? y;
  switch (x) {
    case int():
      y = true;
  }
  y.expectStaticType<Exactly<bool?>>();
}

void testObjectSupertype(Object x) {
  // Trivially exhaustive
  bool? y;
  switch (x) {
    case dynamic():
      y = true;
  }
  y.expectStaticType<Exactly<bool>>();
}

void testObjectUnrelatedType(List<String> x) {
  // Not exhaustive
  bool? y;
  switch (x) {
    case List<int>():
      y = true;
  }
  y.expectStaticType<Exactly<bool?>>();
}

void testObjectSubpatternAlwaysMatches(Object x) {
  // Trivially exhaustive because the hashCode always matches
  bool? y;
  switch (x) {
    case Object(hashCode: _):
      y = true;
  }
  y.expectStaticType<Exactly<bool>>();
}

void testObjectSubpatternMayFailToMatch(Object x) {
  // Not exhaustive because the hashCode may fail to match
  bool? y;
  switch (x) {
    case Object(hashCode: == 0):
      y = true;
  }
  y.expectStaticType<Exactly<bool?>>();
}

void testObjectTwoSubpatternsBothMatch(Object x) {
  // Trivially exhaustive because both subpatterns always match
  bool? y;
  switch (x) {
    case Object(hashCode: _, runtimeType: _):
      y = true;
  }
  y.expectStaticType<Exactly<bool>>();
}

void testObjectTwoSubpatternsFirstMatches(Object x) {
  // Not exhaustive because the runtimeType may not match
  bool? y;
  switch (x) {
    case Object(hashCode: _, runtimeType: == int):
      y = true;
  }
  y.expectStaticType<Exactly<bool?>>();
}

void testObjectTwoSubpatternsSecondMatches(Object x) {
  // Not exhaustive because the hashCode may not match
  bool? y;
  switch (x) {
    case Object(hashCode: == 0, runtimeType: _):
      y = true;
  }
  y.expectStaticType<Exactly<bool?>>();
}

void testObjectTwoSubpatternsNeitherMatches(Object x) {
  // Not exhaustive because neither subpattern always matches
  bool? y;
  switch (x) {
    case Object(hashCode: == 0, runtimeType: == int):
      y = true;
  }
  y.expectStaticType<Exactly<bool?>>();
}

void testRecordSubtype(Object x) {
  // Not exhaustive
  bool? y;
  switch (x) {
    case (_, _):
      y = true;
  }
  y.expectStaticType<Exactly<bool?>>();
}

void testRecordMatchingType((Object, Object) x) {
  // Trivially exhaustive
  bool? y;
  switch (x) {
    case (_, _):
      y = true;
  }
  y.expectStaticType<Exactly<bool>>();
}

void testRecordUnrelatedType(List<String> x) {
  // Not exhaustive
  bool? y;
  switch (x) {
    case (_, _):
      y = true;
  }
  y.expectStaticType<Exactly<bool?>>();
}

void testRecordSubpatternAlwaysMatches((Object,) x) {
  // Trivially exhaustive because the subpattern always matches
  bool? y;
  switch (x) {
    case (_,):
      y = true;
  }
  y.expectStaticType<Exactly<bool>>();
}

void testRecordSubpatternMayFailToMatch((Object,) x) {
  // Not exhaustive because the hashCode may fail to match
  bool? y;
  switch (x) {
    case (int _,):
      y = true;
  }
  y.expectStaticType<Exactly<bool?>>();
}

void testRecordTwoSubpatternsBothMatch((Object, Object) x) {
  // Trivially exhaustive because both subpatterns always match
  bool? y;
  switch (x) {
    case (_, _):
      y = true;
  }
  y.expectStaticType<Exactly<bool>>();
}

void testRecordTwoSubpatternsFirstMatches((Object, Object) x) {
  // Not exhaustive because the second subpattern may not match
  bool? y;
  switch (x) {
    case (_, int _):
      y = true;
  }
  y.expectStaticType<Exactly<bool?>>();
}

void testRecordTwoSubpatternsSecondMatches((Object, Object) x) {
  // Not exhaustive because the first subpattern may not match
  bool? y;
  switch (x) {
    case (int _, _):
      y = true;
  }
  y.expectStaticType<Exactly<bool?>>();
}

void testRecordTwoSubpatternsNeitherMatches((Object, Object) x) {
  // Not exhaustive because neither subpattern always matches
  bool? y;
  switch (x) {
    case (int _, int _):
      y = true;
  }
  y.expectStaticType<Exactly<bool?>>();
}

void testVariableSubtype(Object x) {
  // Not exhaustive because Object !<: int
  bool? y;
  switch (x) {
    case int v:
      y = true;
  }
  y.expectStaticType<Exactly<bool?>>();
}

void testVariableSupertype(Object x) {
  // Trivially exhaustive because Object <: Object?
  bool? y;
  switch (x) {
    case Object? v:
      y = true;
  }
  y.expectStaticType<Exactly<bool>>();
}

void testVariableUnrelatedType(List<String> x) {
  // Not exhaustive because List<String> !<: List<int>
  bool? y;
  switch (x) {
    case List<int> v:
      y = true;
  }
  y.expectStaticType<Exactly<bool?>>();
}

void testVariableUntyped(Object x) {
  // Trivially exhaustive because an untyped variable always matches
  bool? y;
  switch (x) {
    case var v:
      y = true;
  }
  y.expectStaticType<Exactly<bool>>();
}

void testWildcardSubtype(Object x) {
  // Not exhaustive because Object !<: int
  bool? y;
  switch (x) {
    case int _:
      y = true;
  }
  y.expectStaticType<Exactly<bool?>>();
}

void testWildcardSupertype(Object x) {
  // Trivially exhaustive because Object <: Object?
  bool? y;
  switch (x) {
    case Object? _:
      y = true;
  }
  y.expectStaticType<Exactly<bool>>();
}

void testWildcardUnrelatedType(List<String> x) {
  // Not exhaustive because List<String> !<: List<int>
  bool? y;
  switch (x) {
    case List<int> _:
      y = true;
  }
  y.expectStaticType<Exactly<bool?>>();
}

void testWildcardUntyped(Object x) {
  // Trivially exhaustive because an untyped wildcard always matches
  bool? y;
  switch (x) {
    case _:
      y = true;
  }
  y.expectStaticType<Exactly<bool>>();
}

void testRelationalNotEqualsNullWithNonNullableScrutinee(Object x) {
  // TODO(paulberry): this should be trivially exhaustive
  bool? y;
  switch (x) {
    case != null:
      y = true;
  }
  y.expectStaticType<Exactly<bool?>>();
}

void testRelationalNotEqualsNullWithNullableScrutinee(Object? x) {
  // Not exhaustive
  bool? y;
  switch (x) {
    case != null:
      y = true;
  }
  y.expectStaticType<Exactly<bool?>>();
}

void testRelationalEqualsNullWithNullScrutinee(Null x) {
  // Trivially exhaustive
  bool? y;
  switch (x) {
//^^^^^^
// [analyzer] COMPILE_TIME_ERROR.NON_EXHAUSTIVE_SWITCH_STATEMENT
    //    ^
    // [cfe] The type 'Null' is not exhaustively matched by the switch cases since it doesn't match 'null'.
    case == null:
      y = true;
  }
  y.expectStaticType<Exactly<bool>>();
}

void testRelationalEqualsNullWithOtherScrutinee(Object x) {
  // Not exhaustive
  bool? y;
  switch (x) {
    case == null:
      y = true;
  }
  y.expectStaticType<Exactly<bool?>>();
}

main() {}
