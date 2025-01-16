// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart';
import 'package:kernel/class_hierarchy.dart';

import 'member_builder.dart';

abstract class PropertyBuilder implements MemberBuilder {
  bool get hasInitializer;

  @override
  Uri get fileUri;

  bool get isExtensionTypeDeclaredInstanceField;

  bool get isLate;

  bool get isFinal;

  abstract DartType fieldType;

  DartType inferType(ClassHierarchyBase hierarchy);

  /// Builds the field initializers for each field used to encode this field
  /// using the [fileOffset] for the created nodes and [value] as the initial
  /// field value.
  List<Initializer> buildInitializer(int fileOffset, Expression value,
      {required bool isSynthetic});

  /// Creates the AST node for this field as the default initializer.
  void buildImplicitDefaultValue();

  /// Create the [Initializer] for the implicit initialization of this field
  /// in a constructor.
  Initializer buildImplicitInitializer();

  Initializer buildErroneousInitializer(Expression effect, Expression value,
      {required int fileOffset});
}
