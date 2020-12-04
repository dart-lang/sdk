// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// CHANGES:
//
// v0.4 Added support for 'unified collections' (spreads and control flow
// in collection literals).
//
// v0.3 Updated to use ANTLR v4 rather than antlr3.
//
// v0.2 Changed top level variable declarations to avoid redundant and
// misleading occurrence of (FINAL|CONST).
//
// v0.1 First version available in the SDK github repository. Covers the
// Dart language as specified in the language specification based on the
// many grammar rule snippets. That grammar was then adjusted to remove
// known issues (e.g., misplaced metadata) and to resolve ambiguities.

grammar Dart;

@parser::header{
import java.util.Stack;
}

@lexer::header{
import java.util.Stack;
}

@parser::members {
  static String filePath = null;
  static boolean errorHasOccurred = false;

  /// Must be invoked before the first error is reported for a library.
  /// Will print the name of the library and indicate that it has errors.
  static void prepareForErrors() {
    errorHasOccurred = true;
    System.err.println("Syntax error in " + filePath + ":");
  }

  /// Parse library, return true if success, false if errors occurred.
  public boolean parseLibrary(String filePath) throws RecognitionException {
    this.filePath = filePath;
    errorHasOccurred = false;
    libraryDefinition();
    return !errorHasOccurred;
  }

  // Enable the parser to treat AWAIT/YIELD as keywords in the body of an
  // `async`, `async*`, or `sync*` function. Access via methods below.
  private Stack<Boolean> asyncEtcAreKeywords = new Stack<Boolean>();
  { asyncEtcAreKeywords.push(false); }

  // Use this to indicate that we are now entering an `async`, `async*`,
  // or `sync*` function.
  void startAsyncFunction() { asyncEtcAreKeywords.push(true); }

  // Use this to indicate that we are now entering a function which is
  // neither `async`, `async*`, nor `sync*`.
  void startNonAsyncFunction() { asyncEtcAreKeywords.push(false); }

  // Use this to indicate that we are now leaving any funciton.
  void endFunction() { asyncEtcAreKeywords.pop(); }

  // Whether we can recognize AWAIT/YIELD as an identifier/typeIdentifier.
  boolean asyncEtcPredicate(int tokenId) {
    if (tokenId == AWAIT || tokenId == YIELD) {
      return !asyncEtcAreKeywords.peek();
    }
    return false;
  }
}

@lexer::members{
  public static final int BRACE_NORMAL = 1;
  public static final int BRACE_SINGLE = 2;
  public static final int BRACE_DOUBLE = 3;
  public static final int BRACE_THREE_SINGLE = 4;
  public static final int BRACE_THREE_DOUBLE = 5;

  // Enable the parser to handle string interpolations via brace matching.
  // The top of the `braceLevels` stack describes the most recent unmatched
  // '{'. This is needed in order to enable/disable certain lexer rules.
  //
  //   NORMAL: Most recent unmatched '{' was not string literal related.
  //   SINGLE: Most recent unmatched '{' was `'...${`.
  //   DOUBLE: Most recent unmatched '{' was `"...${`.
  //   THREE_SINGLE: Most recent unmatched '{' was `'''...${`.
  //   THREE_DOUBLE: Most recent unmatched '{' was `"""...${`.
  //
  // Access via functions below.
  private Stack<Integer> braceLevels = new Stack<Integer>();

  // Whether we are currently in a string literal context, and which one.
  boolean currentBraceLevel(int braceLevel) {
    if (braceLevels.empty()) return false;
    return braceLevels.peek() == braceLevel;
  }

  // Use this to indicate that we are now entering a specific '{...}'.
  // Call it after accepting the '{'.
  void enterBrace() {
    braceLevels.push(BRACE_NORMAL);
  }
  void enterBraceSingleQuote() {
    braceLevels.push(BRACE_SINGLE);
  }
  void enterBraceDoubleQuote() {
    braceLevels.push(BRACE_DOUBLE);
  }
  void enterBraceThreeSingleQuotes() {
    braceLevels.push(BRACE_THREE_SINGLE);
  }
  void enterBraceThreeDoubleQuotes() {
    braceLevels.push(BRACE_THREE_DOUBLE);
  }

  // Use this to indicate that we are now exiting a specific '{...}',
  // no matter which kind. Call it before accepting the '}'.
  void exitBrace() {
      // We might raise a parse error here if the stack is empty, but the
      // parsing rules should ensure that we get a parse error anyway, and
      // it is not a big problem for the spec parser even if it misinterprets
      // the brace structure of some programs with syntax errors.
      if (!braceLevels.empty()) braceLevels.pop();
  }
}

// ---------------------------------------- Grammar rules.

libraryDefinition
    :    FEFF? SCRIPT_TAG?
         libraryName?
         importOrExport*
         partDirective*
         (metadata topLevelDefinition)*
         EOF
    ;

topLevelDefinition
    :    classDeclaration
    |    mixinDeclaration
    |    extensionDeclaration
    |    enumType
    |    typeAlias
    |    EXTERNAL functionSignature ';'
    |    EXTERNAL getterSignature ';'
    |    EXTERNAL setterSignature ';'
    |    EXTERNAL finalVarOrType identifierList ';'
    |    getterSignature functionBody
    |    setterSignature functionBody
    |    functionSignature functionBody
    |    (FINAL | CONST) type? staticFinalDeclarationList ';'
    |    LATE FINAL type? initializedIdentifierList ';'
    |    LATE? varOrType identifier ('=' expression)?
         (',' initializedIdentifier)* ';'
    ;

