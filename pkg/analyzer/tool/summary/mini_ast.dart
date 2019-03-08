// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:front_end/src/fasta/messages.dart' show LocatedMessage, Message;
import 'package:front_end/src/fasta/parser.dart';
import 'package:front_end/src/fasta/problems.dart'
    show internalProblem, unsupported;
import 'package:front_end/src/fasta/source/stack_listener.dart';
import 'package:front_end/src/scanner/token.dart';

/// "Mini AST" representation of a declaration which can accept annotations.
class AnnotatedNode {
  final Comment documentationComment;

  final List<Annotation> metadata;

  AnnotatedNode(this.documentationComment, List<Annotation> metadata)
      : metadata = metadata ?? const [];
}

/// "Mini AST" representation of an annotation.
class Annotation {
  final String name;

  final String constructorName;

  final List<Expression> arguments;

  Annotation(this.name, this.constructorName, this.arguments);
}

/// "Mini AST" representation of a class declaration.
class ClassDeclaration extends CompilationUnitMember {
  final String name;

  final TypeName superclass;

  final List<ClassMember> members;

  ClassDeclaration(Comment documentationComment, List<Annotation> metadata,
      this.name, this.superclass, this.members)
      : super(documentationComment, metadata);
}

/// "Mini AST" representation of a class member.
class ClassMember extends AnnotatedNode {
  ClassMember(Comment documentationComment, List<Annotation> metadata)
      : super(documentationComment, metadata);
}

/// "Mini AST" representation of a comment.
class Comment {
  final bool isDocumentation;

  final List<Token> tokens;

  factory Comment(Token commentToken) {
    var tokens = <Token>[];
    bool isDocumentation = false;
    while (commentToken != null) {
      if (commentToken.lexeme.startsWith('/**') ||
          commentToken.lexeme.startsWith('///')) {
        isDocumentation = true;
      }
      tokens.add(commentToken);
      commentToken = commentToken.next;
    }
    return new Comment._(isDocumentation, tokens);
  }

  Comment._(this.isDocumentation, this.tokens);
}

/// "Mini AST" representation of a CompilationUnit.
class CompilationUnit {
  final declarations = <CompilationUnitMember>[];
}

/// "Mini AST" representation of a top level member of a compilation unit.
class CompilationUnitMember extends AnnotatedNode {
  CompilationUnitMember(Comment documentationComment, List<Annotation> metadata)
      : super(documentationComment, metadata);
}

/// "Mini AST" representation of a constructor declaration.
class ConstructorDeclaration extends ClassMember {
  final String name;

  ConstructorDeclaration(
      Comment documentationComment, List<Annotation> metadata, this.name)
      : super(documentationComment, metadata);
}

/// "Mini AST" representation of an individual enum constant in an enum
/// declaration.
class EnumConstantDeclaration extends AnnotatedNode {
  final String name;

  EnumConstantDeclaration(
      Comment documentationComment, List<Annotation> metadata, this.name)
      : super(documentationComment, metadata);
}

/// "Mini AST" representation of an enum declaration.
class EnumDeclaration extends CompilationUnitMember {
  final String name;

  final List<EnumConstantDeclaration> constants;

  EnumDeclaration(Comment documentationComment, List<Annotation> metadata,
      this.name, this.constants)
      : super(documentationComment, metadata);
}

/// "Mini AST" representation of an expression.
class Expression {
  String toCode() {
    throw UnimplementedError('$runtimeType');
  }
}

/// "Mini AST" representation of an integer literal.
class IntegerLiteral extends Expression {
  final int value;

  IntegerLiteral(this.value);
}

/// "Mini AST" representation of a list literal.
class ListLiteral extends Expression {
  final Token leftBracket;
  final List<Expression> elements;
  final Token rightBracket;

  ListLiteral(this.leftBracket, this.elements, this.rightBracket);

  @override
  String toCode() {
    return '[' + elements.map((e) => e.toCode()).join(', ') + ']';
  }
}

/// "Mini AST" representation of a named expression.
class NamedExpression extends Expression {
  final String name;
  final Token colon;
  final Expression expression;

  NamedExpression(this.name, this.colon, this.expression);
}

/// "Mini AST" representation of a named expression.
class PrefixedIdentifier extends Expression {
  final String prefix;
  final Token operator;
  final String identifier;

