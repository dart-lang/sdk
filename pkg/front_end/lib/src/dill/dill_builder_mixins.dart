// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart';
import 'package:kernel/class_hierarchy.dart';

import '../base/uri_offset.dart';
import '../builder/constructor_builder.dart';
import '../builder/declaration_builders.dart';
import '../builder/factory_builder.dart';
import '../builder/library_builder.dart';
import '../builder/member_builder.dart';
import '../builder/method_builder.dart';
import '../builder/property_builder.dart';
import '../builder/type_builder.dart';
import '../kernel/hierarchy/class_member.dart';
import 'dill_member_builder.dart';

mixin DillDeclarationBuilderMixin implements IDeclarationBuilder {
  List<TypeParameter> get typeParameterNodes;

  @override
  int get typeParametersCount => typeParameterNodes.length;

  @override
  List<DartType> buildAliasedTypeArguments(LibraryBuilder library,
      List<TypeBuilder>? arguments, ClassHierarchyBase? hierarchy) {
    // For performance reasons, [typeParameters] aren't restored from [target].
    // So, if [arguments] is null, the default types should be retrieved from
    // [cls.typeParameters].
    if (arguments == null) {
      // TODO(johnniwinther): Use i2b here when needed.
      return new List<DartType>.generate(typeParameterNodes.length,
          (int i) => typeParameterNodes[i].defaultType,
          growable: true);
    }

    // [arguments] != null
    return new List<DartType>.generate(
        arguments.length,
        (int i) =>
            arguments[i].buildAliased(library, TypeUse.typeArgument, hierarchy),
        growable: true);
  }
}

mixin DillConstructorBuilderMixin
    implements DillMemberBuilder, ConstructorBuilder {
  @override
  // Coverage-ignore(suite): Not run.
  bool get isProperty => false;

  @override
  // Coverage-ignore(suite): Not run.
  Member? get writeTarget => null;

  @override
  // Coverage-ignore(suite): Not run.
  Reference? get writeTargetReference => null;

  @override
  MemberBuilder get getable => this;

  @override
  MemberBuilder? get setable => null;

  @override
  // Coverage-ignore(suite): Not run.
  List<ClassMember> get localMembers =>
      throw new UnsupportedError('$runtimeType.localMembers');

  @override
  // Coverage-ignore(suite): Not run.
  List<ClassMember> get localSetters =>
      throw new UnsupportedError('$runtimeType.localSetters');
}

mixin DillFieldBuilderMixin implements DillMemberBuilder, PropertyBuilder {
  @override
  bool get isProperty => true;

  @override
  Member? get invokeTarget => null;

  @override
  Reference? get invokeTargetReference => null;

  @override
  MemberBuilder get getable => this;

  @override
  MemberBuilder? get setable => hasSetter ? this : null;

  List<ClassMember>? _localMembers;
  List<ClassMember>? _localSetters;

  @override
  List<ClassMember> get localMembers => _localMembers ??= !member
          .isInternalImplementation
      ? [new DillClassMember(this, ClassMemberKind.Getter, getterUriOffset!)]
      : const [];

  @override
  List<ClassMember> get localSetters => _localSetters ??= hasSetter &&
          !member.isInternalImplementation
      ? [new DillClassMember(this, ClassMemberKind.Setter, setterUriOffset!)]
      : const [];
}

mixin DillGetterBuilderMixin implements DillMemberBuilder, PropertyBuilder {
  @override
  bool get isProperty => true;

  @override
  // Coverage-ignore(suite): Not run.
  bool get isEnumElement => false;

  @override
  // Coverage-ignore(suite): Not run.
  bool get hasConstField => false;

  @override
  // Coverage-ignore(suite): Not run.
  Member? get writeTarget => null;

  @override
  // Coverage-ignore(suite): Not run.
  Reference? get writeTargetReference => null;

  @override
  MemberBuilder get getable => this;

  @override
  MemberBuilder? get setable => null;

  @override
  // Coverage-ignore(suite): Not run.
  UriOffsetLength? get setterUriOffset => null;

  List<ClassMember>? _localMembers;

  @override
  List<ClassMember> get localMembers => _localMembers ??= !member
          .isInternalImplementation
      ? [new DillClassMember(this, ClassMemberKind.Getter, getterUriOffset!)]
      : const [];

  @override
  List<ClassMember> get localSetters => const [];
}

