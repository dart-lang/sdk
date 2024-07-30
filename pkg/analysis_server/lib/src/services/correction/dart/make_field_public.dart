// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_dart.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

class MakeFieldPublic extends ResolvedCorrectionProducer {
  late String _fieldName;

  MakeFieldPublic({required super.context});

  @override
  CorrectionApplicability get applicability =>
      // TODO(applicability): comment on why.
      CorrectionApplicability.singleLocation;

  @override
  List<String>? get fixArguments => [_fieldName];

  @override
  FixKind get fixKind => DartFixKind.MAKE_FIELD_PUBLIC;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    var declaration = node;
    if (declaration is! MethodDeclaration) {
      return;
    }
    var getterName = declaration.name.lexeme;
    _fieldName = '_$getterName';
    if (declaration.name == token && declaration.isGetter) {
      NodeList<ClassMember> members;
      var container = declaration.parent;
      if (container is ClassDeclaration) {
        members = container.members;
      } else if (container is MixinDeclaration) {
        members = container.members;
      } else {
        return;
      }

      MethodDeclaration? setter;
      VariableDeclaration? field;
      for (var member in members) {
        if (member is MethodDeclaration &&
            member.name.lexeme == getterName &&
            member.isSetter) {
          setter = member;
        } else if (member is FieldDeclaration) {
          for (var variable in member.fields.variables) {
            if (variable.name.lexeme == _fieldName) {
              field = variable;
            }
          }
        }
      }
      if (setter == null || field == null) {
        return;
      }
      await builder.addDartFileEdit(file, (builder) {
        builder.addSimpleReplacement(range.token(field!.name), getterName);
        builder.removeMember(members, declaration);
        builder.removeMember(members, setter!);
      });
    }
  }
}

extension on DartFileEditBuilder {
  void removeMember(NodeList<ClassMember> members, ClassMember member) {
    // TODO(brianwilkerson): Consider moving this to DartFileEditBuilder.
    var index = members.indexOf(member);
    if (index == 0) {
      if (members.length == 1) {
        // TODO(brianwilkerson): Remove the whitespace before and after the
        //  member.
        addDeletion(range.node(member));
      } else {
        addDeletion(range.startStart(member, members[index + 1]));
      }
    } else {
      addDeletion(range.endEnd(members[index - 1], member));
    }
  }
}