declaredIdentifier
    :    COVARIANT? finalConstVarOrType identifier
    ;

finalConstVarOrType
    :    LATE? FINAL type?
    |    CONST type?
    |    LATE? varOrType
    ;

finalVarOrType
    :    FINAL type?
    |    varOrType
    ;

varOrType
    :    VAR
    |    type
    ;

initializedIdentifier
    :    identifier ('=' expression)?
    ;

initializedIdentifierList
    :    initializedIdentifier (',' initializedIdentifier)*
    ;

functionSignature
    :    type? identifierNotFUNCTION formalParameterPart
    ;

functionBodyPrefix
    :    ASYNC? '=>'
    |    (ASYNC | ASYNC '*' | SYNC '*')? LBRACE
    ;

functionBody
    :    '=>' { startNonAsyncFunction(); } expression { endFunction(); } ';'
    |    { startNonAsyncFunction(); } block { endFunction(); }
    |    ASYNC '=>'
         { startAsyncFunction(); } expression { endFunction(); } ';'
    |    (ASYNC | ASYNC '*' | SYNC '*')
         { startAsyncFunction(); } block { endFunction(); }
    ;

block
    :    LBRACE statements RBRACE
    ;

formalParameterPart
    :    typeParameters? formalParameterList
    ;

formalParameterList
    :    '(' ')'
    |    '(' normalFormalParameters ','? ')'
    |    '(' normalFormalParameters ',' optionalOrNamedFormalParameters ')'
    |    '(' optionalOrNamedFormalParameters ')'
    ;

normalFormalParameters
    :    normalFormalParameter (',' normalFormalParameter)*
    ;

optionalOrNamedFormalParameters
    :    optionalPositionalFormalParameters
    |    namedFormalParameters
    ;

optionalPositionalFormalParameters
    :    '[' defaultFormalParameter (',' defaultFormalParameter)* ','? ']'
    ;

namedFormalParameters
    :    LBRACE defaultNamedParameter (',' defaultNamedParameter)* ','? RBRACE
    ;

normalFormalParameter
    :    metadata normalFormalParameterNoMetadata
    ;

normalFormalParameterNoMetadata
    :    functionFormalParameter
    |    fieldFormalParameter
    |    simpleFormalParameter
    ;

// NB: It is an anomaly that a functionFormalParameter cannot be FINAL.
functionFormalParameter
    :    COVARIANT? type? identifierNotFUNCTION formalParameterPart '?'?
    ;

simpleFormalParameter
    :    declaredIdentifier
    |    COVARIANT? identifier
    ;

// NB: It is an anomaly that VAR can be a return type (`var this.x()`).
fieldFormalParameter
    :    finalConstVarOrType? THIS '.' identifier (formalParameterPart '?'?)?
    ;

defaultFormalParameter
    :    normalFormalParameter ('=' expression)?
    ;

defaultNamedParameter
    :    REQUIRED? normalFormalParameter ((':' | '=') expression)?
    ;

typeWithParameters
    :    typeIdentifier typeParameters?
    ;

classDeclaration
    :    ABSTRACT? CLASS typeWithParameters superclass? mixins? interfaces?
         LBRACE (metadata classMemberDefinition)* RBRACE
    |    ABSTRACT? CLASS mixinApplicationClass
    ;

superclass
    :    EXTENDS typeNotVoidNotFunction
    ;

mixins
    :    WITH typeNotVoidNotFunctionList
    ;

interfaces
    :    IMPLEMENTS typeNotVoidNotFunctionList
    ;

classMemberDefinition
    :    methodSignature functionBody
    |    declaration ';'
    ;

mixinApplicationClass
    :    typeWithParameters '=' mixinApplication ';'
    ;

mixinDeclaration
    :    MIXIN typeIdentifier typeParameters?
         (ON typeNotVoidNotFunctionList)? interfaces?
         LBRACE (metadata mixinMemberDefinition)* RBRACE
    ;

// TODO: We will probably want to make this more strict.
mixinMemberDefinition
    :    classMemberDefinition
    ;

extensionDeclaration
    :    EXTENSION identifier? typeParameters? ON type
         LBRACE (metadata extensionMemberDefinition)* RBRACE
    ;

// TODO: We might want to make this more strict.
extensionMemberDefinition
    :    classMemberDefinition
    ;

methodSignature
    :    constructorSignature initializers
    |    factoryConstructorSignature
    |    STATIC? functionSignature
    |    STATIC? getterSignature
    |    STATIC? setterSignature
    |    operatorSignature
    |    constructorSignature
    ;

// https://github.com/dart-lang/sdk/issues/29501 reports on the problem which
// was solved by adding a case for redirectingFactoryConstructorSignature.
// TODO(eernst): Close that issue when this is integrated into the spec.

// https://github.com/dart-lang/sdk/issues/29502 reports on the problem that
// than external const factory constructor declaration cannot be derived by
// the spec grammar (and also not by this grammar). The following fixes were
// introduced for that: Added the 'factoryConstructorSignature' case below in
// 'declaration'; also added 'CONST?' in the 'factoryConstructorSignature'
// rule, such that const factories in general are allowed.
// TODO(eernst): Close that issue when this is integrated into the spec.

// TODO(eernst): Note that `EXTERNAL? STATIC? functionSignature` includes
// `STATIC functionSignature`, but a static function cannot be abstract.
// We might want to make that a syntax error rather than a static semantic
// check.

