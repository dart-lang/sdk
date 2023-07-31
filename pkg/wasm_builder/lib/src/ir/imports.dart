// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../serialize/serialize.dart';

/// Any import (function, table, memory or global).
abstract class Import implements Serializable {
  String get module;
  String get name;
}
