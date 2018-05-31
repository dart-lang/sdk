// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart' show Expression, Statement;
import 'package:analyzer/src/fasta/ast_building_factory.dart'
    show AstBuildingForest;
import 'package:analyzer/src/generated/resolver.dart' show TypeProvider;
import 'package:front_end/src/fasta/kernel/body_builder.dart' show BodyBuilder;
import 'package:front_end/src/fasta/kernel/kernel_builder.dart'
    show KernelClassBuilder, KernelLibraryBuilder, ModifierBuilder, Scope;
import 'package:front_end/src/fasta/type_inference/type_inferrer.dart'
    show TypeInferrer;
import 'package:kernel/class_hierarchy.dart' show ClassHierarchy;
import 'package:kernel/core_types.dart' show CoreTypes;

class AstBodyBuilder extends BodyBuilder<Expression, Statement, dynamic> {
  @override
  final AstBuildingForest forest;

  AstBodyBuilder(
      KernelLibraryBuilder library,
      ModifierBuilder member,
      Scope scope,
      Scope formalParameterScope,
      ClassHierarchy hierarchy,
      CoreTypes coreTypes,
      KernelClassBuilder classBuilder,
      bool isInstanceMember,
      Uri uri,
      TypeInferrer typeInferrer,
      TypeProvider typeProvider)
      : forest = new AstBuildingForest(typeProvider),
        super(library, member, scope, formalParameterScope, hierarchy,
            coreTypes, classBuilder, isInstanceMember, uri, typeInferrer);

  @override
  void enterThenForTypePromotion(Expression condition) {
    // Do nothing.
  }
}
