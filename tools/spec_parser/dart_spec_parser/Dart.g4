// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// CHANGES:
//
// v0.52 Support a `switchExpression` with no cases.
//
// v0.51 Add support for digit separators in numeric literals.
//
// v0.50 Add support for static and top-level members with no implementation.
//
// v0.49 Add support for enhanced parts.
//
// v0.48 Make `augment` a built-in identifier (this happened in the feature
// specification v1.10, but wasn't done here at the time).
//
// v0.47 Rename `libraryDefinition` to `libraryDeclaration`, as in the
// language specification. Add support for libraries with imports.
//
// v0.46 Update rule about augmenting extension type declaration to omit
// the primary constructor.
//
// v0.45 Support null-aware elements.
//
// v0.44 Change rule structure such that the association of metadata
// with non-terminals can be explained in a simple and consistent way.
// The derivable terms do not change. Remove `metadata` from the kind
// of `forLoopParts` where the iteration variable is an existing variable
// in scope (this is not implemented, is inconsistent anyway).
//
// v0.43 Support updated augmented `extensionDeclaration`.
//
// v0.42 Add missing `enumEntry` update for augmentations.
//
// v0.41 Include support for augmentation libraries.
//
// v0.40 Include latest changes to mixin related class modifiers.
//
// v0.39 Translate actions from Java to Dart.
//
// v0.38 Broaden `initializerExpression` to match implemented behavior.
//
// v0.37 Correct `libraryExport` to use `configurableUri`, not `uri`.
//
// v0.36 Update syntax from `inline class` to `extension type`, including
// a special case of primary constructors.
//
// v0.35 Change named optional parameter syntax to require '=', that is,
// remove the support for ':' as in `void f({int i: 1})`.
//
// v0.34 Add support for inline classes.
//
// v0.33 This commit does not change the derived language at all. It just
// changes several rules to use the regexp-like grammar operators to simplify
// onParts, recordLiteralNoConst, functionTypeTails, and functionType.
//
// v0.32 Remove unused non-terminal `patterns`.
//
// v0.31 Inline `identifierNotFUNCTION` into `identifier`. Replace all
// other references with `identifier` to match the spec.
//
// v0.30 Add support for the class modifiers `sealed`, `final`, `base`,
// `interface`, and for `mixin class` declarations. Also add support for
// unnamed libraries (`library;`). Introduce `otherIdentifier` to help
// maintaining consistency when the grammar is modified to mention any words
// that weren't previously mentioned, yet are not reserved or built-in.
//
// v0.29 Add an alternative in the `primary` rule to enable method invocations
// of the form `super(...)` and `super<...>(...)`. This was added to the
// language specification in May 21, b26e7287c318c0112610fe8b7e175289792dfde2,
// but the corresponding update here wasn't done here at the time.
//
// v0.28 Add support for `new` in `enumEntry`, e.g., `enum E { x.new(); }`.
// Add `identifierOrNew` non-terminal to simplify the grammar.
//
// v0.27 Remove unused non-terminals; make handling of interpolation in URIs
// consistent with the language specification. Make `partDeclaration` a
// start symbol in addition to `libraryDefinition` (such that no special
// precautions are needed in order to parse a part file). Corrected spacing
// in several rules.
//
// v0.26 Add missing `metadata` in `partDeclaration`.
//
// v0.25 Update pattern rules following changes to the patterns feature
// specification since v0.24.
//
// v0.24 Change constant pattern rules to allow Symbols and negative numbers.
//
// v0.23 Change logical pattern rules to || and &&.
//
// v0.22 Change pattern rules, following updated feature specification.
//
// v0.21 Add support for patterns.
//
// v0.20 Adjust record syntax such that () is allowed (denoting the empty
// record type and the empty record value).
//
// v0.19 Add support for super parameters, named arguments everywhere, and
// records.
//
// v0.18 Add support for enhanced `enum` declarations.
//
// v0.17 (58d917e7573c359580ade43845004dbbc62220d5) Correct `uri` to allow
// multi-line strings (raw and non-raw).
//
// v0.16 (284695f1937c262523a9a11b9084213f889c83e0) Correct instance variable
// declaration syntax such that `covariant late final` is allowed.
//
// v0.15 (6facd6dfdafa2953e8523348220d3129ea884678) Add support for
// constructor tearoffs and explicitly instantiated function tearoffs and
// type literals.
//
// v0.14 (f65c20124edd9e04f7b3a6f014f40c16f51052f6) Correct `partHeader`
// to allow uri syntax in a `PART OF` directive.
//
// v0.13 (bb5cb79a2fd57d6a480b922bc650d5cd15948753) Introduce non-terminals
// `builtinIdentifier` and `reservedWord`; update `typeAlias` to enable
// non-function type aliases; add missing `metadata` to formal parameter
// declarations; correct `symbolLiteral` to allow `VOID`;
//
// v0.12 (82403371ac00ddf004be60fa7b705474d2864509) Cf. language issue #1341:
// correct `metadata`. Change `qualifiedName` such that it only includes the
// cases with a '.'; the remaining case is added where `qualifiedName` is used.
//
// v0.11 (67c703063d5b68c9e132edbaf34dfe375851f5a6) Corrections, mainly:
// `fieldFormalParameter` now allows `?` on the parameter type; cascade was
// reorganized in the spec, it is now reorganized similarly here; `?` was
// removed from argumentPart (null-aware invocation was never added).
//
// v0.10 (8ccdb9ae796d543e4ad8f339c847c02b09018d2d) Simplify grammar by making
// `constructorInvocation` an alternative in `primary`.
//
// v0.9 (f4d7951a88e1b738e22b768c3bc72bf1a1062365) Introduce abstract and
// external variables.
//
// v0.8 (a9ea9365ad8a3e3b59115bd889a55b6aa2c5a5fa) Change null-aware
// invocations of `operator []` and `operator []=` to not have a period.
//
// v0.7 (6826faf583f6a543b1a0e2e85bd6a8042607ce00) Introduce extension and
// mixin declarations. Revise rules about string literals and string
// interpolation. Reorganize "keywords" (built-in identifiers, reserved words,
// other words that are specified in the grammar and not parsed as IDENTIFIER)
// into explicitly marked groups. Change the cascade syntax to be
// compositional.
//
// v0.6 (a58052974ec2b4b334922c5227b043ed2b9c2cc5) Introduce syntax associated
// with null safety.
//
// v0.5 (56793b3d4714d4818d855a72074d5295489aef3f) Stop treating `ASYNC` as a
// conditional reserved word (only `AWAIT` and `YIELD` get this treatment).
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

