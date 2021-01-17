// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../../static_type_helper.dart';

// This test checks various scenarios in which the use of a local variable for
// type promotion is not defeated by an assignment to the local variable itself
// or an assignment to the variable that would be promoted, due to the fact that
// there is no control flow path from the assignment to the use.

lateInitializer_noAssignments(int? x) {
  bool b = x != null;
  late final y = b ? x.expectStaticType<Exactly<int>>() : 3;
}

afterConditionalThen_toConditionalVar(int? x, bool b2) {
  try {
    bool b = x != null;
    if (b) x.expectStaticType<Exactly<int>>();
    b2
        ? [b = true, if (b) x.expectStaticType<Exactly<int?>>(), throw 'foo']
        : null;
    if (b) x.expectStaticType<Exactly<int>>();
  } on String {}
}

afterConditionalThen_toPromotedVar(int? x, bool b2, int? y) {
  try {
    bool b = x != null;
    if (b) x.expectStaticType<Exactly<int>>();
    b2
        ? [x = y, if (b) x.expectStaticType<Exactly<int?>>(), throw 'foo']
        : null;
    if (b) x.expectStaticType<Exactly<int>>();
  } on String {}
}

afterConditionalElse_toConditionalVar(int? x, bool b2) {
  try {
    bool b = x != null;
    if (b) x.expectStaticType<Exactly<int>>();
    b2
        ? null
        : [b = true, if (b) x.expectStaticType<Exactly<int?>>(), throw 'foo'];
    if (b) x.expectStaticType<Exactly<int>>();
  } on String {}
}

afterConditionalElse_toPromotedVar(int? x, bool b2, int? y) {
  try {
    bool b = x != null;
    if (b) x.expectStaticType<Exactly<int>>();
    b2
        ? null
        : [x = y, if (b) x.expectStaticType<Exactly<int?>>(), throw 'foo'];
    if (b) x.expectStaticType<Exactly<int>>();
  } on String {}
}

afterIfStatementThen_toConditionalVar(int? x, bool b2) {
  bool b = x != null;
  if (b) x.expectStaticType<Exactly<int>>();
  if (b2) {
    b = true;
    if (b) x.expectStaticType<Exactly<int?>>();
    return;
  }
  if (b) x.expectStaticType<Exactly<int>>();
}

afterIfStatementThen_toPromotedVar(int? x, bool b2, int? y) {
  bool b = x != null;
  if (b) x.expectStaticType<Exactly<int>>();
  if (b2) {
    x = y;
    if (b) x.expectStaticType<Exactly<int?>>();
    return;
  }
  if (b) x.expectStaticType<Exactly<int>>();
}

afterIfStatementElse_toConditionalVar(int? x, bool b2) {
  bool b = x != null;
  if (b) x.expectStaticType<Exactly<int>>();
  if (b2) {
  } else {
    b = true;
    if (b) x.expectStaticType<Exactly<int?>>();
    return;
  }
  if (b) x.expectStaticType<Exactly<int>>();
}

afterIfStatementElse_toPromotedVar(int? x, bool b2, int? y) {
  bool b = x != null;
  if (b) x.expectStaticType<Exactly<int>>();
  if (b2) {
  } else {
    x = y;
    if (b) x.expectStaticType<Exactly<int?>>();
    return;
  }
  if (b) x.expectStaticType<Exactly<int>>();
}

afterIfListThen_toConditionalVar(int? x, bool b2) {
  try {
    bool b = x != null;
    if (b) x.expectStaticType<Exactly<int>>();
    [
      if (b2)
        [b = true, if (b) x.expectStaticType<Exactly<int?>>(), throw 'foo']
    ];
    if (b) x.expectStaticType<Exactly<int>>();
  } on String {}
}

afterIfListThen_toPromotedVar(int? x, bool b2, int? y) {
  try {
    bool b = x != null;
    if (b) x.expectStaticType<Exactly<int>>();
    [
      if (b2) [x = y, if (b) x.expectStaticType<Exactly<int?>>(), throw 'foo']
    ];
    if (b) x.expectStaticType<Exactly<int>>();
  } on String {}
}

afterIfListElse_toConditionalVar(int? x, bool b2) {
  try {
    bool b = x != null;
    if (b) x.expectStaticType<Exactly<int>>();
    [
      if (b2)
        null
      else
        [b = true, if (b) x.expectStaticType<Exactly<int?>>(), throw 'foo']
    ];
    if (b) x.expectStaticType<Exactly<int>>();
  } on String {}
}

afterIfListElse_toPromotedVar(int? x, bool b2, int? y) {
  try {
    bool b = x != null;
    if (b) x.expectStaticType<Exactly<int>>();
    [
      if (b2)
        null
      else
        [x = y, if (b) x.expectStaticType<Exactly<int?>>(), throw 'foo']
    ];
    if (b) x.expectStaticType<Exactly<int>>();
  } on String {}
}