declaration
    :    EXTERNAL factoryConstructorSignature
    |    EXTERNAL constantConstructorSignature
    |    EXTERNAL constructorSignature
    |    (EXTERNAL STATIC?)? getterSignature
    |    (EXTERNAL STATIC?)? setterSignature
    |    (EXTERNAL STATIC?)? functionSignature
    |    EXTERNAL (STATIC? finalVarOrType | COVARIANT varOrType) identifierList
    |    ABSTRACT (finalVarOrType | COVARIANT varOrType) identifierList
    |    EXTERNAL? operatorSignature
    |    STATIC (FINAL | CONST) type? staticFinalDeclarationList
    |    STATIC LATE FINAL type? initializedIdentifierList
    |    (STATIC | COVARIANT) LATE? varOrType initializedIdentifierList
    |    LATE? (FINAL type? | varOrType) initializedIdentifierList
    |    redirectingFactoryConstructorSignature
    |    constantConstructorSignature (redirection | initializers)?
    |    constructorSignature (redirection | initializers)?
    ;

staticFinalDeclarationList
    :    staticFinalDeclaration (',' staticFinalDeclaration)*
    ;

staticFinalDeclaration
    :    identifier '=' expression
    ;

operatorSignature
    :    type? OPERATOR operator formalParameterList
    ;

operator
    :    '~'
    |    binaryOperator
    |    '[' ']'
    |    '[' ']' '='
    ;

binaryOperator
    :    multiplicativeOperator
    |    additiveOperator
    |    shiftOperator
    |    relationalOperator
    |    '=='
    |    bitwiseOperator
    ;

getterSignature
    :    type? GET identifier
    ;

setterSignature
    :    type? SET identifier formalParameterList
    ;

constructorSignature
    :    constructorName formalParameterList
    ;

constructorName
    :    typeIdentifier ('.' identifier)?
    ;

redirection
    :    ':' THIS ('.' identifier)? arguments
    ;

initializers
    :    ':' initializerListEntry (',' initializerListEntry)*
    ;

initializerListEntry
    :    SUPER arguments
    |    SUPER '.' identifier arguments
    |    fieldInitializer
    |    assertion
    ;

fieldInitializer
    :    (THIS '.')? identifier '=' initializerExpression
    ;

initializerExpression
    :    conditionalExpression
    |    cascade
    ;

factoryConstructorSignature
    :    CONST? FACTORY constructorName formalParameterList
    ;

redirectingFactoryConstructorSignature
    :    CONST? FACTORY constructorName formalParameterList '='
         constructorDesignation
    ;

constantConstructorSignature
    :    CONST constructorName formalParameterList
    ;

mixinApplication
    :    typeNotVoidNotFunction mixins interfaces?
    ;

enumType
    :    ENUM typeIdentifier LBRACE enumEntry (',' enumEntry)* (',')? RBRACE
    ;

enumEntry
    :    metadata identifier
    ;

typeParameter
    :    metadata typeIdentifier (EXTENDS typeNotVoid)?
    ;

typeParameters
    :    '<' typeParameter (',' typeParameter)* '>'
    ;

metadata
    :    ('@' metadatum)*
    ;

metadatum
    :    constructorDesignation arguments
    |    identifier
    |    qualifiedName
    ;

expression
    :    functionExpression
    |    throwExpression
    |    assignableExpression assignmentOperator expression
    |    conditionalExpression
    |    cascade
    ;

expressionWithoutCascade
    :    functionExpressionWithoutCascade
    |    throwExpressionWithoutCascade
    |    assignableExpression assignmentOperator expressionWithoutCascade
    |    conditionalExpression
    ;

expressionList
    :    expression (',' expression)*
    ;

primary
    :    thisExpression
    |    SUPER unconditionalAssignableSelector
    |    constObjectExpression
    |    newExpression
    |    constructorInvocation
    |    functionPrimary
    |    '(' expression ')'
    |    literal
    |    identifier
    ;

constructorInvocation
    :    typeName typeArguments '.' identifier arguments
    ;

literal
    :    nullLiteral
    |    booleanLiteral
    |    numericLiteral
    |    stringLiteral
    |    symbolLiteral
    |    setOrMapLiteral
    |    listLiteral
    ;

nullLiteral
    :    NULL
    ;

numericLiteral
    :    NUMBER
    |    HEX_NUMBER
    ;

booleanLiteral
    :    TRUE
    |    FALSE
    ;

stringLiteral
    :    (multiLineString | singleLineString)+
    ;

// Not used in the specification (needed here for <uri>).
stringLiteralWithoutInterpolation
    :    singleLineStringWithoutInterpolation+
    ;

setOrMapLiteral
    : CONST? typeArguments? LBRACE elements? RBRACE
    ;

listLiteral
    : CONST? typeArguments? '[' elements? ']'
    ;

elements
    : element (',' element)* ','?
    ;

element
    : expressionElement
    | mapElement
    | spreadElement
    | ifElement
    | forElement
    ;

expressionElement
    : expression
    ;

mapElement
    : expression ':' expression
    ;

spreadElement
    : ('...' | '...?') expression
    ;

ifElement
    : IF '(' expression ')' element (ELSE element)?
    ;

forElement
    : AWAIT? FOR '(' forLoopParts ')' element
    ;

throwExpression
    :    THROW expression
    ;

throwExpressionWithoutCascade
    :    THROW expressionWithoutCascade
    ;

functionExpression
    :    formalParameterPart functionExpressionBody
    ;

functionExpressionBody
    :    '=>' { startNonAsyncFunction(); } expression { endFunction(); }
    |    ASYNC '=>' { startAsyncFunction(); } expression { endFunction(); }
    ;

