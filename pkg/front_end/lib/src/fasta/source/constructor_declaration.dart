// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart';

import '../kernel/expression_generator_helper.dart';
import '../type_inference/inference_results.dart';
import 'class_declaration.dart';
import 'source_field_builder.dart';
import 'source_function_builder.dart';

/// Common interface for builders for generative constructor declarations in
/// source code, such as a generative constructor in a regular class or a
/// generative constructor in an extension type declaration.
abstract class ConstructorDeclaration implements SourceFunctionBuilder {
  /// Returns the enclosing [ClassDeclaration].
  ClassDeclaration get classDeclaration;

  /// Returns `true` if this constructor, including its augmentations, is
  /// external.
  ///
  /// An augmented constructor is considered external if all of the origin
  /// and augmentation constructors are external.
  bool get isEffectivelyExternal;

  /// Returns `true` if this constructor or any of its augmentations are
  /// redirecting.
  ///
  /// An augmented constructor is considered redirecting if any of the origin
  /// or augmentation constructors is redirecting. Since it is an error if more
  /// than one is redirecting, only one can be redirecting in the without
  /// errors.
  bool get isEffectivelyRedirecting;

  void addInitializer(Initializer initializer, ExpressionGeneratorHelper helper,
      {required InitializerInferenceResult? inferenceResult});

  List<Initializer> get initializers;

  void prepareInitializers();

  void prependInitializer(Initializer initializer);

  /// Registers field as being initialized by this constructor.
  ///
  /// The field can be initialized either via an initializing formal or via an
  /// entry in the constructor initializer list.
  void registerInitializedField(SourceFieldBuilder fieldBuilder);

  /// Returns the fields registered as initialized by this constructor.
  ///
  /// Returns the set of fields previously registered via
  /// [registerInitializedField] and passes on the ownership of the collection
  /// to the caller.
  Set<SourceFieldBuilder>? takeInitializedFields();

  /// Substitute [fieldType] from the context of the enclosing class or
  /// extension type declaration to this constructor.
  ///
  /// This is used for generic extension type constructors where the type
  /// variable referring to the class type variables must be substituted for
  /// the synthesized constructor type variables.
  DartType substituteFieldType(DartType fieldType);
}
