// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../../static_type_helper.dart';

// This test checks various scenarios in which the use of a local variable for
// type promotion is defeated, either by an assignment to the local variable
// itself or an assignment to the variable that would be promoted.

direct_toConditionVar(int? x) {
  bool b = x != null;
  if (b) x.expectStaticType<Exactly<int>>();
  b = true;
  if (b) x.expectStaticType<Exactly<int?>>();
}

direct_toPromotedVar(int? x, int? y) {
  bool b = x != null;
  if (b) x.expectStaticType<Exactly<int>>();
  x = y;
  if (b) x.expectStaticType<Exactly<int?>>();
}

lateInitializer_toConditionalVar(int? x) {
  bool b = x != null;
  late final y = b ? x.expectStaticType<Exactly<int?>>() : 3;
  b = true;
}

lateInitializer_toPromotedVar(int? x, int? y) {
  bool b = x != null;
  late final y = b ? x.expectStaticType<Exactly<int?>>() : 3;
  x = y;
}

afterConditionalThen_toConditionVar(int? x, bool b2) {
  bool b = x != null;
  if (b) x.expectStaticType<Exactly<int>>();
  b2 ? b = true : null;
  if (b) x.expectStaticType<Exactly<int?>>();
}

afterConditionalThen_toPromotedVar(int? x, bool b2, int? y) {
  bool b = x != null;
  if (b) x.expectStaticType<Exactly<int>>();
  b2 ? x = y : null;
  if (b) x.expectStaticType<Exactly<int?>>();
}

afterConditionalElse_toConditionVar(int? x, bool b2) {
  bool b = x != null;
  if (b) x.expectStaticType<Exactly<int>>();
  b2 ? null : b = true;
  if (b) x.expectStaticType<Exactly<int?>>();
}

afterConditionalElse_toPromotedVar(int? x, bool b2, int? y) {
  bool b = x != null;
  if (b) x.expectStaticType<Exactly<int>>();
  b2 ? null : x = y;
  if (b) x.expectStaticType<Exactly<int?>>();
}

afterIfStatementThen_toConditionVar(int? x, bool b2) {
  bool b = x != null;
  if (b) x.expectStaticType<Exactly<int>>();
  if (b2) b = true;
  if (b) x.expectStaticType<Exactly<int?>>();
}

afterIfStatementThen_toPromotedVar(int? x, bool b2, int? y) {
  bool b = x != null;
  if (b) x.expectStaticType<Exactly<int>>();
  if (b2) x = y;
  if (b) x.expectStaticType<Exactly<int?>>();
}

afterIfStatementElse_toConditionVar(int? x, bool b2) {
  bool b = x != null;
  if (b) x.expectStaticType<Exactly<int>>();
  if (b2) {
  } else {
    b = true;
  }
  if (b) x.expectStaticType<Exactly<int?>>();
}

afterIfStatementElse_toPromotedVar(int? x, bool b2, int? y) {
  bool b = x != null;
  if (b) x.expectStaticType<Exactly<int>>();
  if (b2) {
  } else {
    x = y;
  }
  if (b) x.expectStaticType<Exactly<int?>>();
}

afterIfListThen_toConditionVar(int? x, bool b2) {
  bool b = x != null;
  if (b) x.expectStaticType<Exactly<int>>();
  [if (b2) b = true];
  if (b) x.expectStaticType<Exactly<int?>>();
}

afterIfListThen_toPromotedVar(int? x, bool b2, int? y) {
  bool b = x != null;
  if (b) x.expectStaticType<Exactly<int>>();
  [if (b2) x = y];
  if (b) x.expectStaticType<Exactly<int?>>();
}

afterIfListElse_toConditionVar(int? x, bool b2) {
  bool b = x != null;
  if (b) x.expectStaticType<Exactly<int>>();
  [if (b2) null else b = true];
  if (b) x.expectStaticType<Exactly<int?>>();
}

afterIfListElse_toPromotedVar(int? x, bool b2, int? y) {
  bool b = x != null;
  if (b) x.expectStaticType<Exactly<int>>();
  [if (b2) null else x = y];
  if (b) x.expectStaticType<Exactly<int?>>();
}

afterIfSetThen_toConditionVar(int? x, bool b2) {
  bool b = x != null;
  if (b) x.expectStaticType<Exactly<int>>();
  ({if (b2) b = true});
  if (b) x.expectStaticType<Exactly<int?>>();
}

afterIfSetThen_toPromotedVar(int? x, bool b2, int? y) {
  bool b = x != null;
  if (b) x.expectStaticType<Exactly<int>>();
  ({if (b2) x = y});
  if (b) x.expectStaticType<Exactly<int?>>();
}

