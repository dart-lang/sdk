// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/lsp_protocol/protocol.dart' hide Element;
import 'package:analysis_server/src/lsp/constants.dart';
import 'package:analysis_server/src/lsp/error_or.dart';
import 'package:analysis_server/src/lsp/handlers/handlers.dart';
import 'package:analysis_server/src/lsp/mapping.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/ast.dart';

class SummaryHandler
    extends
        SharedMessageHandler<DartTextDocumentSummaryParams, DocumentSummary> {
  SummaryHandler(super.server);

  @override
  Method get handlesMessage => CustomMethods.summary;

  @override
  LspJsonHandler<DartTextDocumentSummaryParams> get jsonHandler =>
      DartTextDocumentSummaryParams.jsonHandler;

  @override
  bool get requiresTrustedCaller => false;

  @override
  Future<ErrorOr<DocumentSummary>> handle(
    DartTextDocumentSummaryParams params,
    MessageInfo message,
    CancellationToken token,
  ) async {
    if (!isDartUri(params.uri)) {
      return success(DocumentSummary());
    }

    var path = pathOfUri(params.uri);
    var resultOr = await path.mapResult(requireUnresolvedUnit);
    if (resultOr.isError) {
      return ErrorOr.error(resultOr.errorOrNull!);
    }
    return resultOr.mapResultSync((result) {
      try {
        var summary = SummaryWriter(result).summarize();
        return success(DocumentSummary(summary: summary));
      } catch (e) {
        return error(ErrorCodes.InternalError, 'Failed to create a summary.');
      }
    });
  }
}

/// An objct used to write a summary for a single file.
///
/// The summary contains the public API for the library, but doesn't include
/// - private members
/// - bodies of functions / methods
/// - initializers of variables / fields
class SummaryWriter {
  final ParsedUnitResult result;

  final StringBuffer buffer = StringBuffer();

  SummaryWriter(this.result);

  void copyRange(int offset, int end) {
    buffer.write(result.content.substring(offset, end));
  }

  String summarize() {
    for (var declaration in result.unit.declarations) {
      switch (declaration) {
        case ClassDeclaration():
          summarizeClass(declaration);
        case EnumDeclaration():
          summarizeEnum(declaration);
        case ExtensionDeclaration():
          summarizeExtension(declaration);
        case ExtensionTypeDeclaration():
          summarizeExtensionType(declaration);
        case FunctionDeclaration():
          summarizeFunction(declaration);
        case MixinDeclaration():
          summarizeMixin(declaration);
        case TopLevelVariableDeclaration():
          summarizeVariable(declaration);
        case TypeAlias():
          summarizeTypeAlias(declaration);
      }
    }
    return buffer.toString();
  }

  void summarizeClass(ClassDeclaration declaration) {
    var name = declaration.name.lexeme;
    if (name.isEmpty || Identifier.isPrivateName(name)) {
      return;
    }

    var offset = declaration.firstTokenAfterCommentAndMetadata.offset;
    var end = declaration.leftBracket.end;
    copyRange(offset, end);
    buffer.writeln();
    summarizeMembers(declaration.members);
    buffer.writeln('}');
  }

  void summarizeConstructor(ConstructorDeclaration declaration) {
    var name = declaration.name?.lexeme;
    if (name != null && (name.isEmpty || Identifier.isPrivateName(name))) {
      return;
    }

    var offset = declaration.firstTokenAfterCommentAndMetadata.offset;
    var end = declaration.parameters.rightParenthesis.end;
    copyRange(offset, end);
    buffer.writeln(';');
  }

  void summarizeEnum(EnumDeclaration declaration) {
    var name = declaration.name.lexeme;
    if (name.isEmpty || Identifier.isPrivateName(name)) {
      return;
    }

    var offset = declaration.firstTokenAfterCommentAndMetadata.offset;
    var end = declaration.leftBracket.end;
    copyRange(offset, end);
    buffer.writeln();
    summarizeEnumConstants(declaration.constants);
    summarizeMembers(declaration.members);
    buffer.writeln('}');
  }