// FAQ:
// Q: How do I generate a parser?
// A: Install ANTLR4 and run `antlr -Dlanguage=Dart <path to Dart.g4>`.
//    See https://github.com/antlr/antlr4/blob/master/doc/dart-target.md
//    for more info.

grammar Dart;

@lexer::members {
static const _BRACE_NORMAL = 1;
static const _BRACE_SINGLE = 2;
static const _BRACE_DOUBLE = 3;
static const _BRACE_THREE_SINGLE = 4;
static const _BRACE_THREE_DOUBLE = 5;

// Enable the parser to handle string interpolations via brace matching.
// The top of the `_braceLevels` stack describes the most recent unmatched
// '{'. This is needed in order to enable/disable certain lexer rules.
//
//   NORMAL: Most recent unmatched '{' was not string literal related.
//   SINGLE: Most recent unmatched '{' was `'...${`.
//   DOUBLE: Most recent unmatched '{' was `"...${`.
//   THREE_SINGLE: Most recent unmatched '{' was `'''...${`.
//   THREE_DOUBLE: Most recent unmatched '{' was `"""...${`.
//
// Access via functions below.
final _braceLevels = <int>[];

// Whether we are currently in a string literal context, and which one.
bool _currentBraceLevel(int braceLevel) {
  if (_braceLevels.isEmpty) return false;
  return _braceLevels.last == braceLevel;
}

bool _currentBraceLevelNormal() {
  return _currentBraceLevel(_BRACE_NORMAL);
}

bool _currentBraceLevelSingleQuote() {
  return _currentBraceLevel(_BRACE_SINGLE);
}

bool _currentBraceLevelDoubleQuote() {
  return _currentBraceLevel(_BRACE_DOUBLE);
}

bool _currentBraceLevelThreeSingleQuotes() {
  return _currentBraceLevel(_BRACE_THREE_SINGLE);
}

bool _currentBraceLevelThreeDoubleQuotes() {
  return _currentBraceLevel(_BRACE_THREE_DOUBLE);
}

// Use this to indicate that we are now entering a specific '{...}'.
// Call it after accepting the '{'.
void _enterBrace() {
  _braceLevels.add(_BRACE_NORMAL);
}

void _enterBraceSingleQuote() {
  _braceLevels.add(_BRACE_SINGLE);
}

void _enterBraceDoubleQuote() {
  _braceLevels.add(_BRACE_DOUBLE);
}

void _enterBraceThreeSingleQuotes() {
  _braceLevels.add(_BRACE_THREE_SINGLE);
}

void _enterBraceThreeDoubleQuotes() {
  _braceLevels.add(_BRACE_THREE_DOUBLE);
}

// Use this to indicate that we are now exiting a specific '{...}',
// no matter which kind. Call it before accepting the '}'.
void _exitBrace() {
  // We might raise a parse error here if the stack is empty, but the
  // parsing rules should ensure that we get a parse error anyway, and
  // it is not a big problem for the spec parser even if it misinterprets
  // the brace structure of some programs with syntax errors.
  if (!_braceLevels.isEmpty) _braceLevels.removeLast();
}
}