afterIfSetElse_toConditionVar(int? x, bool b2) {
  bool b = x != null;
  if (b) x.expectStaticType<Exactly<int>>();
  ({if (b2) null else b = true});
  if (b) x.expectStaticType<Exactly<int?>>();
}

afterIfSetElse_toPromotedVar(int? x, bool b2, int? y) {
  bool b = x != null;
  if (b) x.expectStaticType<Exactly<int>>();
  ({if (b2) null else x = y});
  if (b) x.expectStaticType<Exactly<int?>>();
}

afterIfMapKeyThen_toConditionVar(int? x, bool b2) {
  bool b = x != null;
  if (b) x.expectStaticType<Exactly<int>>();
  ({if (b2) b = true: null});
  if (b) x.expectStaticType<Exactly<int?>>();
}

afterIfMapKeyThen_toPromotedVar(int? x, bool b2, int? y) {
  bool b = x != null;
  if (b) x.expectStaticType<Exactly<int>>();
  ({if (b2) x = y: null});
  if (b) x.expectStaticType<Exactly<int?>>();
}

afterIfMapKeyElse_toConditionVar(int? x, bool b2) {
  bool b = x != null;
  if (b) x.expectStaticType<Exactly<int>>();
  ({if (b2) null: null else b = true: null});
  if (b) x.expectStaticType<Exactly<int?>>();
}

afterIfMapKeyElse_toPromotedVar(int? x, bool b2, int? y) {
  bool b = x != null;
  if (b) x.expectStaticType<Exactly<int>>();
  ({if (b2) null: null else x = y: null});
  if (b) x.expectStaticType<Exactly<int?>>();
}

afterIfMapValueThen_toConditionVar(int? x, bool b2) {
  bool b = x != null;
  if (b) x.expectStaticType<Exactly<int>>();
  ({if (b2) null: b = true});
  if (b) x.expectStaticType<Exactly<int?>>();
}

afterIfMapValueThen_toPromotedVar(int? x, bool b2, int? y) {
  bool b = x != null;
  if (b) x.expectStaticType<Exactly<int>>();
  ({if (b2) null: x = y});
  if (b) x.expectStaticType<Exactly<int?>>();
}

afterIfMapValueElse_toConditionVar(int? x, bool b2) {
  bool b = x != null;
  if (b) x.expectStaticType<Exactly<int>>();
  ({if (b2) null: null else null: b = true});
  if (b) x.expectStaticType<Exactly<int?>>();
}

afterIfMapValueElse_toPromotedVar(int? x, bool b2, int? y) {
  bool b = x != null;
  if (b) x.expectStaticType<Exactly<int>>();
  ({if (b2) null: null else null: x = y});
  if (b) x.expectStaticType<Exactly<int?>>();
}

doLater_toConditionalVar(int? x, int i) {
  bool b = x != null;
  if (b) x.expectStaticType<Exactly<int>>();
  do {
    if (b) x.expectStaticType<Exactly<int?>>();
    b = true;
  } while (i-- > 0);
}

doLater_toPromotedVar(int? x, int i, int? y) {
  bool b = x != null;
  if (b) x.expectStaticType<Exactly<int>>();
  do {
    if (b) x.expectStaticType<Exactly<int?>>();
    x = y;
  } while (i-- > 0);
}

forLater_toConditionalVar(int? x, int i) {
  bool b = x != null;
  if (b) x.expectStaticType<Exactly<int>>();
  for (int j = 0; j < i; j++) {
    if (b) x.expectStaticType<Exactly<int?>>();
    b = true;
  }
}

forLater_toPromotedVar(int? x, int i, int? y) {
  bool b = x != null;
  if (b) x.expectStaticType<Exactly<int>>();
  for (int j = 0; j < i; j++) {
    if (b) x.expectStaticType<Exactly<int?>>();
    x = y;
  }
}

forEachLater_toConditionalVar(int? x) {
  bool b = x != null;
  if (b) x.expectStaticType<Exactly<int>>();
  for (var v in [null]) {
    if (b) x.expectStaticType<Exactly<int?>>();
    b = true;
  }
}

forEachLater_toPromotedVar(int? x, int? y) {
  bool b = x != null;
  if (b) x.expectStaticType<Exactly<int>>();
  for (var v in [null]) {
    if (b) x.expectStaticType<Exactly<int?>>();
    x = y;
  }
}

whileLater_toConditionalVar(int? x, int i) {
  bool b = x != null;
  if (b) x.expectStaticType<Exactly<int>>();
  while (i-- > 0) {
    if (b) x.expectStaticType<Exactly<int?>>();
    b = true;
  }
}

