// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// This library exports all API from Kernel that can be used throughout fasta.
library fasta.kernel_api;

export 'package:kernel/type_algebra.dart' show instantiateToBounds;

export 'package:kernel/class_hierarchy.dart' show ClassHierarchy;

export 'package:kernel/clone.dart' show CloneVisitor;

export 'package:kernel/core_types.dart' show CoreTypes;

export 'package:kernel/transformations/flags.dart' show TransformerFlag;
