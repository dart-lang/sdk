// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart';

import '../source/source_library_builder.dart';
import 'library_builder.dart';
import 'named_type_builder.dart';
import 'nullability_builder.dart';
import 'type_builder.dart';

class OmittedTypeBuilder extends TypeBuilder {
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

  bool get hasType => _type != null;

  DartType? _type;

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
}

/// Listener for the late computation of an inferred type.
abstract class InferredTypeListener {
  void onInferredType(DartType type);
}
