// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../../static_type_helper.dart';

/// Test that the type of a local variable is treated as a "type of interest"
/// for the variable, and that for non-final variables, the initialization (if
/// any) is treated as an assignment for the purposes of promotion.

/// Verify that the declared type of a local variable is a type of interest.
void declaredTypeIsATypeOfInterest() {
  // Check that a variable declared with a non-nullable type can be assignment
  // demoted back to its declared type after being promoted.
  {
    num x = 3;
    x.expectStaticType<Exactly<num>>();
    // Promote x to int
    if (x is int) {
      x.expectStaticType<Exactly<int>>();
      // Verify that demotion back to num works
      x = 3.5;
      x.expectStaticType<Exactly<num>>();
    }
    x.expectStaticType<Exactly<num>>();
  }

  // Check that a variable declared with a nullable type can be assignment
  // promoted to the non-nullable variant of its type, and demoted back to both
  // the non-nullable variant and the declared type after being promoted.
  {
    num? x = (3 as num?);
    x.expectStaticType<Exactly<num?>>();
    // This should promote to num, since num and num? should both be types of
    // interest.
    x = 3;
    x.expectStaticType<Exactly<num>>();
    // Promote x to int
    if (x is int) {
      x.expectStaticType<Exactly<int>>();
      // Verify that demotion back to num works
      x = 3.5;
      x.expectStaticType<Exactly<num>>();
    }
    x.expectStaticType<Exactly<num>>();
    // Verify that demotion back to num? works
    x = null;
    x.expectStaticType<Exactly<num?>>();
  }

  // Check that a late variable declared with a non-nullable type can be
  // assignment demoted back to its declared type after being promoted.
  {
    late num x = 3;
    x.expectStaticType<Exactly<num>>();
    // Promote x to int
    if (x is int) {
      x.expectStaticType<Exactly<int>>();
      // Verify that demotion back to num works
      x = 3.5;
      x.expectStaticType<Exactly<num>>();
    }
    x.expectStaticType<Exactly<num>>();
  }

  // Check that a late variable declared with a nullable type can be assignment
  // promoted to the non-nullable variant of its type, and demoted back to both
  // the non-nullable variant and the declared type after being promoted.
  {
    late num? x = (3 as num?);
    x.expectStaticType<Exactly<num?>>();
    // This should promote to num, since num and num? should both be types of
    // interest.
    x = 3;
    x.expectStaticType<Exactly<num>>();
    // Promote x to int
    if (x is int) {
      x.expectStaticType<Exactly<int>>();
      // Verify that demotion back to num works
      x = 3.5;
      x.expectStaticType<Exactly<num>>();
    }
    x.expectStaticType<Exactly<num>>();
    // Verify that demotion back to num? works
    x = null;
    x.expectStaticType<Exactly<num?>>();
  }

  // Final variables are not re-assignable, but can still be subject to
  // to assignment based promotion and demotion in a few situations.

  // Check that a late final variable declared with a non-nullable type can be
  // assignment demoted back to its declared type after being promoted.
  {
    late final num x;
    // Make x potentially assigned, and initialize it
    if (num == num) {
      x = 3.5;
    }
    // Branch will not be taken to avoid a double initialization error
    if (x is int) {
      x.expectStaticType<Exactly<int>>();
      x = 3.5; // Demote to num.
      x.expectStaticType<Exactly<num>>();
    }
  }

  // Check that a final variable declared with a non-nullable type can be
  // assignment promoted to the non-nullable variant of its type.
  {
    final num? x;
    // Promote to num, since num is a type of interest
    x = 3;
    // Verify that we have promoted to num
    x.expectStaticType<Exactly<num>>();
  }

  // Check that a late final variable declared with a non-nullable type can be
  // assignment promoted to the non-nullable variant of its type.
  {
    late final num? x;
    // Promote to num, since num is a type of interest
    x = 3;
    // Verify that we have promoted to num
    x.expectStaticType<Exactly<num>>();
  }
}

/// Verify that the inferred type of a local variable is a type of interest.
void inferredTypeIsATypeOfInterest() {
  // Check that a variable inferred with a non-nullable type can be
  // assignment demoted back to its declared type after being promoted.
  {
    var x = (3 as num);
    x.expectStaticType<Exactly<num>>();
    // Promote x to int
    if (x is int) {
      x.expectStaticType<Exactly<int>>();
      // Verify that demotion back to num works
      x = 3.5;
      x.expectStaticType<Exactly<num>>();
    }
    x.expectStaticType<Exactly<num>>();
  }

  // Check that a variable inferred to have a nullable type can be assignment
  // promoted to the non-nullable variant of its type, and demoted back to both
  // the non-nullable variant and the declared type after being promoted.
  {
    var x = (3 as num?);
    x.expectStaticType<Exactly<num?>>();
    // This should promote to num, since num and num? should both be types of
    // interest.
    x = 3;
    x.expectStaticType<Exactly<num>>();
    // Promote x to int
    if (x is int) {
      x.expectStaticType<Exactly<int>>();
      // Verify that demotion back to num works
      x = 3.5;
      x.expectStaticType<Exactly<num>>();
    }
    x.expectStaticType<Exactly<num>>();
    // Verify that demotion back to num? works
    x = null;
    x.expectStaticType<Exactly<num?>>();
  }

  // Check that a variable inferred with a non-nullable type can be
  // assignment demoted back to its declared type after being promoted.
  {
    late var x = (3 as num);
    x.expectStaticType<Exactly<num>>();
    // Promote x to int
    if (x is int) {
      x.expectStaticType<Exactly<int>>();
      // Verify that demotion back to num works
      x = 3.5;
      x.expectStaticType<Exactly<num>>();
    }
    x.expectStaticType<Exactly<num>>();
  }

  // Check that a late variable inferred to have a nullable type can be
  // assignment promoted to the non-nullable variant of its type, and demoted
  // back to both the non-nullable variant and the declared type after being
  // promoted.
  {
    late var x = (3 as num?);
    x.expectStaticType<Exactly<num?>>();
    // This should promote to num, since num and num? should both be types of
    // interest.
    x = 3;
    x.expectStaticType<Exactly<num>>();
    // Promote x to int
    if (x is int) {
      x.expectStaticType<Exactly<int>>();
      // Verify that demotion back to num works
      x = 3.5;
      x.expectStaticType<Exactly<num>>();
    }
    x.expectStaticType<Exactly<num>>();
    // Verify that demotion back to num? works
    x = null;
    x.expectStaticType<Exactly<num?>>();
  }
}

