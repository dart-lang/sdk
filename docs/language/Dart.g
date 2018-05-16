// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// *** This grammar is under development and it contains known bugs. ***
//
// CHANGES:
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

  /// Produce grammar debugging friendly output, as described in 'The
  /// Definitive ANTLR Reference', p247.
  public String getErrorMessage(RecognitionException e, String[] tokenNames) {
    List stack = getRuleInvocationStack(e, this.getClass().getName());
    String msg = null;
    if (e instanceof NoViableAltException) {
      NoViableAltException nvae = (NoViableAltException)e;
      msg = "no viable alt; token=" + e.token +
          " (decision=" + nvae.decisionNumber +
          " state " + nvae.stateNumber + ")" +
          " decision=<<" + nvae.grammarDecisionDescription + ">>";
    }
    else {
      msg = super.getErrorMessage(e, tokenNames);
    }
    if (!errorHasOccurred) prepareForErrors();
    return stack + " " + msg;
  }

  public String getTokenErrorDisplay(Token t) {
    return t.toString();
  }

  // Enable the parser to treat ASYNC/AWAIT/YIELD as keywords in the body of an
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

  // Whether we can recognize ASYNC/AWAIT/YIELD as an identifier/typeIdentifier.
  boolean asyncEtcPredicate(int tokenId) {
    if (tokenId == ASYNC || tokenId == AWAIT || tokenId == YIELD) {
      return !asyncEtcAreKeywords.peek();
    }
    return false;
  }

  // Debugging support methods.
  void dp(int indent, String method, String sep) {
    for (int i = 0; i < indent; i++) {
      System.out.print("  ");
    }
    System.out.println(method + sep + " " + input.LT(1) + " " + state.failed);
  }

  void dpBegin(int indent, String method) { dp(indent, method, ":"); }
  void dpEnd(int indent, String method) { dp(indent, method, " END:"); }
  void dpCall(int indent, String method) { dp(indent, method, "?"); }
  void dpCalled(int indent, String method) { dp(indent, method, ".."); }
  void dpResult(int indent, String method) { dp(indent, method, "!"); }
}

