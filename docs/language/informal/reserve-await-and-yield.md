# Reserve "await" and "yield"

Author: Bob Nystrom (rnystrom@google.com)

Status: Under discussion

Most languages define a set of "reserved words". These are identifiers that are
used as keywords by the language *and can't be used for anything else*. Stuff
like `if` and `else`. You can't name a variable "if" in most languages.

Other identifiers act like keywords in some places but are otherwise free for
user use. In Dart, "hide" is one example. In an import directive, it is a
keyword:

```dart
import "library.dart" hide unwantedThing;
```

But you can use it yourself if you want:

```dart
class Button {
  void hide() { ... }
}

new Button().hide();
```

Dart has more of these "contextual keywords" than most languages:

```
abstract as async await covariant deferred export
external factory Function get hide implements
import library of on operator part set show static
sync typedef yield
```

The language designers initially chose to do this for a few reasons:

*   **It's more flexible.** Some keywords are really useful as identifiers and
    it would be annoying if they were unavailable. For example, Dart has a Set
    class, so it suck if you couldn't name a variable `set`. Likewise, it's
    pretty common to see methods named `get()`, fields named `part`, etc.

*   **It makes interop easier.** If Dart reserves a word that is a usable
    identifier in another language, it can make it harder to call a foreign
    method with that name. Dart was initially focused entirely on the web, so it
    does not reserve any words that aren't reserved in JavaScript.

As the language evolved, a third reason arose:

*   **It's backwards compatible.** Introducing a new reserved word after the
    language is out in the wild breaks existing uses of that word as an
    identifier. That's why most other languages grow contextual keywords over
    time.

There are some cons to contextual keywords, though:

*   **They are harder for users to understand.** Most programmers have a notion
    of "reserved words". They may not be familiar with contextual keywords. If
    they see one used as a keyword, they may not realize it can also be used
    as an identifier. Likewise, if they see it used as an identifier, they may
    be confused when they later see it treated like a keyword by the language.

*   **They are hard to support with simple parsers.** Many tools that work with
    Dart code don't use complete parsers for various reasons. In particular,
    syntax highlighters often don't do a full parse. Instead, they break the
    code into a flat sequence of tokens and use only local information to decide
    how to color each one. That means they don't have the nested tree structure
    neeeded to tell if a word like `on` is appearing in a catch clause and acts
    like a keyword or is used as an identifier elsewhere.

    The parsing framework, Grammar-Kit, used by the IntelliJ plug-in has
    problems handling them.

*   **It's harder to produce good error messages around them.** When an
    erroneous piece of code uses a contextual keyword, it may not be clear if
    the author was trying to use it as a keyword, or an identifier. Usually, a
    smart tool can guess correctly, but it's still a guess. The error message
    usually has to be worded to handle both cases, which tends to make it
    confusing.

## `await` and `yield`

The last two problems apply in particular to `await` and `yield`. Most
contextual keywords can be disambiguated using very local context. `hide` is
only a keyword when right inside an import directive. `of` is only a keyword if
it immediately follows `part` at the top level.

But `await` is a keyword if the surrounding method is declared `async`. That
modifier may be very far away from the use of `await`. The `yield` identifier is
similar for generator methods.

What makes this worse is that it is a very common error to forget the `async`
modifier when intending to write an asynchronous method. So the error message
around misusing `await` is both hard to write well and actually occurs very
often in practice.

The proposal is simple: Add `await` and `yield` to the list of reserved words.
It is a syntax error to use either as an identifier, even outside of async or
generator functions.

**This is a breaking change.** However, `await` and `yield` are rarely used as
identifiers, so the practical impact of the breakage is likely minimal. In a
corpus of 49,553 Dart files, including the Dart repository, Flutter, and the
latest versions of all packages on Pub, I found:

* 47,457 uses of `await` as a keyword.
* 14 uses of `await` as an identifier.
* 878 uses of `yield` as a keyword.
* 48 uses of `yield` as an identifier.
* 2,212 uses of `sync` as an identifier.
* 13,418,913 uses of any identifier.

In other words, 0.0001% of identifiers are `await` and 0.0003% are `yield`. A
random use of `await` is 3389 times more likely to be a keyword than an
identifier.

Even so, we may wish to roll this out as part of the transition to Dart 2.0.

## What about other contextual keywords?

That still leaves a long list of contextual keywords. Should we reserve any of
those while we're at it? The tools folks who requested we reserve `await` and
`yield` also requested `async`. However:

