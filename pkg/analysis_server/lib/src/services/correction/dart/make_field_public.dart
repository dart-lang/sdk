// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server/src/utilities/index_range.dart';
import 'package:analysis_server_plugin/edit/correction_utils.dart';
import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analyzer/source/source_range.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_dart.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';
import 'package:collection/collection.dart';

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
  FixKind get fixKind => DartFixKind.makeFieldPublic;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    var declaration = node;
    if (declaration is! MethodDeclaration) {
      return;
    }
    var getterName = declaration.name.lexeme;
    _fieldName = '_$getterName';
    if (declaration.name == token && declaration.isGetter) {
      List<ClassMember> members;
      FormalParameter? declaringParameter;
      var container = declaration.parent?.parent;
      if (container is ClassDeclaration) {
        members = container.body.members;
        declaringParameter = container.findDeclaringParameterNamed(_fieldName);
      } else if (container is MixinDeclaration) {
        members = container.body.members;
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
      if (setter == null || (field == null && declaringParameter == null)) {
        return;
      }
      await builder.addDartFileEdit(file, (builder) {
        if (field != null) {
          builder.addSimpleReplacement(range.token(field.name), getterName);
        } else if (declaringParameter?.name case var name?) {
          builder.addSimpleReplacement(range.token(name), getterName);
        }
        builder._deleteMembers(utils, members, [declaration, setter!]);
      });
    }
  }
}

extension on DartFileEditBuilder {
  /// Deletes [membersToRemove] out of [members].
  void _deleteMembers(
    CorrectionUtils utils,
    List<ClassMember> members,
    List<ClassMember> membersToRemove,
  ) {
    // Generally we want to use endEnd to delete from the end of the previous
    // member to the end of the current member. However, this does not work for
    // the first member. We can use startStart for the first member (to the
    // second) but this would cause a conflicting edit if we're removing the
    // first and second.
    //
    // To avoid this, group the members into contiguous ranges and use
    // startStart if there is a range starting at 0, and endEnd for everything
    // else. Since we know none of these groups touch each other, there cannot
    // be conflicting edits.
    var indexesToRemove = membersToRemove.map(members.indexOf).toList()..sort();
    for (var removedRange in IndexRange.contiguousSubRanges(indexesToRemove)) {
      var range = _getDeletionRange(utils, members, removedRange);
      addDeletion(range);
    }
  }

  /// Compute the range to delete the members in [removedRange] from members.
  SourceRange _getDeletionRange(
    CorrectionUtils utils,
    List<ClassMember> members,
    IndexRange removedRange,
  ) {
    // Removing all members, use a range that covers all lines from the start
    // to end because we don't want to leave whitespace on either side.
    if (removedRange.lower == 0 && removedRange.upper == members.length - 1) {
      return utils.getLinesRange(
        range.startEnd(
          members[removedRange.lower],
          members[removedRange.upper],
        ),
      );
    }

    // Removing a range of members from the start, use the start of the first
    // until the start of the one after the range.
    if (removedRange.lower == 0) {
      return range.startStart(
        members[removedRange.lower],
        members[removedRange.upper + 1],
      );
    }

    // Removing a range that is not at the start, use the end of the one before
    // the range until the end of the last one in the range.
    return range.endEnd(
      members[removedRange.lower - 1],
      members[removedRange.upper],
    );
  }
}

extension on FormalParameter {
  /// Whether this parameter is a declaring parameter because it has a `final`
  /// or `var` keyword.
  bool get isDeclaringParameter {
    if (this case FormalParameterImpl(finalOrVarKeyword: _?)) {
      return true;
    }
    return false;
  }
}

extension on PrimaryConstructorDeclaration {
  Iterable<FormalParameter> get declaringParameters => formalParameters
      .parameters
      .where((parameter) => parameter.isDeclaringParameter);
}

extension on ClassDeclaration {
  /// Finds the declaring parameter with [name].
  ///
  /// If there are multiple parameters with this name (invalid code), the first
  /// is returned.
  ///
  /// Returns `null` if there is no such parameter.
  FormalParameter? findDeclaringParameterNamed(String name) {
    if (namePart case PrimaryConstructorDeclaration namePart) {
      return namePart.declaringParameters.firstWhereOrNull(
        (parameter) => parameter.name?.lexeme == name,
      );
    }
    return null;
  }
}
