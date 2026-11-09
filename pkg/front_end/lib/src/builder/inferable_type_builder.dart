// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart' show DartType;
import 'package:kernel/class_hierarchy.dart';

import '../source/source_library_builder.dart';
import 'omitted_type_builder.dart';
import 'type_builder.dart';

abstract class InferableType {
  /// Triggers inference of this type.
  ///
  /// If an [Inferable] has been register, this is called to infer the type of
  /// this builder. Otherwise the type is inferred to be `dynamic`.
  DartType inferType(ClassHierarchyBase hierarchy);
}

class InferableTypeUse implements InferableType {
  final SourceLibraryBuilder sourceLibraryBuilder;
  final TypeBuilder typeBuilder;
  final TypeUse typeUse;

  new(this.sourceLibraryBuilder, this.typeBuilder, this.typeUse);

  @override
  DartType inferType(ClassHierarchyBase hierarchy) {
    return typeBuilder.build(
      sourceLibraryBuilder,
      typeUse,
      hierarchy: hierarchy,
    );
  }
}