@lexer::members{
  public static final int BRACE_NORMAL = 1;
  public static final int BRACE_SINGLE = 2;
  public static final int BRACE_DOUBLE = 3;
  public static final int BRACE_THREE_SINGLE = 4;
  public static final int BRACE_THREE_DOUBLE = 5;

  /// This override ensures that lexer errors are recognized as errors,
  /// but does not change the format of the reported error.
  public String getErrorMessage(RecognitionException e, String[] tokenNames) {
    if (!DartParser.errorHasOccurred) DartParser.prepareForErrors();
    return super.getErrorMessage(e, tokenNames);
  }

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
         ((metadata LIBRARY) => libraryName)?
         ((metadata (IMPORT | EXPORT)) => importOrExport)*
         ((metadata PART) => partDirective)*
         (metadata topLevelDefinition)*
         EOF
    ;

topLevelDefinition
    :    classDefinition
    |    enumType
    |    (TYPEDEF typeIdentifier typeParameters? '=') => typeAlias
    |    (TYPEDEF functionPrefix ('<' | '(')) => typeAlias
    |    (EXTERNAL functionSignature ';') => EXTERNAL functionSignature ';'
    |    (EXTERNAL getterSignature) => EXTERNAL getterSignature ';'
    |    (EXTERNAL type? SET identifier '(') =>
         EXTERNAL setterSignature ';'
    |    (getterSignature functionBodyPrefix) => getterSignature functionBody
    |    (type? SET identifier '(') => setterSignature functionBody
    |    (type? identifierNotFUNCTION typeParameters? '(') =>
         functionSignature functionBody
    |    (FINAL | CONST) type? staticFinalDeclarationList ';'
    |    topLevelVariableDeclaration ';'
    ;

topLevelVariableDeclaration
    :    varOrType identifier ('=' expression)? (',' initializedIdentifier)*
    ;

declaredIdentifier
    :    COVARIANT? finalConstVarOrType identifier
    ;

finalConstVarOrType
    :    FINAL type?
    |    CONST type?
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
    |    '(' normalFormalParameters (','? | ',' optionalFormalParameters) ')'
    |    '(' optionalFormalParameters ')'
    ;

normalFormalParameters
    :    normalFormalParameter (',' normalFormalParameter)*
    ;

optionalFormalParameters
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
    :    (COVARIANT? type? identifierNotFUNCTION formalParameterPart) =>
         functionFormalParameter
    |    (finalConstVarOrType? THIS) => fieldFormalParameter
    |    simpleFormalParameter
    ;

// NB: It is an anomaly that a functionFormalParameter cannot be FINAL.
functionFormalParameter
    :    COVARIANT? type? identifierNotFUNCTION formalParameterPart
    ;

simpleFormalParameter
    :    declaredIdentifier
    |    COVARIANT? identifier
    ;

// NB: It is an anomaly that VAR can be a return type (`var this.x()`).
fieldFormalParameter
    :    finalConstVarOrType? THIS '.' identifier formalParameterPart?
    ;

defaultFormalParameter
    :    normalFormalParameter ('=' expression)?
    ;

defaultNamedParameter
    :    normalFormalParameter ((':' | '=') expression)?
    ;

typeApplication
    :    typeIdentifier typeParameters?
    ;

classDefinition
    :    (ABSTRACT? CLASS typeApplication (EXTENDS|IMPLEMENTS|LBRACE)) =>
         ABSTRACT? CLASS typeApplication (superclass mixins?)? interfaces?
         LBRACE (metadata classMemberDefinition)* RBRACE
    |    (ABSTRACT? CLASS typeApplication '=') =>
         ABSTRACT? CLASS mixinApplicationClass
    ;

mixins
    :    WITH typeNotVoidNotFunctionList
    ;

classMemberDefinition
    :    (methodSignature functionBodyPrefix) => methodSignature functionBody
    |    declaration ';'
    ;

methodSignature
    :    (constructorSignature ':') => constructorSignature initializers
    |    (FACTORY constructorName '(') => factoryConstructorSignature
    |    (STATIC? type? identifierNotFUNCTION typeParameters? '(') =>
         STATIC? functionSignature
    |    (STATIC? type? GET) => STATIC? getterSignature
    |    (STATIC? type? SET) => STATIC? setterSignature
    |    (type? OPERATOR operator '(') => operatorSignature
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
    :    (EXTERNAL CONST? FACTORY constructorName '(') =>
         EXTERNAL factoryConstructorSignature
    |    (EXTERNAL CONST constructorName '(') =>
         EXTERNAL constantConstructorSignature
    |    (EXTERNAL constructorName '(') => EXTERNAL constructorSignature
    |    ((EXTERNAL STATIC?)? type? GET identifier) =>
         (EXTERNAL STATIC?)? getterSignature
    |    ((EXTERNAL STATIC?)? type? SET identifier) =>
         (EXTERNAL STATIC?)? setterSignature
    |    (EXTERNAL? type? OPERATOR) => EXTERNAL? operatorSignature
    |    (STATIC (FINAL | CONST)) =>
         STATIC (FINAL | CONST) type? staticFinalDeclarationList
    |    FINAL type? initializedIdentifierList
    |    ((STATIC | COVARIANT)? (VAR | type) identifier ('=' | ',' | ';')) =>
         (STATIC | COVARIANT)? (VAR | type) initializedIdentifierList
    |    (EXTERNAL? STATIC? functionSignature ';') =>
         EXTERNAL? STATIC? functionSignature
    |    (CONST? FACTORY constructorName formalParameterList '=') =>
         redirectingFactoryConstructorSignature
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
    |    (shiftOperator) => shiftOperator
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
    :    ':' superCallOrFieldInitializer (',' superCallOrFieldInitializer)*
    ;

superCallOrFieldInitializer
    :    SUPER arguments
    |    SUPER '.' identifier arguments
    |    fieldInitializer
    |    assertClause
    ;

fieldInitializer
    :    (THIS '.')? identifier '=' conditionalExpression cascadeSection*
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

superclass
    :    EXTENDS typeNotVoidNotFunction
    ;

interfaces
    :    IMPLEMENTS typeNotVoidNotFunctionList
    ;

mixinApplicationClass
    :    typeApplication '=' mixinApplication ';'
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
    |    qualified
    ;

expression
    :    (formalParameterPart functionExpressionBodyPrefix) =>
         functionExpression
    |    throwExpression
    |    (assignableExpression assignmentOperator) =>
         assignableExpression assignmentOperator expression
    |    conditionalExpression cascadeSection*
    ;

expressionWithoutCascade
    :    (formalParameterPart functionExpressionBodyPrefix) =>
         functionExpressionWithoutCascade
    |    throwExpressionWithoutCascade
    |    (assignableExpression assignmentOperator) =>
         assignableExpression assignmentOperator expressionWithoutCascade
    |    conditionalExpression
    ;

expressionList
    :    expression (',' expression)*
    ;

primary
    :    thisExpression
    |    SUPER unconditionalAssignableSelector
    |    (CONST constructorDesignation) => constObjectExpression
    |    newExpression
    |    (formalParameterPart functionPrimaryBodyPrefix) => functionPrimary
    |    '(' expression ')'
    |    literal
    |    identifier
    ;

literal
    :    nullLiteral
    |    booleanLiteral
    |    numericLiteral
    |    stringLiteral
    |    symbolLiteral
    |    (CONST? typeArguments? LBRACE) => mapLiteral
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

stringLiteralWithoutInterpolation
    :    singleLineStringWithoutInterpolation+
    ;

listLiteral
    :    CONST? typeArguments? '[' (expressionList ','?)? ']'
    ;

mapLiteral
    :    CONST? typeArguments?
         LBRACE (mapLiteralEntry (',' mapLiteralEntry)* ','?)? RBRACE
    ;

mapLiteralEntry
    :    expression ':' expression
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

cascadeSection
    :    '..'
         (cascadeSelector argumentPart*)
         (assignableSelector argumentPart*)*
         (assignmentOperator expressionWithoutCascade)?
    ;

cascadeSelector
    :    '[' expression ']'
    |    identifier
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
    :    (prefixOperator ~SUPER) => prefixOperator unaryExpression
    |    (awaitExpression) => awaitExpression
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

// The `(selector)` predicate ensures that the parser commits to the longest
// possible chain of selectors, e.g., `a<b,c>(d)` as a call rather than as a
// sequence of two relational expressions.

postfixExpression
    :    (assignableExpression postfixOperator) =>
         assignableExpression postfixOperator
    |    (typeName typeArguments '.') =>
         constructorInvocation ((selector) => selector)*
    |    primary ((selector) => selector)*
    ;

constructorInvocation
    :    typeName typeArguments '.' identifier arguments
    ;

postfixOperator
    :    incrementOperator
    ;

selector
    :    assignableSelector
    |    argumentPart
    ;

argumentPart
    :    typeArguments? arguments
    ;

incrementOperator
    :    '++'
    |    '--'
    ;

// The `(assignableSelectorPart)` predicate ensures that the parser
// commits to the longest possible chain, e.g., `a<b,c>(d).e` as one rather
// than two expressions. The first `identifier` alternative handles all
// the simple cases; the final `identifier` alternative at the end catches
// the case where we have `identifier '<'` and the '<' is used as a
// relationalOperator, not the beginning of typeArguments.

assignableExpression
    :    (SUPER unconditionalAssignableSelector
            ~('<' | '(' | '[' | '.' | '?.')) =>
         SUPER unconditionalAssignableSelector
    |    (typeName typeArguments '.' identifier '(') =>
         constructorInvocation
         ((assignableSelectorPart) => assignableSelectorPart)+
    |    (identifier ~('<' | '(' | '[' | '.' | '?.')) => identifier
    |    (primary assignableSelectorPart) =>
         primary ((assignableSelectorPart) => assignableSelectorPart)+
    |    identifier
    ;

assignableSelectorPart
    :    argumentPart* assignableSelector
    ;

unconditionalAssignableSelector
    :    '[' expression ']'
    |    '.' identifier
    ;

assignableSelector
    :    unconditionalAssignableSelector
    |    '?.' identifier
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
    |    LIBRARY // Built-in identifier.
    |    OPERATOR // Built-in identifier.
    |    PART // Built-in identifier.
    |    SET // Built-in identifier.
    |    STATIC // Built-in identifier.
    |    TYPEDEF // Built-in identifier.
    |    HIDE // Not a built-in identifier.
    |    OF // Not a built-in identifier.
    |    ON // Not a built-in identifier.
    |    SHOW // Not a built-in identifier.
    |    SYNC // Not a built-in identifier.
    |    { asyncEtcPredicate(input.LA(1)) }? (ASYNC|AWAIT|YIELD)
    ;

identifier
    :    identifierNotFUNCTION
    |    FUNCTION // Built-in identifier that can be used as a type.
    ;

qualified
    :    typeIdentifier
    |    typeIdentifier '.' identifier
    |    typeIdentifier '.' typeIdentifier '.' identifier
    ;

typeIdentifier
    :    IDENTIFIER
    |    DYNAMIC // Built-in identifier that can be used as a type.
    |    HIDE // Not a built-in identifier.
    |    OF // Not a built-in identifier.
    |    ON // Not a built-in identifier.
    |    SHOW // Not a built-in identifier.
    |    SYNC // Not a built-in identifier.
    |    { asyncEtcPredicate(input.LA(1)) }? (ASYNC|AWAIT|YIELD)
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
    :    (LBRACE) => block
    |    (metadata declaredIdentifier ('='|','|';')) =>
         localVariableDeclaration
    |    (AWAIT? FOR) => forStatement
    |    whileStatement
    |    doStatement
    |    switchStatement
    |    ifStatement
    |    rethrowStatement
    |    tryStatement
    |    breakStatement
    |    continueStatement
    |    returnStatement
    |    (metadata functionSignature functionBodyPrefix) =>
         localFunctionDeclaration
    |    assertStatement
    |    (YIELD ~'*') => yieldStatement
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
    :    IF '(' expression ')' statement ((ELSE) => ELSE statement | ())
    ;

forStatement
    :    AWAIT? FOR '(' forLoopParts ')' statement
    ;

forLoopParts
    :    (metadata declaredIdentifier IN) =>
         metadata declaredIdentifier IN expression
    |    (metadata identifier IN) => metadata identifier IN expression
    |    forInitializerStatement expression? ';' expressionList?
    ;

// The localVariableDeclaration cannot be CONST, but that can
// be enforced in a later phase, and the grammar allows it.
forInitializerStatement
    :    (localVariableDeclaration) => localVariableDeclaration
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
    :    (onPart (ON|CATCH)) => onPart onParts
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
    :    assertClause ';'
    ;

assertClause
    :    ASSERT '(' expression (',' expression)? ','? ')'
    ;

libraryName
    :    metadata LIBRARY identifier ('.' identifier)* ';'
    ;

importOrExport
    :    (metadata IMPORT) => libraryImport
    |    (metadata EXPORT) => libraryExport
    ;

libraryImport
    :    metadata importSpecification
    ;

importSpecification
    :    IMPORT uri (AS identifier)? combinator* ';'
    |    IMPORT uri DEFERRED AS identifier combinator* ';'
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

uri
    :    stringLiteralWithoutInterpolation
    ;

type
    :    (FUNCTION ('('|'<')) => functionTypeTails
    |    (typeNotFunction FUNCTION ('('|'<')) =>
         typeNotFunction functionTypeTails
    |    typeNotFunction
    ;

typeNotFunction
    :    typeNotVoidNotFunction
    |    VOID
    ;

typeNotVoid
    :    (typeNotFunction? FUNCTION ('('|'<')) => functionType
    |    typeNotVoidNotFunction
    ;

typeNotVoidNotFunction
    :    typeName typeArguments?
    |    FUNCTION
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
    :    (TYPEDEF typeIdentifier typeParameters? '=') =>
         TYPEDEF typeIdentifier typeParameters? '=' functionType ';'
    |    TYPEDEF functionTypeAlias
    ;

functionTypeAlias
    :    functionPrefix formalParameterPart ';'
    ;

functionPrefix
    :    (type identifier) => type identifier
    |    identifier
    ;

functionTypeTail
    :    FUNCTION typeParameters? parameterTypeList
    ;

functionTypeTails
    :    (functionTypeTail FUNCTION ('<'|'(')) =>
         functionTypeTail functionTypeTails
    |    functionTypeTail
    ;

functionType
    :    (FUNCTION ('<'|'(')) => functionTypeTails
    |    typeNotFunction functionTypeTails
    ;

parameterTypeList
    :    ('(' ')') => '(' ')'
    |    ('(' normalParameterTypes ',' ('['|'{')) =>
         '(' normalParameterTypes ',' optionalParameterTypes ')'
    |    ('(' normalParameterTypes ','? ')') =>
         '(' normalParameterTypes ','? ')'
    |    '(' optionalParameterTypes ')'
    ;

normalParameterTypes
    :    normalParameterType (',' normalParameterType)*
    ;

normalParameterType
    :    (typedIdentifier) => typedIdentifier
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
    :    LBRACE typedIdentifier (',' typedIdentifier)* ','? RBRACE
    ;

typedIdentifier
    :    type identifier
    ;

constructorDesignation
    :    qualified
    |    typeName typeArguments ('.' identifier)?
    ;

// Predicate: Force resolution as composite symbolLiteral as far as possible.
symbolLiteral
    :    '#' (operator | (identifier (('.' identifier) => '.' identifier)*))
    ;

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

FINAL
    :    'final'
    ;

CONST
    :    'const'
    ;

VAR
    :    'var'
    ;

VOID
    :    'void'
    ;

ASYNC
    :    'async'
    ;

THIS
    :    'this'
    ;

ABSTRACT
    :    'abstract'
    ;

AS
    :    'as'
    ;

SYNC
    :    'sync'
    ;

CLASS
    :    'class'
    ;

WITH
    :    'with'
    ;

STATIC
    :    'static'
    ;

DYNAMIC
    :    'dynamic'
    ;

EXTERNAL
    :    'external'
    ;

GET
    :    'get'
    ;

SET
    :    'set'
    ;

OPERATOR
    :    'operator'
    ;

SUPER
    :    'super'
    ;

FACTORY
    :    'factory'
    ;

EXTENDS
    :    'extends'
    ;

IMPLEMENTS
    :    'implements'
    ;

ENUM
    :    'enum'
    ;

NULL
    :    'null'
    ;

TRUE
    :    'true'
    ;

FALSE
    :    'false'
    ;

THROW
    :    'throw'
    ;

NEW
    :    'new'
    ;

AWAIT
    :    'await'
    ;

DEFERRED
    :    'deferred'
    ;

EXPORT
    :    'export'
    ;

IMPORT
    :    'import'
    ;

LIBRARY
    :    'library'
    ;

PART
    :    'part'
    ;

TYPEDEF
    :    'typedef'
    ;

IS
    :    'is'
    ;

IF
    :    'if'
    ;

ELSE
    :    'else'
    ;

WHILE
    :    'while'
    ;

FOR
    :    'for'
    ;

IN
    :    'in'
    ;

DO
    :    'do'
    ;

SWITCH
    :    'switch'
    ;

CASE
    :    'case'
    ;

DEFAULT
    :    'default'
    ;

RETHROW
    :    'rethrow'
    ;

TRY
    :    'try'
    ;

ON
    :    'on'
    ;

CATCH
    :    'catch'
    ;

FINALLY
    :    'finally'
    ;

RETURN
    :    'return'
    ;

BREAK
    :    'break'
    ;

CONTINUE
    :    'continue'
    ;

YIELD
    :    'yield'
    ;

SHOW
    :    'show'
    ;

HIDE
    :    'hide'
    ;

OF
    :    'of'
    ;

ASSERT
    :    'assert'
    ;

COVARIANT
    :    'covariant'
    ;

FUNCTION
    :    'Function'
    ;

NUMBER
    :    (DIGIT+ '.' DIGIT) => DIGIT+ '.' DIGIT+ EXPONENT?
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
    :    'r' '"""' (options {greedy=false;} : .)* '"""'
    |    'r' '\'\'\'' (options {greedy=false;} : .)* '\'\'\''
    ;

fragment
SIMPLE_STRING_INTERPOLATION
    :    '$' IDENTIFIER_NO_DOLLAR
    ;

fragment
STRING_CONTENT_SQ
    :    ~('\\' | '\'' | '$' |  '\r' | '\n')
    |    '\\' ~( '\r' | '\n')
    |    SIMPLE_STRING_INTERPOLATION
    ;

SINGLE_LINE_STRING_SQ_BEGIN_END
    :    '\'' STRING_CONTENT_SQ* '\''
    ;

SINGLE_LINE_STRING_SQ_BEGIN_MID
    :    '\'' STRING_CONTENT_SQ* '${' { enterBraceSingleQuote(); }
    ;

SINGLE_LINE_STRING_SQ_MID_MID
    :    { currentBraceLevel(BRACE_SINGLE) }? =>
         ('}' STRING_CONTENT_SQ* '${') =>
         { exitBrace(); } '}' STRING_CONTENT_SQ* '${'
         { enterBraceSingleQuote(); }
    ;

SINGLE_LINE_STRING_SQ_MID_END
    :    { currentBraceLevel(BRACE_SINGLE) }? =>
         ('}' STRING_CONTENT_SQ* '\'') =>
         { exitBrace(); } '}' STRING_CONTENT_SQ* '\''
    ;

fragment
STRING_CONTENT_DQ
    :    ~('\\' | '"' | '$' | '\r' | '\n')
    |    '\\' ~('\r' | '\n')
    |    SIMPLE_STRING_INTERPOLATION
    ;

SINGLE_LINE_STRING_DQ_BEGIN_END
    :    '"' STRING_CONTENT_DQ* '"'
    ;

SINGLE_LINE_STRING_DQ_BEGIN_MID
    :    '"' STRING_CONTENT_DQ* '${' { enterBraceDoubleQuote(); }
    ;

SINGLE_LINE_STRING_DQ_MID_MID
    :    { currentBraceLevel(BRACE_DOUBLE) }? =>
         ('}' STRING_CONTENT_DQ* '${') =>
         { exitBrace(); } '}' STRING_CONTENT_DQ* '${'
         { enterBraceDoubleQuote(); }
    ;

SINGLE_LINE_STRING_DQ_MID_END
    :    { currentBraceLevel(BRACE_DOUBLE) }? =>
         ('}' STRING_CONTENT_DQ* '"') =>
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
         (~('\\' | '$' | '\'') | '\\' . | SIMPLE_STRING_INTERPOLATION)
    ;

MULTI_LINE_STRING_SQ_BEGIN_END
    :    '\'\'\'' STRING_CONTENT_TSQ* '\'\'\''
    ;

MULTI_LINE_STRING_SQ_BEGIN_MID
    :    '\'\'\'' STRING_CONTENT_TSQ* QUOTES_SQ '${'
         { enterBraceThreeSingleQuotes(); }
    ;

MULTI_LINE_STRING_SQ_MID_MID
    :    { currentBraceLevel(BRACE_THREE_SINGLE) }? =>
         ('}' STRING_CONTENT_TSQ* QUOTES_SQ '${') =>
         { exitBrace(); } '}' STRING_CONTENT_TSQ* QUOTES_SQ '${'
         { enterBraceThreeSingleQuotes(); }
    ;

MULTI_LINE_STRING_SQ_MID_END
    :    { currentBraceLevel(BRACE_THREE_SINGLE) }? =>
         ('}' STRING_CONTENT_TSQ* '\'\'\'') =>
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
         (~('\\' | '$' | '"') | '\\' . | SIMPLE_STRING_INTERPOLATION)
    ;

MULTI_LINE_STRING_DQ_BEGIN_END
    :    '"""' STRING_CONTENT_TDQ* '"""'
    ;

MULTI_LINE_STRING_DQ_BEGIN_MID
    :    '"""' STRING_CONTENT_TDQ* QUOTES_DQ '${'
         { enterBraceThreeDoubleQuotes(); }
    ;

MULTI_LINE_STRING_DQ_MID_MID
    :    { currentBraceLevel(BRACE_THREE_DOUBLE) }? =>
         ('}' STRING_CONTENT_TDQ* QUOTES_DQ '${') =>
         { exitBrace(); } '}' STRING_CONTENT_TDQ* QUOTES_DQ '${'
         { enterBraceThreeDoubleQuotes(); }
    ;

MULTI_LINE_STRING_DQ_MID_END
    :    { currentBraceLevel(BRACE_THREE_DOUBLE) }? =>
         ('}' STRING_CONTENT_TDQ* '"""') =>
         { exitBrace(); } '}' STRING_CONTENT_TDQ* '"""'
    ;

LBRACE
    :    '{' { enterBrace(); }
    ;

RBRACE
    :    { currentBraceLevel(BRACE_NORMAL) }? => ('}') => { exitBrace(); } '}'
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
    :    '/*' (options {greedy=false;} : (MULTI_LINE_COMMENT | .))* '*/'
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
