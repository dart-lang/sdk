// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Can't run in strong mode since it contains a legacy library.
// Requirements=nnbd-weak

import 'package:expect/expect.dart';

import 'function_type_bounds_legacy_lib.dart';
import 'function_type_bounds_null_safe_lib.dart';

main() {
  // void fn<T extends Object>() is void Function<T extends Object>()
  Expect.isTrue(fnWithNonNullObjectBound is fnTypeWithNonNullObjectBound);
  // void fn<T extends Object>() is void Function<T extends Object*>()
  Expect.isTrue(fnWithNonNullObjectBound is fnTypeWithLegacyObjectBound);
  // void fn<T extends Object?>() is void Function<T extends Object*>()
  Expect.isTrue(fnWithNullableObjectBound is fnTypeWithLegacyObjectBound);
  // void fn<T extends Object*>() is void Function<T extends Object>()
  Expect.isTrue(fnWithLegacyObjectBound is fnTypeWithNonNullObjectBound);
  // void fn<T extends Object*>() is void Function<T extends Object?>()
  Expect.isTrue(fnWithLegacyObjectBound is fnTypeWithNullableObjectBound);

  // void fn<T extends int>() is void Function<T extends int>()
  Expect.isTrue(fnWithNonNullIntBound is fnTypeWithNonNullIntBound);
  // void fn<T extends int>() is void Function<T extends int*>()
  Expect.isTrue(fnWithNonNullIntBound is fnTypeWithLegacyIntBound);
  // void fn<T extends int?>() is void Function<T extends int*>()
  Expect.isTrue(fnWithNullableIntBound is fnTypeWithLegacyIntBound);
  // void fn<T extends int*>() is void Function<T extends int>()
  Expect.isTrue(fnWithLegacyIntBound is fnTypeWithNonNullIntBound);
  // void fn<T extends int*>() is void Function<T extends int?>()
  Expect.isTrue(fnWithLegacyIntBound is fnTypeWithNullableIntBound);

  // void fn<T extends String*, S extends Object*>() is
  //   void Function<T extends String, S extends Object?>()
  Expect.isTrue(fnWithLegacyStringLegacyObjectBounds
      is fnTypeWithNonNullableStringNullableObjectBounds);

  // void fn<T extends String, S extends Object?>() is
  //   void Function<T extends String*, S extends Object*>()
  Expect.isTrue(fnWithNonNullableStringNullableObjectBounds
      is fnTypeWithLegacyStringLegacyObjectBounds);
}
