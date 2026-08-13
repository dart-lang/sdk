// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/assist.dart';
import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer_plugin/utilities/assist/assist.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_dart.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';
import 'package:collection/collection.dart';

class ConvertToInBodyConstructor extends ResolvedCorrectionProducer {
  new({required super.context});

  @override
  CorrectionApplicability get applicability =>
      // Not a fix.
      CorrectionApplicability.singleLocation;

  @override
  AssistKind? get assistKind => DartAssistKind.convertToInBodyConstructor;

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
    if (containerBody is! BlockEnumBody) {
      return;
    }

    var constants = containerBody.constants;
    if (constants.isEmpty) return;

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
    // Verify the parameters and collect the corresponding elements.
    var parameterList = declaration.formalParameters;
    var parameterElements = <FormalParameterElement>[];
    for (var parameter in parameterList.parameters) {
      var parameterElement = parameter.declaredFragment?.element;
      if (parameter.name == null || parameterElement == null) {
        return;
      }
      parameterElements.add(parameterElement);
    }

    var referencingFields = _fieldsReferencingParameters(
      members,
      parameterElements,
    );

    await builder.addDartFileEdit(file, (builder) {
      var fieldOffset = leftBracket.end;
      var needsSemicolon = false;
      var parent = declaration.parent;
      if (parent is EnumDeclaration) {
        var body = parent.body;
        var semicolon = body is BlockEnumBody ? body.semicolon : null;
        if (semicolon == null) {
          needsSemicolon = true;
          var constants = body is BlockEnumBody ? body.constants : null;
          fieldOffset = constants?.endToken?.end ?? fieldOffset;
        } else {
          fieldOffset = semicolon.end;
        }
      }

      if (body == null) {
        var isNamed = declaration.constructorName != null;
        var constructorOffset = _offsetForConstructor(
          members,
          fieldOffset,
          isNamed,
        );
        // Add explicit fields and add a new constructor.
        if (constructorOffset == fieldOffset) {
          var codeStyleOptions = getCodeStyleOptions(unitResult.file);
          builder.addInsertion(constructorOffset, (builder) {
            if (needsSemicolon) {
              builder.write(';');
            }
            if (codeStyleOptions.sortConstructorsFirst) {
              _writeFullInBodyConstructor(
                builder,
                declaration,
                referencingFields,
                body,
              );
              _writeImplicitlyDeclaredFields(
                builder: builder,
                parameterList: parameterList,
                needsBlankLine: fieldOffset != leftBracket.end,
              );
            } else {
              _writeImplicitlyDeclaredFields(
                builder: builder,
                parameterList: parameterList,
                needsBlankLine: fieldOffset != leftBracket.end,
              );
              _writeFullInBodyConstructor(
                builder,
                declaration,
                referencingFields,
                body,
              );
            }
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
            _writeFullInBodyConstructor(
              builder,
              declaration,
              referencingFields,
              body,
            );
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

      // Remove the initializers that reference parameters from the primary
      // constructor.
      _removeFieldInitializers(builder, referencingFields);
    });
  }

  Future<void> _convertPrimaryConstructorInEmptyBody({
    required ChangeBuilder builder,
    required PrimaryConstructorDeclaration declaration,
    required PrimaryConstructorBody? body,
    required Token semicolon,
  }) async {
    // Verify the parameters and collect the corresponding elements.
    var parameterList = declaration.formalParameters;
    var parameterElements = <FormalParameterElement>[];
    for (var parameter in parameterList.parameters) {
      var parameterElement = parameter.declaredFragment?.element;
      if (parameter.name == null || parameterElement == null) {
        return;
      }
      parameterElements.add(parameterElement);
    }

    var referencingFields = _fieldsReferencingParameters([], parameterElements);

    await builder.addDartFileEdit(file, (builder) {
      builder.addReplacement(range.token(semicolon), (builder) {
        builder.write(' {');
        _writeImplicitlyDeclaredFields(
          builder: builder,
          parameterList: parameterList,
          needsBlankLine: false,
        );
        _writeFullInBodyConstructor(
          builder,
          declaration,
          referencingFields,
          body,
        );
        builder.writeln();
        builder.write('}');
      });

      // Remove the primary constructor that was converted.
      _removePrimaryConstructor(builder: builder, declaration: declaration);

      // Remove the initializers that reference parameters from the primary
      // constructor.
      _removeFieldInitializers(builder, referencingFields);
    });
  }

  List<VariableDeclaration> _fieldsReferencingParameters(
    List<ClassMember> members,
    List<FormalParameterElement> parameterElements,
  ) {
    var referencingFields = <VariableDeclaration>[];
    for (var member in members) {
      if (member is FieldDeclaration) {
        for (var field in member.fields.variables) {
          var initializer = field.initializer;
          if (initializer != null) {
            var checker = _ReferenceChecker(parameterElements);
            initializer.accept(checker);
            if (checker.hasReference) {
              referencingFields.add(field);
            }
          }
        }
      }
    }
    return referencingFields;
  }

  /// Returns the offset at which a constructor should be inserted based on the
  /// existing [members] of the declaration to which the constructor is being
  /// added.
  ///
  /// [isNamed] indicates whether the constructor being inserted is named,
  /// which affects placement when the `sort_unnamed_constructors_first` lint is
  /// enabled.
  int _offsetForConstructor(
    List<ClassMember> members,
    int defaultOffset,
    bool isNamed,
  ) {
    var codeStyleOptions = getCodeStyleOptions(unitResult.file);
    if (codeStyleOptions.sortConstructorsFirst) {
      return members.lastWhereOrNull((m) => m is ConstructorDeclaration)?.end ??
          defaultOffset;
    }
    if (!isNamed && codeStyleOptions.sortUnnamedConstructorsFirst) {
      return members
              .lastWhereOrNull(
                (m) =>
                    (m is ConstructorDeclaration && m.name == null) ||
                    m is FieldDeclaration,
              )
              ?.end ??
          defaultOffset;
    }
    if (isNamed && codeStyleOptions.sortUnnamedConstructorsFirst) {
      return members
              .lastWhereOrNull(
                (m) => m is ConstructorDeclaration && m.name == null,
              )
              ?.end ??
          defaultOffset;
    }
    ClassMember? previousMember;
    for (var member in members) {
      if (member is ConstructorDeclaration) {
        return previousMember == null ? defaultOffset : previousMember.end;
      }
      previousMember = member;
    }
    return defaultOffset;
  }

  /// Removes the field initializers that reference parameters in the primary
  /// constructor.
  void _removeFieldInitializers(
    DartFileEditBuilder builder,
    List<VariableDeclaration> referencingFields,
  ) {
    for (var field in referencingFields) {
      builder.addDeletion(range.endEnd(field.name, field.initializer!));
    }
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

  /// Write a full in-body constructor to the [builder].
  void _writeFullInBodyConstructor(
    DartEditBuilder builder,
    PrimaryConstructorDeclaration declaration,
    List<VariableDeclaration> referencingFields,
    PrimaryConstructorBody? body,
  ) {
    builder.writeln();
    builder.write('  ');
    _writeNameAndParameterList(builder, declaration);
    if (body != null) {
      var colon = body.colon;
      if (colon != null) {
        var initializerText = utils.getRangeText(
          range.startEnd(colon, body.initializers.last),
        );
        builder.write(initializerText);
        if (referencingFields.isNotEmpty) {
          builder.write(', ');
          _writeReferencingFields(builder, referencingFields);
        }
      } else if (referencingFields.isNotEmpty) {
        builder.write(' : ');
        _writeReferencingFields(builder, referencingFields);
      }
      var bodyText = utils.getRangeText(range.node(body.body));
      builder.write(bodyText);
    } else {
      if (referencingFields.isNotEmpty) {
        builder.write(' : ');
        _writeReferencingFields(builder, referencingFields);
      }
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
    if (declaration.constKeyword != null &&
        declaration.parent is! EnumDeclaration) {
      builder.write('const ');
    }
    var constructorName = declaration.constructorName;
    builder.write('new');
    if (constructorName != null) {
      builder.write(' ');
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
        offset = parameter.name!.offset;
        if (parameter.isRequiredNamed) {
          prefix = 'required $prefix';
        }
        if (parameter.functionTypedSuffix != null) {
          end = parameter.name!.end;
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

  /// Writes constructor initializers for all of the fields whose initializer
  /// references one of the parameters from the primary constructor.
  void _writeReferencingFields(
    DartEditBuilder builder,
    List<VariableDeclaration> referencingFields,
  ) {
    var needsComma = false;
    for (var field in referencingFields) {
      var initializerText = utils.getRangeText(
        range.startEnd(field.name, field.initializer!),
      );
      if (needsComma) {
        builder.write(', ');
      }
      builder.write(initializerText);
      needsComma = true;
    }
  }
}

class _ReferenceChecker extends RecursiveAstVisitor<void> {
  List<FormalParameterElement> parameterElements;

  bool hasReference = false;

  new(this.parameterElements);

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    var element = node.element;
    if (parameterElements.contains(element)) {
      hasReference = true;
    }
    super.visitSimpleIdentifier(node);
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
    return switch (this) {
      RegularFormalParameter parameter => parameter.varKeyword != null,
      FieldFormalParameter() => false,
      SuperFormalParameter() => false,
    };
  }
}
