// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/src/generated/utilities_dart.dart';
import 'package:front_end/src/scanner/token.dart';
import 'package:meta/meta.dart';

/**
 * A collection of factory methods which may be used to create concrete
 * instances of the interfaces that constitute the AST.
 *
 * Clients should not extend, implement or mix-in this class.
 */
abstract class AstFactory {
  /**
   * Returns a newly created list of adjacent strings. To be syntactically
   * valid, the list of [strings] must contain at least two elements.
   */
  AdjacentStrings adjacentStrings(List<StringLiteral> strings);

  /**
   * Returns a newly created annotation. Both the [period] and the
   * [constructorName] can be `null` if the annotation is not referencing a
   * named constructor. The [arguments] can be `null` if the annotation is not
   * referencing a constructor.
   */
  Annotation annotation(Token atSign, Identifier name, Token period,
      SimpleIdentifier constructorName, ArgumentList arguments);

  /**
   * Returns a newly created list of arguments. The list of [arguments] can
   * be `null` if there are no arguments.
   */
  ArgumentList argumentList(Token leftParenthesis, List<Expression> arguments,
      Token rightParenthesis);

  /**
   * Returns a newly created as expression.
   */
  AsExpression asExpression(
      Expression expression, Token asOperator, TypeAnnotation type);

  /**
   * Returns a newly created assert initializer. The [comma] and [message]
   * can be `null` if there is no message.
   */
  AssertInitializer assertInitializer(
      Token assertKeyword,
      Token leftParenthesis,
      Expression condition,
      Token comma,
      Expression message,
      Token rightParenthesis);

  /**
   * Returns a newly created assert statement. The [comma] and [message] can
   * be `null` if there is no message.
   */
  AssertStatement assertStatement(
      Token assertKeyword,
      Token leftParenthesis,
      Expression condition,
      Token comma,
      Expression message,
      Token rightParenthesis,
      Token semicolon);

  /**
   * Returns a newly created assignment expression.
   */
  AssignmentExpression assignmentExpression(
      Expression leftHandSide, Token operator, Expression rightHandSide);

  /**
   * Returns a newly created await expression.
   */
  AwaitExpression awaitExpression(Token awaitKeyword, Expression expression);

  /**
   * Returns a newly created binary expression.
   */
  BinaryExpression binaryExpression(
      Expression leftOperand, Token operator, Expression rightOperand);

  /**
   * Returns a newly created block of code.
   */
  Block block(
      Token leftBracket, List<Statement> statements, Token rightBracket);

  /**
   * Returns a block comment consisting of the given [tokens].
   */
  Comment blockComment(List<Token> tokens);

  /**
   * Returns a newly created function body consisting of a block of
   * statements. The [keyword] can be `null` if there is no keyword specified
   * for the block. The [star] can be `null` if there is no star following the
   * keyword (and must be `null` if there is no keyword).
   */
  BlockFunctionBody blockFunctionBody(Token keyword, Token star, Block block);

  /**
   * Returns a newly created boolean literal.
   */
  BooleanLiteral booleanLiteral(Token literal, bool value);

  /**
   * Returns a newly created break statement. The [label] can be `null` if
   * there is no label associated with the statement.
   */
  BreakStatement breakStatement(
      Token breakKeyword, SimpleIdentifier label, Token semicolon);

  /**
   * Returns a newly created cascade expression. The list of
   * [cascadeSections] must contain at least one element.
   */
  CascadeExpression cascadeExpression(
      Expression target, List<Expression> cascadeSections);

  /**
   * Returns a newly created catch clause. The [onKeyword] and
   * [exceptionType] can be `null` if the clause will catch all exceptions. The
   * [comma] and [stackTraceParameter] can be `null` if the stack trace
   * parameter is not defined.
   */
  CatchClause catchClause(
      Token onKeyword,
      TypeAnnotation exceptionType,
      Token catchKeyword,
      Token leftParenthesis,
      SimpleIdentifier exceptionParameter,
      Token comma,
      SimpleIdentifier stackTraceParameter,
      Token rightParenthesis,
      Block body);

