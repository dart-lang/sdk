// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/assist.dart';
import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/ast/token.dart';
import 'package:analyzer_plugin/utilities/assist/assist.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_dart.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

class ConvertToSecondaryConstructor extends ResolvedCorrectionProducer {
  ConvertToSecondaryConstructor({required super.context});

  @override
  CorrectionApplicability get applicability =>
      // Not a fix.
      CorrectionApplicability.singleLocation;

  @override
  AssistKind? get assistKind => DartAssistKind.convertToSecondaryConstructor;

  PrimaryConstructorDeclaration? get primaryConstructorDeclaration {
    AstNode? node = this.node;
    if (node is PrimaryConstructorName) {
      node = node.parent;
    }
    if (node is! PrimaryConstructorDeclaration) return null;
    return node;
  }

  @override
  Future<void> compute(ChangeBuilder builder) async {
    var declaration = primaryConstructorDeclaration;
    if (declaration == null) return;
    var container = declaration.parent;
    if (container is ClassDeclaration) {
      await _convertClassBody(builder, declaration, container);
    } else if (container is EnumDeclaration) {
      await _convertEnumBody(builder, declaration, container);
    }
  }

  Future<void> _convertClassBody(
    ChangeBuilder builder,
    PrimaryConstructorDeclaration declaration,
    ClassDeclaration classDeclaration,
  ) async {
    var containerBody = classDeclaration.body;
    if (containerBody is BlockClassBody) {
      await _convertPrimaryConstructorInBlockBody(
        builder: builder,
        declaration: declaration,
        body: classDeclaration.primaryConstructorBody,
        leftBracket: containerBody.leftBracket,
        members: containerBody.members,
        rightBracket: containerBody.rightBracket,
      );
    } else if (containerBody is EmptyClassBody) {
      await _convertPrimaryConstructorInEmptyBody(
        builder: builder,
        declaration: declaration,
        body: classDeclaration.primaryConstructorBody,
        semicolon: containerBody.semicolon,
      );
    }
  }

  Future<void> _convertEnumBody(
    ChangeBuilder builder,
    PrimaryConstructorDeclaration declaration,
    EnumDeclaration enumDeclaration,
  ) async {
    var containerBody = enumDeclaration.body;
    if (containerBody.constants.isEmpty) return;
    var namePart = enumDeclaration.namePart;
    if (namePart is! PrimaryConstructorDeclaration) return;

    await _convertPrimaryConstructorInBlockBody(
      builder: builder,
      declaration: declaration,
      body: namePart.body,
      leftBracket: containerBody.leftBracket,
      members: containerBody.members,
      rightBracket: containerBody.rightBracket,
    );
  }

