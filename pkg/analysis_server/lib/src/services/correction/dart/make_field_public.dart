// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/dart/abstract_producer.dart';
import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_dart.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

class MakeFieldPublic extends CorrectionProducer {
  late String _fieldName;

  @override
  List<Object>? get fixArguments => [_fieldName];

  @override
  FixKind get fixKind => DartFixKind.MAKE_FIELD_PUBLIC;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    var node = this.node;
    if (node is! SimpleIdentifier) {
      return;
    }
    var getterName = node.name;
    _fieldName = '_$getterName';
    var parent = node.parent;
    if (parent is MethodDeclaration && parent.name == node && parent.isGetter) {
      var container = parent.parent;
      if (container is ClassOrMixinDeclaration) {
        var members = container.members;
        MethodDeclaration? setter;
        VariableDeclaration? field;
        for (var member in members) {
          if (member is MethodDeclaration &&
              member.name.name == getterName &&
              member.isSetter) {
            setter = member;
          } else if (member is FieldDeclaration) {
            for (var variable in member.fields.variables) {
              if (variable.name.name == _fieldName) {
                field = variable;
              }
            }
          }
        }
        if (setter == null || field == null) {
          return;
        }
        await builder.addDartFileEdit(file, (builder) {
          builder.addSimpleReplacement(range.node(field!.name), getterName);
          builder.removeMember(members, parent);
          builder.removeMember(members, setter!);
        });
      }
    }
  }

  /// Return an instance of this class. Used as a tear-off in `FixProcessor`.
  static MakeFieldPublic newInstance() => MakeFieldPublic();
}

extension on DartFileEditBuilder {
  void removeMember(NodeList<ClassMember> members, ClassMember member) {
    // TODO(brianwilkerson) Consider moving this to DartFileEditBuilder.
    var index = members.indexOf(member);
    if (index == 0) {
      if (members.length == 1) {
        // TODO(brianwilkerson) Remove the whitespace before and after the
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