  /**
   * Returns a newly created class declaration. Either or both of the
   * [comment] and [metadata] can be `null` if the class does not have the
   * corresponding attribute. The [abstractKeyword] can be `null` if the class
   * is not abstract. The [typeParameters] can be `null` if the class does not
   * have any type parameters. Any or all of the [extendsClause], [withClause],
   * and [implementsClause] can be `null` if the class does not have the
   * corresponding clause. The list of [members] can be `null` if the class does
   * not have any members.
   */
  ClassDeclaration classDeclaration(
      Comment comment,
      List<Annotation> metadata,
      Token abstractKeyword,
      Token classKeyword,
      SimpleIdentifier name,
      TypeParameterList typeParameters,
      ExtendsClause extendsClause,
      WithClause withClause,
      ImplementsClause implementsClause,
      Token leftBracket,
      List<ClassMember> members,
      Token rightBracket);

  /**
   * Returns a newly created class type alias. Either or both of the
   * [comment] and [metadata] can be `null` if the class type alias does not
   * have the corresponding attribute. The [typeParameters] can be `null` if the
   * class does not have any type parameters. The [abstractKeyword] can be
   * `null` if the class is not abstract. The [implementsClause] can be `null`
   * if the class does not implement any interfaces.
   */
  ClassTypeAlias classTypeAlias(
      Comment comment,
      List<Annotation> metadata,
      Token keyword,
      SimpleIdentifier name,
      TypeParameterList typeParameters,
      Token equals,
      Token abstractKeyword,
      TypeName superclass,
      WithClause withClause,
      ImplementsClause implementsClause,
      Token semicolon);

  /**
   * Returns a newly created reference to a Dart element. The [newKeyword]
   * can be `null` if the reference is not to a constructor.
   */
  CommentReference commentReference(Token newKeyword, Identifier identifier);

  /**
   * Returns a newly created compilation unit to have the given directives
   * and declarations. The [scriptTag] can be `null` if there is no script tag
   * in the compilation unit. The list of [directives] can be `null` if there
   * are no directives in the compilation unit. The list of [declarations] can
   * be `null` if there are no declarations in the compilation unit.
   */
  CompilationUnit compilationUnit(
      Token beginToken,
      ScriptTag scriptTag,
      List<Directive> directives,
      List<CompilationUnitMember> declarations,
      Token endToken);

  /**
   * Returns a newly created conditional expression.
   */
  ConditionalExpression conditionalExpression(
      Expression condition,
      Token question,
      Expression thenExpression,
      Token colon,
      Expression elseExpression);

  /**
   * Returns a newly created configuration.
   */
  Configuration configuration(
      Token ifKeyword,
      Token leftParenthesis,
      DottedName name,
      Token equalToken,
      StringLiteral value,
      Token rightParenthesis,
      StringLiteral libraryUri);

  /**
   * Returns a newly created constructor declaration. The [externalKeyword]
   * can be `null` if the constructor is not external. Either or both of the
   * [comment] and [metadata] can be `null` if the constructor does not have the
   * corresponding attribute. The [constKeyword] can be `null` if the
   * constructor cannot be used to create a constant. The [factoryKeyword] can
   * be `null` if the constructor is not a factory. The [period] and [name] can
   * both be `null` if the constructor is not a named constructor. The
   * [separator] can be `null` if the constructor does not have any initializers
   * and does not redirect to a different constructor. The list of
   * [initializers] can be `null` if the constructor does not have any
   * initializers. The [redirectedConstructor] can be `null` if the constructor
   * does not redirect to a different constructor. The [body] can be `null` if
   * the constructor does not have a body.
   */
  ConstructorDeclaration constructorDeclaration(
      Comment comment,
      List<Annotation> metadata,
      Token externalKeyword,
      Token constKeyword,
      Token factoryKeyword,
      Identifier returnType,
      Token period,
      SimpleIdentifier name,
      FormalParameterList parameters,
      Token separator,
      List<ConstructorInitializer> initializers,
      ConstructorName redirectedConstructor,
      FunctionBody body);

  /**
   * Returns a newly created field initializer to initialize the field with
   * the given name to the value of the given expression. The [thisKeyword] and
   * [period] can be `null` if the 'this' keyword was not specified.
   */
  ConstructorFieldInitializer constructorFieldInitializer(
      Token thisKeyword,
      Token period,
      SimpleIdentifier fieldName,
      Token equals,
      Expression expression);

  /**
   * Returns a newly created constructor name. The [period] and [name] can be
   * `null` if the constructor being named is the unnamed constructor.
   */
  ConstructorName constructorName(
      TypeName type, Token period, SimpleIdentifier name);

  /**
   * Returns a newly created continue statement. The [label] can be `null` if
   * there is no label associated with the statement.
   */
  ContinueStatement continueStatement(
      Token continueKeyword, SimpleIdentifier label, Token semicolon);