  Future<void> _convertPrimaryConstructorInBlockBody({
    required ChangeBuilder builder,
    required PrimaryConstructorDeclaration declaration,
    required PrimaryConstructorBody? body,
    required Token leftBracket,
    required NodeList<ClassMember> members,
    required Token rightBracket,
  }) async {
    var parameterList = declaration.formalParameters;

    for (var parameter in parameterList.parameters) {
      var normalParameter = parameter.normalParameter;
      if (normalParameter.name == null ||
          parameter.declaredFragment?.element == null) {
        return;
      }
    }

    await builder.addDartFileEdit(file, (builder) {
      var fieldOffset = leftBracket.end;
      var needsSemicolon = false;
      var parent = declaration.parent;
      if (parent is EnumDeclaration) {
        var body = parent.body;
        var semicolon = body.semicolon;
        if (semicolon == null) {
          needsSemicolon = true;
          fieldOffset = body.constants.endToken?.end ?? fieldOffset;
        } else {
          fieldOffset = semicolon.end;
        }
      }

      if (body == null) {
        var constructorOffset = _offsetForConstructor(members, fieldOffset);
        // Add explicit fields and add a new constructor.
        if (constructorOffset == fieldOffset) {
          builder.addInsertion(constructorOffset, (builder) {
            if (needsSemicolon) {
              builder.write(';');
            }
            _writeImplicitlyDeclaredFields(
              builder: builder,
              parameterList: parameterList,
              needsBlankLine: fieldOffset != leftBracket.end,
            );
            _writeFullSecondaryConstructor(builder, declaration, body);
            if (members.isNotEmpty || leftBracket.end == rightBracket.offset) {
              builder.writeln();
            }
          });
        } else {
          builder.addInsertion(fieldOffset, (builder) {
            if (needsSemicolon) {
              builder.write(';');
            }
            _writeImplicitlyDeclaredFields(
              builder: builder,
              parameterList: parameterList,
              needsBlankLine: fieldOffset != leftBracket.end,
            );
          });
          builder.addInsertion(constructorOffset, (builder) {
            if (members.isNotEmpty) {
              builder.writeln();
            }
            _writeFullSecondaryConstructor(builder, declaration, body);
            if (constructorOffset == rightBracket.offset) {
              builder.writeln();
            }
          });
        }
      } else {
        // Add explicit fields and update the existing constructor body.
        builder.addInsertion(fieldOffset, (builder) {
          if (needsSemicolon) {
            builder.write(';');
          }
          _writeImplicitlyDeclaredFields(
            builder: builder,
            parameterList: parameterList,
            needsBlankLine: fieldOffset != leftBracket.end,
          );
        });
        builder.addReplacement(range.token(body.thisKeyword), (builder) {
          _writeNameAndParameterList(builder, declaration);
        });
      }

      // Remove the primary constructor that was converted.
      _removePrimaryConstructor(builder: builder, declaration: declaration);
    });
  }

  Future<void> _convertPrimaryConstructorInEmptyBody({
    required ChangeBuilder builder,
    required PrimaryConstructorDeclaration declaration,
    required PrimaryConstructorBody? body,
    required Token semicolon,
  }) async {
    var parameterList = declaration.formalParameters;

    for (var parameter in parameterList.parameters) {
      var normalParameter = parameter.normalParameter;
      if (normalParameter.name == null ||
          parameter.declaredFragment?.element == null) {
        return;
      }
    }

    await builder.addDartFileEdit(file, (builder) {
      builder.addReplacement(range.token(semicolon), (builder) {
        builder.write(' {');
        _writeImplicitlyDeclaredFields(
          builder: builder,
          parameterList: parameterList,
          needsBlankLine: false,
        );
        _writeFullSecondaryConstructor(builder, declaration, body);
        builder.writeln();
        builder.write('}');
      });

      // Remove the primary constructor that was converted.
      _removePrimaryConstructor(builder: builder, declaration: declaration);
    });
  }

  /// Returns the offset at which a constructor should be inserted based on the
  /// existing [members] of the declaration to which the constructor is being
  /// added.
  ///
  /// This will either be before the first constructor or at the [defaultOffset]
  int _offsetForConstructor(List<ClassMember> members, int defaultOffset) {
    // TODO(brianwilkerson): This should take into account the enablement of the
    //  `sort_constructors_first` and `sort_unnamed_constructors_first` lint
    //  rules.
    ClassMember? previousMember;
    for (var member in members) {
      if (member is ConstructorDeclaration) {
        return previousMember == null ? defaultOffset : previousMember.end;
      }
      previousMember = member;
    }
    return defaultOffset;
  }

  void _removePrimaryConstructor({
    required DartFileEditBuilder builder,
    required PrimaryConstructorDeclaration declaration,
  }) {
    var constKeyword = declaration.constKeyword;
    if (constKeyword != null) {
      builder.addDeletion(range.startStart(constKeyword, constKeyword.next!));
    }
    var constructorName = declaration.constructorName;
    var parameterList = declaration.formalParameters;
    if (constructorName != null) {
      builder.addDeletion(
        range.startEnd(constructorName.period, parameterList),
      );
    } else {
      builder.addDeletion(range.node(parameterList));
    }
  }

  /// Write a full secondary constructor to the [builder].
  void _writeFullSecondaryConstructor(
    DartEditBuilder builder,
    PrimaryConstructorDeclaration declaration,
    PrimaryConstructorBody? body,
  ) {
    builder.writeln();
    builder.write('  ');
    _writeNameAndParameterList(builder, declaration);
    int start;
    if (body != null) {
      if (body.colon != null) {
        start = body.colon!.offset;
      } else {
        start = body.body.offset;
      }
      var bodyText = utils.getRangeText(
        range.startOffsetEndOffset(start, body.end),
      );
      builder.write(bodyText);
    } else {
      builder.write(';');
    }
  }