functionExpressionBodyPrefix
    :    ASYNC? '=>'
    ;

functionExpressionWithoutCascade
    :    formalParameterPart functionExpressionWithoutCascadeBody
    ;

functionExpressionWithoutCascadeBody
    :    '=>' { startNonAsyncFunction(); }
         expressionWithoutCascade { endFunction(); }
    |    ASYNC '=>' { startAsyncFunction(); }
         expressionWithoutCascade { endFunction(); }
    ;

functionPrimary
    :    formalParameterPart functionPrimaryBody
    ;

functionPrimaryBody
    :    { startNonAsyncFunction(); } block { endFunction(); }
    |    (ASYNC | ASYNC '*' | SYNC '*')
         { startAsyncFunction(); } block { endFunction(); }
    ;

functionPrimaryBodyPrefix
    : (ASYNC | ASYNC '*' | SYNC '*')? LBRACE
    ;

thisExpression
    :    THIS
    ;

newExpression
    :    NEW constructorDesignation arguments
    ;

constObjectExpression
    :    CONST constructorDesignation arguments
    ;

arguments
    :    '(' (argumentList ','?)? ')'
    ;

argumentList
    :    namedArgument (',' namedArgument)*
    |    expressionList (',' namedArgument)*
    ;

namedArgument
    :    label expression
    ;

cascade
    :     cascade '..' cascadeSection
    |     conditionalExpression ('?..' | '..') cascadeSection
    ;

cascadeSection
    :    cascadeSelector cascadeSectionTail
    ;

cascadeSelector
    :    '[' expression ']'
    |    identifier
    ;

cascadeSectionTail
    :    cascadeAssignment
    |    selector* (assignableSelector cascadeAssignment)?
    ;

cascadeAssignment
    :    assignmentOperator expressionWithoutCascade
    ;

assignmentOperator
    :    '='
    |    compoundAssignmentOperator
    ;

compoundAssignmentOperator
    :    '*='
    |    '/='
    |    '~/='
    |    '%='
    |    '+='
    |    '-='
    |    '<<='
    |    '>' '>' '>' '='
    |    '>' '>' '='
    |    '&='
    |    '^='
    |    '|='
    |    '??='
    ;

conditionalExpression
    :    ifNullExpression
         ('?' expressionWithoutCascade ':' expressionWithoutCascade)?
    ;

ifNullExpression
    :    logicalOrExpression ('??' logicalOrExpression)*
    ;

logicalOrExpression
    :    logicalAndExpression ('||' logicalAndExpression)*
    ;

logicalAndExpression
    :    equalityExpression ('&&' equalityExpression)*
    ;

equalityExpression
    :    relationalExpression (equalityOperator relationalExpression)?
    |    SUPER equalityOperator relationalExpression
    ;

equalityOperator
    :    '=='
    |    '!='
    ;

relationalExpression
    :    bitwiseOrExpression
         (typeTest | typeCast | relationalOperator bitwiseOrExpression)?
    |    SUPER relationalOperator bitwiseOrExpression
    ;

relationalOperator
    :    '>' '='
    |    '>'
    |    '<='
    |    '<'
    ;

bitwiseOrExpression
    :    bitwiseXorExpression ('|' bitwiseXorExpression)*
    |    SUPER ('|' bitwiseXorExpression)+
    ;

bitwiseXorExpression
    :    bitwiseAndExpression ('^' bitwiseAndExpression)*
    |    SUPER ('^' bitwiseAndExpression)+
    ;

bitwiseAndExpression
    :    shiftExpression ('&' shiftExpression)*
    |    SUPER ('&' shiftExpression)+
    ;

bitwiseOperator
    :    '&'
    |    '^'
    |    '|'
    ;

shiftExpression
    :    additiveExpression (shiftOperator additiveExpression)*
    |    SUPER (shiftOperator additiveExpression)+
    ;

shiftOperator
    :    '<<'
    |    '>' '>' '>'
    |    '>' '>'
    ;

additiveExpression
    :    multiplicativeExpression (additiveOperator multiplicativeExpression)*
    |    SUPER (additiveOperator multiplicativeExpression)+
    ;

additiveOperator
    :    '+'
    |    '-'
    ;

multiplicativeExpression
    :    unaryExpression (multiplicativeOperator unaryExpression)*
    |    SUPER (multiplicativeOperator unaryExpression)+
    ;

multiplicativeOperator
    :    '*'
    |    '/'
    |    '%'
    |    '~/'
    ;

unaryExpression
    :    prefixOperator unaryExpression
    |    awaitExpression
    |    postfixExpression
    |    (minusOperator | tildeOperator) SUPER
    |    incrementOperator assignableExpression
    ;

prefixOperator
    :    minusOperator
    |    negationOperator
    |    tildeOperator
    ;

minusOperator
    :    '-'
    ;

negationOperator
    :    '!'
    ;

tildeOperator
    :    '~'
    ;

awaitExpression
    :    AWAIT unaryExpression
    ;

postfixExpression
    :    assignableExpression postfixOperator
    |    primary selector*
    ;

postfixOperator
    :    incrementOperator
    ;

selector
    :    '!'
    |    assignableSelector
    |    argumentPart
    ;

argumentPart
    :    typeArguments? arguments
    ;

incrementOperator
    :    '++'
    |    '--'
    ;

assignableExpression
    :    SUPER unconditionalAssignableSelector
    |    primary assignableSelectorPart
    |    identifier
    ;

assignableSelectorPart
    :    selector* assignableSelector
    ;

unconditionalAssignableSelector
    :    '[' expression ']'
    |    '.' identifier
    ;