whileLater_toPromotedVar(int? x, int i, int? y) {
  bool b = x != null;
  if (b) x.expectStaticType<Exactly<int>>();
  while (i-- > 0) {
    if (b) x.expectStaticType<Exactly<int?>>();
    x = y;
  }
}

switchLaterLabeled_toConditionalVar(int? x, int i) {
  bool b = x != null;
  if (b) x.expectStaticType<Exactly<int>>();
  switch (i) {
    L:
    case 0:
      if (b) x.expectStaticType<Exactly<int?>>();
      break;
    case 1:
      b = true;
      continue L;
  }
}

switchLaterLabeled_toPromotedVar(int? x, int i, int? y) {
  bool b = x != null;
  if (b) x.expectStaticType<Exactly<int>>();
  switch (i) {
    L:
    case 0:
      if (b) x.expectStaticType<Exactly<int?>>();
      break;
    case 1:
      x = y;
      continue L;
  }
}

afterDo_toConditionalVar(int? x, int i) {
  bool b = x != null;
  if (b) x.expectStaticType<Exactly<int>>();
  do {
    b = true;
  } while (i-- > 0);
  if (b) x.expectStaticType<Exactly<int?>>();
}

afterDo_toPromotedVar(int? x, int i, int? y) {
  bool b = x != null;
  if (b) x.expectStaticType<Exactly<int>>();
  do {
    x = y;
  } while (i-- > 0);
  if (b) x.expectStaticType<Exactly<int?>>();
}

afterFor_toConditionalVar(int? x, int i) {
  bool b = x != null;
  if (b) x.expectStaticType<Exactly<int>>();
  for (int j = 0; j < i; j++) {
    b = true;
  }
  if (b) x.expectStaticType<Exactly<int?>>();
}

afterFor_toPromotedVar(int? x, int i, int? y) {
  bool b = x != null;
  if (b) x.expectStaticType<Exactly<int>>();
  for (int j = 0; j < i; j++) {
    x = y;
  }
  if (b) x.expectStaticType<Exactly<int?>>();
}

afterForEach_toConditionalVar(int? x, Iterable i) {
  bool b = x != null;
  if (b) x.expectStaticType<Exactly<int>>();
  for (var v in i) {
    b = true;
  }
  if (b) x.expectStaticType<Exactly<int?>>();
}

afterForEach_toPromotedVar(int? x, Iterable i, int? y) {
  bool b = x != null;
  if (b) x.expectStaticType<Exactly<int>>();
  for (var v in i) {
    x = y;
  }
  if (b) x.expectStaticType<Exactly<int?>>();
}

afterWhile_toConditionalVar(int? x, int i) {
  bool b = x != null;
  if (b) x.expectStaticType<Exactly<int>>();
  while (i-- > 0) {
    b = true;
  }
  if (b) x.expectStaticType<Exactly<int?>>();
}

afterWhile_toPromotedVar(int? x, int i, int? y) {
  bool b = x != null;
  if (b) x.expectStaticType<Exactly<int>>();
  while (i-- > 0) {
    x = y;
  }
  if (b) x.expectStaticType<Exactly<int?>>();
}

afterSwitch_toConditionalVar(int? x, int i) {
  bool b = x != null;
  if (b) x.expectStaticType<Exactly<int>>();
  switch (i) {
    case 0:
      b = true;
      break;
    case 1:
      break;
  }
  if (b) x.expectStaticType<Exactly<int?>>();
}

afterSwitch_toPromotedVar(int? x, int i, int? y) {
  bool b = x != null;
  if (b) x.expectStaticType<Exactly<int>>();
  switch (i) {
    case 0:
      x = y;
      break;
    case 1:
      break;
  }
  if (b) x.expectStaticType<Exactly<int?>>();
}

tryCatchCatch_toConditionalVar(int? x) {
  bool b = x != null;
  if (b) x.expectStaticType<Exactly<int>>();
  try {
    b = true;
  } catch (_) {
    if (b) x.expectStaticType<Exactly<int?>>();
  }
}

tryCatchCatch_toPromotedVar(int? x, int? y) {
  bool b = x != null;
  if (b) x.expectStaticType<Exactly<int>>();
  try {
    x = y;
  } catch (_) {
    if (b) x.expectStaticType<Exactly<int?>>();
  }
}

afterTryCatchTry_toConditionalVar(int? x) {
  bool b = x != null;
  if (b) x.expectStaticType<Exactly<int>>();
  try {
    b = true;
  } catch (_) {}
  if (b) x.expectStaticType<Exactly<int?>>();
}