  /// Write the implicitly declared fields to the [builder].
  void _writeImplicitlyDeclaredFields({
    required DartEditBuilder builder,
    required FormalParameterList parameterList,
    required bool needsBlankLine,
  }) {
    var parameters = parameterList.parameters;
    if (needsBlankLine && parameters.isNotEmpty) {
      builder.writeln();
    }
    for (var parameter in parameters) {
      if (parameter.isDeclaring) {
        builder.writeln();
        builder.write('  ');
        if (parameter.isFinal) {
          builder.write('final ');
        }
        builder.writeType(parameter.declaredFragment!.element.type);
        builder.write(' ');
        builder.write(parameter.name!.lexeme);
        builder.writeln(';');
      }
    }
  }

  /// Write the name and parameter list of the new constructor to the [builder].
  void _writeNameAndParameterList(
    DartEditBuilder builder,
    PrimaryConstructorDeclaration declaration,
  ) {
    var parameterList = declaration.formalParameters;
    if (declaration.constKeyword != null ||
        declaration.parent is EnumDeclaration) {
      builder.write('const ');
    }
    var constructorName = declaration.constructorName;
    builder.write(declaration.typeName.lexeme);
    if (constructorName != null) {
      builder.write(constructorName.period.lexeme);
      builder.write(constructorName.name.lexeme);
    }

    builder.write('(');
    bool needsComma = false;
    String? groupEnd;
    for (var parameter in parameterList.parameters) {
      if (needsComma) {
        builder.write(', ');
      } else {
        needsComma = true;
      }
      if (groupEnd == null) {
        if (parameter.isOptionalPositional) {
          builder.write('[');
          groupEnd = ']';
        } else if (parameter.isNamed) {
          builder.write('{');
          groupEnd = '}';
        }
      }
      String prefix;
      int offset;
      int end = parameter.end;
      if (parameter.isDeclaring) {
        prefix = 'this.';
        var normalParameter = parameter.normalParameter;
        offset = normalParameter.name!.offset;
        if (parameter.isRequiredNamed) {
          prefix = 'required $prefix';
        }
        if (parameter is FunctionTypedFormalParameter) {
          end = parameter.name.end;
        }
      } else {
        prefix = '';
        offset = parameter.offset;
      }
      var parameterText = utils.getRangeText(
        range.startOffsetEndOffset(offset, end),
      );
      builder.write(prefix);
      builder.write(parameterText);
    }
    if (groupEnd != null) {
      builder.write(groupEnd);
    }
    builder.write(')');
  }
}

extension on ClassDeclaration {
  /// Returns the primary constructor body associated with `this`.
  ///
  /// Returns `null` if there is no primary constructor body associated with
  /// `this`.
  PrimaryConstructorBody? get primaryConstructorBody {
    var body = this.body;
    if (body is! BlockClassBody) return null;
    for (var member in body.members) {
      if (member is PrimaryConstructorBody) return member;
    }
    return null;
  }
}

extension on FormalParameter {
  bool get isDeclaring {
    if (isFinal) return true;
    var normalParameter = this.normalParameter;
    return switch (normalParameter) {
      SimpleFormalParameter() => normalParameter.keyword.isVar,
      FunctionTypedFormalParameter() => normalParameter.keyword.isVar,
      FieldFormalParameter() => false,
      SuperFormalParameter() => false,
    };
  }

  /// Returns the normal formal parameter associated with `this`.
  NormalFormalParameter get normalParameter {
    var self = this;
    return switch (self) {
      DefaultFormalParameter(:var parameter) => parameter,
      NormalFormalParameter() => self,
    };
  }
}

extension on Token? {
  /// Whether this token is a `var` keyword.
  bool get isVar {
    var self = this;
    return self is KeywordToken && self.keyword == Keyword.VAR;
  }
}