  /**
   * Returns a newly created formal parameter. Either or both of the
   * [comment] and [metadata] can be `null` if the declaration does not have the
   * corresponding attribute. The [keyword] can be `null` if a type name is
   * given. The [type] must be `null` if the keyword is 'var'.
   */
  DeclaredIdentifier declaredIdentifier(
      Comment comment,
      List<Annotation> metadata,
      Token keyword,
      TypeAnnotation type,
      SimpleIdentifier identifier);

  /**
   * Returns a newly created default formal parameter. The [separator] and
   * [defaultValue] can be `null` if there is no default value.
   */
  DefaultFormalParameter defaultFormalParameter(NormalFormalParameter parameter,
      ParameterKind kind, Token separator, Expression defaultValue);

  /**
   * Returns a documentation comment consisting of the given [tokens] and having
   * the given [references] (if supplied) embedded within it.
   */
  Comment documentationComment(List<Token> tokens,
      [List<CommentReference> references]);

  /**
   * Returns a newly created do loop.
   */
  DoStatement doStatement(
      Token doKeyword,
      Statement body,
      Token whileKeyword,
      Token leftParenthesis,
      Expression condition,
      Token rightParenthesis,
      Token semicolon);

  /**
   * Returns a newly created dotted name.
   */
  DottedName dottedName(List<SimpleIdentifier> components);

  /**
   * Returns a newly created floating point literal.
   */
  DoubleLiteral doubleLiteral(Token literal, double value);

  /**
   * Returns a newly created function body.
   */
  EmptyFunctionBody emptyFunctionBody(Token semicolon);

  /**
   * Returns a newly created empty statement.
   */
  EmptyStatement emptyStatement(Token semicolon);

  /**
   * Returns an end-of-line comment consisting of the given [tokens].
   */
  Comment endOfLineComment(List<Token> tokens);

  /**
   * Returns a newly created enum constant declaration. Either or both of the
   * [comment] and [metadata] can be `null` if the constant does not have the
   * corresponding attribute. (Technically, enum constants cannot have metadata,
   * but we allow it for consistency.)
   */
  EnumConstantDeclaration enumConstantDeclaration(
      Comment comment, List<Annotation> metadata, SimpleIdentifier name);

  /**
   * Returns a newly created enumeration declaration. Either or both of the
   * [comment] and [metadata] can be `null` if the declaration does not have the
   * corresponding attribute. The list of [constants] must contain at least one
   * value.
   */
  EnumDeclaration enumDeclaration(
      Comment comment,
      List<Annotation> metadata,
      Token enumKeyword,
      SimpleIdentifier name,
      Token leftBracket,
      List<EnumConstantDeclaration> constants,
      Token rightBracket);

  /**
   * Returns a newly created export directive. Either or both of the
   * [comment] and [metadata] can be `null` if the directive does not have the
   * corresponding attribute. The list of [combinators] can be `null` if there
   * are no combinators.
   */
  ExportDirective exportDirective(
      Comment comment,
      List<Annotation> metadata,
      Token keyword,
      StringLiteral libraryUri,
      List<Configuration> configurations,
      List<Combinator> combinators,
      Token semicolon);
  /**
   * Returns a newly created function body consisting of a block of
   * statements. The [keyword] can be `null` if the function body is not an
   * async function body.
   */
  ExpressionFunctionBody expressionFunctionBody(Token keyword,
      Token functionDefinition, Expression expression, Token semicolon);

  /**
   * Returns a newly created expression statement.
   */
  ExpressionStatement expressionStatement(
      Expression expression, Token semicolon);

  /**
   * Returns a newly created extends clause.
   */
  ExtendsClause extendsClause(Token extendsKeyword, TypeName superclass);

  /**
   * Returns a newly created field declaration. Either or both of the
   * [comment] and [metadata] can be `null` if the declaration does not have the
   * corresponding attribute. The [staticKeyword] can be `null` if the field is
   * not a static field.
   *
   * Use [fieldDeclaration2] instead.
   */
  @deprecated
  FieldDeclaration fieldDeclaration(Comment comment, List<Annotation> metadata,
      Token staticKeyword, VariableDeclarationList fieldList, Token semicolon);

  /**
   * Returns a newly created field declaration. Either or both of the
   * [comment] and [metadata] can be `null` if the declaration does not have the
   * corresponding attribute. The [staticKeyword] can be `null` if the field is
   * not a static field.
   */
  FieldDeclaration fieldDeclaration2(
      {Comment comment,
      List<Annotation> metadata,
      Token covariantKeyword,
      Token staticKeyword,
      @required VariableDeclarationList fieldList,
      @required Token semicolon});

