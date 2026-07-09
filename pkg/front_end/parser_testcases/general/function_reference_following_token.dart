// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// The test cases called `typeArgs_...` verify that `<` and `>` are treated as
// delimiting type arguments when the `>` is followed by one of the tokens:
//
//     ( . == != ) ] } ; : ,

var typeArgs_closeBrace = {f<a, b>};
var typeArgs_closeBracket = [f<a, b>];
var typeArgs_closeParen = g(f<a, b>);
var typeArgs_colon = {f<a, b>: null};
var typeArgs_comma = [f<a, b>, null];
var typeArgs_equals = f<a, b> == null;
var typeArgs_not_equals = f<a, b> != null;

// This is a special case because when a `(` follows `<typeArguments>` it is
// parsed as a MethodInvocation rather than a GenericInstantiation.
var typeArgs_openParen = f<a, b>();

// This is a special case because `f<a, b>.methodName(...)` is parsed as an
// InstanceCreationExpression.
var typeArgs_period_methodInvocation = f<a, b>.toString();

var typeArgs_period_methodInvocation_generic = f<a, b>.foo<c>();
var typeArgs_period_propertyAccess = f<a, b>.hashCode;

var typeArgs_semicolon = f<a, b>;

// The test cases called `operators_...` verify that `<` and `>` are treated as
// operators when the `>` is not followed by one of the tokens:
//
//     ( . == != ) ] } ; : ,
//
// Except as noted, these test cases should result in parse errors.

var operators_ampersand = f(a<b,c>&d);

// Note: this should not be a parse error since it is allowed to have an
// identifier called `as`.
var operators_as = f(a<b,c>as);

var operators_asterisk = f(a<b,c>*d);

// Note: this could never be a valid expression because the thing to the right
// of `!` is required to have type `bool`, and the type of `[d]` will always be
// a list type.  But it is not the responsibility of the parser to report an
// error here; that should be done by type analysis.
var operators_bang_openBracket = f(a<b,c>![d]);

// Note: this should not be a parse error since `c` could have a type that
// defines a `>` operator that accepts `bool`.
var operators_bang_paren = f(a<b,c>!(d));

var operators_bar = f(a<b,c>|d);
var operators_caret = f(a<b,c>^d);
var operators_is = f(a<b,c> is int);

// Note: in principle we could parse this as a generic instantiation of a
// generic instantiation, but since `<` is not one of the tokens that signals
// `<` and `>` to be treated as type argument delimiters, the first pair of `<`
// and `>` is treated as operators, and this results in a parse error.
var operators_lessThan = f<a><b>;

// Note: this should not be a parse error (indeed, this is valid if `a`, `b`,
// `c`, and `d` are all of type `num`).
var operators_minus = f(a<b,c>-d);

// Note: this should not be a parse error since `c` could have a type that
// defines a `>` operator that accepts `List`.
var operators_openBracket = f(a<b,c>[d]);

// Note: in principle we could parse `<b, c>` as type arguments, `[d]` as an
// index operation, and the final `>` as a greater-than operator, but since `[`
// is not one of the tokens that signals `<` and `>` to be treated as argument
// delimiters, the pair of `<` and `>` is treated as operators, and this results
// in a parse error.
var operators_openBracket_error = f(a<b,c>[d]>e);

// Note: this should not be a parse error since `c` could have a type that
// defines a `>` operator that accepts `List`.
var operators_openBracket_unambiguous = f(a<b,c>[d, e]);

var operators_percent = f(a<b,c>%d);
var operators_period_period = f(a<b,c>..toString());
var operators_plus = f(a<b,c>+d);
var operators_question = f(a<b,c> ? null : null);
var operators_question_period_methodInvocation = f(a<b,c>?.toString());
var operators_question_period_methodInvocation_generic = f(a<b,c>?.foo<c>());
var operators_question_period_period = f(a<b,c>?..toString());
var operators_question_period_propertyAccess = f(a<b,c>?.hashCode);
var operators_question_question = f(a<b,c> ?? d);
var operators_slash = f(a<b,c>/d);
var operators_tilde_slash = f(a<b,c>~/d);