afterTryCatchTry_toPromotedVar(int? x, int? y) {
  bool b = x != null;
  if (b) x.expectStaticType<Exactly<int>>();
  try {
    x = y;
  } catch (_) {}
  if (b) x.expectStaticType<Exactly<int?>>();
}

afterTryCatchCatch_toConditionalVar(int? x) {
  bool b = x != null;
  if (b) x.expectStaticType<Exactly<int>>();
  try {} catch (_) {
    b = true;
  }
  if (b) x.expectStaticType<Exactly<int?>>();
}

afterTryCatchCatch_toPromotedVar(int? x, int? y) {
  bool b = x != null;
  if (b) x.expectStaticType<Exactly<int>>();
  try {} catch (_) {
    x = y;
  }
  if (b) x.expectStaticType<Exactly<int?>>();
}

tryFinallyFinally_toConditionalVar(int? x) {
  bool b = x != null;
  if (b) x.expectStaticType<Exactly<int>>();
  try {
    b = true;
  } finally {
    if (b) x.expectStaticType<Exactly<int?>>();
  }
}

tryFinallyFinally_toPromotedVar(int? x, int? y) {
  bool b = x != null;
  if (b) x.expectStaticType<Exactly<int>>();
  try {
    x = y;
  } finally {
    if (b) x.expectStaticType<Exactly<int?>>();
  }
}

afterTryFinallyTry_toConditionalVar(int? x) {
  bool b = x != null;
  if (b) x.expectStaticType<Exactly<int>>();
  try {
    b = true;
  } finally {}
  if (b) x.expectStaticType<Exactly<int?>>();
}

afterTryFinallyTry_toPromotedVar(int? x, int? y) {
  bool b = x != null;
  if (b) x.expectStaticType<Exactly<int>>();
  try {
    x = y;
  } finally {}
  if (b) x.expectStaticType<Exactly<int?>>();
}

afterTryFinallyFinally_toConditionalVar(int? x) {
  bool b = x != null;
  if (b) x.expectStaticType<Exactly<int>>();
  try {} finally {
    b = true;
  }
  if (b) x.expectStaticType<Exactly<int?>>();
}

afterTryFinallyFinally_toPromotedVar(int? x, int? y) {
  bool b = x != null;
  if (b) x.expectStaticType<Exactly<int>>();
  try {} finally {
    x = y;
  }
  if (b) x.expectStaticType<Exactly<int?>>();
}

