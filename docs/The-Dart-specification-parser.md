> [!IMPORTANT]
> This page was copied from https://github.com/dart-lang/sdk/wiki and needs review.
> Please [contribute](../CONTRIBUTING.md) changes to bring it up-to-date -
> removing this header - or send a CL to delete the file.

---

**Author**: eernst@

**Version**: 0.2

We have created a _Dart specification parser_, built on a grammar specification [Dart.g](https://github.com/dart-lang/sdk/blob/master/tools/spec_parser/Dart.g), which is transformed into a working parser by the tool [ANTLR](https://www.antlr.org/index.html), using a couple of helper files (in particular, [spec_parse.py](https://github.com/dart-lang/sdk/blob/master/tools/spec_parse.py) and [spec_parser](https://github.com/dart-lang/sdk/tree/master/tools/spec_parser)). This document gives a short introduction to what it is, and some motivations for why we have it, along with an outline of the consequences for the testing workflow when we have a specification parser.

## Motivation

One main **motivation** for having this specification parser is that we can use it to parse existing Dart source code. This allows us to verify that `Dart.g` **specifies the syntax** in a manner which is consistent and parseable, and which corresponds precisely to the language as it is **actually implemented** and used.

The other main **motivation** is that `Dart.g` is a mechanized and hence precise specification of the language syntax. This allows us to use `Dart.g` as a source of information about how to maintain the grammar rules in the [language specification](https://github.com/dart-lang/language/blob/master/specification/dartLangSpec.tex). The grammar rules in the language specification will never be a verbatim copy of the ones in `Dart.g`, because that is an ANTLR specification which necessarily contains a number of details that are specific to ANTLR, or otherwise accidental. However, `Dart.g` is still such a detailed source of trustworthy information that we expect it to be very **helpful in the maintenance of** the language **specification** grammar rules.

The grammar rules in the **language specification** should be **more abstract** than the ones in `Dart.g`. It is not even a problem if the grammar rules in the language specification are somewhat ambiguous, especially if this allows them to be significantly simpler and more readable. One justification for this is that grammar rules in a language specification may well be used for mentally constructing expressions, declarations, or other constructs, when the reader is thinking about how the language can be used to express a specific idea as software.

Grammar ambiguities must be resolved in order to enable (non-exotic) parsing, but derivation of snippets of code will work just fine, even when there are some ambiguities. Besides, those who seek **practical** solutions in relation to **Dart parsing** would be able to use `Dart.g` as a source of information about how it can be done.


## Testing: Now includes syntax errors

The Dart testing setup makes it possible to specify **multi-tests**, i.e., test libraries where certain lines are deleted or preserved according to the given labels. For instance, the following library will print "none" and "01" during subtest "01", "none" and "02" during subtest "02", and it will report a compile-time error (in Dart 2 and strong mode) in subtest "03", thus enabling one of the subtests at a time. Moreover, it will just print "none" in a separate run where none of the subtests are enabled, i.e., all the subtest specific lines are deleted. Here is the code:
```dart
main() {
  print("none");
  print("01"); //# 01: ok
  print("02"); //# 02: ok
  print("03" + new Map()); //# 03: compile-time error
}
```

Now that the Dart specification parser has been added to the toolset there is a **need** for one more expected **outcome**, namely `syntax error`:
```dart
main() {
  print("nothing because this fails to parse!"; //# 01: syntax error
}
```
Every tool other than the specification parser will consider `syntax error` to be an indication that the expected outcome for this subtest is a compile-time error, i.e., we might as well have written `//# 01: compile-time error`, for running tests with all those other tools.

However, the specification parser makes the distinction between syntax errors and other compile-time errors, because it does not perform any static analysis except syntax checking. This also means that any subtest outcome expectation which is a `compile-time error` (or any variant thereof which is _not_ `syntax error`) will be considered to mean "expect no errors" by the specification parser. So we will both detect unexpected syntax errors (when the specification parser detects an error, but the expected outcome is not `syntax error`) and unexpectedly missing syntax errors (when the specification parser parses the test library successfully, but the expected subtest outcome is `syntax error`).

This means that multi-tests should be written and maintained such that **syntax errors** are **indicated as such**, and other compile-time errors are indicated as `compile-time error` (or `checked mode compile-time error`, or whatever other variant that may be available and appropriate).

It will not (yet) produce failing **buildbot** runs to continue to use `compile-time error` everywhere as we have done until now, because the specification parser is not (yet) running on a buildbot.

However, it is likely to be **useful to make the distinction** anyway, because it will typically destroy the ability of a test to test the right thing if it contains a syntax error that the developer did not intend to write. In particular, a `compile-time error` may be reported as expected, but it never tests the type error or similar phenomenon which was intended, because the static analysis fails already in the parser. This may then masquerade as a successful test for months, and everybody thinks that the test works as intended. This does occur, by the way: I fixed several of these issue while doing this work.

At this point (November 2017) I would **recommend using a best effort approach**, and simply marking those subtests as `syntax error` which are intended to be syntax errors. These marks will be adjusted as needed before the specification parser runs on a main waterfall buildbot, which may not happen at all, and in any case will not happen right now.

It should be noted that **every Dart tool** (except the specification parser) **is free to redistribute error detection from the parser to other parts of the static analysis, and vice versa**. This means that that certain things which are syntax errors according to `Dart.g` are detected later on in the static analysis of some tool, or certain things which are not syntax errors according to `Dart.g` will be rejected by the parser in some tool. This does not create any conflicts, because all other tools than the specification parser should continue to report all compile-time errors as compile-time errors, no matter whether they are detected by the parser or by some other part of static analysis, and the testing framework (`test.py`) will consider the test run as successful as long as each tool (except the specification parser) reports a compile-time error in a subtest which has any of the expectations `syntax error`, `compile-time error`, or any of its variants. In other words, each tool which is not the specification parser should not make an attempt to detect and report syntax errors separately (they should be considered as compile-time errors, as they have been until now), and in particular _it should not be considered to be a bug if such tools report a certain expected `syntax error` as a non-syntax compile-time error, or vice versa_.


## Use

If you need to use the specification parser, or you're just curious, there is support for running it, in some situations. In particular, it is not yet possible to build it using `tools/build.py`, and it may not work on all platforms.

On a Linux host where the ANTLR library is available at `/usr/share/java/antlr4-runtime.jar`, the specification parser can be generated with the command `make parser` in `tools/spec_parser`, and it may then be invoked as `tools/spec_parse.py <files-to-parse>...` (or with `some/other/path/tools/spec_parse.py` from some other directory, or via the `PATH`, etc.).

Support for building the specification parser using `tools/build.py` or `tools/ninja.py` and on all platforms will be implemented.

For test runs involving multi-tests it is necessary to use `tools/test.py` (as always, because a multi-test is generally full of syntax errors until it has been processed by `tools/test.py`). Here is an example invocation:
```
> tools/test.py -c spec_parser language_2/variable
[00:05 | 100% | +  137 | -    0]
>
```
