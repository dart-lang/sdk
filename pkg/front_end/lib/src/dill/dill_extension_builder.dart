// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart';

import '../base/name_space.dart';
import '../base/scope.dart';
import '../builder/declaration_builders.dart';
import '../builder/library_builder.dart';
import '../builder/type_builder.dart';
import 'dill_builder_mixins.dart';
import 'dill_class_builder.dart';
import 'dill_extension_member_builder.dart';

class DillExtensionBuilder extends ExtensionBuilderImpl
    with DillDeclarationBuilderMixin {
  @override
  final Extension extension;

  late final LookupScope _scope;

  final NameSpace _nameSpace;

  @override
  final ConstructorScope constructorScope;

  List<NominalVariableBuilder>? _typeParameters;
  TypeBuilder? _onType;

  DillExtensionBuilder(this.extension, LibraryBuilder parent)
      : _nameSpace = new NameSpaceImpl(),
        constructorScope = new ConstructorScope(extension.name, const {}),
        super(/* metadata = */ null, 0, extension.name, parent,
            extension.fileOffset) {
    _scope = new NameSpaceLookupScope(
        _nameSpace, ScopeKind.declaration, "extension ${extension.name}",
        parent: parent.scope);
    for (ExtensionMemberDescriptor descriptor in extension.memberDescriptors) {
      Name name = descriptor.name;
      switch (descriptor.kind) {
        case ExtensionMemberKind.Method:
          if (descriptor.isStatic) {
            Procedure procedure = descriptor.memberReference.asProcedure;
            nameSpace.addLocalMember(
                name.text,
                new DillExtensionStaticMethodBuilder(
                    procedure, descriptor, this),
                setter: false);
          } else {
            Procedure procedure = descriptor.memberReference.asProcedure;
            Procedure? tearOff = descriptor.tearOffReference?.asProcedure;
            assert(
                tearOff != null, // Coverage-ignore(suite): Not run.
                "No tear found for ${descriptor}");
            nameSpace.addLocalMember(
                name.text,
                new DillExtensionInstanceMethodBuilder(
                    procedure, descriptor, this, tearOff!),
                setter: false);
          }
          break;
        case ExtensionMemberKind.Getter:
          Procedure procedure = descriptor.memberReference.asProcedure;
          nameSpace.addLocalMember(name.text,
              new DillExtensionGetterBuilder(procedure, descriptor, this),
              setter: false);
          break;
        case ExtensionMemberKind.Field:
          Field field = descriptor.memberReference.asField;
          nameSpace.addLocalMember(
              name.text, new DillExtensionFieldBuilder(field, descriptor, this),
              setter: false);
          break;
        case ExtensionMemberKind.Setter:
          Procedure procedure = descriptor.memberReference.asProcedure;
          nameSpace.addLocalMember(name.text,
              new DillExtensionSetterBuilder(procedure, descriptor, this),
              setter: true);
          break;
        case ExtensionMemberKind.Operator:
          Procedure procedure = descriptor.memberReference.asProcedure;
          nameSpace.addLocalMember(name.text,
              new DillExtensionOperatorBuilder(procedure, descriptor, this),
              setter: false);
          break;
      }
    }
  }

  @override
  LookupScope get scope => _scope;

  @override
  NameSpace get nameSpace => _nameSpace;

  @override
  List<NominalVariableBuilder>? get typeParameters {
    if (_typeParameters == null && extension.typeParameters.isNotEmpty) {
      _typeParameters = computeTypeVariableBuilders(
          extension.typeParameters, libraryBuilder.loader);
    }
    return _typeParameters;
  }

  @override
  // Coverage-ignore(suite): Not run.
  TypeBuilder get onType {
    return _onType ??=
        libraryBuilder.loader.computeTypeBuilder(extension.onType);
  }

  @override
  // Coverage-ignore(suite): Not run.
  List<TypeParameter> get typeParameterNodes => extension.typeParameters;
}