mixin DillSetterBuilderMixin implements DillMemberBuilder, PropertyBuilder {
  @override
  bool get isProperty => true;

  @override
  // Coverage-ignore(suite): Not run.
  bool get isEnumElement => false;

  @override
  // Coverage-ignore(suite): Not run.
  bool get hasConstField => false;

  @override
  Member? get readTarget => null;

  @override
  Reference? get readTargetReference => null;

  @override
  Member? get invokeTarget => null;

  @override
  Reference? get invokeTargetReference => null;

  @override
  MemberBuilder? get getable => null;

  @override
  MemberBuilder get setable => this;

  @override
  // Coverage-ignore(suite): Not run.
  UriOffsetLength? get getterUriOffset => null;

  List<ClassMember>? _localSetters;

  @override
  List<ClassMember> get localMembers => const [];

  @override
  List<ClassMember> get localSetters => _localSetters ??= !member
          .isInternalImplementation
      ? [new DillClassMember(this, ClassMemberKind.Setter, setterUriOffset!)]
      : const [];
}

mixin DillMethodBuilderMixin implements DillMemberBuilder, MethodBuilder {
  @override
  bool get isProperty => false;

  @override
  bool get isOperator => false;

  @override
  MemberBuilder get getable => this;

  @override
  MemberBuilder? get setable => null;

  @override
  // Coverage-ignore(suite): Not run.
  Member? get writeTarget => null;

  @override
  // Coverage-ignore(suite): Not run.
  Reference? get writeTargetReference => null;

  List<ClassMember>? _localMembers;

  UriOffsetLength get uriOffset;

  @override
  List<ClassMember> get localMembers =>
      _localMembers ??= !member.isInternalImplementation
          ? [new DillClassMember(this, ClassMemberKind.Method, uriOffset)]
          : const [];

  @override
  List<ClassMember> get localSetters => const [];
}

mixin DillOperatorBuilderMixin implements DillMemberBuilder, MethodBuilder {
  @override
  bool get isProperty => false;

  @override
  bool get isOperator => true;

  @override
  MemberBuilder get getable => this;

  @override
  MemberBuilder? get setable => null;

  @override
  Member? get readTarget => null;

  @override
  // Coverage-ignore(suite): Not run.
  Reference? get readTargetReference => null;

  @override
  // Coverage-ignore(suite): Not run.
  Member? get writeTarget => null;

  @override
  // Coverage-ignore(suite): Not run.
  Reference? get writeTargetReference => null;

  List<ClassMember>? _localMembers;

  UriOffsetLength get uriOffset;

  @override
  List<ClassMember> get localMembers =>
      _localMembers ??= !member.isInternalImplementation
          ? [new DillClassMember(this, ClassMemberKind.Method, uriOffset)]
          : const [];

  @override
  List<ClassMember> get localSetters => const [];
}

mixin DillFactoryBuilderMixin implements DillMemberBuilder, FactoryBuilder {
  @override
  // Coverage-ignore(suite): Not run.
  bool get isProperty => false;

  @override
  MemberBuilder get getable => this;

  @override
  MemberBuilder? get setable => null;

  @override
  // Coverage-ignore(suite): Not run.
  Member? get writeTarget => null;

  @override
  // Coverage-ignore(suite): Not run.
  Reference? get writeTargetReference => null;

  @override
  // Coverage-ignore(suite): Not run.
  List<ClassMember> get localMembers =>
      throw new UnsupportedError('$runtimeType.localMembers');

  @override
  // Coverage-ignore(suite): Not run.
  List<ClassMember> get localSetters =>
      throw new UnsupportedError('$runtimeType.localSetters');
}