*   "async" is the name of a prominent Dart library, "dart:async". If we ever
    get a [syntax for imports that doesn't require a quoted string][import],
    that would cause problems if `async` was a reserved word.

*   "async" is more commonly used as an identifier than `await` and `yield`. I
    count 11,046 occurrences in the same corpus as above.

*   "async" appears in the exact same place as "sync" in the grammar, so it
    would be strange to reserve one without the other. Unfortunately, "sync"
    shows up as an identifier in some important places, such as `Future.sync()`.

[import]: https://github.com/dart-lang/sdk/issues/10018

We could consider reserving some of the other contextual keywords, but so far we
have not had any user or tool author requests to do so, so they don't seem to be
problematic.

## Suggested Spec Changes

### 20.1.1 Reserved Words

Add `await` and `yield` to the list of reserved words.

### 16.33 Identifier Reference

Remove this paragraph:

> It is a compile-time error if any of the identifiers `async`, `await` or
> `yield` is used as an identifier in a function body marked with either
> `async`, `async*` or `sync*`.

It's redundant for `await` and `yield` since they can't be used as identifiers
*anywhere*. For `async`, there's no real need to disallow it inside a function
body since it's unambiguous, even inside an asynchronous function.

## Appendix: Corpus scraper

Here's the little script I used to count the uses of the keywords and
identifiers:

```dart
import 'dart:io';

import 'package:analyzer/analyzer.dart';
import 'package:analyzer/src/generated/scanner.dart';
import 'package:analyzer/src/string_source.dart';
import 'package:analyzer/src/dart/scanner/reader.dart';
import 'package:analyzer/src/dart/scanner/scanner.dart';
import 'package:analyzer/src/generated/parser.dart';
import 'package:path/path.dart' as p;

final sourceDir = "/Users/rnystrom/dev/corpus/out";

var awaitExprs = 0;
var yieldStmts = 0;
var ids = 0;
var awaitIds = 0;
var yieldIds = 0;
var asyncIds = 0;
var syncIds = 0;

void main() {
  var readFiles = 0;

  for (var entry in new Directory(sourceDir).listSync(recursive: true)) {
    if (entry is File && entry.path.endsWith(".dart")) {
      // Skip tests since they bias towards weird uses.
      if (entry.path.contains("sdk/tests")) continue;

      readFiles++;
      parse(entry.readAsStringSync(), entry.path);

      if (readFiles % 100 == 0) {
        var relative = p.relative(entry.path, from: sourceDir);
        print(relative);
      }
    }
  }

  print("read $readFiles files");
  print("${awaitExprs.toString().padLeft(9)} await expressions");
  print("${yieldStmts.toString().padLeft(9)} yield statements");
  print("${ids.toString().padLeft(9)} identifiers");
  print("${awaitIds.toString().padLeft(9)} await identifiers");
  print("${yieldIds.toString().padLeft(9)} yield identifiers");
  print("${asyncIds.toString().padLeft(9)} async identifiers");
  print("${syncIds.toString().padLeft(9)} sync identifiers");
}

bool parse(String source, String path) {
  // Tokenize the source.
  var errorListener = new ErrorListener();
  var reader = new CharSequenceReader(source);
  var stringSource = new StringSource(source, path);
  var scanner = new Scanner(stringSource, reader, errorListener);
  var startToken = scanner.tokenize();

  // Parse it.
  var parser = new Parser(stringSource, errorListener);
  parser.enableAssertInitializer = true;
  var node = parser.parseCompilationUnit(startToken);
  if (errorListener.errors.isNotEmpty) return false;

  var visitor = new SourceVisitor();
  node.accept(visitor);
  return true;
}

/// A simple [AnalysisErrorListener] that just collects the reported errors.
class ErrorListener implements AnalysisErrorListener {
  final errors = <AnalysisError>[];

  void onError(AnalysisError error) {
    errors.add(error);
  }
}

class SourceVisitor extends RecursiveAstVisitor<Null> {
  Null visitAwaitExpression(AwaitExpression node) {
    super.visitAwaitExpression(node);
    awaitExprs++;
  }

  Null visitSimpleIdentifier(SimpleIdentifier node) {
    super.visitSimpleIdentifier(node);

    ids++;
    if (node.token.lexeme == "await") {
      awaitIds++;
    } else if (node.token.lexeme == "yield") {
      yieldIds++;
    } else if (node.token.lexeme == "async") {
      asyncIds++;
    } else if (node.token.lexeme == "sync") {
      syncIds++;
    }
  }

  Null visitYieldStatement(YieldStatement node) {
    super.visitYieldStatement(node);
    yieldStmts++;
  }
}
```