afterIfSetThen_toConditionalVar(int? x, bool b2) {
  try {
    bool b = x != null;
    if (b) x.expectStaticType<Exactly<int>>();
    ({
      if (b2)
        [b = true, if (b) x.expectStaticType<Exactly<int?>>(), throw 'foo']
    });
    if (b) x.expectStaticType<Exactly<int>>();
  } on String {}
}

afterIfSetThen_toPromotedVar(int? x, bool b2, int? y) {
  try {
    bool b = x != null;
    if (b) x.expectStaticType<Exactly<int>>();
    ({
      if (b2) [x = y, if (b) x.expectStaticType<Exactly<int?>>(), throw 'foo']
    });
    if (b) x.expectStaticType<Exactly<int>>();
  } on String {}
}

afterIfSetElse_toConditionalVar(int? x, bool b2) {
  try {
    bool b = x != null;
    if (b) x.expectStaticType<Exactly<int>>();
    ({
      if (b2)
        null
      else
        [b = true, if (b) x.expectStaticType<Exactly<int?>>(), throw 'foo']
    });
    if (b) x.expectStaticType<Exactly<int>>();
  } on String {}
}

afterIfSetElse_toPromotedVar(int? x, bool b2, int? y) {
  try {
    bool b = x != null;
    if (b) x.expectStaticType<Exactly<int>>();
    ({
      if (b2)
        null
      else
        [x = y, if (b) x.expectStaticType<Exactly<int?>>(), throw 'foo']
    });
    if (b) x.expectStaticType<Exactly<int>>();
  } on String {}
}

afterIfMapKeyThen_toConditionalVar(int? x, bool b2) {
  try {
    bool b = x != null;
    if (b) x.expectStaticType<Exactly<int>>();
    ({
      if (b2)
        [b = true, if (b) x.expectStaticType<Exactly<int?>>(), throw 'foo']:
            null
    });
    if (b) x.expectStaticType<Exactly<int>>();
  } on String {}
}

afterIfMapKeyThen_toPromotedVar(int? x, bool b2, int? y) {
  try {
    bool b = x != null;
    if (b) x.expectStaticType<Exactly<int>>();
    ({
      if (b2)
        [x = y, if (b) x.expectStaticType<Exactly<int?>>(), throw 'foo']: null
    });
    if (b) x.expectStaticType<Exactly<int>>();
  } on String {}
}

afterIfMapKeyElse_toConditionalVar(int? x, bool b2) {
  try {
    bool b = x != null;
    if (b) x.expectStaticType<Exactly<int>>();
    ({
      if (b2)
        null: null
      else
        [b = true, if (b) x.expectStaticType<Exactly<int?>>(), throw 'foo']:
            null
    });
    if (b) x.expectStaticType<Exactly<int>>();
  } on String {}
}

afterIfMapKeyElse_toPromotedVar(int? x, bool b2, int? y) {
  try {
    bool b = x != null;
    if (b) x.expectStaticType<Exactly<int>>();
    ({
      if (b2)
        null: null
      else
        [x = y, if (b) x.expectStaticType<Exactly<int?>>(), throw 'foo']: null
    });
    if (b) x.expectStaticType<Exactly<int>>();
  } on String {}
}

afterIfMapValueThen_toConditionalVar(int? x, bool b2) {
  try {
    bool b = x != null;
    if (b) x.expectStaticType<Exactly<int>>();
    ({
      if (b2)
        null: [
          b = true,
          if (b) x.expectStaticType<Exactly<int?>>(),
          throw 'foo'
        ]
    });
    if (b) x.expectStaticType<Exactly<int>>();
  } on String {}
}

afterIfMapValueThen_toPromotedVar(int? x, bool b2, int? y) {
  try {
    bool b = x != null;
    if (b) x.expectStaticType<Exactly<int>>();
    ({
      if (b2)
        null: [x = y, if (b) x.expectStaticType<Exactly<int?>>(), throw 'foo']
    });
    if (b) x.expectStaticType<Exactly<int>>();
  } on String {}
}

afterIfMapValueElse_toConditionalVar(int? x, bool b2) {
  try {
    bool b = x != null;
    if (b) x.expectStaticType<Exactly<int>>();
    ({
      if (b2)
        null: null
      else
        null: [
          b = true,
          if (b) x.expectStaticType<Exactly<int?>>(),
          throw 'foo'
        ]
    });
    if (b) x.expectStaticType<Exactly<int>>();
  } on String {}
}

afterIfMapValueElse_toPromotedVar(int? x, bool b2, int? y) {
  try {
    bool b = x != null;
    if (b) x.expectStaticType<Exactly<int>>();
    ({
      if (b2)
        null: null
      else
        null: [x = y, if (b) x.expectStaticType<Exactly<int?>>(), throw 'foo']
    });
    if (b) x.expectStaticType<Exactly<int>>();
  } on String {}
}

