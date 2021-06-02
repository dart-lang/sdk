// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test/test.dart';

Matcher throwsExceptionWithToString(Object matcher) => throwsA(
      isA<Exception>().having((p0) => p0.toString(), 'toString', matcher),
    );
