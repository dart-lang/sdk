// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of '../fragment.dart';

abstract class ClassDeclaration {
  String get name;
  List<MetadataBuilder>? get metadata;
  LookupScope get compilationUnitScope;
  Uri get fileUri;
  int get nameOffset;
  int get startOffset;
  int get endOffset;
  List<NominalParameterBuilder>? get typeParameters;
  bool get isMixinDeclaration;

  TypeBuilder? get supertype;
  List<TypeBuilder>? get mixedInTypes;
  List<TypeBuilder>? get interfaces;
}

class RegularClassDeclaration implements ClassDeclaration {
  final ClassFragment _fragment;

  RegularClassDeclaration(this._fragment);

  @override
  List<MetadataBuilder>? get metadata => _fragment.metadata;

  @override
  LookupScope get compilationUnitScope => _fragment.enclosingScope;

  @override
  Uri get fileUri => _fragment.fileUri;

  @override
  int get endOffset => _fragment.endOffset;

  @override
  String get name => _fragment.name;

  @override
  int get nameOffset => _fragment.nameOffset;

  @override
  int get startOffset => _fragment.startOffset;

  @override
  List<NominalParameterBuilder>? get typeParameters =>
      _fragment.typeParameters?.builders;

  @override
  bool get isMixinDeclaration => false;

  @override
  TypeBuilder? get supertype => _fragment.supertype;

  @override
  List<TypeBuilder>? get mixedInTypes => _fragment.mixins;

  @override
  List<TypeBuilder>? get interfaces => _fragment.interfaces;
}

class EnumDeclaration implements ClassDeclaration {
  final EnumFragment _fragment;

  @override
  final TypeBuilder supertype;

  EnumDeclaration(this._fragment, this.supertype);

  @override
  List<MetadataBuilder>? get metadata => _fragment.metadata;

  @override
  LookupScope get compilationUnitScope => _fragment.enclosingScope;

  @override
  Uri get fileUri => _fragment.fileUri;

  @override
  int get endOffset => _fragment.endOffset;

  @override
  String get name => _fragment.name;

  @override
  int get nameOffset => _fragment.nameOffset;

  @override
  int get startOffset => _fragment.startOffset;

  @override
  List<NominalParameterBuilder>? get typeParameters =>
      _fragment.typeParameters?.builders;

  @override
  bool get isMixinDeclaration => false;

  @override
  List<TypeBuilder>? get mixedInTypes => _fragment.mixins;

  @override
  List<TypeBuilder>? get interfaces => _fragment.interfaces;
}

class NamedMixinApplication implements ClassDeclaration {
  final NamedMixinApplicationFragment _fragment;

  @override
  final List<TypeBuilder> mixedInTypes;

  NamedMixinApplication(this._fragment, this.mixedInTypes);

  @override
  List<MetadataBuilder>? get metadata => _fragment.metadata;

  @override
  LookupScope get compilationUnitScope => _fragment.enclosingScope;

  @override
  Uri get fileUri => _fragment.fileUri;

  @override
  int get endOffset => _fragment.endOffset;

  @override
  String get name => _fragment.name;

  @override
  int get nameOffset => _fragment.nameOffset;

  @override
  int get startOffset => _fragment.startOffset;

  @override
  List<NominalParameterBuilder>? get typeParameters =>
      _fragment.typeParameters?.builders;

  @override
  bool get isMixinDeclaration => false;

  @override
  TypeBuilder? get supertype => _fragment.supertype;

  @override
  List<TypeBuilder>? get interfaces => _fragment.interfaces;
}

class AnonymousMixinApplication implements ClassDeclaration {
  @override
  final String name;

  @override
  final LookupScope compilationUnitScope;

  @override
  final int nameOffset;

  @override
  final int startOffset;

  @override
  final int endOffset;

  @override
  final Uri fileUri;

  @override
  final List<NominalParameterBuilder>? typeParameters;

  @override
  final TypeBuilder? supertype;

  @override
  bool get isMixinDeclaration => false;

  @override
  List<TypeBuilder>? get mixedInTypes => null;

  @override
  final List<TypeBuilder>? interfaces;

  AnonymousMixinApplication(
      {required this.name,
      required this.compilationUnitScope,
      required this.fileUri,
      required this.nameOffset,
      required this.startOffset,
      required this.endOffset,
      required this.typeParameters,
      required this.supertype,
      required this.interfaces});

  @override
  List<MetadataBuilder>? get metadata => null;
}

class MixinDeclaration implements ClassDeclaration {
  final MixinFragment _fragment;

  MixinDeclaration(this._fragment);

  @override
  List<MetadataBuilder>? get metadata => _fragment.metadata;

  @override
  LookupScope get compilationUnitScope => _fragment.enclosingScope;

  @override
  Uri get fileUri => _fragment.fileUri;

  @override
  int get endOffset => _fragment.endOffset;

  @override
  String get name => _fragment.name;

  @override
  int get nameOffset => _fragment.nameOffset;

  @override
  int get startOffset => _fragment.startOffset;

  @override
  List<NominalParameterBuilder>? get typeParameters =>
      _fragment.typeParameters?.builders;

  @override
  bool get isMixinDeclaration => true;

  @override
  TypeBuilder? get supertype => _fragment.supertype;

  @override
  List<TypeBuilder>? get mixedInTypes => _fragment.mixins;

  @override
  List<TypeBuilder>? get interfaces => _fragment.interfaces;
}