afterSwitch_toConditionalVar(int? x, int i) {
  bool b = x != null;
  if (b) x.expectStaticType<Exactly<int>>();
  switch (i) {
    case 0:
      b = true;
      if (b) x.expectStaticType<Exactly<int?>>();
      return;
    case 1:
      break;
  }
  if (b) x.expectStaticType<Exactly<int>>();
}

afterSwitch_toPromotedVar(int? x, int i, int? y) {
  bool b = x != null;
  if (b) x.expectStaticType<Exactly<int>>();
  switch (i) {
    case 0:
      x = y;
      if (b) x.expectStaticType<Exactly<int?>>();
      return;
    case 1:
      break;
  }
  if (b) x.expectStaticType<Exactly<int>>();
}

afterTryCatchTry_toConditionalVar(int? x, bool b2) {
  bool b = x != null;
  if (b) x.expectStaticType<Exactly<int>>();
  try {
    if (b2) {
      b = true;
      if (b) x.expectStaticType<Exactly<int?>>();
      return;
    }
  } catch (_) {
    if (b) x.expectStaticType<Exactly<int?>>();
    return;
  }
  if (b) x.expectStaticType<Exactly<int>>();
}

afterTryCatchTry_toPromotedVar(int? x, bool b2, int? y) {
  bool b = x != null;
  if (b) x.expectStaticType<Exactly<int>>();
  try {
    if (b2) {
      x = y;
      if (b) x.expectStaticType<Exactly<int?>>();
      return;
    }
  } catch (_) {
    if (b) x.expectStaticType<Exactly<int?>>();
    return;
  }
  if (b) x.expectStaticType<Exactly<int>>();
}

afterTryCatchCatch_toConditionalVar(int? x) {
  bool b = x != null;
  if (b) x.expectStaticType<Exactly<int>>();
  try {} catch (_) {
    b = true;
    if (b) x.expectStaticType<Exactly<int?>>();
    return;
  }
  if (b) x.expectStaticType<Exactly<int>>();
}

afterTryCatchCatch_toPromotedVar(int? x, int? y) {
  bool b = x != null;
  if (b) x.expectStaticType<Exactly<int>>();
  try {} catch (_) {
    x = y;
    if (b) x.expectStaticType<Exactly<int?>>();
    return;
  }
  if (b) x.expectStaticType<Exactly<int>>();
}

afterTryFinallyTry_toConditionalVar(int? x, bool b2) {
  bool b = x != null;
  if (b) x.expectStaticType<Exactly<int>>();
  try {
    if (b2) {
      b = true;
      if (b) x.expectStaticType<Exactly<int?>>();
      return;
    }
  } finally {
    if (b) x.expectStaticType<Exactly<int?>>();
  }
  if (b) x.expectStaticType<Exactly<int>>();
}

afterTryFinallyTry_toPromotedVar(int? x, bool b2, int? y) {
  bool b = x != null;
  if (b) x.expectStaticType<Exactly<int>>();
  try {
    if (b2) {
      x = y;
      if (b) x.expectStaticType<Exactly<int?>>();
      return;
    }
  } finally {
    if (b) x.expectStaticType<Exactly<int?>>();
  }
  if (b) x.expectStaticType<Exactly<int>>();
}

afterTryFinallyFinally_toConditionalVar(int? x, bool b2) {
  bool b = x != null;
  if (b) x.expectStaticType<Exactly<int>>();
  try {} finally {
    if (b2) {
      b = true;
      if (b) x.expectStaticType<Exactly<int?>>();
      return;
    }
  }
  if (b) x.expectStaticType<Exactly<int>>();
}

afterTryFinallyFinally_toPromotedVar(int? x, bool b2, int? y) {
  bool b = x != null;
  if (b) x.expectStaticType<Exactly<int>>();
  try {} finally {
    if (b2) {
      x = y;
      if (b) x.expectStaticType<Exactly<int?>>();
      return;
    }
  }
  if (b) x.expectStaticType<Exactly<int>>();
}

switchLaterUnlabeled_toConditionalVar(int? x, int i) {
  bool b = x != null;
  if (b) x.expectStaticType<Exactly<int>>();
  switch (i) {
    case 0:
      // Promotion is preserved because the case clause is unlabeled, so there's
      // no path from the assignment back to here.
      if (b) x.expectStaticType<Exactly<int>>();
      break;
    case 1:
      b = true;
      break;
  }
}

switchLaterUnlabeled_toPromotedVar(int? x, int i, int? y) {
  bool b = x != null;
  if (b) x.expectStaticType<Exactly<int>>();
  switch (i) {
    case 0:
      // Promotion is preserved because the case clause is unlabeled, so there's
      // no path from the assignment back to here.
      if (b) x.expectStaticType<Exactly<int>>();
      break;
    case 1:
      x = y;
      break;
  }
}

