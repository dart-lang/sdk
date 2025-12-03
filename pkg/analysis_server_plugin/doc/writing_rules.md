# Writing rules

This package gives analyzer plugin authors the ability to write static rules
for Dart source code. This document describes briefly how to write such a rule,
and how to register it in an analyzer plugin.

## Declaring an analysis rule

Every analysis rule is declared in two parts: a rule class that extends
`AnalysisRule`, and a visitor class that extends `SimpleAstVisitor`.

### The rule class

The rule class contains some general information about the rule, like its name
and the diagnostic or diagnostics that the rule reports. It also registers the
various Dart syntax tree nodes that the visitor class needs to visit. Let's see
an example:

```dart
import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/error.dart';

class MyRule extends AnalysisRule {
  static const LintCode code = LintCode(
    'my_rule',
    'No await expressions',
    correctionMessage: "Try removing 'await'.",
  );

  MyRule()
      : super(
          name: 'my_rule',
          description: 'A longer description of the rule.',
        );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(
      RuleVisitorRegistry registry, RuleContext context) {
    var visitor = _Visitor(this, context);
    registry.addAwaitExpression(this, visitor);
  }
}
```

Let's look at each declaration individually:

* `class MyRule extends AnalysisRule` - The rule class must extend
  `AnalysisRule`.

* `static const LintCode _code` and `LintCode get diagnosticCode` - The rule class
  must implement `LintCode get diagnosticCode`, for infrastructure to be able
  to register the diagnostic code that the rule can report.

  A `LintCode` is the template for each diagnostic that is to be reported. It
  contains the diagnostic name, problem message, and optionally the correction
  message. We instantiate a `LintCode` as a static field so that it can also be
  made const.

  Alternatively, if a rule can report several different diagnostic codes
  (typically for differentiated messages), it can instead extend
  `MultiAnalysisRule`, and then implement `List<LintCode> get diagnosticCodes`
  instead of `LintCode get diagnosticCode`. The rule can then declare the
  different `LintCode`s in multiple static fields, which are referenced in the
  `diagnosticCodes` getter.

* `MyRule()` - The rule class must have a constructor that calls `super()`,
  passing along the name of the rule, and a description. Typically this
  constructor has zero parameters.

* `void registerNodeProcessors(...)` - An analysis rule uses a visitor to walk
  a [Dart syntax tree][] (we see how the visitor is defined in "The visitor
  class," below). This visitor is typically named `_Visitor`. This visitor
  class must be instantiated once in this method. Typically, the instance of
  the rule class (`this`) and a `RuleContext` object (described below) are
  passed to the visitor constructor.

  In order for such a visitor's various 'visit' methods to be called, we need
  to register them, in a `RuleVisitorRegistry`. Each 'visit' method found on
  `SimpleAstVisitor` has a corresponding 'add' method in the
  `RuleVisitorRegistry` class.

[Dart syntax tree]: https://github.com/dart-lang/sdk/blob/main/pkg/analyzer/doc/tutorial/ast.md

### The visitor class

The visitor class contains the code that examines syntax nodes and reports
diagnostics. See the [API documentation][SimpleAstVisitor docs] for the
`SimpleAstVisitor` class to find the various 'visit' methods available for
implementation. Let's look at a quick example:

[SimpleAstVisitor docs]: https://github.com/dart-lang/sdk/blob/main/pkg/analyzer/lib/dart/ast/visitor.dart#L1841

```dart
import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

class _Visitor extends SimpleAstVisitor<void> {
  final AnalysisRule rule;

  final RuleContext context;

  _Visitor(this.rule, this.context);

  @override
  void visitAwaitExpression(AwaitExpression node) {
    if (context.isInLibDir) {
      rule.reportAtNode(node);
    }
  }
}
```

Let's look at each declaration individually:

* `class _Visitor extends SimpleAstVisitor<void>` - Each visitor must extend
  `SimpleAstVisitor`. While the analyzer package provides other Dart syntax
  tree visitors, using one directly in a rule can result in poor performance
  and unexpected behavior. The type argument on `SimpleAstVisitor` is not
  important, as 'visit' return values are not used, so `void` is appropriate.
* `final AnalysisRule rule` - The rule is the object to which we can report
  diagnostics (lints or warnings). Several methods are provided, all starting
  with `reportAt`. The different methods allow for different ranges of text to
  be highlighted.
* `final RuleContext context` - The RuleContext object provides various
  information about the library being analyzed. In this example, we make use of
  a `isInLibDir` utility.
* `_Visitor(...)` - Often the constructor just initializes the AnalysisRule and
  RuleContext fields. Other information can be initialized as well.
* `void visitAwaitExpression(AwaitExpression node)` - The main component of the
  `_Visitor` class is the 'visit' methods. In this case, `visitAwaitExpression`
  is invoked for each 'await expression' found in the source code under
  analysis. Typically, a 'visit' method like this is where we perform some
  analysis and maybe report lint(s) or warning(s).

Some rules do not require complex logic in the visitor class, but rules may
also need to walk up or down the syntax tree, or examine properties of nodes
carefully and thoroughly. For many examples of analysis rules and their visitor
classes, see the [lint rules] that ship with the Dart Analysis Server.

[lint rules]: https://github.com/dart-lang/sdk/tree/main/pkg/linter/lib/src/rules

## Registering an analysis rule

In order for an analysis rule to be used in an analyzer plugin, it must be
registered. Register an instance of an analysis rule inside a plugin's
`register` method:

```dart
import 'package:analysis_server_plugin/plugin.dart';
import 'package:analysis_server_plugin/registry.dart';

class SimplePlugin extends Plugin {
  @override
  String get name => 'Simple plugin';

  @override
  void register(PluginRegistry registry) {
    registry.registerWarningRule(MyRule());
  }
}
```

Here, the instance of MyRule is registered as a "warning rule," so that it is
enabled by default. To register an analysis rule as a "lint rule," such that it
must be specifically enabled from analysis options, use `registerLintRule`
instead.

See [writing a plugin][] for information about the `Plugin` class.

## Testing an analysis rule

Writing tests for an analysis rule is very easy, and is documented at [testing
rules][].

[writing a plugin]: https://github.com/dart-lang/sdk/blob/main/pkg/analysis_server_plugin/doc/writing_a_plugin.md
[testing rules]: https://github.com/dart-lang/sdk/blob/main/pkg/analysis_server_plugin/doc/testing_rules.md