  PrefixedIdentifier(this.prefix, this.operator, this.identifier);

  @override
  String toCode() {
    return '$prefix.$identifier';
  }
}

/// "Mini AST" representation of a method declaration.
class MethodDeclaration extends ClassMember {
  final bool isGetter;

  final String name;

  final TypeName returnType;

  MethodDeclaration(Comment documentationComment, List<Annotation> metadata,
      this.isGetter, this.name, this.returnType)
      : super(documentationComment, metadata);
}

/// Parser listener which generates a "mini AST" representation of the source
/// code.  This representation is just sufficient for summary code generation.
class MiniAstBuilder extends StackListener {
  bool inMetadata = false;

  final compilationUnit = new CompilationUnit();

  @override
  Uri get uri => null;

  @override
  void addProblem(Message message, int charOffset, int length,
      {bool wasHandled: false, List<LocatedMessage> context}) {
    internalProblem(message, charOffset, uri);
  }

  @override
  void beginMetadata(Token token) {
    inMetadata = true;
  }

  @override
  void beginMetadataStar(Token token) {
    debugEvent("beginMetadataStar");
    if (token.precedingComments != null) {
      push(new Comment(token.precedingComments));
    } else {
      push(NullValue.Comments);
    }
  }

  @override
  void endArguments(int count, Token beginToken, Token endToken) {
    debugEvent("Arguments");
    push(popList(count, new List<dynamic>.filled(count, null, growable: true)));
  }

  @override
  void endClassOrMixinBody(int memberCount, Token beginToken, Token endToken) {
    debugEvent("ClassOrMixinBody");
    push(popList(memberCount,
        new List<ClassMember>.filled(memberCount, null, growable: true)));
  }

  @override
  void handleClassWithClause(Token withKeyword) {
    debugEvent("ClassWithClause");
  }

  @override
  void handleClassNoWithClause() {
    debugEvent("NoClassWithClause");
  }

  @override
  void handleNamedMixinApplicationWithClause(Token withKeyword) {
    debugEvent("NamedMixinApplicationWithClause");
  }

  @override
  void handleRecoverClassHeader() {
    pop(); // superclass
  }

  void endClassDeclaration(Token beginToken, Token endToken) {
    debugEvent("ClassDeclaration");
    List<ClassMember> members = popTypedList();
    TypeName superclass = pop();
    pop(); // Type variables
    String name = pop();
    List<Annotation> metadata = popTypedList();
    Comment comment = pop();
    compilationUnit.declarations.add(
        new ClassDeclaration(comment, metadata, name, superclass, members));
  }

  @override
  void endCombinators(int count) {
    debugEvent("Combinators");
  }

  @override
  void endConditionalUris(int count) {
    debugEvent("ConditionalUris");
    if (count != 0) {
      unsupported("Conditional URIs", -1, null);
    }
  }

  void endEnum(Token enumKeyword, Token leftBrace, int count) {
    debugEvent("Enum");
    List<EnumConstantDeclaration> constants =
        new List.filled(count, null, growable: true);
    popList(count, constants);
    String name = pop();
    List<Annotation> metadata = popTypedList();
    Comment comment = pop();
    compilationUnit.declarations
        .add(new EnumDeclaration(comment, metadata, name, constants));
  }

  @override
  void endFactoryMethod(
      Token beginToken, Token factoryKeyword, Token endToken) {
    debugEvent("FactoryMethod");
    pop(); // Body
    pop(); // Type variables
    String name = pop();
    List<Annotation> metadata = popTypedList();
    Comment comment = pop();
    push(new ConstructorDeclaration(comment, metadata, name));
  }

  @override
  void endFieldInitializer(Token assignment, Token token) {
    debugEvent("FieldInitializer");
    pop(); // Expression
  }

  @override
  void endFormalParameter(Token thisKeyword, Token periodAfterThis,
      Token nameToken, FormalParameterKind kind, MemberKind memberKind) {
    debugEvent("FormalParameter");
    pop(); // Name
    pop(); // Type
    pop(); // Metadata
    pop(); // Comment
  }

  @override
  void endFormalParameters(
      int count, Token beginToken, Token endToken, MemberKind kind) {
    debugEvent("FormalParameters");
  }