assignableSelector
    :    unconditionalAssignableSelector
    |    '?.' identifier
    |    '?' '[' expression ']'
    ;

identifierNotFUNCTION
    :    IDENTIFIER
    |    ABSTRACT // Built-in identifier.
    |    AS // Built-in identifier.
    |    COVARIANT // Built-in identifier.
    |    DEFERRED // Built-in identifier.
    |    DYNAMIC // Built-in identifier.
    |    EXPORT // Built-in identifier.
    |    EXTERNAL // Built-in identifier.
    |    FACTORY // Built-in identifier.
    |    GET // Built-in identifier.
    |    IMPLEMENTS // Built-in identifier.
    |    IMPORT // Built-in identifier.
    |    INTERFACE // Built-in identifier.
    |    LATE // Built-in identifier.
    |    LIBRARY // Built-in identifier.
    |    MIXIN // Built-in identifier.
    |    OPERATOR // Built-in identifier.
    |    PART // Built-in identifier.
    |    REQUIRED // Built-in identifier.
    |    SET // Built-in identifier.
    |    STATIC // Built-in identifier.
    |    TYPEDEF // Built-in identifier.
    |    ASYNC // Not a built-in identifier.
    |    HIDE // Not a built-in identifier.
    |    OF // Not a built-in identifier.
    |    ON // Not a built-in identifier.
    |    SHOW // Not a built-in identifier.
    |    SYNC // Not a built-in identifier.
    |    { asyncEtcPredicate(getCurrentToken().getType()) }? (AWAIT|YIELD)
    ;

identifier
    :    identifierNotFUNCTION
    |    FUNCTION // Built-in identifier that can be used as a type.
    ;

qualifiedName
    :    typeIdentifier '.' identifier
    |    typeIdentifier '.' typeIdentifier '.' identifier
    ;

typeIdentifier
    :    IDENTIFIER
    |    DYNAMIC // Built-in identifier that can be used as a type.
    |    ASYNC // Not a built-in identifier.
    |    HIDE // Not a built-in identifier.
    |    OF // Not a built-in identifier.
    |    ON // Not a built-in identifier.
    |    SHOW // Not a built-in identifier.
    |    SYNC // Not a built-in identifier.
    |    { asyncEtcPredicate(getCurrentToken().getType()) }? (AWAIT|YIELD)
    ;

typeTest
    :    isOperator typeNotVoid
    ;

isOperator
    :    IS '!'?
    ;

typeCast
    :    asOperator typeNotVoid
    ;

asOperator
    :    AS
    ;

statements
    :    statement*
    ;

statement
    :    label* nonLabelledStatement
    ;

// Exception in the language specification: An expressionStatement cannot
// start with LBRACE. We force anything that starts with LBRACE to be a block,
// which will prevent an expressionStatement from starting with LBRACE, and
// which will not interfere with the recognition of any other case. If we
// add another statement which can start with LBRACE we must adjust this
// check.
nonLabelledStatement
    :    block
    |    localVariableDeclaration
    |    forStatement
    |    whileStatement
    |    doStatement
    |    switchStatement
    |    ifStatement
    |    rethrowStatement
    |    tryStatement
    |    breakStatement
    |    continueStatement
    |    returnStatement
    |    localFunctionDeclaration
    |    assertStatement
    |    yieldStatement
    |    yieldEachStatement
    |    expressionStatement
    ;

expressionStatement
    :    expression? ';'
    ;

localVariableDeclaration
    :    metadata initializedVariableDeclaration ';'
    ;

initializedVariableDeclaration
    :    declaredIdentifier ('=' expression)? (',' initializedIdentifier)*
    ;

localFunctionDeclaration
    :    metadata functionSignature functionBody
    ;

ifStatement
    :    IF '(' expression ')' statement (ELSE statement)?
    ;

forStatement
    :    AWAIT? FOR '(' forLoopParts ')' statement
    ;

forLoopParts
    :    metadata declaredIdentifier IN expression
    |    metadata identifier IN expression
    |    forInitializerStatement expression? ';' expressionList?
    ;

// The localVariableDeclaration cannot be CONST, but that can
// be enforced in a later phase, and the grammar allows it.
forInitializerStatement
    :    localVariableDeclaration
    |    expression? ';'
    ;

whileStatement
    :    WHILE '(' expression ')' statement
    ;

doStatement
    :    DO statement WHILE '(' expression ')' ';'
    ;

switchStatement
    :    SWITCH '(' expression ')' LBRACE switchCase* defaultCase? RBRACE
    ;

switchCase
    :    label* CASE expression ':' statements
    ;

defaultCase
    :    label* DEFAULT ':' statements
    ;

rethrowStatement
    :    RETHROW ';'
    ;

tryStatement
    :    TRY block (onParts finallyPart? | finallyPart)
    ;

onPart
    :    catchPart block
    |    ON typeNotVoid catchPart? block
    ;

onParts
    :    onPart onParts
    |    onPart
    ;

catchPart
    :    CATCH '(' identifier (',' identifier)? ')'
    ;

finallyPart
    :    FINALLY block
    ;

returnStatement
    :    RETURN expression? ';'
    ;

label
    :    identifier ':'
    ;

breakStatement
    :    BREAK identifier? ';'
    ;

continueStatement
    :    CONTINUE identifier? ';'
    ;

yieldStatement
    :    YIELD expression ';'
    ;

yieldEachStatement
    :    YIELD '*' expression ';'
    ;

assertStatement
    :    assertion ';'
    ;

assertion
    :    ASSERT '(' expression (',' expression)? ','? ')'
    ;