  void summarizeEnumConstants(NodeList<EnumConstantDeclaration> constants) {
    buffer.write('  ');
    var separator = '';
    for (var constant in constants) {
      buffer.write(separator);
      var offset = constant.firstTokenAfterCommentAndMetadata.offset;
      var end = constant.endToken.end;
      copyRange(offset, end);
      separator = ', ';
    }
    buffer.writeln(';');
  }

  void summarizeExtension(ExtensionDeclaration declaration) {
    var name = declaration.name?.lexeme;
    if (name != null && Identifier.isPrivateName(name)) {
      return;
    }

    var offset = declaration.firstTokenAfterCommentAndMetadata.offset;
    var end = declaration.leftBracket.end;
    copyRange(offset, end);
    buffer.writeln();
    summarizeMembers(declaration.members);
    buffer.writeln('}');
  }

  void summarizeExtensionType(ExtensionTypeDeclaration declaration) {
    var name = declaration.name.lexeme;
    if (name.isEmpty || Identifier.isPrivateName(name)) {
      return;
    }

    var offset = declaration.firstTokenAfterCommentAndMetadata.offset;
    var end = declaration.leftBracket.end;
    copyRange(offset, end);
    buffer.writeln();
    summarizeMembers(declaration.members);
    buffer.writeln('}');
  }

  void summarizeFields(FieldDeclaration declaration) {
    var fields = declaration.fields;
    var variableList = fields.variables;
    var offset = declaration.firstTokenAfterCommentAndMetadata.offset;
    var end = variableList.beginToken!.previous!.end;
    copyRange(offset, end);
    var separator = ' ';
    for (var field in variableList) {
      buffer.write(separator);
      buffer.write(field.name.lexeme);
      separator = ', ';
    }
    buffer.writeln(';');
  }

  void summarizeFunction(FunctionDeclaration declaration) {
    var offset = declaration.firstTokenAfterCommentAndMetadata.offset;
    var end = declaration.functionExpression.body.beginToken.previous!.end;
    copyRange(offset, end);
    buffer.writeln(';');
  }

  void summarizeMembers(NodeList<ClassMember> members) {
    for (var member in members) {
      buffer.write('  ');
      switch (member) {
        case ConstructorDeclaration():
          summarizeConstructor(member);
        case FieldDeclaration():
          summarizeFields(member);
        case MethodDeclaration():
          summarizeMethod(member);
      }
    }
  }

  void summarizeMethod(MethodDeclaration declaration) {
    var name = declaration.name.lexeme;
    if (name.isEmpty || Identifier.isPrivateName(name)) {
      return;
    }

    var offset = declaration.firstTokenAfterCommentAndMetadata.offset;
    var end = declaration.body.beginToken.previous!.end;
    copyRange(offset, end);
    buffer.writeln(';');
  }

  void summarizeMixin(MixinDeclaration declaration) {
    var name = declaration.name.lexeme;
    if (name.isEmpty || Identifier.isPrivateName(name)) {
      return;
    }

    var offset = declaration.firstTokenAfterCommentAndMetadata.offset;
    var end = declaration.leftBracket.end;
    copyRange(offset, end);
    buffer.writeln();
    summarizeMembers(declaration.members);
    buffer.writeln('}');
  }

  void summarizeTypeAlias(TypeAlias declaration) {
    var name = declaration.name.lexeme;
    if (name.isEmpty || Identifier.isPrivateName(name)) {
      return;
    }

    var offset = declaration.firstTokenAfterCommentAndMetadata.offset;
    var end = declaration.endToken.end;
    copyRange(offset, end);
    buffer.writeln();
  }

  void summarizeVariable(TopLevelVariableDeclaration declaration) {
    var variables = declaration.variables;
    var variableList = variables.variables;
    var offset = declaration.firstTokenAfterCommentAndMetadata.offset;
    var end = variableList.beginToken!.previous!.end;
    copyRange(offset, end);
    var separator = ' ';
    for (var variable in variableList) {
      buffer.write(separator);
      buffer.write(variable.name.lexeme);
      separator = ', ';
    }
    buffer.writeln(';');
  }
}
