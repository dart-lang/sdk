// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library mdv_observe.test.utils;

import 'package:unittest/unittest.dart';

// TODO(jmesserly): use matchers when this is supported. For now just
// compare to toStrings.
expectChanges(actual, expected, {reason}) =>
    expect('$actual', '$expected', reason: reason);
