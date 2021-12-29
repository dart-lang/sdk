// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart';
import 'package:kernel/class_hierarchy.dart';

import '../builder/extension_builder.dart';
import '../builder/library_builder.dart';
import '../builder/member_builder.dart';
import '../builder/type_builder.dart';
import '../builder/type_variable_builder.dart';

import '../kernel/kernel_helper.dart';

import '../scope.dart';

import '../util/helpers.dart';

import 'dill_class_builder.dart';
import 'dill_extension_member_builder.dart';

class DillExtensionBuilder extends ExtensionBuilderImpl {
  @override
  final Extension extension;
  List<TypeVariableBuilder>? _typeParameters;
  TypeBuilder? _onType;

  DillExtensionBuilder(this.extension, LibraryBuilder parent)
      : super(
            /* metadata = */ null,
            0,
            extension.name,
            parent,
            extension.fileOffset,
            new Scope(
                local: <String, MemberBuilder>{},
                setters: <String, MemberBuilder>{},
                parent: parent.scope,
                debugName: "extension ${extension.name}",
                isModifiable: false)) {
    Map<Name, ExtensionMemberDescriptor> _methods = {};
    Map<Name, Procedure> _tearOffs = {};
    for (ExtensionMemberDescriptor descriptor in extension.members) {
      Name name = descriptor.name;
      switch (descriptor.kind) {
        case ExtensionMemberKind.Method:
          if (descriptor.isStatic) {
            Procedure procedure = descriptor.member.asProcedure;
            scopeBuilder.addMember(
                name.text,
                new DillExtensionStaticMethodBuilder(
                    procedure, descriptor, this));
          } else {
            _methods[name] = descriptor;
          }
          break;
        case ExtensionMemberKind.TearOff:
          _tearOffs[name] = descriptor.member.asProcedure;
          break;
        case ExtensionMemberKind.Getter:
          Procedure procedure = descriptor.member.asProcedure;
          scopeBuilder.addMember(name.text,
              new DillExtensionGetterBuilder(procedure, descriptor, this));
          break;
        case ExtensionMemberKind.Field:
          Field field = descriptor.member.asField;
          scopeBuilder.addMember(name.text,
              new DillExtensionFieldBuilder(field, descriptor, this));
          break;
        case ExtensionMemberKind.Setter:
          Procedure procedure = descriptor.member.asProcedure;
          scopeBuilder.addSetter(name.text,
              new DillExtensionSetterBuilder(procedure, descriptor, this));
          break;
        case ExtensionMemberKind.Operator:
          Procedure procedure = descriptor.member.asProcedure;
          scopeBuilder.addMember(name.text,
              new DillExtensionOperatorBuilder(procedure, descriptor, this));
          break;
      }
    }
    _methods.forEach((Name name, ExtensionMemberDescriptor descriptor) {
      Procedure procedure = descriptor.member.asProcedure;
      assert(_tearOffs.containsKey(name),
          "No tear found for ${descriptor} in ${_tearOffs}");
      scopeBuilder.addMember(
          name.text,
          new DillExtensionInstanceMethodBuilder(
              procedure, descriptor, this, _tearOffs[name]!));
    });
  }

  @override
  List<TypeVariableBuilder>? get typeParameters {
    if (_typeParameters == null && extension.typeParameters.isNotEmpty) {
      _typeParameters =
          computeTypeVariableBuilders(library, extension.typeParameters);
    }
    return _typeParameters;
  }

  @override
  TypeBuilder get onType {
    return _onType ??= library.loader.computeTypeBuilder(extension.onType);
  }

  @override
  void buildOutlineExpressions(
      LibraryBuilder library,
      ClassHierarchy classHierarchy,
      List<DelayedActionPerformer> delayedActionPerformers,
      List<SynthesizedFunctionNode> synthesizedFunctionNodes) {
    // TODO(johnniwinther): Remove the need for this.
  }
}
