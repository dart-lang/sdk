// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer_testing/src/mock_packages/mock_library.dart';

final widgetsFrameworkLibrary = MockLibraryUnit(
  'lib/src/widgets/framework.dart',
  r'''
import 'package:flutter/foundation.dart';

export 'package:flutter/foundation.dart' show required;
export 'package:flutter/foundation.dart' show Key, LocalKey, ValueKey;

typedef WidgetBuilder = Widget Function(BuildContext context);

abstract class BuildContext {
  bool get mounted;

  Widget get widget;
}

abstract class RenderObjectWidget extends Widget {
  const RenderObjectWidget({super.key});
}

abstract class SingleChildRenderObjectWidget extends RenderObjectWidget {
  final Widget? child;

  const SingleChildRenderObjectWidget({super.key, this.child});
}

abstract class MultiChildRenderObjectWidget extends RenderObjectWidget {
  final List<Widget> children;

  const MultiChildRenderObjectWidget({super.key, this.children = const <Widget>[]});
}

@optionalTypeArgs
abstract class State<T extends StatefulWidget> with Diagnosticable {
  T get widget => throw UnimplementedError();

  BuildContext get context => throw UnimplementedError();

  bool get mounted => true;

  @protected
  Widget build(BuildContext context);

  @protected
  @mustCallSuper
  void dispose() {}

  @protected
  @mustCallSuper
  void initState() {}

  @protected
  void setState(VoidCallback fn) {}
}

abstract class StatefulWidget extends Widget {
  const StatefulWidget({super.key});

  @protected
  @factory
  State<StatefulWidget> createState();
}

abstract class StatelessWidget extends Widget {
  const StatelessWidget({super.key});

  @protected
  external Widget build(BuildContext context);
}

@immutable
abstract class Widget extends DiagnosticableTree {
  final Key? key;

  const Widget({this.key});

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties);
}

class ParentData {}

abstract class ProxyWidget extends Widget {}

abstract class InheritedWidget extends ProxyWidget {}

abstract class ParentDataWidget<T extends ParentData> extends ProxyWidget {}
''',
);
