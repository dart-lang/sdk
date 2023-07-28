// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../builder/inline_class_builder.dart';
import '../builder/member_builder.dart';
import '../builder/type_builder.dart';
import '../builder/type_variable_builder.dart';
import 'package:kernel/ast.dart';

import '../scope.dart';
import 'dill_class_builder.dart';
import 'dill_extension_type_member_builder.dart';
import 'dill_library_builder.dart';

class DillExtensionTypeBuilder extends InlineClassBuilderImpl {
  final InlineClass _extensionType;

  List<TypeVariableBuilder>? _typeParameters;

  List<TypeBuilder>? _interfaceBuilders;

  DillExtensionTypeBuilder(this._extensionType, DillLibraryBuilder parent)
      : super(
            /*metadata builders*/
            null,
            /* modifiers*/
            0,
            _extensionType.name,
            parent,
            _extensionType.fileOffset,
            new Scope(
                kind: ScopeKind.declaration,
                local: <String, MemberBuilder>{},
                setters: <String, MemberBuilder>{},
                parent: parent.scope,
                debugName: "extension type ${_extensionType.name}",
                isModifiable: false),
            new ConstructorScope(
                _extensionType.name, <String, MemberBuilder>{})) {
    Map<Name, Procedure> _tearOffs = {};
    for (InlineClassMemberDescriptor descriptor in inlineClass.members) {
      Name name = descriptor.name;
      if (descriptor.kind == InlineClassMemberKind.TearOff) {
        _tearOffs[name] = descriptor.member.asProcedure;
      }
    }

    for (InlineClassMemberDescriptor descriptor in inlineClass.members) {
      Name name = descriptor.name;
      switch (descriptor.kind) {
        case InlineClassMemberKind.Method:
          if (descriptor.isStatic) {
            Procedure procedure = descriptor.member.asProcedure;
            scope.addLocalMember(
                name.text,
                new DillExtensionTypeStaticMethodBuilder(
                    procedure, descriptor, this),
                setter: false);
          } else {
            Procedure procedure = descriptor.member.asProcedure;
            assert(_tearOffs.containsKey(name),
                "No tear found for ${descriptor} in ${_tearOffs}");
            scope.addLocalMember(
                name.text,
                new DillExtensionTypeInstanceMethodBuilder(
                    procedure, descriptor, this, _tearOffs[name]!),
                setter: false);
          }
          break;
        case InlineClassMemberKind.TearOff:
          assert(_tearOffs[name] == descriptor.member.asProcedure);
          break;
        case InlineClassMemberKind.Getter:
          Procedure procedure = descriptor.member.asProcedure;
          scope.addLocalMember(name.text,
              new DillExtensionTypeGetterBuilder(procedure, descriptor, this),
              setter: false);
          break;
        case InlineClassMemberKind.Field:
          Field field = descriptor.member.asField;
          scope.addLocalMember(name.text,
              new DillExtensionTypeFieldBuilder(field, descriptor, this),
              setter: false);
          break;
        case InlineClassMemberKind.Setter:
          Procedure procedure = descriptor.member.asProcedure;
          scope.addLocalMember(name.text,
              new DillExtensionTypeSetterBuilder(procedure, descriptor, this),
              setter: true);
          break;
        case InlineClassMemberKind.Operator:
          Procedure procedure = descriptor.member.asProcedure;
          scope.addLocalMember(name.text,
              new DillExtensionTypeOperatorBuilder(procedure, descriptor, this),
              setter: false);
          break;
        case InlineClassMemberKind.Constructor:
          Procedure procedure = descriptor.member.asProcedure;
          constructorScope.addLocalMember(
              name.text,
              new DillExtensionTypeConstructorBuilder(
                  procedure, _tearOffs[name], descriptor, this));
          break;
        case InlineClassMemberKind.Factory:
        case InlineClassMemberKind.RedirectingFactory:
          Procedure procedure = descriptor.member.asProcedure;
          constructorScope.addLocalMember(
              name.text,
              new DillExtensionTypeFactoryBuilder(
                  procedure, _tearOffs[name], descriptor, this));
          break;
      }
    }
  }

  @override
  DillLibraryBuilder get libraryBuilder => parent as DillLibraryBuilder;

  @override
  DartType get declaredRepresentationType =>
      _extensionType.declaredRepresentationType;

  @override
  InlineClass get inlineClass => _extensionType;

  @override
  List<TypeVariableBuilder>? get typeParameters {
    List<TypeVariableBuilder>? typeVariables = _typeParameters;
    if (typeVariables == null && _extensionType.typeParameters.isNotEmpty) {
      typeVariables = _typeParameters = computeTypeVariableBuilders(
          libraryBuilder, _extensionType.typeParameters);
    }
    return typeVariables;
  }

  @override
  List<TypeBuilder>? get interfaceBuilders {
    if (_extensionType.implements.isEmpty) return null;
    List<TypeBuilder>? interfaceBuilders = _interfaceBuilders;
    if (interfaceBuilders == null) {
      interfaceBuilders = _interfaceBuilders = new List<TypeBuilder>.generate(
          _extensionType.implements.length,
          (int i) => libraryBuilder.loader
              .computeTypeBuilder(_extensionType.implements[i]),
          growable: false);
    }
    return interfaceBuilders;
  }
}
