// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:core' hide MapEntry;

import 'package:kernel/ast.dart';

import '../builder/extension_builder.dart';
import '../builder/library_builder.dart';
import '../builder/member_builder.dart';
import '../builder/type_builder.dart';
import '../builder/type_variable_builder.dart';

import '../scope.dart';

import 'dill_class_builder.dart';
import 'dill_extension_member_builder.dart';

class DillExtensionBuilder extends ExtensionBuilderImpl {
  final Extension extension;
  List<TypeVariableBuilder> _typeParameters;
  TypeBuilder _onType;

  DillExtensionBuilder(this.extension, LibraryBuilder parent)
      : super(
            null,
            0,
            extension.name,
            parent,
            extension.fileOffset,
            new Scope(
                local: <String, MemberBuilder>{},
                setters: <String, MemberBuilder>{},
                parent: parent.scope,
                debugName: "extension ${extension.name}",
                isModifiable: false),
            null,
            null) {
    Map<Name, ExtensionMemberDescriptor> _methods = {};
    Map<Name, Member> _tearOffs = {};
    for (ExtensionMemberDescriptor descriptor in extension.members) {
      Name name = descriptor.name;
      switch (descriptor.kind) {
        case ExtensionMemberKind.Method:
          _methods[name] = descriptor;
          break;
        case ExtensionMemberKind.TearOff:
          _tearOffs[name] = descriptor.member.asMember;
          break;
        case ExtensionMemberKind.Getter:
        case ExtensionMemberKind.Operator:
        case ExtensionMemberKind.Field:
          Member member = descriptor.member.asMember;
          scopeBuilder.addMember(name.name,
              new DillExtensionMemberBuilder(member, descriptor, this));
          break;
        case ExtensionMemberKind.Setter:
          Member member = descriptor.member.asMember;
          scopeBuilder.addSetter(name.name,
              new DillExtensionMemberBuilder(member, descriptor, this));
          break;
      }
    }
    _methods.forEach((Name name, ExtensionMemberDescriptor descriptor) {
      Member member = descriptor.member.asMember;
      scopeBuilder.addMember(
          name.name,
          new DillExtensionMemberBuilder(
              member, descriptor, this, _tearOffs[name]));
    });
  }

  @override
  List<TypeVariableBuilder> get typeParameters {
    if (_typeParameters == null && extension.typeParameters.isNotEmpty) {
      _typeParameters =
          computeTypeVariableBuilders(library, extension.typeParameters);
    }
    return _typeParameters;
  }

  @override
  TypeBuilder get onType {
    if (_onType == null) {
      _onType = library.loader.computeTypeBuilder(extension.onType);
    }
    return _onType;
  }
}