  @override
  void handleIdentifierList(int count) {
    debugEvent("IdentifierList");
    push(popList(count, new List<dynamic>.filled(count, null, growable: true)));
  }

  @override
  void handleImportPrefix(Token deferredKeyword, Token asKeyword) {
    debugEvent("ImportPrefix");
    pushIfNull(asKeyword, NullValue.Prefix);
  }

  @override
  void endImport(Token importKeyword, Token semicolon) {
    debugEvent("Import");
    pop(NullValue.Prefix); // Prefix identifier
    pop(); // URI
    pop(); // Metadata
    pop(); // Comment
  }

  @override
  void handleRecoverImport(Token semicolon) {
    debugEvent("RecoverImport");
    pop(NullValue.Prefix); // Prefix identifier
  }

  @override
  void endLibraryName(Token libraryKeyword, Token semicolon) {
    debugEvent("LibraryName");
    pop(); // Library name
    pop(); // Metadata
    pop(); // Comment
  }

  @override
  void endLiteralString(int interpolationCount, Token endToken) {
    super.endLiteralString(interpolationCount, endToken);
    String value = pop();
    push(new StringLiteral(value));
  }

  @override
  void handleNativeClause(Token nativeToken, bool hasName) {
    debugEvent("NativeClause");
    if (hasName) {
      pop(); // Pop the native name which is a StringLiteral.
    }
  }

  @override
  void handleInvalidMember(Token endToken) {
    debugEvent("InvalidMember");
    pop(); // metadata star
  }

  @override
  void endMember() {
    debugEvent("Member");
  }

  @override
  void endMetadata(Token beginToken, Token periodBeforeName, Token endToken) {
    debugEvent("Metadata");
    inMetadata = false;
    List arguments = pop();
    String constructorName = popIfNotNull(periodBeforeName);
    pop(); // Type arguments
    String name = pop();
    push(new Annotation(name, constructorName,
        arguments == null ? null : arguments.cast<Expression>()));
  }

  @override
  void endMetadataStar(int count) {
    debugEvent("MetadataStar");
    push(popList(
            count, new List<Annotation>.filled(count, null, growable: true)) ??
        NullValue.Metadata);
  }

  void endMethod(
      Token getOrSet, Token beginToken, Token beginParam, Token endToken) {
    debugEvent("Method");
    pop(); // Body
    pop(); // Initializers
    pop(); // Formal parameters
    pop(); // Type variables
    String name = pop();
    TypeName returnType = pop();
    List<Annotation> metadata = popTypedList();
    Comment comment = pop();
    push(new MethodDeclaration(
        comment, metadata, getOrSet?.lexeme == 'get', name, returnType));
  }

  @override
  void handleSend(Token beginToken, Token endToken) {
    debugEvent("Send");

    var arguments = pop();
    pop(); // Type arguments
    if (arguments != null) {
      pop(); // Receiver
      push(new UnknownExpression());
    } else {
      // Property get.
    }
  }

  @override
  void endShow(Token showKeyword) {
    debugEvent("Show");
    pop(); // Shown names
  }

  @override
  void handleNamedArgument(Token colon) {
    var expression = pop();
    var name = pop();
    push(NamedExpression(name, colon, expression));
  }

  @override
  void handleLiteralList(
      int count, Token leftBracket, Token constKeyword, Token rightBracket) {
    debugEvent("LiteralList");

    var elements = List<Object>(count);
    popList(count, elements);
    pop(); // type arguments

    push(
      ListLiteral(
        leftBracket,
        List<Expression>.from(elements),
        rightBracket,
      ),
    );
  }

  @override
  void endTopLevelFields(Token staticToken, Token covariantToken,
      Token varFinalOrConst, int count, Token beginToken, Token endToken) {
    // We ignore top level variable declarations; they are present just to make
    // the IDL analyze without warnings.
    debugEvent("TopLevelFields");
    popList(
        count, new List<dynamic>.filled(count, null, growable: true)); // Fields
    pop(); // Type
    pop(); // Metadata
    pop(); // Comment
  }

  @override
  void endTypeArguments(int count, Token beginToken, Token endToken) {
    debugEvent("TypeArguments");
    push(
        popList(count, new List<TypeName>.filled(count, null, growable: true)));
  }

