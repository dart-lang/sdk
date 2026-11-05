// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;

/// The unsatisfied superclass constraint for a
/// [diag.mixinApplicationNotImplementedInterface] diagnostic.
final mixinApplicationNotImplementedInterfaceConstraint =
    Expando<InterfaceTypeImpl>();