libraryName
    :    metadata LIBRARY dottedIdentifierList ';'
    ;

dottedIdentifierList
    :    identifier ('.' identifier)*
    ;

importOrExport
    :    libraryImport
    |    libraryExport
    ;

libraryImport
    :    metadata importSpecification
    ;

importSpecification
    :    IMPORT configurableUri (DEFERRED? AS identifier)? combinator* ';'
    ;

combinator
    :    SHOW identifierList
    |    HIDE identifierList
    ;

identifierList
    :    identifier (',' identifier)*
    ;

libraryExport
    :    metadata EXPORT uri combinator* ';'
    ;

partDirective
    :    metadata PART uri ';'
    ;

partHeader
    :    metadata PART OF identifier ('.' identifier)* ';'
    ;

partDeclaration
    :    partHeader topLevelDefinition* EOF
    ;

// In the specification a plain <stringLiteral> is used.
// TODO(eernst): Check whether it creates ambiguities to do that.
uri
    :    stringLiteralWithoutInterpolation
    ;

configurableUri
    :    uri configurationUri*
    ;

configurationUri
    :    IF '(' uriTest ')' uri
    ;

uriTest
    :    dottedIdentifierList ('==' stringLiteral)?
    ;

type
    :    functionType '?'?
    |    typeNotFunction
    ;

typeNotVoid
    :    functionType '?'?
    |    typeNotVoidNotFunction
    ;

typeNotFunction
    :    typeNotVoidNotFunction
    |    VOID
    ;

typeNotVoidNotFunction
    :    typeName typeArguments? '?'?
    |    FUNCTION '?'?
    ;

typeName
    :    typeIdentifier ('.' typeIdentifier)?
    ;

typeArguments
    :    '<' typeList '>'
    ;

typeList
    :    type (',' type)*
    ;

typeNotVoidNotFunctionList
    :    typeNotVoidNotFunction (',' typeNotVoidNotFunction)*
    ;

typeAlias
    :    TYPEDEF typeIdentifier typeParameters? '=' functionType ';'
    |    TYPEDEF functionTypeAlias
    ;

functionTypeAlias
    :    functionPrefix formalParameterPart ';'
    ;

functionPrefix
    :    type identifier
    |    identifier
    ;

functionTypeTail
    :    FUNCTION typeParameters? parameterTypeList
    ;

functionTypeTails
    :    functionTypeTail '?'? functionTypeTails
    |    functionTypeTail
    ;

functionType
    :    functionTypeTails
    |    typeNotFunction functionTypeTails
    ;

parameterTypeList
    :    '(' ')'
    |    '(' normalParameterTypes ',' optionalParameterTypes ')'
    |    '(' normalParameterTypes ','? ')'
    |    '(' optionalParameterTypes ')'
    ;

normalParameterTypes
    :    normalParameterType (',' normalParameterType)*
    ;

normalParameterType
    :    typedIdentifier
    |    type
    ;

optionalParameterTypes
    :    optionalPositionalParameterTypes
    |    namedParameterTypes
    ;

optionalPositionalParameterTypes
    :    '[' normalParameterTypes ','? ']'
    ;

namedParameterTypes
    :    LBRACE namedParameterType (',' namedParameterType)* ','? RBRACE
    ;

namedParameterType
    :    REQUIRED? typedIdentifier
    ;

typedIdentifier
    :    type identifier
    ;

constructorDesignation
    :    typeIdentifier
    |    qualifiedName
    |    typeName typeArguments ('.' identifier)?
    ;

symbolLiteral
    :    '#' (operator | (identifier ('.' identifier)*))
    ;

// Not used in the specification (needed here for <uri>).
singleLineStringWithoutInterpolation
    :    RAW_SINGLE_LINE_STRING
    |    SINGLE_LINE_STRING_DQ_BEGIN_END
    |    SINGLE_LINE_STRING_SQ_BEGIN_END
    ;

singleLineString
    :    RAW_SINGLE_LINE_STRING
    |    SINGLE_LINE_STRING_SQ_BEGIN_END
    |    SINGLE_LINE_STRING_SQ_BEGIN_MID expression
         (SINGLE_LINE_STRING_SQ_MID_MID expression)*
         SINGLE_LINE_STRING_SQ_MID_END
    |    SINGLE_LINE_STRING_DQ_BEGIN_END
    |    SINGLE_LINE_STRING_DQ_BEGIN_MID expression
         (SINGLE_LINE_STRING_DQ_MID_MID expression)*
         SINGLE_LINE_STRING_DQ_MID_END
    ;

multiLineString
    :    RAW_MULTI_LINE_STRING
    |    MULTI_LINE_STRING_SQ_BEGIN_END
    |    MULTI_LINE_STRING_SQ_BEGIN_MID expression
         (MULTI_LINE_STRING_SQ_MID_MID expression)*
         MULTI_LINE_STRING_SQ_MID_END
    |    MULTI_LINE_STRING_DQ_BEGIN_END
    |    MULTI_LINE_STRING_DQ_BEGIN_MID expression
         (MULTI_LINE_STRING_DQ_MID_MID expression)*
         MULTI_LINE_STRING_DQ_MID_END
    ;

// ---------------------------------------- Lexer rules.

fragment
LETTER
    :    'a' .. 'z'
    |    'A' .. 'Z'
    ;

fragment
DIGIT
    :    '0' .. '9'
    ;

fragment
EXPONENT
    :    ('e' | 'E') ('+' | '-')? DIGIT+
    ;

