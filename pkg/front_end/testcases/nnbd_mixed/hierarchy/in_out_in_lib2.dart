// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart=2.9

import 'in_out_in_lib1.dart';

abstract class LegacyClass extends Super implements SuperExtra {}

abstract class LegacyClassQ extends SuperQ implements SuperExtra {}

abstract class LegacyMixedIn with Super implements SuperExtra {}

abstract class LegacyMixedInQ with SuperQ implements SuperExtra {}
