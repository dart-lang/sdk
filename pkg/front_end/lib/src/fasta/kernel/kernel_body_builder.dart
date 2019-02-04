// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.kernel_body_builder;

import 'package:kernel/ast.dart' show Expression;

import '../type_inference/type_inferrer.dart' show TypeInferrer;

import 'body_builder.dart' show BodyBuilder;

import 'fangorn.dart' show Fangorn;

import 'forest.dart' show Forest;

import 'kernel_api.dart' show ClassHierarchy, CoreTypes;

import 'kernel_builder.dart'
    show KernelClassBuilder, KernelLibraryBuilder, ModifierBuilder, Scope;

class KernelBodyBuilder extends BodyBuilder {
  @override
  final Forest forest;

  KernelBodyBuilder(
      KernelLibraryBuilder library,
      ModifierBuilder member,
      Scope scope,
      Scope formalParameterScope,
      ClassHierarchy hierarchy,
      CoreTypes coreTypes,
      KernelClassBuilder classBuilder,
      bool isInstanceMember,
      Uri uri,
      TypeInferrer typeInferrer)
      : forest = const Fangorn(),
        super(library, member, scope, formalParameterScope, hierarchy,
            coreTypes, classBuilder, isInstanceMember, uri, typeInferrer);

  KernelBodyBuilder.forField(ModifierBuilder member, TypeInferrer typeInferrer)
      : forest = const Fangorn(),
        super.forField(member, typeInferrer);

  @override
  void enterThenForTypePromotion(Expression condition) {
    typePromoter?.enterThen(condition);
  }
}