@parser::members {
// Enable the parser to treat AWAIT/YIELD as keywords in the body of an
// `async`, `async*`, or `sync*` function. Access via methods below.
final _asyncEtcAreKeywords = <bool>[false];

// Use this to indicate that we are now entering an `async`, `async*`,
// or `sync*` function.
void _startAsyncFunction() { _asyncEtcAreKeywords.add(true); }

// Use this to indicate that we are now entering a function which is
// neither `async`, `async*`, nor `sync*`.
void _startNonAsyncFunction() { _asyncEtcAreKeywords.add(false); }

// Use this to indicate that we are now leaving any funciton.
void _endFunction() { _asyncEtcAreKeywords.removeLast(); }

// Whether we can recognize AWAIT/YIELD as an identifier/typeIdentifier.
bool _asyncEtcPredicate() {
  final tokenId = currentToken.type;
  if (tokenId == TOKEN_AWAIT || tokenId == TOKEN_YIELD) {
    return !_asyncEtcAreKeywords.last;
  }
  return false;
}
}

// ---------------------------------------- Grammar rules.

startSymbol
    :    libraryDeclaration
    |    partDeclaration
    ;

libraryDeclaration
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
    |    extensionTypeDeclaration
    |    extensionDeclaration
    |    enumType
    |    typeAlias
    |    AUGMENT? EXTERNAL functionSignature ';'
    |    AUGMENT? EXTERNAL getterSignature ';'
    |    AUGMENT? EXTERNAL setterSignature ';'
    |    AUGMENT? EXTERNAL finalVarOrType identifierList ';'
    |    AUGMENT? getterSignature (functionBody | ';')
    |    AUGMENT? setterSignature (functionBody | ';')
    |    AUGMENT? functionSignature (functionBody | ';')
    |    AUGMENT? (FINAL | CONST) type? initializedIdentifierList ';'
    |    AUGMENT? LATE FINAL type? initializedIdentifierList ';'
    |    AUGMENT? LATE? varOrType initializedIdentifierList ';'
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
    :    type? identifier formalParameterPart
    ;

functionBody
    :    '=>' { _startNonAsyncFunction(); } expression { _endFunction(); } ';'
    |    { _startNonAsyncFunction(); } block { _endFunction(); }
    |    ASYNC '=>'
         { _startAsyncFunction(); } expression { _endFunction(); } ';'
    |    (ASYNC | ASYNC '*' | SYNC '*')
         { _startAsyncFunction(); } block { _endFunction(); }
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
    |    superFormalParameter
    ;

// NB: It is an anomaly that a functionFormalParameter cannot be FINAL.
functionFormalParameter
    :    COVARIANT? type? identifier formalParameterPart '?'?
    ;

simpleFormalParameter
    :    declaredIdentifier
    |    COVARIANT? identifier
    ;

// NB: It is an anomaly that VAR can be a return type (`var this.x()`).
fieldFormalParameter
    :    finalConstVarOrType? THIS '.' identifier (formalParameterPart '?'?)?
    ;

superFormalParameter
    :    type? SUPER '.' identifier (formalParameterPart '?'?)?
    ;

