// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart';

import '../builder/declaration_builders.dart';
import '../builder/library_builder.dart';
import '../builder/member_builder.dart';
import '../builder/type_builder.dart';
import '../scope.dart';
import 'dill_class_builder.dart';
import 'dill_extension_member_builder.dart';
import 'dill_builder_mixins.dart';

class DillExtensionBuilder extends ExtensionBuilderImpl
    with DillDeclarationBuilderMixin {
  @override
  final Extension extension;
  List<NominalVariableBuilder>? _typeParameters;
  TypeBuilder? _onType;

  DillExtensionBuilder(this.extension, LibraryBuilder parent)
      : super(
            /* metadata = */ null,
            0,
            extension.name,
            parent,
            extension.fileOffset,
            new Scope(
                kind: ScopeKind.declaration,
                local: <String, MemberBuilder>{},
                setters: <String, MemberBuilder>{},
                parent: parent.scope,
                debugName: "extension ${extension.name}",
                isModifiable: false)) {
    for (ExtensionMemberDescriptor descriptor in extension.memberDescriptors) {
      Name name = descriptor.name;
      switch (descriptor.kind) {
        case ExtensionMemberKind.Method:
          if (descriptor.isStatic) {
            Procedure procedure = descriptor.memberReference.asProcedure;
            scope.addLocalMember(
                name.text,
                new DillExtensionStaticMethodBuilder(
                    procedure, descriptor, this),
                setter: false);
          } else {
            Procedure procedure = descriptor.memberReference.asProcedure;
            Procedure? tearOff = descriptor.tearOffReference?.asProcedure;
            assert(tearOff != null, "No tear found for ${descriptor}");
            scope.addLocalMember(
                name.text,
                new DillExtensionInstanceMethodBuilder(
                    procedure, descriptor, this, tearOff!),
                setter: false);
          }
          break;
        case ExtensionMemberKind.Getter:
          Procedure procedure = descriptor.memberReference.asProcedure;
          scope.addLocalMember(name.text,
              new DillExtensionGetterBuilder(procedure, descriptor, this),
              setter: false);
          break;
        case ExtensionMemberKind.Field:
          Field field = descriptor.memberReference.asField;
          scope.addLocalMember(
              name.text, new DillExtensionFieldBuilder(field, descriptor, this),
              setter: false);
          break;
        case ExtensionMemberKind.Setter:
          Procedure procedure = descriptor.memberReference.asProcedure;
          scope.addLocalMember(name.text,
              new DillExtensionSetterBuilder(procedure, descriptor, this),
              setter: true);
          break;
        case ExtensionMemberKind.Operator:
          Procedure procedure = descriptor.memberReference.asProcedure;
          scope.addLocalMember(name.text,
              new DillExtensionOperatorBuilder(procedure, descriptor, this),
              setter: false);
          break;
      }
    }
  }

  @override
  List<NominalVariableBuilder>? get typeParameters {
    if (_typeParameters == null && extension.typeParameters.isNotEmpty) {
      _typeParameters = computeTypeVariableBuilders(extension.typeParameters);
    }
    return _typeParameters;
  }

  @override
  TypeBuilder get onType {
    return _onType ??=
        libraryBuilder.loader.computeTypeBuilder(extension.onType);
  }

  @override
  List<TypeParameter> get typeParameterNodes => extension.typeParameters;
}