  @override
  void handleInvalidTypeArguments(Token token) {
    debugEvent("InvalidTypeArguments");
    pop(NullValue.TypeArguments);
  }

  @override
  void handleAsyncModifier(Token asyncToken, Token starToken) {
    debugEvent("AsyncModifier");
  }

  @override
  void endBinaryExpression(Token token) {
    debugEvent("BinaryExpression");

    if (identical('.', token.stringValue)) {
      var rightOperand = pop();
      var leftOperand = pop();
      if (leftOperand is String && !leftOperand.contains('.')) {
        push(PrefixedIdentifier(leftOperand, token, rightOperand));
      } else {
        push(new UnknownExpression());
      }
    } else {
      pop(); // RHS
      pop(); // LHS
      push(new UnknownExpression());
    }
  }

  @override
  void handleFormalParameterWithoutValue(Token token) {
    debugEvent("FormalParameterWithoutValue");
  }

  @override
  void handleFunctionBodySkipped(Token token, bool isExpressionBody) {
    if (isExpressionBody) pop();
    push(NullValue.FunctionBody);
  }

  @override
  void handleNativeFunctionBodyIgnored(Token nativeToken, Token semicolon) {
    debugEvent("NativeFunctionBodyIgnored");
  }

  @override
  void handleNativeFunctionBodySkipped(Token nativeToken, Token semicolon) {
    debugEvent("NativeFunctionBodySkipped");
    push(NullValue.FunctionBody);
  }

  void handleIdentifier(Token token, IdentifierContext context) {
    if (context == IdentifierContext.enumValueDeclaration) {
      List<Annotation> metadata = popTypedList();
      Comment comment = pop();
      push(new EnumConstantDeclaration(comment, metadata, token.lexeme));
    } else {
      push(token.lexeme);
    }
  }

  @override
  void handleInvalidTopLevelDeclaration(Token endToken) {
    debugEvent("InvalidTopLevelDeclaration");
    pop(); // metadata star
  }

  void handleLiteralInt(Token token) {
    debugEvent("LiteralInt");
    push(new IntegerLiteral(int.parse(token.lexeme)));
  }

  void handleLiteralNull(Token token) {
    debugEvent("LiteralNull");
    push(new UnknownExpression());
  }

  @override
  void handleQualified(Token period) {
    debugEvent("Qualified");
    String suffix = pop();
    String prefix = pop();
    push('$prefix.$suffix');
  }

  @override
  void handleType(Token beginToken, Token questionMark) {
    debugEvent("Type");
    reportErrorIfNullableType(questionMark);
    List<TypeName> typeArguments = popTypedList();
    String name = pop();
    push(new TypeName(name, typeArguments));
  }

  @override
  void handleNonNullAssertExpression(Token bang) {
    reportNonNullAssertExpressionNotEnabled(bang);
  }

  /// Calls [pop] and creates a list with the appropriate type parameter `T`
  /// from the resulting `List<dynamic>`.
  List<T> popTypedList<T>() {
    List list = pop();
    return list != null ? new List<T>.from(list) : null;
  }

  List popList(int n, List list) {
    if (n == 0) return null;
    return stack.popList(n, list, null);
  }
}

/// Parser intended for use with [MiniAstBuilder].
class MiniAstParser extends Parser {
  MiniAstParser(MiniAstBuilder listener) : super(listener);

  Token parseArgumentsOpt(Token token) {
    MiniAstBuilder listener = this.listener;
    if (listener.inMetadata) {
      return super.parseArgumentsOpt(token);
    } else {
      return skipArgumentsOpt(token);
    }
  }

  Token parseFunctionBody(Token token, bool isExpression, bool allowAbstract) {
    return skipFunctionBody(token, isExpression, allowAbstract);
  }

  @override
  Token parseInvalidBlock(Token token) => skipBlock(token);
}

/// "Mini AST" representation of a string literal.
class StringLiteral extends Expression {
  final String stringValue;

  StringLiteral(this.stringValue);
}

/// "Mini AST" representation of a type name.
class TypeName {
  final String name;

  final List<TypeName> typeArguments;

  TypeName(this.name, this.typeArguments);
}

/// "Mini AST" representation of an expression which summary code generation
/// need not be concerned about.
class UnknownExpression extends Expression {}