defaultFormalParameter
    :    normalFormalParameter ('=' expression)?
    ;

defaultNamedParameter
    :    metadata REQUIRED? normalFormalParameterNoMetadata ('=' expression)?
    ;

typeWithParameters
    :    typeIdentifier typeParameters?
    ;

classDeclaration
    :    AUGMENT? (classModifiers | mixinClassModifiers)
         CLASS typeWithParameters superclass? interfaces?
         LBRACE (metadata classMemberDeclaration)* RBRACE
    |    classModifiers MIXIN? CLASS mixinApplicationClass
    ;

classModifiers
    :    SEALED
    |    ABSTRACT? (BASE | INTERFACE | FINAL)?
    ;

mixinClassModifiers
    :    ABSTRACT? BASE? MIXIN
    ;

superclass
    :    EXTENDS typeNotVoidNotFunction mixins?
    |    mixins
    ;

mixins
    :    WITH typeNotVoidNotFunctionList
    ;

interfaces
    :    IMPLEMENTS typeNotVoidNotFunctionList
    ;

classMemberDeclaration
    :    AUGMENT? methodSignature functionBody
    |    AUGMENT? declaration ';'
    ;

mixinApplicationClass
    :    typeWithParameters '=' mixinApplication ';'
    ;

mixinDeclaration
    :    AUGMENT? BASE? MIXIN typeWithParameters
         (ON typeNotVoidNotFunctionList)? interfaces?
         LBRACE (metadata mixinMemberDeclaration)* RBRACE
    ;

// TODO: We might want to make this more strict.
mixinMemberDeclaration
    :    classMemberDeclaration
    ;

extensionTypeDeclaration
    :    EXTENSION TYPE CONST? typeWithParameters
         representationDeclaration interfaces?
         LBRACE (metadata extensionTypeMemberDeclaration)* RBRACE
    |    AUGMENT EXTENSION TYPE typeWithParameters interfaces?
         LBRACE (metadata extensionTypeMemberDeclaration)* RBRACE
    ;

representationDeclaration
    :    ('.' identifierOrNew)? '(' metadata typedIdentifier ')'
    ;


// TODO: We might want to make this more strict.
extensionTypeMemberDeclaration
    :    classMemberDeclaration
    ;

extensionDeclaration
    :    EXTENSION typeIdentifierNotType? typeParameters? ON type extensionBody
    |    AUGMENT EXTENSION typeIdentifierNotType typeParameters? extensionBody
    ;

extensionBody
    :    LBRACE (metadata extensionMemberDeclaration)* RBRACE
    ;

// TODO: We might want to make this more strict.
extensionMemberDeclaration
    :    classMemberDeclaration
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

declaration
    :    EXTERNAL? factoryConstructorSignature
    |    EXTERNAL constantConstructorSignature
    |    EXTERNAL constructorSignature
    |    EXTERNAL? STATIC? getterSignature
    |    EXTERNAL? STATIC? setterSignature
    |    EXTERNAL? STATIC? functionSignature
    |    EXTERNAL (STATIC? finalVarOrType | COVARIANT varOrType) identifierList
    |    EXTERNAL? operatorSignature
    |    ABSTRACT (finalVarOrType | COVARIANT varOrType) identifierList
    |    STATIC (FINAL | CONST) type? initializedIdentifierList
    |    STATIC LATE FINAL type? initializedIdentifierList
    |    STATIC LATE? varOrType initializedIdentifierList
    |    COVARIANT LATE FINAL type? identifierList
    |    COVARIANT LATE? varOrType initializedIdentifierList
    |    LATE? (FINAL type? | varOrType) initializedIdentifierList
    |    redirectingFactoryConstructorSignature
    |    constantConstructorSignature (redirection | initializers)?
    |    constructorSignature (redirection | initializers)?
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
    :    typeIdentifier ('.' identifierOrNew)?
    ;

// TODO: Add this in the language specification, use it in grammar rules.
identifierOrNew
    :    identifier
    |    NEW
    ;

redirection
    :    ':' THIS ('.' identifierOrNew)? arguments
    ;

initializers
    :    ':' initializerListEntry (',' initializerListEntry)*
    ;

initializerListEntry
    :    SUPER arguments
    |    SUPER '.' identifierOrNew arguments
    |    fieldInitializer
    |    assertion
    ;

