// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:flutter_gen/gen.dart'; // OK

import 'package:sample_project/sample_project.dart'; // OK
import 'package:public_dep/public_dep.dart'; // OK
import 'package:private_dep/private_dep.dart'; // LINT
import 'package:transitive_dep/transitive_dep.dart'; // LINT

export 'package:sample_project/sample_project.dart'; // OK
export 'package:public_dep/public_dep.dart'; // OK
export 'package:private_dep/private_dep.dart'; // LINT
export 'package:transitive_dep/transitive_dep.dart'; // LINT
