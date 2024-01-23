# Coding style

This document is a place to record information about the coding style that's
currently being used by the developers of the analyzer packages (the
`analysis_server`, `analyzer`, `analyzer_plugin`, `analyzer_utilities`,
`dartdoc`, `linter`, and `markdown` packages). As such, it's subject to change
as the language evolves and as our experience dictates.

The document is divided into three main sections covering the coding styles we
- have decided to follow,
- are currently discussing, and
- have decided not to enforce.

Our goal is to make as much as possible of the style be automatically enforced,
either through lints or tests, but this document also includes style choices
that can't reasonably be enforced automatically.

## Styles we're following

This section documents the styles we have agreed to follow.

### Lint rules

- `flutter_style_todos` - Keeps our todo format canonical.
- `prefer_single_quotes` - We don't enforce this in each of our packages yet, but
  we aspire to.
- `unnecessary_breaks` - All our packages require at least Dart `3.0.0`, so we
  can do it.

### Formatting and sorting

All of our source code is expected to be
- formatted by the `dart format` command, and
- sorted according to the Sort Members command (available in IDEs).

(With the exception that we don't sort in either the `dartdoc` or `markdown`
packages.)

Formatting is enforced by presubmit and sorting is enforced by tests. We
recommend that you enable both the formatter and the Sort Members command to be
run on save, at least within our packages.

### Naming conventions

We generally follow the naming conventions from the Dart style guide. We do have
some legacy code that uses screaming caps for constant names, but newer code
doesn't use that style for constants.

#### Import prefixes

The Dart style guide doesn't explicitly specify a naming convention for import
prefixes beyond the guidance to use snake case. (See
https://dart.dev/effective-dart/style#do-name-import-prefixes-using-lowercase_with_underscores).

However, the examples in the style guide all use the name of the file with the
`.dart` suffix removed. That's the standard we follow, with the exception that
we also drop `_test.dart` for test files. That includes using the prefix `path`
for the path package, even though it's a commonly used variable name. In code
where there's a conflict, we prefix the variable name with an adjective to form
a unique name, such as `filePath`.

#### Extensions

Public extensions (which are intended to be accessible outside their declaring
library) are named in a consistent style. An extension on a type `Foo` is
named `FooExtension`. An extension on a nullable type `Foo?` uses the word
"Nullable" in place of the question mark, like `FooNullableExtension`. While
this can lead to long names (like `AnalysisOptionsImplExtension`), the
extension name is rarely used (only in explicit extension overrides), and we
value consistency.

### Modifier usage

#### Local variables

We use `var` to declare local variables with two exceptions:

- We use a type annotation if the type of the variable would be incorrectly
  inferred without it, such as when a variable that needs to be nullable would
  be inferred to be non-nullable because it's initialized to a non-null value.

- We use `final` if the local variable shadows a field and is being used to
  allow the type of the field to be promoted.

## Styles we're discussing

This section documents the styles we are currently discussing. The purpose
is to capture the state of the discussions so that we don't forget what we've
already discussed.

### Lint rules

For historic reasons we have enabled some of the lint rules in the [core][core]
and [recommended][recommended] rule sets, but some have been disabled in various
packages.

[core]:https://github.com/dart-lang/lints/blob/main/lib/core.yaml
[recommended]:https://github.com/dart-lang/lints/blob/main/lib/recommended.yaml

In addition, there are lint rules outside those sets that are enabled in some
packages but not in all packages.

All of these lint rules need to be discussed, and descriptions will be added as
discussions occur.

### Other style guidelines

#### No new null-asserts

There is a proposal to disallow any new uses of the unary null-assert operator
(`!`). Use of the operator is generally undesirable because if the value of the
operand is `null` an exception will be thrown.

The biggest concern is with the fact that we have some nullable properties that
can't be made non-nullable (because of limitations in the type system) but that
are known to be non-nullable in practice. The most obvious examples of this are
`Token.next` and `Token.previous`. We routinely use the null-assert operator in
those cases.

A similar case is `Expression.staticType` where we know that the type will be
non-null after resolution, but there we've wrapped the null check in an
extension getter named `typeOrThrow`. We could use this as a convention to
signal that we've decided that the possibility of an exception is rare.

It has also been suggested that it might be better, however, to just use `!` to
signal those cases, and to only disallow the operator in cases where we don't
think the exception will be rare. That might have the advantage of making the
presence of the check (and possibility of an exception) more explicit in the
code.

We might want to allow this in tests, where the null-assert becomes another form
of expectation.

#### No new type casts

There is a proposal to disallow any new uses of type casts, with two exceptions:
when using `covariant` and where there isn't any other reasonable way.

There's concern about using `covariant` other than in places where we know it to
be safe (for example, the `AstNode` hierarchy is designed in such a way that
it's safe to use `covariant` if the covariant type is the `Impl` type of the
overridden method).

The second exclusion is not well defined. We probably need to clarify what cases
we would allow so we know that the style can be consistently applied.

There's also speculation that we might want to not impose this restriction in
test code because using type casts is effectively equivalent to an expectation
but with the advantage that the type of the variable can be promoted.

## Styles we're not following

This section documents the styles that we've explicitly decided we're not going
to follow. For each style there should be a description of why the decision was
made. The purpose is to know when circumstances have changed enough that it
might be worth reconsidering.

### Lint rules

TBD

### Other style guidelines

TBD