  /**
   * Returns a newly created formal parameter. Either or both of the
   * [comment] and [metadata] can be `null` if the parameter does not have the
   * corresponding attribute. The [keyword] can be `null` if there is a type.
   * The [type] must be `null` if the keyword is 'var'. The [thisKeyword] and
   * [period] can be `null` if the keyword 'this' was not provided.  The
   * [parameters] can be `null` if this is not a function-typed field formal
   * parameter.
   *
   * Use [fieldFormalParameter2] instead.
   */
  @deprecated
  FieldFormalParameter fieldFormalParameter(
      Comment comment,
      List<Annotation> metadata,
      Token keyword,
      TypeAnnotation type,
      Token thisKeyword,
      Token period,
      SimpleIdentifier identifier,
      TypeParameterList typeParameters,
      FormalParameterList parameters);

  /**
   * Returns a newly created formal parameter. Either or both of the
   * [comment] and [metadata] can be `null` if the parameter does not have the
   * corresponding attribute. The [keyword] can be `null` if there is a type.
   * The [type] must be `null` if the keyword is 'var'. The [thisKeyword] and
   * [period] can be `null` if the keyword 'this' was not provided.  The
   * [parameters] can be `null` if this is not a function-typed field formal
   * parameter.
   */
  FieldFormalParameter fieldFormalParameter2(
      {Comment comment,
      List<Annotation> metadata,
      Token covariantKeyword,
      Token keyword,
      TypeAnnotation type,
      @required Token thisKeyword,
      @required Token period,
      @required SimpleIdentifier identifier,
      TypeParameterList typeParameters,
      FormalParameterList parameters});

  /**
   * Returns a newly created for-each statement whose loop control variable
   * is declared internally (in the for-loop part). The [awaitKeyword] can be
   * `null` if this is not an asynchronous for loop.
   */
  ForEachStatement forEachStatementWithDeclaration(
      Token awaitKeyword,
      Token forKeyword,
      Token leftParenthesis,
      DeclaredIdentifier loopVariable,
      Token inKeyword,
      Expression iterator,
      Token rightParenthesis,
      Statement body);

  /**
   * Returns a newly created for-each statement whose loop control variable
   * is declared outside the for loop. The [awaitKeyword] can be `null` if this
   * is not an asynchronous for loop.
   */
  ForEachStatement forEachStatementWithReference(
      Token awaitKeyword,
      Token forKeyword,
      Token leftParenthesis,
      SimpleIdentifier identifier,
      Token inKeyword,
      Expression iterator,
      Token rightParenthesis,
      Statement body);

  /**
   * Returns a newly created parameter list. The list of [parameters] can be
   * `null` if there are no parameters. The [leftDelimiter] and [rightDelimiter]
   * can be `null` if there are no optional parameters.
   */
  FormalParameterList formalParameterList(
      Token leftParenthesis,
      List<FormalParameter> parameters,
      Token leftDelimiter,
      Token rightDelimiter,
      Token rightParenthesis);

  /**
   * Returns a newly created for statement. Either the [variableList] or the
   * [initialization] must be `null`. Either the [condition] and the list of
   * [updaters] can be `null` if the loop does not have the corresponding
   * attribute.
   */
  ForStatement forStatement(
      Token forKeyword,
      Token leftParenthesis,
      VariableDeclarationList variableList,
      Expression initialization,
      Token leftSeparator,
      Expression condition,
      Token rightSeparator,
      List<Expression> updaters,
      Token rightParenthesis,
      Statement body);

  /**
   * Returns a newly created function declaration. Either or both of the
   * [comment] and [metadata] can be `null` if the function does not have the
   * corresponding attribute. The [externalKeyword] can be `null` if the
   * function is not an external function. The [returnType] can be `null` if no
   * return type was specified. The [propertyKeyword] can be `null` if the
   * function is neither a getter or a setter.
   */
  FunctionDeclaration functionDeclaration(
      Comment comment,
      List<Annotation> metadata,
      Token externalKeyword,
      TypeAnnotation returnType,
      Token propertyKeyword,
      SimpleIdentifier name,
      FunctionExpression functionExpression);

  /**
   * Returns a newly created function declaration statement.
   */
  FunctionDeclarationStatement functionDeclarationStatement(
      FunctionDeclaration functionDeclaration);