main() {
  direct_toConditionVar(0);
  direct_toConditionVar(null);
  direct_toPromotedVar(0, null);
  direct_toPromotedVar(null, null);
  lateInitializer_toConditionalVar(0);
  lateInitializer_toConditionalVar(null);
  lateInitializer_toPromotedVar(0, null);
  lateInitializer_toPromotedVar(null, null);
  afterConditionalThen_toConditionVar(0, true);
  afterConditionalThen_toConditionVar(null, true);
  afterConditionalThen_toPromotedVar(0, true, null);
  afterConditionalThen_toPromotedVar(null, true, null);
  afterConditionalElse_toConditionVar(0, false);
  afterConditionalElse_toConditionVar(null, false);
  afterConditionalElse_toPromotedVar(0, false, null);
  afterConditionalElse_toPromotedVar(null, false, null);
  afterIfStatementThen_toConditionVar(0, true);
  afterIfStatementThen_toConditionVar(null, true);
  afterIfStatementThen_toPromotedVar(0, true, null);
  afterIfStatementThen_toPromotedVar(null, true, null);
  afterIfStatementElse_toConditionVar(0, false);
  afterIfStatementElse_toConditionVar(null, false);
  afterIfStatementElse_toPromotedVar(0, false, null);
  afterIfStatementElse_toPromotedVar(null, false, null);
  afterIfListThen_toConditionVar(0, true);
  afterIfListThen_toConditionVar(null, true);
  afterIfListThen_toPromotedVar(0, true, null);
  afterIfListThen_toPromotedVar(null, true, null);
  afterIfListElse_toConditionVar(0, false);
  afterIfListElse_toConditionVar(null, false);
  afterIfListElse_toPromotedVar(0, false, null);
  afterIfListElse_toPromotedVar(null, false, null);
  afterIfSetThen_toConditionVar(0, true);
  afterIfSetThen_toConditionVar(null, true);
  afterIfSetThen_toPromotedVar(0, true, null);
  afterIfSetThen_toPromotedVar(null, true, null);
  afterIfSetElse_toConditionVar(0, false);
  afterIfSetElse_toConditionVar(null, false);
  afterIfSetElse_toPromotedVar(0, false, null);
  afterIfSetElse_toPromotedVar(null, false, null);
  afterIfMapKeyThen_toConditionVar(0, true);
  afterIfMapKeyThen_toConditionVar(null, true);
  afterIfMapKeyThen_toPromotedVar(0, true, null);
  afterIfMapKeyThen_toPromotedVar(null, true, null);
  afterIfMapKeyElse_toConditionVar(0, false);
  afterIfMapKeyElse_toConditionVar(null, false);
  afterIfMapKeyElse_toPromotedVar(0, false, null);
  afterIfMapKeyElse_toPromotedVar(null, false, null);
  afterIfMapValueThen_toConditionVar(0, true);
  afterIfMapValueThen_toConditionVar(null, true);
  afterIfMapValueThen_toPromotedVar(0, true, null);
  afterIfMapValueThen_toPromotedVar(null, true, null);
  afterIfMapValueElse_toConditionVar(0, false);
  afterIfMapValueElse_toConditionVar(null, false);
  afterIfMapValueElse_toPromotedVar(0, false, null);
  afterIfMapValueElse_toPromotedVar(null, false, null);
  doLater_toConditionalVar(0, 1);
  doLater_toConditionalVar(null, 1);
  doLater_toPromotedVar(0, 1, null);
  doLater_toPromotedVar(null, 1, null);
  forLater_toConditionalVar(0, 1);
  forLater_toConditionalVar(null, 1);
  forLater_toPromotedVar(0, 1, null);
  forLater_toPromotedVar(null, 1, null);
  forEachLater_toConditionalVar(0);
  forEachLater_toConditionalVar(null);
  forEachLater_toPromotedVar(0, null);
  forEachLater_toPromotedVar(null, null);
  whileLater_toConditionalVar(0, 1);
  whileLater_toConditionalVar(null, 1);
  whileLater_toPromotedVar(0, 1, null);
  whileLater_toPromotedVar(null, 1, null);
  switchLaterLabeled_toConditionalVar(0, 1);
  switchLaterLabeled_toConditionalVar(null, 1);
  switchLaterLabeled_toPromotedVar(0, 1, null);
  switchLaterLabeled_toPromotedVar(null, 1, null);
  afterDo_toConditionalVar(0, 1);
  afterDo_toConditionalVar(null, 1);
  afterDo_toPromotedVar(0, 1, null);
  afterDo_toPromotedVar(null, 1, null);
  afterFor_toConditionalVar(0, 1);
  afterFor_toConditionalVar(null, 1);
  afterFor_toPromotedVar(0, 1, null);
  afterFor_toPromotedVar(null, 1, null);
  afterForEach_toConditionalVar(0, [null]);
  afterForEach_toConditionalVar(null, [null]);
  afterForEach_toPromotedVar(0, [null], null);
  afterForEach_toPromotedVar(null, [null], null);
  afterWhile_toConditionalVar(0, 1);
  afterWhile_toConditionalVar(null, 1);
  afterWhile_toPromotedVar(0, 1, null);
  afterWhile_toPromotedVar(null, 1, null);
  afterSwitch_toConditionalVar(0, 0);
  afterSwitch_toConditionalVar(null, 0);
  afterSwitch_toPromotedVar(0, 0, null);
  afterSwitch_toPromotedVar(null, 0, null);
  tryCatchCatch_toConditionalVar(0);
  tryCatchCatch_toConditionalVar(null);
  tryCatchCatch_toPromotedVar(0, null);
  tryCatchCatch_toPromotedVar(null, null);
  afterTryCatchTry_toConditionalVar(0);
  afterTryCatchTry_toConditionalVar(null);
  afterTryCatchTry_toPromotedVar(0, null);
  afterTryCatchTry_toPromotedVar(null, null);
  afterTryCatchCatch_toConditionalVar(0);
  afterTryCatchCatch_toConditionalVar(null);
  afterTryCatchCatch_toPromotedVar(0, null);
  afterTryCatchCatch_toPromotedVar(null, null);
  tryFinallyFinally_toConditionalVar(0);
  tryFinallyFinally_toConditionalVar(null);
  tryFinallyFinally_toPromotedVar(0, null);
  tryFinallyFinally_toPromotedVar(null, null);
  afterTryFinallyTry_toConditionalVar(0);
  afterTryFinallyTry_toConditionalVar(null);
  afterTryFinallyTry_toPromotedVar(0, null);
  afterTryFinallyTry_toPromotedVar(null, null);
  afterTryFinallyFinally_toConditionalVar(0);
  afterTryFinallyFinally_toConditionalVar(null);
  afterTryFinallyFinally_toPromotedVar(0, null);
  afterTryFinallyFinally_toPromotedVar(null, null);
}