fragment
HEX_DIGIT
    :    ('a' | 'b' | 'c' | 'd' | 'e' | 'f')
    |    ('A' | 'B' | 'C' | 'D' | 'E' | 'F')
    |    DIGIT
    ;

// Reserved words.

ASSERT
    :    'assert'
    ;

BREAK
    :    'break'
    ;

CASE
    :    'case'
    ;

CATCH
    :    'catch'
    ;

CLASS
    :    'class'
    ;

CONST
    :    'const'
    ;

CONTINUE
    :    'continue'
    ;

DEFAULT
    :    'default'
    ;

DO
    :    'do'
    ;

ELSE
    :    'else'
    ;

ENUM
    :    'enum'
    ;

EXTENDS
    :    'extends'
    ;

FALSE
    :    'false'
    ;

FINAL
    :    'final'
    ;

FINALLY
    :    'finally'
    ;

FOR
    :    'for'
    ;

IF
    :    'if'
    ;

IN
    :    'in'
    ;

IS
    :    'is'
    ;

NEW
    :    'new'
    ;

NULL
    :    'null'
    ;

RETHROW
    :    'rethrow'
    ;

RETURN
    :    'return'
    ;

SUPER
    :    'super'
    ;

SWITCH
    :    'switch'
    ;

THIS
    :    'this'
    ;

THROW
    :    'throw'
    ;

TRUE
    :    'true'
    ;

TRY
    :    'try'
    ;

VAR
    :    'var'
    ;

VOID
    :    'void'
    ;

WHILE
    :    'while'
    ;

WITH
    :    'with'
    ;

// Built-in identifiers.

ABSTRACT
    :    'abstract'
    ;

AS
    :    'as'
    ;

COVARIANT
    :    'covariant'
    ;

DEFERRED
    :    'deferred'
    ;

DYNAMIC
    :    'dynamic'
    ;

EXPORT
    :    'export'
    ;

EXTENSION
    :    'extension'
    ;

EXTERNAL
    :    'external'
    ;

FACTORY
    :    'factory'
    ;

FUNCTION
    :    'Function'
    ;

GET
    :    'get'
    ;

IMPLEMENTS
    :    'implements'
    ;

IMPORT
    :    'import'
    ;

INTERFACE
    :    'interface'
    ;

LATE
    :    'late'
    ;

LIBRARY
    :    'library'
    ;

OPERATOR
    :    'operator'
    ;

MIXIN
    :    'mixin'
    ;

PART
    :    'part'
    ;

REQUIRED
    :    'required'
    ;

SET
    :    'set'
    ;

STATIC
    :    'static'
    ;

TYPEDEF
    :    'typedef'
    ;

// "Contextual keywords".

AWAIT
    :    'await'
    ;

YIELD
    :    'yield'
    ;

// Other words used in the grammar.

ASYNC
    :    'async'
    ;

HIDE
    :    'hide'
    ;

OF
    :    'of'
    ;

ON
    :    'on'
    ;

SHOW
    :    'show'
    ;

SYNC
    :    'sync'
    ;

// Lexical tokens that are not words.

NUMBER
    :    DIGIT+ '.' DIGIT+ EXPONENT?
    |    DIGIT+ EXPONENT?
    |    '.' DIGIT+ EXPONENT?
    ;

HEX_NUMBER
    :    '0x' HEX_DIGIT+
    |    '0X' HEX_DIGIT+
    ;

RAW_SINGLE_LINE_STRING
    :    'r' '\'' (~('\'' | '\r' | '\n'))* '\''
    |    'r' '"' (~('"' | '\r' | '\n'))* '"'
    ;

RAW_MULTI_LINE_STRING
    :    'r' '"""' (.)*? '"""'
    |    'r' '\'\'\'' (.)*? '\'\'\''
    ;

fragment
SIMPLE_STRING_INTERPOLATION
    :    '$' IDENTIFIER_NO_DOLLAR
    ;

fragment
ESCAPE_SEQUENCE
    :    '\\n'
    |    '\\r'
    |    '\\b'
    |    '\\t'
    |    '\\v'
    |    '\\x' HEX_DIGIT HEX_DIGIT
    |    '\\u' HEX_DIGIT HEX_DIGIT HEX_DIGIT HEX_DIGIT
    |    '\\u{' HEX_DIGIT_SEQUENCE '}'
    ;

fragment
HEX_DIGIT_SEQUENCE
    :    HEX_DIGIT HEX_DIGIT? HEX_DIGIT?
         HEX_DIGIT? HEX_DIGIT? HEX_DIGIT?
    ;

fragment
STRING_CONTENT_COMMON
    :    ~('\\' | '\'' | '"' | '$' | '\r' | '\n')
    |    ESCAPE_SEQUENCE
    |    '\\' ~('n' | 'r' | 'b' | 't' | 'v' | 'x' | 'u' | '\r' | '\n')
    |    SIMPLE_STRING_INTERPOLATION
    ;

fragment
STRING_CONTENT_SQ
    :    STRING_CONTENT_COMMON
    |    '"'
    ;

SINGLE_LINE_STRING_SQ_BEGIN_END
    :    '\'' STRING_CONTENT_SQ* '\''
    ;

SINGLE_LINE_STRING_SQ_BEGIN_MID
    :    '\'' STRING_CONTENT_SQ* '${' { enterBraceSingleQuote(); }
    ;

SINGLE_LINE_STRING_SQ_MID_MID
    :    { currentBraceLevel(BRACE_SINGLE) }?
         { exitBrace(); } '}' STRING_CONTENT_SQ* '${'
         { enterBraceSingleQuote(); }
    ;