  /**
   * Returns a newly created function declaration.
   */
  FunctionExpression functionExpression(TypeParameterList typeParameters,
      FormalParameterList parameters, FunctionBody body);

  /**
   * Returns a newly created function expression invocation.
   */
  FunctionExpressionInvocation functionExpressionInvocation(Expression function,
      TypeArgumentList typeArguments, ArgumentList argumentList);

  /**
   * Returns a newly created function type alias. Either or both of the
   * [comment] and [metadata] can be `null` if the function does not have the
   * corresponding attribute. The [returnType] can be `null` if no return type
   * was specified. The [typeParameters] can be `null` if the function has no
   * type parameters.
   */
  FunctionTypeAlias functionTypeAlias(
      Comment comment,
      List<Annotation> metadata,
      Token keyword,
      TypeAnnotation returnType,
      SimpleIdentifier name,
      TypeParameterList typeParameters,
      FormalParameterList parameters,
      Token semicolon);

  /**
   * Returns a newly created formal parameter. Either or both of the
   * [comment] and [metadata] can be `null` if the parameter does not have the
   * corresponding attribute. The [returnType] can be `null` if no return type
   * was specified.
   *
   * Use [functionTypedFormalParameter2] instead.
   */
  @deprecated
  FunctionTypedFormalParameter functionTypedFormalParameter(
      Comment comment,
      List<Annotation> metadata,
      TypeAnnotation returnType,
      SimpleIdentifier identifier,
      TypeParameterList typeParameters,
      FormalParameterList parameters,
      {Token question: null});

  /**
   * Returns a newly created formal parameter. Either or both of the
   * [comment] and [metadata] can be `null` if the parameter does not have the
   * corresponding attribute. The [returnType] can be `null` if no return type
   * was specified.
   */
  FunctionTypedFormalParameter functionTypedFormalParameter2(
      {Comment comment,
      List<Annotation> metadata,
      Token covariantKeyword,
      TypeAnnotation returnType,
      @required SimpleIdentifier identifier,
      TypeParameterList typeParameters,
      @required FormalParameterList parameters,
      Token question});

  /**
   * Initialize a newly created generic function type.
   */
  GenericFunctionType genericFunctionType(
      TypeAnnotation returnType,
      Token functionKeyword,
      TypeParameterList typeParameters,
      FormalParameterList parameters);

  /**
   * Returns a newly created generic type alias. Either or both of the
   * [comment] and [metadata] can be `null` if the variable list does not have
   * the corresponding attribute. The [typeParameters] can be `null` if there
   * are no type parameters.
   */
  GenericTypeAlias genericTypeAlias(
      Comment comment,
      List<Annotation> metadata,
      Token typedefKeyword,
      SimpleIdentifier name,
      TypeParameterList typeParameters,
      Token equals,
      GenericFunctionType functionType,
      Token semicolon);

  /**
   * Returns a newly created import show combinator.
   */
  HideCombinator hideCombinator(
      Token keyword, List<SimpleIdentifier> hiddenNames);

  /**
   * Returns a newly created if statement. The [elseKeyword] and
   * [elseStatement] can be `null` if there is no else clause.
   */
  IfStatement ifStatement(
      Token ifKeyword,
      Token leftParenthesis,
      Expression condition,
      Token rightParenthesis,
      Statement thenStatement,
      Token elseKeyword,
      Statement elseStatement);

  /**
   * Returns a newly created implements clause.
   */
  ImplementsClause implementsClause(
      Token implementsKeyword, List<TypeName> interfaces);

  /**
   * Returns a newly created import directive. Either or both of the
   * [comment] and [metadata] can be `null` if the function does not have the
   * corresponding attribute. The [deferredKeyword] can be `null` if the import
   * is not deferred. The [asKeyword] and [prefix] can be `null` if the import
   * does not specify a prefix. The list of [combinators] can be `null` if there
   * are no combinators.
   */
  ImportDirective importDirective(
      Comment comment,
      List<Annotation> metadata,
      Token keyword,
      StringLiteral libraryUri,
      List<Configuration> configurations,
      Token deferredKeyword,
      Token asKeyword,
      SimpleIdentifier prefix,
      List<Combinator> combinators,
      Token semicolon);

  /**
   * Returns a newly created index expression.
   */
  IndexExpression indexExpressionForCascade(
      Token period, Token leftBracket, Expression index, Token rightBracket);

  /**
   * Returns a newly created index expression.
   */
  IndexExpression indexExpressionForTarget(Expression target, Token leftBracket,
      Expression index, Token rightBracket);