fieldInitializer
    :    (THIS '.')? identifier '=' initializerExpression
    ;

initializerExpression
    :    throwExpression
    |    assignableExpression assignmentOperator expression
    |    conditionalExpression
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
    :    AUGMENT? ENUM typeWithParameters mixins? interfaces? LBRACE
         enumEntry (',' enumEntry)* (',')?
         (';' (metadata classMemberDeclaration)*)?
         RBRACE
    ;

enumEntry
    :    metadata AUGMENT? identifier argumentPart?
    |    metadata AUGMENT? identifier typeArguments?
         '.' identifierOrNew arguments
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
    :    patternAssignment
    |    functionExpression
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
    |    SUPER argumentPart
    |    functionPrimary
    |    literal
    |    identifier
    |    newExpression
    |    constObjectExpression
    |    constructorInvocation
    |    '(' expression ')'
    |    constructorTearoff
    |    switchExpression
    ;

constructorInvocation
    :    typeName typeArguments '.' NEW arguments
    |    typeName '.' NEW arguments
    ;

literal
    :    nullLiteral
    |    booleanLiteral
    |    numericLiteral
    |    stringLiteral
    |    symbolLiteral
    |    setOrMapLiteral
    |    listLiteral
    |    recordLiteral
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

setOrMapLiteral
    :    CONST? typeArguments? LBRACE elements? RBRACE
    ;

listLiteral
    :    CONST? typeArguments? '[' elements? ']'
    ;

recordLiteral
    :    CONST? recordLiteralNoConst
    ;

recordLiteralNoConst
    :    '(' ')'
    |    '(' expression ',' ')'
    |    '(' label expression ','? ')'
    |    '(' recordField (',' recordField)+ ','? ')'
    ;

recordField
    :    label? expression
    ;

elements
    :    element (',' element)* ','?
    ;

element
    :    nullAwareExpressionElement
    |    nullAwareMapElement
    |    expressionElement
    |    mapElement
    |    spreadElement
    |    ifElement
    |    forElement
    ;

nullAwareExpressionElement
    :    '?' expression
    ;

nullAwareMapElement
    :    '?' expression ':' '?'? expression
    |    expression ':' '?' expression
    ;

expressionElement
    :    expression
    ;

mapElement
    :    expression ':' expression
    ;

spreadElement
    :    ('...' | '...?') expression
    ;

ifElement
    :    ifCondition element (ELSE element)?
    ;

forElement
    :    AWAIT? FOR '(' forLoopParts ')' element
    ;

constructorTearoff
    :    typeName typeArguments? '.' NEW
    ;

switchExpression
    :    SWITCH '(' expression ')'
         LBRACE (switchExpressionCase (',' switchExpressionCase)* ','?)? RBRACE
    ;

switchExpressionCase
    :    guardedPattern '=>' expression
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
    :    '=>' { _startNonAsyncFunction(); } expression { _endFunction(); }
    |    ASYNC '=>' { _startAsyncFunction(); } expression { _endFunction(); }
    ;

functionExpressionWithoutCascade
    :    formalParameterPart functionExpressionWithoutCascadeBody
    ;

functionExpressionWithoutCascadeBody
    :    '=>' { _startNonAsyncFunction(); }
         expressionWithoutCascade { _endFunction(); }
    |    ASYNC '=>' { _startAsyncFunction(); }
         expressionWithoutCascade { _endFunction(); }
    ;

functionPrimary
    :    formalParameterPart functionPrimaryBody
    ;

functionPrimaryBody
    :    { _startNonAsyncFunction(); } block { _endFunction(); }
    |    (ASYNC | ASYNC '*' | SYNC '*')
         { _startAsyncFunction(); } block { _endFunction(); }
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
    :    argument (',' argument)*
    ;

argument
    :    label? expression
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
    |    typeArguments
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

identifier
    :    IDENTIFIER
    |    builtInIdentifier
    |    otherIdentifier
    |    { _asyncEtcPredicate() }? (AWAIT|YIELD)
    ;

qualifiedName
    :    typeIdentifier '.' identifierOrNew
    |    typeIdentifier '.' typeIdentifier '.' identifierOrNew
    ;

