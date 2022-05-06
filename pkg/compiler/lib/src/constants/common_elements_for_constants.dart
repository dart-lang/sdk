// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../elements/types.dart';

/// This is a facade interface for the members of CommonElements that are
/// required by 'constants/value.dart'.
// TODO(48820): When CommonElements is migrated, remove this facade.
abstract class CommonElements {
  DartType get boolType;
  DartType get doubleType;
  DartType get dynamicType;
  DartType get intType;
  DartType get nullType;
  DartType get stringType;

  DartTypes get dartTypes;
}