  /**
   * Returns a newly created instance creation expression.
   */
  InstanceCreationExpression instanceCreationExpression(Token keyword,
      ConstructorName constructorName, ArgumentList argumentList);

  /**
   * Returns a newly created integer literal.
   */
  IntegerLiteral integerLiteral(Token literal, int value);

  /**
   * Returns a newly created interpolation expression.
   */
  InterpolationExpression interpolationExpression(
      Token leftBracket, Expression expression, Token rightBracket);

  /**
   * Returns a newly created string of characters that are part of a string
   * interpolation.
   */
  InterpolationString interpolationString(Token contents, String value);

  /**
   * Returns a newly created is expression. The [notOperator] can be `null`
   * if the sense of the test is not negated.
   */
  IsExpression isExpression(Expression expression, Token isOperator,
      Token notOperator, TypeAnnotation type);

  /**
   * Returns a newly created label.
   */
  Label label(SimpleIdentifier label, Token colon);

  /**
   * Returns a newly created labeled statement.
   */
  LabeledStatement labeledStatement(List<Label> labels, Statement statement);

  /**
   * Returns a newly created library directive. Either or both of the
   * [comment] and [metadata] can be `null` if the directive does not have the
   * corresponding attribute.
   */
  LibraryDirective libraryDirective(Comment comment, List<Annotation> metadata,
      Token libraryKeyword, LibraryIdentifier name, Token semicolon);

  /**
   * Returns a newly created prefixed identifier.
   */
  LibraryIdentifier libraryIdentifier(List<SimpleIdentifier> components);

  /**
   * Returns a newly created list literal. The [constKeyword] can be `null`
   * if the literal is not a constant. The [typeArguments] can be `null` if no
   * type arguments were declared. The list of [elements] can be `null` if the
   * list is empty.
   */
  ListLiteral listLiteral(Token constKeyword, TypeArgumentList typeArguments,
      Token leftBracket, List<Expression> elements, Token rightBracket);

  /**
   * Returns a newly created map literal. The [constKeyword] can be `null` if
   * the literal is not a constant. The [typeArguments] can be `null` if no type
   * arguments were declared. The [entries] can be `null` if the map is empty.
   */
  MapLiteral mapLiteral(Token constKeyword, TypeArgumentList typeArguments,
      Token leftBracket, List<MapLiteralEntry> entries, Token rightBracket);

  /**
   * Returns a newly created map literal entry.
   */
  MapLiteralEntry mapLiteralEntry(
      Expression key, Token separator, Expression value);

  /**
   * Returns a newly created method declaration. Either or both of the
   * [comment] and [metadata] can be `null` if the declaration does not have the
   * corresponding attribute. The [externalKeyword] can be `null` if the method
   * is not external. The [modifierKeyword] can be `null` if the method is
   * neither abstract nor static. The [returnType] can be `null` if no return
   * type was specified. The [propertyKeyword] can be `null` if the method is
   * neither a getter or a setter. The [operatorKeyword] can be `null` if the
   * method does not implement an operator. The [parameters] must be `null` if
   * this method declares a getter.
   */
  MethodDeclaration methodDeclaration(
      Comment comment,
      List<Annotation> metadata,
      Token externalKeyword,
      Token modifierKeyword,
      TypeAnnotation returnType,
      Token propertyKeyword,
      Token operatorKeyword,
      SimpleIdentifier name,
      TypeParameterList typeParameters,
      FormalParameterList parameters,
      FunctionBody body);

  /**
   * Returns a newly created method invocation. The [target] and [operator]
   * can be `null` if there is no target.
   */
  MethodInvocation methodInvocation(
      Expression target,
      Token operator,
      SimpleIdentifier methodName,
      TypeArgumentList typeArguments,
      ArgumentList argumentList);

  /**
   * Returns a newly created named expression..
   */
  NamedExpression namedExpression(Label name, Expression expression);

  /**
   * Returns a newly created native clause.
   */
  NativeClause nativeClause(Token nativeKeyword, StringLiteral name);

  /**
   * Returns a newly created function body consisting of the 'native' token,
   * a string literal, and a semicolon.
   */
  NativeFunctionBody nativeFunctionBody(
      Token nativeKeyword, StringLiteral stringLiteral, Token semicolon);

  /**
   * Returns a newly created list of nodes such that all of the nodes that
   * are added to the list will have their parent set to the given [owner]. The
   * list will initially be populated with the given [elements].
   */
  NodeList/*<E>*/ nodeList/*<E extends AstNode>*/(AstNode owner,
      [List/*<E>*/ elements]);

