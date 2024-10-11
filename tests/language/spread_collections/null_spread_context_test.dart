// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that the context type schema for a null-aware spread is correct (it
// should be nullable compared to context type schema for a non-null-aware
// spread).

import 'package:expect/static_type_helper.dart';

main() {
  {
    List<int> notNullAware = [
      ...(contextType(<int>[])..expectStaticType<Exactly<Iterable<int>>>())
    ];
    List<int> nullAware = [
      ...?(contextType(<int>[])..expectStaticType<Exactly<Iterable<int>?>>())
    ];
  }
  {
    Set<int> notNullAware = {
      ...(contextType(<int>[])..expectStaticType<Exactly<Iterable<int>>>())
    };
    Set<int> nullAware = {
      ...?(contextType(<int>[])..expectStaticType<Exactly<Iterable<int>?>>())
    };
  }
  {
    Map<int, int> notNullAware = {
      ...(contextType(<int, int>{})..expectStaticType<Exactly<Map<int, int>>>())
    };
    Map<int, int> nullAware = {
      ...?(contextType(<int, int>{})
        ..expectStaticType<Exactly<Map<int, int>?>>())
    };
  }
}
