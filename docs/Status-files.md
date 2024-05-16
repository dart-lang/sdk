> [!IMPORTANT]
> This page was copied from https://github.com/dart-lang/sdk/wiki and needs review.
> Please [contribute](../CONTRIBUTING.md) changes to bring it up-to-date -
> removing this header - or send a CL to delete the file.

---

Stability is important for a programming language used to implement applications
that [manage billions of dollars](http://news.dartlang.org/2016/03/the-new-adwords-ui-uses-dart-we-asked.html). To that end, the Dart repository contains a
comprehensive test suite to cover the various configurations, compilers, tools,
and runtimes we maintain and support.

We have tens of thousands of tests and a single test may be run across a
combinatorial explosion of configurations. Does the static analyzer report any
errors on it? In strong mode? Does it run on the standalone VM? Can dart2js
compile it? Does the resulting code run in Chrome? Firefox? IE? In checked mode?
With minification on? You get the idea.

Many tests are only meaningful for certain combinations of configurations. A
test that uses "dart:io" is, by design, not going to run in a browser which
doesn't have access to the local file system. Some bleeding edge web features
aren't fully supported across all browsers. As we ramp up new tools, parts of
our own stack may not be passing all tests.

So, for all of these tests, we need to track not just the test itself, but it's
*status* -- what the expected outcome of the test is on various configurations.
This status information lives (mostly) outside of the tests in separate "status
files" with a ".status" extension.

This document explains the format of those files and how the test runner
interprets them.

## Outcomes and expectations

The test runner's main job, as you'd imagine, is to run tests. This sometimes
involves invoking a compiler, and then spawning another process to execute the
test itself. That process then may or may not complete successfully.

The test runner monitors this and tracks the various ways it can go wrong.
Each of these outcomes has a canonical name. Things like:

- **Pass** – The runtime exited with exit code zero.
- **CompileTimeError** – The compiler exited with a non-zero exit code.
- **RuntimeError** – The runtime exited with a non-zero exit code.

There are other, more exotic outcomes. For the full list of them, see the code:

[pkg/status_file/lib/expectation.dart](https://github.com/dart-lang/sdk/blob/master/pkg/status_file/lib/expectation.dart)

In a perfect world, every test would pass in every configuration and the test
runner could simplify verify that every test's outcome was "Pass". Alas, life is
complicated. The status files keep track of what the *expected* outcome of each
test is, which is why these outcomes are usually referred to as "expectations".

A test that ends with a runtime error is a successful test if the status file
says we *expect* to get a runtime error. The test fails if no runtime error
occurred.

## Status files

Status files define the expectations for the tests by combining three facets:

* What are the expected outcomes...
* ...for which tests...
* ...under which configurations.

It's a bit like [Clue][]'s "Miss Scarlett, in the library, with the revolver."
The status file says something like "'math/low_test', when compiled using
dart2js, should produce a CompileError".

[clue]: https://en.wikipedia.org/wiki/Cluedo

With miles of tests and piles of configurtions, we need a compact notation for
defining expectations. That's what status files aim to be.

A status file is a line-oriented (newlines are significant) plain text file.
Comments start with `#` and continue to the end of the line. Blank lines are
ignored.

### Sections

Each status file consists of a list of **sections**. Each section starts with a
**header**, followed by one or more **entries**. (Entries at the top of the file
above any header go into an implicit header-less section.)

Sections have no relation to each other and the order does not matter.

### Headers

The header defines which configurations its entries apply to. It lets you
specify the conditions under which a set of expectations come into play. The
header contains an expression made up of accesses to various configuration
variables. It's evaluated against the current configuration's values for those
variables. If the expression evaluates to true, the section is applied and its
entries are used. Otherwise, its entries are ignored.

If there are entries in the implicit first headerless section, the condition is
always considered to be true and the entries are always applied.

Arbitarily large expressions are supported, but the larger they are, the harder
it is for your fellow teammates to understand what outcomes are expected for a
given configuration.

Here's a complex example:

```text
[ $compiler == dart2js && ( $browser || $runtime == d8 ) ]
```

The expression is contained in square brackets. Since we all love EBNF, the
grammar for the expression inside is:

```text
expression := or
or         := and ( "||" and )*
and        := primary ( "&&" primary )*
primary    := "$" identifier ( "==" | "!=" ) identifier |
              "!"? "$" identifier |
              "(" expression ")"
identifier := regex "\w+"
```

There are a few different expression forms:

*   **Variable** – This looks up the value of some configuration option like
    `$runtime` for which execution environment the test will be run in or
    `$strong` for whether the test is run in strong mode. Variables are always
    prefixed by `$`.

    If the variable is a Boolean, you use it as a bare identifier like `$strong`
    or `$checked`. It may be prefixed with `!` to negate its value, so `!
    $checked` evaluates to true if the test is run in unchecked mode.

    Non-Boolean variables accept one of an enumerated set of values. The set of
    values depends on the variable. For example, `$mode` can be `debug`,
    `release`, or `product`. To use one of these, it must be followed by `==` or
    `!=` and the value being tested. Examples:

    ```text
    $runtime == vm
    $mode != debug
    ```

    Note that unlike variables, values are not prefixed with `$`. Note also
    that the equality operator and value is part of the variable expression
    itself. You can't do something like: `$mode == $runtime`. You always have
    to test against a literal value.

    The set of variables that are available in status file expressions is baked
    into test.dart. You can see the full list of them here:

    [tools/testing/dart/environment.dart](https://github.com/dart-lang/sdk/blob/master/tools/testing/dart/environment.dart#L13)

    For each variable, test.dart also knows all of the values that are allowed
    for it. It uses this to validate these expressions at parse time. If you
    misspell a variable, like `$compile` or test it against a value it can't
    have like `$runtime == dart2js` (dart2js is a compiler, not a runtime), it
    reports an error.

*   **Logical operators** - You can join two subexpressions using `||` or `&&`,
    with their usual meaning. `&&` has higher precedence than `||`.

*   **Parentheses** – If you want a `||` expression to be an operand to a `&&`
    expression, you can explicitly parenthesize.

Here are some examples:

```text
[ ! $checked ]
```

This section applies only when not running the test in checked mode.

```text
[ $arch == simarm || $arch == simarmv6 || $arch == simarmv5te ]
```

This section applies only on various ARM simulator architectures.

```text
[ $checked && ($compiler == dartk || $compiler == dartkp) ]
```

This section applies if the test is running in checked mode and using either of
two Kernel compilers.

```text
[ $compiler != dart2js ]
```

This section applies for any compiler except dart2js.

### Entries

After the header, a section contains a list of entries. Each entry defines a
glob-like path that matches a set of test files. Then it specifies the set of
allowed outcomes for those tests.

For example:

```
typed_data/int64_list_load_store_test: RuntimeError # Issue 10275
```

The syntax is a path, followed by `:`, followed by a comma-separated list of
expectation names. It's a good idea to have a comment explaining why the test(s)
have this expectation. If the expectation is because the test should be passing
but isn't, the comment usually mentions the relevant issue number.

Here, it says the "int64_list_load_store_test" is failing at runtime because of
some bug we should fix.

The path string is relative to the directory containing the status file. Note
that paths do not have ".dart" extensions, even when they only match a single
file (which is the normal case). You can also use `*` like a glob to match part
of a path component as in:

```text
async/*deferred*: Pass,RuntimeError # Issue 17458
```

This matches any test inside the "async" directory whose name contains
"deferred". If you want an entry that matches every single test in the directory
containing the status file, use:

```text
*: Skip # Issue 28649
```

## Applying status files

The trickiest part of status files is that the same test may be matched by
multiple entries in different sections, potentially spread across different
status files. These entries may apply and overlap in some configurations but not
in others. For example, the status file for the corelib tests has five sections
with entries that all match "async/multiple_timer_test" (I removed other
unrelated entries here):

```text
[ $compiler == dart2js && $runtime == jsshell ]
async/multiple_timer_test: RuntimeError,OK # Needs Timer to run.

[ $runtime == vm && $system == fuchsia ]
async/multiple_timer_test: RuntimeError

[ $compiler == none && ($runtime == drt || $runtime == dartium) ]
async/multiple_timer_test: Fail, Pass # Issue 15487

[ $compiler == none && $runtime == drt && $system == windows ]
async/multiple_timer_test: Fail, Pass # See Issue 10982

[ $hot_reload || $hot_reload_rollback ]
async/multiple_timer_test: Pass, Fail # Timing related
```

Many of these sections are disjoint so that if one applies, another won't, but
not all of them are. For example, if you're running on Fuchsia on the VM with
hot reload enabled, the second and last sections both apply. They have different
expectations. So what does test.dart expect this test to do?

When there are multiple sets of expectations for the same file, test.dart unions
all of the sets together. So, in this case, the resulting expectation is
"RuntimeError, Pass, Fail".

A test succeeds if the outcome is *any* of the expectations. Here, that
basically means the test is going to succeed no matter what as long as it
doesn't crash or timeout or something.

If no entries match a given file, the default expectation is "Pass". That means
you only need to mention a file in a status file if it doesn't pass in at least
one configuration.

## Special expectations

Some "expectations" don't line up with actual possible test outcomes. Instead,
they affect how the test runner works or have another purpose. A couple of
important ones are:

*   **Skip** and **SkipByDesign** – These tell test.dart to not run the test at
    all. The latter is OK, it means "this behavior isn't relevant for this
    configuration". For example, Dartium doesn't support "dart:io", so the
    status file says:

    ```text
    [ $compiler == none && ($runtime == drt || $runtime == dartium) ]
    io/*: SkipByDesign # Don't run tests using dart:io in the browser
    ```

    The "Skip" expectation is older and should be avoided, since it doesn't
    convey *why* the test is being skipped.

*   **OK** isn't a real expectation. It's more like a comment for a reader of
    the status file to know the behavior is intentional and desired. For
    example:

    ```text
    [ $compiler == dart2js && $runtime == jsshell ]
    async/timer_cancel_test: RuntimeError,OK # Needs Timer to run.
    ```

    jsshell doesn't support Times, so we never expect this test to pass.

There are some other special expectations, documented in the source here:

[/pkg/status_file/lib/expectation.dart](https://github.com/dart-lang/sdk/blob/master/pkg/status_file/lib/expectation.dart)
