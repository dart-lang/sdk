## Writing Lints

Preliminary notes on writing lints.

## Lint Criteria

Borrowing heavily from the criteria for [adding new checks to errorprone]
(https://github.com/google/error-prone/wiki/Criteria-for-new-checks), lints should have the following properties.

Dart lints:

* should be easy to understand. The problem should be obvious once the linter points it out.
* should have a correspondingly easy fix. For example, "Remove this type annotation", or "Delete these braces", not 
"Introduce a new subclass and override methods A, B, and C."
* should have *few* false positives.

## Lint Properties

Every lint has a:

**Description.** A short description of the lint, suitable for printing in console output.  For example:

```
[lint] DO name types using UpperCamelCase.
```

**Kind.** The first word in the description should identify the *kind* of lint where kinds are derived from the 
[style guide](https://www.dartlang.org/articles/style-guide/). In summary:

 * ***DO*** guidelines describe practices that should always be followed. There will almost never be a valid reason 
to stray from them.

 * ***DON'T*** guidelines are the converse: things that are almost never a good idea. You'll note there are few of 
these here. Guidelines like these in other languages help to avoid the pitfalls that appear over time. Dart is 
new enough that we can just fix those pitfalls directly instead of putting up ropes around them.

 * ***PREFER*** guidelines are practices that you should follow. However, there may be circumstances where it makes 
sense to do otherwise. Just make sure you understand the full implications of ignoring the guideline when you do.

 * ***AVOID*** guidelines are the dual to "prefer": stuff you shouldn't do but where there may be good reasons to 
on rare occasions.

 * ***CONSIDER*** guidelines are practices that you might or might not want to follow, depending on circumstances, 
precedents, and your own preference.

**Detailed Description.** In addition to the short description, a lint rule should have more detailed rationale 
with code examples, ideally *good* and *bad*. The [style guide](https://www.dartlang.org/articles/style-guide/) is 
a great source for inspiration.  Many style recommendations have been directly translated to lints as enumerated
[here](http://dart-lang.github.io/linter/lints/).

**Group.**  A grouping.  For example, *Style Guide* aggregates style guide derived lints.

**Maturity.** Rules can be further distinguished by maturity. Unqualified rules are considered stable, 
while others may be marked *EXPERIMENTAL* or *PROPOSED* to indicate that they are under review.

## Mechanics

Lints live in the [lib/src/rules](https://github.com/dart-lang/linter/tree/master/lib/src/rules) directory. 
Corresponding tests live in [test/rules](https://github.com/dart-lang/linter/tree/master/test/rules). 

Rule stubs can be generated with the [rule.dart](https://github.com/dart-lang/linter/blob/master/tool/rule.dart) 
helper script and documentation gets generated with [doc.dart] 
(https://github.com/dart-lang/linter/blob/master/tool/doc.dart).

Needless to say, details are under active development.  Feedback is most [welcome](https://github.com/dart-lang/linter/issues)!