  /**
   * Returns a newly created null literal.
   */
  NullLiteral nullLiteral(Token literal);

  /**
   * Returns a newly created parenthesized expression.
   */
  ParenthesizedExpression parenthesizedExpression(
      Token leftParenthesis, Expression expression, Token rightParenthesis);

  /**
   * Returns a newly created part directive. Either or both of the [comment]
   * and [metadata] can be `null` if the directive does not have the
   * corresponding attribute.
   */
  PartDirective partDirective(Comment comment, List<Annotation> metadata,
      Token partKeyword, StringLiteral partUri, Token semicolon);

  /**
   * Returns a newly created part-of directive. Either or both of the
   * [comment] and [metadata] can be `null` if the directive does not have the
   * corresponding attribute.
   */
  PartOfDirective partOfDirective(
      Comment comment,
      List<Annotation> metadata,
      Token partKeyword,
      Token ofKeyword,
      StringLiteral uri,
      LibraryIdentifier libraryName,
      Token semicolon);

  /**
   * Returns a newly created postfix expression.
   */
  PostfixExpression postfixExpression(Expression operand, Token operator);

  /**
   * Returns a newly created prefixed identifier.
   */
  PrefixedIdentifier prefixedIdentifier(
      SimpleIdentifier prefix, Token period, SimpleIdentifier identifier);

  /**
   * Returns a newly created prefix expression.
   */
  PrefixExpression prefixExpression(Token operator, Expression operand);

  /**
   * Returns a newly created property access expression.
   */
  PropertyAccess propertyAccess(
      Expression target, Token operator, SimpleIdentifier propertyName);

  /**
   * Returns a newly created redirecting invocation to invoke the constructor
   * with the given name with the given arguments. The [constructorName] can be
   * `null` if the constructor being invoked is the unnamed constructor.
   */
  RedirectingConstructorInvocation redirectingConstructorInvocation(
      Token thisKeyword,
      Token period,
      SimpleIdentifier constructorName,
      ArgumentList argumentList);

  /**
   * Returns a newly created rethrow expression.
   */
  RethrowExpression rethrowExpression(Token rethrowKeyword);

  /**
   * Returns a newly created return statement. The [expression] can be `null`
   * if no explicit value was provided.
   */
  ReturnStatement returnStatement(
      Token returnKeyword, Expression expression, Token semicolon);

  /**
   * Returns a newly created script tag.
   */
  ScriptTag scriptTag(Token scriptTag);

  /**
   * Returns a newly created import show combinator.
   */
  ShowCombinator showCombinator(
      Token keyword, List<SimpleIdentifier> shownNames);

  /**
   * Returns a newly created formal parameter. Either or both of the
   * [comment] and [metadata] can be `null` if the parameter does not have the
   * corresponding attribute. The [keyword] can be `null` if a type was
   * specified. The [type] must be `null` if the keyword is 'var'.
   *
   * Use [simpleFormalParameter2] instead.
   */
  @deprecated
  SimpleFormalParameter simpleFormalParameter(
      Comment comment,
      List<Annotation> metadata,
      Token keyword,
      TypeAnnotation type,
      SimpleIdentifier identifier);

  /**
   * Returns a newly created formal parameter. Either or both of the
   * [comment] and [metadata] can be `null` if the parameter does not have the
   * corresponding attribute. The [keyword] can be `null` if a type was
   * specified. The [type] must be `null` if the keyword is 'var'.
   */
  SimpleFormalParameter simpleFormalParameter2(
      {Comment comment,
      List<Annotation> metadata,
      Token covariantKeyword,
      Token keyword,
      TypeAnnotation type,
      @required SimpleIdentifier identifier});

  /**
   * Returns a newly created identifier.
   */
  SimpleIdentifier simpleIdentifier(Token token, {bool isDeclaration: false});

  /**
   * Returns a newly created simple string literal.
   */
  SimpleStringLiteral simpleStringLiteral(Token literal, String value);

  /**
   * Returns a newly created string interpolation expression.
   */
  StringInterpolation stringInterpolation(List<InterpolationElement> elements);

  /**
   * Returns a newly created super invocation to invoke the inherited
   * constructor with the given name with the given arguments. The [period] and
   * [constructorName] can be `null` if the constructor being invoked is the
   * unnamed constructor.
   */
  SuperConstructorInvocation superConstructorInvocation(
      Token superKeyword,
      Token period,
      SimpleIdentifier constructorName,
      ArgumentList argumentList);