typeIdentifierNotType
    :    IDENTIFIER
    |    DYNAMIC // Built-in identifier that can be used as a type.
    |    otherIdentifierNotType // Occur in grammar rules, are not built-in.
    |    { _asyncEtcPredicate() }? (AWAIT|YIELD)
    ;

typeIdentifier
    :    typeIdentifierNotType
    |    TYPE
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

pattern
    :    logicalOrPattern
    ;

logicalOrPattern
    :    logicalAndPattern ('||' logicalAndPattern)*
    ;

logicalAndPattern
    :    relationalPattern ('&&' relationalPattern)*
    ;

relationalPattern
    :    (equalityOperator | relationalOperator) bitwiseOrExpression
    |    unaryPattern
    ;

unaryPattern
    :    castPattern
    |    nullCheckPattern
    |    nullAssertPattern
    |    primaryPattern
    ;

primaryPattern
    :    constantPattern
    |    variablePattern
    |    parenthesizedPattern
    |    listPattern
    |    mapPattern
    |    recordPattern
    |    objectPattern
    ;

castPattern
    :    primaryPattern AS type
    ;

nullCheckPattern
    :    primaryPattern '?'
    ;

nullAssertPattern
    :    primaryPattern '!'
    ;

constantPattern
    :    booleanLiteral
    |    nullLiteral
    |    '-'? numericLiteral
    |    stringLiteral
    |    symbolLiteral
    |    identifier
    |    qualifiedName
    |    constObjectExpression
    |    CONST typeArguments? '[' elements? ']'
    |    CONST typeArguments? LBRACE elements? RBRACE
    |    CONST '(' expression ')'
    ;

variablePattern
    :    (VAR | FINAL | FINAL? type)? identifier
    ;

parenthesizedPattern
    :    '(' pattern ')'
    ;

listPattern
    :    typeArguments? '[' listPatternElements? ']'
    ;

listPatternElements
    :    listPatternElement (',' listPatternElement)* ','?
    ;

listPatternElement
    :    pattern
    |    restPattern
    ;

restPattern
    :    '...' pattern?
    ;

mapPattern
    :    typeArguments? LBRACE mapPatternEntries? RBRACE
    ;

mapPatternEntries
    :    mapPatternEntry (',' mapPatternEntry)* ','?
    ;

mapPatternEntry
    :    expression ':' pattern
    |    '...'
    ;

recordPattern
    :    '(' patternFields? ')'
    ;

patternFields
    :    patternField (',' patternField)* ','?
    ;

patternField
    :    (identifier? ':')? pattern
    ;

objectPattern
    :    (typeName typeArguments? | typeNamedFunction) '(' patternFields? ')'
    ;

patternVariableDeclaration
    :    outerPatternDeclarationPrefix '=' expression
    ;

outerPattern
    :    parenthesizedPattern
    |    listPattern
    |    mapPattern
    |    recordPattern
    |    objectPattern
    ;

outerPatternDeclarationPrefix
    :    (FINAL | VAR) outerPattern
    ;

patternAssignment
    :    outerPattern '=' expression
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
    |    metadata patternVariableDeclaration ';'
    ;

initializedVariableDeclaration
    :    declaredIdentifier ('=' expression)? (',' initializedIdentifier)*
    ;

localFunctionDeclaration
    :    metadata functionSignature functionBody
    ;

ifStatement
    :    ifCondition statement (ELSE statement)?
    ;

ifCondition
    :    IF '(' expression (CASE guardedPattern)? ')'
    ;

forStatement
    :    AWAIT? FOR '(' forLoopParts ')' statement
    ;

forLoopParts
    :    forInLoopPrefix IN expression
    |    forInitializerStatement expression? ';' expressionList?
    ;

forInLoopPrefix
    :    metadata declaredIdentifier
    |    metadata outerPatternDeclarationPrefix
    |    identifier
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
    :    SWITCH '(' expression ')'
         LBRACE switchStatementCase* switchStatementDefault? RBRACE
    ;

switchStatementCase
    :    label* CASE guardedPattern ':' statements
    ;

guardedPattern
    :    pattern (WHEN expression)?
    ;

switchStatementDefault
    :    label* DEFAULT ':' statements
    ;

rethrowStatement
    :    RETHROW ';'
    ;

tryStatement
    :    TRY block (onPart+ finallyPart? | finallyPart)
    ;

