// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

import '../analyzer.dart';
import '../util/flutter_utils.dart';

const _desc = r'Sort child properties last in widget instance creations.';

const _details = r'''
Sort arguments to end with a Widget in widget instance creations.  This improves
readability and plays nicest with UI as Code visualization in IDEs with UI as
Code Guides in editors (such as IntelliJ) where Properties in the correct order
appear clearly associated with the constructor call and separated from the
children.

**BAD:**
```dart
return Scaffold(
  appBar: AppBar(
    title: Text(widget.title),
  ),
  body: Center(
    child: Column(
      children: <Widget>[
        Text(
          'You have pushed the button this many times:',
         ),
        Text(
          '$_counter',
          style: Theme.of(context).textTheme.display1,
         ),
      ],
      mainAxisAlignment: MainAxisAlignment.center,
    ),
    widthFactor: 0.5,
  ),
  floatingActionButton: FloatingActionButton(
    child: Icon(Icons.add),
    onPressed: _incrementCounter,
    tooltip: 'Increment',
  ),
);
```

**GOOD:**
```dart
return Scaffold(
  appBar: AppBar(
    title: Text(widget.title),
  ),
  body: Center(
    widthFactor: 0.5,
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Text(
          'You have pushed the button this many times:',
         ),
        Text(
          '$_counter',
          style: Theme.of(context).textTheme.display1,
         ),
      ],
    ),
  ),
  floatingActionButton: FloatingActionButton(
    onPressed: _incrementCounter,
    tooltip: 'Increment',
    child: Icon(Icons.add),
  ),
);
```

Exception: It's allowed to have function expression arguments after the last
Widget argument.
''';

class SortChildPropertiesLast extends LintRule implements NodeLintRule {
  SortChildPropertiesLast()
      : super(
            name: 'sort_child_properties_last',
            description: _desc,
            details: _details,
            group: Group.style);

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    var visitor = _Visitor(this);
    registry.addInstanceCreationExpression(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor {
  final LintRule rule;

  _Visitor(this.rule);

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    if (!isWidgetType(node.staticType)) {
      return;
    }

    var arguments = node.argumentList.arguments;
    if (arguments.length < 2 || isWidgetProperty(arguments.last.staticType)) {
      return;
    }

    var lastWidgetIndex =
        arguments.lastIndexWhere((e) => isWidgetProperty(e.staticType));

    // no widget argument
    if (lastWidgetIndex == -1) {
      return;
    }

    var onlyClosuresAfterLastWidget = arguments
        .skip(lastWidgetIndex + 1)
        .where(
            (e) => e is NamedExpression && e.expression is! FunctionExpression)
        .isEmpty;
    if (!onlyClosuresAfterLastWidget) {
      rule.reportLint(arguments[lastWidgetIndex]);
    }
  }
}