  /**
   * Returns a newly created super expression.
   */
  SuperExpression superExpression(Token superKeyword);

  /**
   * Returns a newly created switch case. The list of [labels] can be `null`
   * if there are no labels.
   */
  SwitchCase switchCase(List<Label> labels, Token keyword,
      Expression expression, Token colon, List<Statement> statements);

  /**
   * Returns a newly created switch default. The list of [labels] can be
   * `null` if there are no labels.
   */
  SwitchDefault switchDefault(List<Label> labels, Token keyword, Token colon,
      List<Statement> statements);

  /**
   * Returns a newly created switch statement. The list of [members] can be
   * `null` if there are no switch members.
   */
  SwitchStatement switchStatement(
      Token switchKeyword,
      Token leftParenthesis,
      Expression expression,
      Token rightParenthesis,
      Token leftBracket,
      List<SwitchMember> members,
      Token rightBracket);

  /**
   * Returns a newly created symbol literal.
   */
  SymbolLiteral symbolLiteral(Token poundSign, List<Token> components);

  /**
   * Returns a newly created this expression.
   */
  ThisExpression thisExpression(Token thisKeyword);

  /**
   * Returns a newly created throw expression.
   */
  ThrowExpression throwExpression(Token throwKeyword, Expression expression);

  /**
   * Returns a newly created top-level variable declaration. Either or both
   * of the [comment] and [metadata] can be `null` if the variable does not have
   * the corresponding attribute.
   */
  TopLevelVariableDeclaration topLevelVariableDeclaration(
      Comment comment,
      List<Annotation> metadata,
      VariableDeclarationList variableList,
      Token semicolon);

  /**
   * Returns a newly created try statement. The list of [catchClauses] can be
   * `null` if there are no catch clauses. The [finallyKeyword] and
   * [finallyBlock] can be `null` if there is no finally clause.
   */
  TryStatement tryStatement(Token tryKeyword, Block body,
      List<CatchClause> catchClauses, Token finallyKeyword, Block finallyBlock);

  /**
   * Returns a newly created list of type arguments.
   */
  TypeArgumentList typeArgumentList(
      Token leftBracket, List<TypeAnnotation> arguments, Token rightBracket);

  /**
   * Returns a newly created type name. The [typeArguments] can be `null` if
   * there are no type arguments.
   */
  TypeName typeName(Identifier name, TypeArgumentList typeArguments,
      {Token question: null});

  /**
   * Returns a newly created type parameter. Either or both of the [comment]
   * and [metadata] can be `null` if the parameter does not have the
   * corresponding attribute. The [extendsKeyword] and [bound] can be `null` if
   * the parameter does not have an upper bound.
   */
  TypeParameter typeParameter(Comment comment, List<Annotation> metadata,
      SimpleIdentifier name, Token extendsKeyword, TypeAnnotation bound);

  /**
   * Returns a newly created list of type parameters.
   */
  TypeParameterList typeParameterList(Token leftBracket,
      List<TypeParameter> typeParameters, Token rightBracket);

  /**
   * Returns a newly created variable declaration. The [equals] and
   * [initializer] can be `null` if there is no initializer.
   */
  VariableDeclaration variableDeclaration(
      SimpleIdentifier name, Token equals, Expression initializer);

  /**
   * Returns a newly created variable declaration list. Either or both of the
   * [comment] and [metadata] can be `null` if the variable list does not have
   * the corresponding attribute. The [keyword] can be `null` if a type was
   * specified. The [type] must be `null` if the keyword is 'var'.
   */
  VariableDeclarationList variableDeclarationList(
      Comment comment,
      List<Annotation> metadata,
      Token keyword,
      TypeAnnotation type,
      List<VariableDeclaration> variables);

  /**
   * Returns a newly created variable declaration statement.
   */
  VariableDeclarationStatement variableDeclarationStatement(
      VariableDeclarationList variableList, Token semicolon);

  /**
   * Returns a newly created while statement.
   */
  WhileStatement whileStatement(Token whileKeyword, Token leftParenthesis,
      Expression condition, Token rightParenthesis, Statement body);

  /**
   * Returns a newly created with clause.
   */
  WithClause withClause(Token withKeyword, List<TypeName> mixinTypes);

  /**
   * Returns a newly created yield expression. The [star] can be `null` if no
   * star was provided.
   */
  YieldStatement yieldStatement(
      Token yieldKeyword, Token star, Expression expression, Token semicolon);
}