onPart
    :    catchPart block
    |    ON typeNotVoid catchPart? block
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
    :    metadata libraryNameBody ';'
    ;

libraryNameBody
    :    LIBRARY dottedIdentifierList?
    |    AUGMENT LIBRARY uri
    ;

dottedIdentifierList
    :    identifier ('.' identifier)*
    ;

importOrExport
    :    libraryImport
    |    libraryAugmentImport
    |    libraryExport
    ;

libraryImport
    :    metadata importSpecification
    ;

libraryAugmentImport
    :    metadata IMPORT AUGMENT uri ';'
    ;

importSpecification
    :    IMPORT configurableUri (DEFERRED? AS typeIdentifier)? combinator* ';'
    ;

combinator
    :    SHOW identifierList
    |    HIDE identifierList
    ;

identifierList
    :    identifier (',' identifier)*
    ;

libraryExport
    :    metadata EXPORT configurableUri combinator* ';'
    ;

partDirective
    :    metadata PART configurableUri ';'
    ;

partHeader
    :    metadata PART OF uri ';'
    ;

partDeclaration
    :    FEFF? partHeader
         importOrExport*
         partDirective*
         (metadata topLevelDefinition)*
         EOF
    ;

uri
    :    stringLiteral
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
    |    recordType '?'?
    |    typeNotVoidNotFunction '?'?
    ;

typeNotFunction
    :    typeNotVoidNotFunction '?'?
    |    recordType '?'?
    |    VOID
    ;

typeNamedFunction
    :    (typeIdentifier '.')? FUNCTION
    ;

typeNotVoidNotFunction
    :    typeName typeArguments?
    |    typeNamedFunction
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

recordType
    :    '(' ')'
    |    '(' recordTypeFields ',' recordTypeNamedFields ')'
    |    '(' recordTypeFields ','? ')'
    |    '(' recordTypeNamedFields ')'
    ;

recordTypeFields
    :    recordTypeField (',' recordTypeField)*
    ;

recordTypeField
    :    metadata type identifier?
    ;

recordTypeNamedFields
    :    LBRACE recordTypeNamedField (',' recordTypeNamedField)* ','? RBRACE
    ;

recordTypeNamedField
    :    metadata typedIdentifier
    ;

typeNotVoidNotFunctionList
    :    typeNotVoidNotFunction (',' typeNotVoidNotFunction)*
    ;

typeAlias
    :    AUGMENT? TYPEDEF typeWithParameters '=' type ';'
    |    AUGMENT? TYPEDEF functionTypeAlias
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
    :    (functionTypeTail '?'?)* functionTypeTail
    ;

functionType
    :    typeNotFunction? functionTypeTails
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
    :    metadata typedIdentifier
    |    metadata type
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
    :    metadata REQUIRED? typedIdentifier
    ;

typedIdentifier
    :    type identifier
    ;

constructorDesignation
    :    typeIdentifier
    |    qualifiedName
    |    typeName typeArguments ('.' identifierOrNew)?
    ;

symbolLiteral
    :    '#' (operator | (identifier ('.' identifier)*) | VOID)
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

reservedWord
    :    ASSERT
    |    BREAK
    |    CASE
    |    CATCH
    |    CLASS
    |    CONST
    |    CONTINUE
    |    DEFAULT
    |    DO
    |    ELSE
    |    ENUM
    |    EXTENDS
    |    FALSE
    |    FINAL
    |    FINALLY
    |    FOR
    |    IF
    |    IN
    |    IS
    |    NEW
    |    NULL
    |    RETHROW
    |    RETURN
    |    SUPER
    |    SWITCH
    |    THIS
    |    THROW
    |    TRUE
    |    TRY
    |    VAR
    |    VOID
    |    WHILE
    |    WITH
    ;

builtInIdentifier
    :    ABSTRACT
    |    AS
    |    AUGMENT
    |    COVARIANT
    |    DEFERRED
    |    DYNAMIC
    |    EXPORT
    |    EXTENSION
    |    EXTERNAL
    |    FACTORY
    |    FUNCTION
    |    GET
    |    IMPLEMENTS
    |    IMPORT
    |    INTERFACE
    |    LATE
    |    LIBRARY
    |    OPERATOR
    |    MIXIN
    |    PART
    |    REQUIRED
    |    SET
    |    STATIC
    |    TYPEDEF
    ;