SINGLE_LINE_STRING_SQ_MID_END
    :    { currentBraceLevel(BRACE_SINGLE) }?
         { exitBrace(); } '}' STRING_CONTENT_SQ* '\''
    ;

fragment
STRING_CONTENT_DQ
    :    STRING_CONTENT_COMMON
    |    '\''
    ;

SINGLE_LINE_STRING_DQ_BEGIN_END
    :    '"' STRING_CONTENT_DQ* '"'
    ;

SINGLE_LINE_STRING_DQ_BEGIN_MID
    :    '"' STRING_CONTENT_DQ* '${' { enterBraceDoubleQuote(); }
    ;

SINGLE_LINE_STRING_DQ_MID_MID
    :    { currentBraceLevel(BRACE_DOUBLE) }?
         { exitBrace(); } '}' STRING_CONTENT_DQ* '${'
         { enterBraceDoubleQuote(); }
    ;

SINGLE_LINE_STRING_DQ_MID_END
    :    { currentBraceLevel(BRACE_DOUBLE) }?
         { exitBrace(); } '}' STRING_CONTENT_DQ* '"'
    ;

fragment
QUOTES_SQ
    :
    |    '\''
    |    '\'\''
    ;

// Read string contents, which may be almost anything, but stop when seeing
// '\'\'\'' and when seeing '${'. We do this by allowing all other
// possibilities including escapes, simple interpolation, and fewer than
// three '\''.
fragment
STRING_CONTENT_TSQ
    :    QUOTES_SQ
         (STRING_CONTENT_COMMON | '"' | '\r' | '\n' | '\\\r' | '\\\n')
    ;

MULTI_LINE_STRING_SQ_BEGIN_END
    :    '\'\'\'' STRING_CONTENT_TSQ* '\'\'\''
    ;

MULTI_LINE_STRING_SQ_BEGIN_MID
    :    '\'\'\'' STRING_CONTENT_TSQ* QUOTES_SQ '${'
         { enterBraceThreeSingleQuotes(); }
    ;

MULTI_LINE_STRING_SQ_MID_MID
    :    { currentBraceLevel(BRACE_THREE_SINGLE) }?
         { exitBrace(); } '}' STRING_CONTENT_TSQ* QUOTES_SQ '${'
         { enterBraceThreeSingleQuotes(); }
    ;

MULTI_LINE_STRING_SQ_MID_END
    :    { currentBraceLevel(BRACE_THREE_SINGLE) }?
         { exitBrace(); } '}' STRING_CONTENT_TSQ* '\'\'\''
    ;

fragment
QUOTES_DQ
    :
    |    '"'
    |    '""'
    ;

// Read string contents, which may be almost anything, but stop when seeing
// '"""' and when seeing '${'. We do this by allowing all other possibilities
// including escapes, simple interpolation, and fewer-than-three '"'.
fragment
STRING_CONTENT_TDQ
    :    QUOTES_DQ
         (STRING_CONTENT_COMMON | '\'' | '\r' | '\n' | '\\\r' | '\\\n')
    ;

MULTI_LINE_STRING_DQ_BEGIN_END
    :    '"""' STRING_CONTENT_TDQ* '"""'
    ;

MULTI_LINE_STRING_DQ_BEGIN_MID
    :    '"""' STRING_CONTENT_TDQ* QUOTES_DQ '${'
         { enterBraceThreeDoubleQuotes(); }
    ;

MULTI_LINE_STRING_DQ_MID_MID
    :    { currentBraceLevel(BRACE_THREE_DOUBLE) }?
         { exitBrace(); } '}' STRING_CONTENT_TDQ* QUOTES_DQ '${'
         { enterBraceThreeDoubleQuotes(); }
    ;

MULTI_LINE_STRING_DQ_MID_END
    :    { currentBraceLevel(BRACE_THREE_DOUBLE) }?
         { exitBrace(); } '}' STRING_CONTENT_TDQ* '"""'
    ;

LBRACE
    :    '{' { enterBrace(); }
    ;

RBRACE
    :    { currentBraceLevel(BRACE_NORMAL) }? { exitBrace(); } '}'
    ;

fragment
IDENTIFIER_START_NO_DOLLAR
    :    LETTER
    |    '_'
    ;

fragment
IDENTIFIER_PART_NO_DOLLAR
    :    IDENTIFIER_START_NO_DOLLAR
    |    DIGIT
    ;

fragment
IDENTIFIER_NO_DOLLAR
    :    IDENTIFIER_START_NO_DOLLAR IDENTIFIER_PART_NO_DOLLAR*
    ;

fragment
IDENTIFIER_START
    :    IDENTIFIER_START_NO_DOLLAR
    |    '$'
    ;

fragment
IDENTIFIER_PART
    :    IDENTIFIER_START
    |    DIGIT
    ;

SCRIPT_TAG
    :    '#!' (~('\r' | '\n'))* NEWLINE
    ;

IDENTIFIER
    :    IDENTIFIER_START IDENTIFIER_PART*
    ;

SINGLE_LINE_COMMENT
    :    '//' (~('\r' | '\n'))* NEWLINE?
         { skip(); }
    ;

MULTI_LINE_COMMENT
    :    '/*' (MULTI_LINE_COMMENT | .)*? '*/'
         { skip(); }
    ;

fragment
NEWLINE
    :    ('\r' | '\n' | '\r\n')
    ;

FEFF
    :    '\uFEFF'
    ;

WS
    :    (' ' | '\t' | '\r' | '\n')+
         { skip(); }
    ;
