# Scrape

The scrape package is sort of a micro-framework to make it easier to write
little scripts that parse and traverse Dart code and gather statistics about the
contents.

For example, say you want to find out how many if statements in a body of Dart
code contain else clauses. A script using this package to measure that is:

```dart
import 'package:analyzer/dart/ast/ast.dart';
import 'package:scrape/scrape.dart';

void main(List<String> arguments) {
  Scrape()
    ..addHistogram("If")
    ..addVisitor(() => IfVisitor())
    ..runCommandLine(arguments);
}

class IfVisitor extends ScrapeVisitor {
  @override
  void visitIfStatement(IfStatement node) {
    if (node.elseStatement != null) {
      record("If", "else");
    } else {
      record("If", "no else");
    }
    super.visitIfStatement(node);
  }
}
```

Run that script on the package itself:

```
$ dart example/if.dart .
```

And it prints out:

```
-- If (137 total) --
    104 ( 75.912%): no else  =======================================
     33 ( 24.088%): else     =============
Took 262ms to scrape 1349 lines in 12 files.
```

So it looks like if statements without elses are about three times more common
than ones with elses. We use data like this to inform how we design and evolve
the language.

## A scrape script

I wanted to make scrape flexible enough to let you write whatever kinds of
logic to analyze code. That meant that instead of scrape being a *tool you run*,
it is more like a *library you consume*. This way, inside your script, you have
access to the full Dart language. At the same time, I didn't want every script
to have to copy/paste the same boring argument parsing and other code.

The compromise between those is the Scrape class. It is a builder for an
analysis over some code. It has a few methods you call on it to set up an
analysis:

*   `addHistogram()` registers a new named histogram. This is the main way you
    count occurences of datapoints you care about in the code you are analyzing.
    Each histogram is a named collection of datapoints. When the analysis
    completes, scrape prints out each histogram, buckets the datapoints, and
    shows how many of each datapoint occurred.

    In the example above, we have one histogram named "If" and we count two
    different datapoints, "no else", and "else".

*   `addVisitor()` registers a callback that creates a visitor. This is the
    main way you analyze code. When the analysis runs, scrape parses every
    Dart file you specify. For each file and each registered visitor callback,
    it invokes the callback to create a visitor and then runs that to walk over
    the parsed code.

    You call this passing in a callback that creates an instance of your own
    visitor class, which should extend `ScrapeVisitor`.

*   Then at the end call `runCommandLine()`, passing in your script's command
    line arguments. This reads the file paths the user wants to analyze and
    a few other command line options and flags that scrape automatically
    supports. To learn more, call that with `--help`.

## A visitor class

The way your script analyzes code is through one or more custom subclasses of
`ScrapeVisitor`. That base class itself extends the analyzer package's
[`RecursiveAstVisitor`][visitor] class. It will walk over every single syntax
tree node in the parsed Dart file and invoke visit methods specific to each one.
You override the visit methods for the AST nodes you care about and put
whatever logic you want in there to analyze the code.

An important limitation of scrape is that it only *parses* Dart files. It does
not to any static analysis, name resolution, or type checking. This makes it
lightweight and fast to run (for example you can run it on a pub package
without needing to download its dependencies), but significantly limits the
kinds of analysis you can do.

It's good for syntax and tolerable for things like API usage if you're willing
to assume that certain names do refer to the API you think they do. If you look
in the examples directory, you'll get a sense for what kinds of tasks scrape is
well suited for.

[visitor]: https://pub.dev/documentation/analyzer/0.40.0/dart_ast_visitor/RecursiveAstVisitor-class.html