otherIdentifierNotType
    :    ASYNC
    |    BASE
    |    HIDE
    |    OF
    |    ON
    |    SEALED
    |    SHOW
    |    SYNC
    |    WHEN
    ;

otherIdentifier
    :    otherIdentifierNotType
    |    TYPE
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
    :    ('e' | 'E') ('+' | '-')? DIGITS
    ;

fragment
DIGITS
    : DIGIT ('_'* DIGIT)*
    ;

fragment
HEX_DIGIT
    :    ('a' | 'b' | 'c' | 'd' | 'e' | 'f')
    |    ('A' | 'B' | 'C' | 'D' | 'E' | 'F')
    |    DIGIT
    ;

fragment
HEX_DIGITS
    :    HEX_DIGIT ('_'* HEX_DIGIT)*
    ;

// Reserved words (if updated, update `reservedWord` as well).

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

// Built-in identifiers (if updated, update `builtInIdentifier` as well).

ABSTRACT
    :    'abstract'
    ;

AS
    :    'as'
    ;

AUGMENT
    :    'augment'
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

// Other words used in the grammar (if updated, update `otherIdentifier`, too).

ASYNC
    :    'async'
    ;

BASE
    :    'base'
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

SEALED
    :    'sealed'
    ;

SHOW
    :    'show'
    ;

SYNC
    :    'sync'
    ;

TYPE
    :    'type'
    ;

WHEN
    :    'when'
    ;

// Lexical tokens that are not words.

NUMBER
    :    DIGITS ('.' DIGITS)? EXPONENT?
    |    '.' DIGITS EXPONENT?
    ;

HEX_NUMBER
    :    '0x' HEX_DIGITS
    |    '0X' HEX_DIGITS
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
    :    '\'' STRING_CONTENT_SQ* '${' { _enterBraceSingleQuote(); }
    ;

SINGLE_LINE_STRING_SQ_MID_MID
    :    { _currentBraceLevelSingleQuote() }?
         { _exitBrace(); } '}' STRING_CONTENT_SQ* '${'
         { _enterBraceSingleQuote(); }
    ;

SINGLE_LINE_STRING_SQ_MID_END
    :    { _currentBraceLevelSingleQuote() }?
         { _exitBrace(); } '}' STRING_CONTENT_SQ* '\''
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
    :    '"' STRING_CONTENT_DQ* '${' { _enterBraceDoubleQuote(); }
    ;

SINGLE_LINE_STRING_DQ_MID_MID
    :    { _currentBraceLevelDoubleQuote() }?
         { _exitBrace(); } '}' STRING_CONTENT_DQ* '${'
         { _enterBraceDoubleQuote(); }
    ;

SINGLE_LINE_STRING_DQ_MID_END
    :    { _currentBraceLevelDoubleQuote() }?
         { _exitBrace(); } '}' STRING_CONTENT_DQ* '"'
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
         { _enterBraceThreeSingleQuotes(); }
    ;

MULTI_LINE_STRING_SQ_MID_MID
    :    { _currentBraceLevelThreeSingleQuotes() }?
         { _exitBrace(); } '}' STRING_CONTENT_TSQ* QUOTES_SQ '${'
         { _enterBraceThreeSingleQuotes(); }
    ;

MULTI_LINE_STRING_SQ_MID_END
    :    { _currentBraceLevelThreeSingleQuotes() }?
         { _exitBrace(); } '}' STRING_CONTENT_TSQ* '\'\'\''
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
         { _enterBraceThreeDoubleQuotes(); }
    ;

MULTI_LINE_STRING_DQ_MID_MID
    :    { _currentBraceLevelThreeDoubleQuotes() }?
         { _exitBrace(); } '}' STRING_CONTENT_TDQ* QUOTES_DQ '${'
         { _enterBraceThreeDoubleQuotes(); }
    ;

MULTI_LINE_STRING_DQ_MID_END
    :    { _currentBraceLevelThreeDoubleQuotes() }?
         { _exitBrace(); } '}' STRING_CONTENT_TDQ* '"""'
    ;

LBRACE
    :    '{' { _enterBrace(); }
    ;

RBRACE
    :    { _currentBraceLevelNormal() }? { _exitBrace(); } '}'
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