main() {
  lateInitializer_noAssignments(0);
  lateInitializer_noAssignments(null);
  afterConditionalThen_toConditionalVar(0, true);
  afterConditionalThen_toConditionalVar(null, true);
  afterConditionalThen_toPromotedVar(0, true, null);
  afterConditionalThen_toPromotedVar(null, true, null);
  afterConditionalElse_toConditionalVar(0, false);
  afterConditionalElse_toConditionalVar(null, false);
  afterConditionalElse_toPromotedVar(0, false, null);
  afterConditionalElse_toPromotedVar(null, false, null);
  afterIfStatementThen_toConditionalVar(0, true);
  afterIfStatementThen_toConditionalVar(null, true);
  afterIfStatementThen_toPromotedVar(0, true, null);
  afterIfStatementThen_toPromotedVar(null, true, null);
  afterIfStatementElse_toConditionalVar(0, false);
  afterIfStatementElse_toConditionalVar(null, false);
  afterIfStatementElse_toPromotedVar(0, false, null);
  afterIfStatementElse_toPromotedVar(null, false, null);
  afterIfListThen_toConditionalVar(0, true);
  afterIfListThen_toConditionalVar(null, true);
  afterIfListThen_toPromotedVar(0, true, null);
  afterIfListThen_toPromotedVar(null, true, null);
  afterIfListElse_toConditionalVar(0, false);
  afterIfListElse_toConditionalVar(null, false);
  afterIfListElse_toPromotedVar(0, false, null);
  afterIfListElse_toPromotedVar(null, false, null);
  afterIfSetThen_toConditionalVar(0, true);
  afterIfSetThen_toConditionalVar(null, true);
  afterIfSetThen_toPromotedVar(0, true, null);
  afterIfSetThen_toPromotedVar(null, true, null);
  afterIfSetElse_toConditionalVar(0, false);
  afterIfSetElse_toConditionalVar(null, false);
  afterIfSetElse_toPromotedVar(0, false, null);
  afterIfSetElse_toPromotedVar(null, false, null);
  afterIfMapKeyThen_toConditionalVar(0, true);
  afterIfMapKeyThen_toConditionalVar(null, true);
  afterIfMapKeyThen_toPromotedVar(0, true, null);
  afterIfMapKeyThen_toPromotedVar(null, true, null);
  afterIfMapKeyElse_toConditionalVar(0, false);
  afterIfMapKeyElse_toConditionalVar(null, false);
  afterIfMapKeyElse_toPromotedVar(0, false, null);
  afterIfMapKeyElse_toPromotedVar(null, false, null);
  afterIfMapValueThen_toConditionalVar(0, true);
  afterIfMapValueThen_toConditionalVar(null, true);
  afterIfMapValueThen_toPromotedVar(0, true, null);
  afterIfMapValueThen_toPromotedVar(null, true, null);
  afterIfMapValueElse_toConditionalVar(0, false);
  afterIfMapValueElse_toConditionalVar(null, false);
  afterIfMapValueElse_toPromotedVar(0, false, null);
  afterIfMapValueElse_toPromotedVar(null, false, null);
  afterSwitch_toConditionalVar(0, 1);
  afterSwitch_toConditionalVar(null, 1);
  afterSwitch_toPromotedVar(0, 1, null);
  afterSwitch_toPromotedVar(null, 1, null);
  afterTryCatchTry_toConditionalVar(0, false);
  afterTryCatchTry_toConditionalVar(null, false);
  afterTryCatchTry_toPromotedVar(0, false, null);
  afterTryCatchTry_toPromotedVar(null, false, null);
  afterTryCatchCatch_toConditionalVar(0);
  afterTryCatchCatch_toConditionalVar(null);
  afterTryCatchCatch_toPromotedVar(0, null);
  afterTryCatchCatch_toPromotedVar(null, null);
  afterTryFinallyTry_toConditionalVar(0, false);
  afterTryFinallyTry_toConditionalVar(null, false);
  afterTryFinallyTry_toPromotedVar(0, false, null);
  afterTryFinallyTry_toPromotedVar(null, false, null);
  afterTryFinallyFinally_toConditionalVar(0, false);
  afterTryFinallyFinally_toConditionalVar(null, false);
  afterTryFinallyFinally_toPromotedVar(0, false, null);
  afterTryFinallyFinally_toPromotedVar(null, false, null);
  switchLaterUnlabeled_toConditionalVar(0, 0);
  switchLaterUnlabeled_toConditionalVar(null, 0);
  switchLaterUnlabeled_toPromotedVar(0, 0, null);
  switchLaterUnlabeled_toPromotedVar(null, 0, null);
}
