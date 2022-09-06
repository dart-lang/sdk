// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../js_model/env.dart' show JProgramEnv;

// TODO(48820): Delete once migration is complete
abstract class KLibraryData {}

abstract class KLibraryEnv {}

abstract class KClassData {}

abstract class KClassEnv {}

abstract class KMemberData {}

abstract class KTypeVariableData {}

abstract class KProgramEnv {
  JProgramEnv convert();
}
