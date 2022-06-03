// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart';
import 'package:kernel/type_environment.dart';

import '../source/source_library_builder.dart';
import 'library_builder.dart';
import 'named_type_builder.dart';
import 'nullability_builder.dart';
import 'type_builder.dart';

abstract class OmittedTypeBuilder extends TypeBuilder {
  const OmittedTypeBuilder();

  @override
  DartType build(LibraryBuilder library, TypeUse typeUse) {
    throw new UnsupportedError('$runtimeType.build');
  }

  @override
  DartType buildAliased(LibraryBuilder library, TypeUse typeUse) {
    throw new UnsupportedError('$runtimeType.buildAliased');
  }

  @override
  Supertype? buildMixedInType(LibraryBuilder library) {
    throw new UnsupportedError('$runtimeType.buildMixedInType');
  }

  @override
  Supertype? buildSupertype(LibraryBuilder library) {
    throw new UnsupportedError('$runtimeType.buildSupertype');
  }

  @override
  int? get charOffset => null;

  @override
  TypeBuilder clone(
      List<NamedTypeBuilder> newTypes,
      SourceLibraryBuilder contextLibrary,
      TypeParameterScopeBuilder contextDeclaration) {
    return this;
  }

  @override
  String get debugName => 'OmittedTypeBuilder';

  @override
  Uri? get fileUri => null;

  @override
  bool get isVoidType => false;

  @override
  Object? get name => null;

  @override
  NullabilityBuilder get nullabilityBuilder =>
      const NullabilityBuilder.omitted();

  @override
  StringBuffer printOn(StringBuffer buffer) => buffer;

  @override
  TypeBuilder withNullabilityBuilder(NullabilityBuilder nullabilityBuilder) {
    return this;
  }

  bool get hasType;

  DartType get type;
}

class ImplicitTypeBuilder extends OmittedTypeBuilder {
  const ImplicitTypeBuilder();

  @override
  bool get hasType => true;

  @override
  DartType get type => const DynamicType();
}

class InferableTypeBuilder extends OmittedTypeBuilder {
  @override
  bool get hasType => _type != null;

  DartType? _type;

  @override
  DartType get type => _type!;

  List<InferredTypeListener>? _listeners;

  @override
  void registerInferredTypeListener(InferredTypeListener onType) {
    if (hasType) {
      onType.onInferredType(type);
    } else {
      (_listeners ??= []).add(onType);
    }
  }

  void _registerType(DartType type) {
    // TODO(johnniwinther): Avoid multiple registration from enums and
    //  duplicated fields.
    if (_type == null) {
      _type = type;
      List<InferredTypeListener>? listeners = _listeners;
      if (listeners != null) {
        _listeners = null;
        for (InferredTypeListener listener in listeners) {
          listener.onInferredType(type);
        }
      }
    }
  }

  @override
  void registerInferredType(DartType type) {
    _registerType(type);
  }

  Inferable? _inferable;

  Inferable? get inferable => _inferable;

  @override
  void registerInferable(Inferable inferable) {
    assert(
        _inferable == null,
        "Inferable $_inferable has already been register, "
        "trying to register $inferable.");
    _inferable = inferable;
  }

  /// Triggers inference of this type.
  ///
  /// If an [Inferable] has been register, this is called to infer the type of
  /// this builder. Otherwise the type is inferred to be `dynamic`.
  void inferType(TypeEnvironment typeEnvironment) {
    if (!hasType) {
      Inferable? inferable = _inferable;
      if (inferable != null) {
        inferable.inferTypes(typeEnvironment);
      } else {
        registerInferredType(const DynamicType());
      }
      assert(hasType);
    }
  }
}

/// Listener for the late computation of an inferred type.
abstract class InferredTypeListener {
  /// Called when the type of an [InferableTypeBuilder] has been computed.
  void onInferredType(DartType type);
}

/// Interface for builders that can infer the type of an [InferableTypeBuilder].
abstract class Inferable {
  /// Triggers the inference of the types of one or more
  /// [InferableTypeBuilder]s.
  void inferTypes(TypeEnvironment typeEnvironment);
}
