// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// A library that is used to select the default implementation of smoke. During
/// development we use a default mirror-based implementation, for deployment we
/// let the main program set programatically what implementation to use (likely
/// one based on static code generation).
library smoke.src.implementation;

// IMPORTANT NOTE: This file is edited by a transformer in this package
// (default_transformer.dart), so any edits here should be coordinated with
// changes there.

import 'package:smoke/mirrors.dart';
import 'package:smoke/smoke.dart';

/// Implementation of [ObjectAccessorService] in use, initialized lazily so it
/// can be replaced at deployment time with an efficient alternative.
ObjectAccessorService objectAccessor =
    new ReflectiveObjectAccessorService();

/// Implementation of [TypeInspectorService] in use, initialized lazily so it
/// can be replaced at deployment time with an efficient alternative.
TypeInspectorService typeInspector =
    new ReflectiveTypeInspectorService();

/// Implementation of [SymbolConverterService] in use, initialized lazily so it
/// can be replaced at deployment time with an efficient alternative.
SymbolConverterService symbolConverter =
    new ReflectiveSymbolConverterService();

throwNotConfiguredError() {
  throw new Exception('The "smoke" library has not been configured. '
      'Make sure you import and configure one of the implementations ('
      'package:smoke/mirrors.dart or package:smoke/static.dart).');
}