/// Verify that the initializer on a mutable variable is treated as if it were
/// an assignment for the purposes of promotion, and therefore assigning a
/// non-nullable value can promote to a non-nullable variant of the declared
/// type.
void initializersOnVarPromote() {
  // Check that a variable declared to have a nullable type can be promoted on
  // initialization to the non-nullable variant of its type, demoted back to the
  // declared type, and assignment promoted to the non-nullable variant of the
  // declared type.
  {
    num? x = 3;
    // Verify that we have promoted to num
    x.expectStaticType<Exactly<num>>();
    // Verify that num? is a type of interest by demoting to it
    x = null;
    x.expectStaticType<Exactly<num?>>();
    // Verify that num is a type of interest by promoting to it.
    x = 3;
    x.expectStaticType<Exactly<num>>();
  }

  // Check that a late variable declared to have a nullable type can be promoted
  // on initialization to the non-nullable variant of its type, demoted back to
  // the declared type, and assignment promoted to the non-nullable variant of
  // the declared type.
  {
    late num? x = 3;
    // Verify that we have promoted to num
    x.expectStaticType<Exactly<num>>();
    // Verify that num? is a type of interest by demoting to it
    x = null;
    x.expectStaticType<Exactly<num?>>();
    // Verify that num is a type of interest by promoting to it.
    x = 3;
    x.expectStaticType<Exactly<num>>();
  }
}

/// Verify that the initializer on a final variable is not treated as if it were
/// an assignment for the purposes of promotion, and therefore assigning a
/// non-nullable value does not promote to a non-nullable variant of the
/// declared type.
void initializersOnFinalDoNotPromote() {
  // Check that a final nullable variable initialized with a non-nullable value
  // does not get promoted by the initializer to the non-nullable variant of the
  // type.
  {
    final num? x = 3;
    // Verify that we have not promoted to num
    x.expectStaticType<Exactly<num?>>();
  }

  // Check that a late final nullable variable initialized with a non-nullable
  // value does not get promoted by the initializer to the non-nullable variant
  // of the type.
  {
    late final num? x = 3;
    // Verify that we have not promoted to num
    x.expectStaticType<Exactly<num?>>();
  }
}

/// Check that when an initializer is a promoted type variable `X & T`, the
/// inferred type of the variable is `X`, but that the variable is immediately
/// promoted to `X & T`.
void typeVariableTypedVariableInferencePromotes<T>(T x0, T x1, bool b) {
  if (x0 is num) {
    // Promote `x0` to T & num

    {
      // Declare y, which should have inferred type T, and be promoted to T &
      // num
      var y = x0;
      // Check that y is assignable to z, and hence that y is still promoted to
      // T & num
      num z = y;
      // Check that y can be demoted to T, but do it conditionally so that T &
      // num remains a type of interest.
      if (b) y = x1;
      // T & num is still a type of interest, and hence this assignment should
      // promote to T & num.
      y = x0;
      // Check that y is assignable to z, and hence that y has been promoted T &
      // num
      z = y;
    }

    {
      // Declare y, which should have inferred type T, and be promoted to T &
      // num
      late var y = x0;
      // Check that y is assignable to z, and hence that y is still promoted to
      // T & num
      num z = y;
      // Check that y can be demoted to T, but do it conditionally so that T &
      // num remains a type of interest.
      if (b) y = x1;
      // T & num is still a type of interest, and hence this assignment should
      // promote to T & num.
      y = x0;
      // Check that y is assignable to z, and hence that y has been promoted T &
      // num
      z = y;
    }

    {
      // Declare y, which should have inferred type T, and be promoted to T &
      // num
      final y = x0;
      // Check that y is assignable to z, and hence that y is still promoted to
      // T & num
      num z = y;
    }

    {
      // Declare y, which should have inferred type T, and be promoted to T &
      // num
      late final y = x0;
      // Check that y is assignable to z, and hence that y is still promoted to
      // T & num
      num z = y;
    }
  }
}

void main() {
  declaredTypeIsATypeOfInterest();
  inferredTypeIsATypeOfInterest();
  initializersOnVarPromote();
  initializersOnFinalDoNotPromote();
  typeVariableTypedVariableInferencePromotes<num>(3, 3.5, true);
}
