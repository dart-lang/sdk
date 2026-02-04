// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/assist.dart';
import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer_plugin/utilities/assist/assist.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:linter/src/lint_names.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../fix/fix_processor.dart';
import 'assist_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(FlutterRemoveWidgetTest);
    defineReflectiveTests(RemoveContainerTest);
    defineReflectiveTests(RemoveContainerBulkTest);
  });
}

@reflectiveTest
class FlutterRemoveWidgetTest extends AssistProcessorTest {
  @override
  AssistKind get kind => DartAssistKind.flutterRemoveWidget;

  @override
  void setUp() {
    super.setUp();
    writeTestPackageConfig(flutter: true);
  }

  Future<void> test_builder_blockFunctionBody() async {
    await resolveTestCode('''
import 'package:flutter/material.dart';
void f() {
  ^Builder(
    builder: (context) {
      return Text('');
    }
  );
}
''');
    await assertHasAssist('''
import 'package:flutter/material.dart';
void f() {
  Text('');
}
''');
  }

  Future<void> test_builder_blockFunctionBody_many_statements() async {
    await resolveTestCode('''
import 'package:flutter/material.dart';
void f() {
  ^Builder(
    builder: (context) {
      var i = 1;
      return Text('');
    }
  );
}
''');
    await assertNoAssist();
  }

  Future<void> test_builder_expressionFunctionBody() async {
    await resolveTestCode('''
import 'package:flutter/material.dart';
void f() {
  ^Builder(
    builder: (context) => Text('')
  );
}
''');
    await assertHasAssist('''
import 'package:flutter/material.dart';
void f() {
  Text('');
}
''');
  }

  Future<void> test_builder_parameter_used() async {
    await resolveTestCode('''
import 'package:flutter/material.dart';
void f() {
  ^Builder(
    builder: (context) => context.widget
  );
}
''');
    await assertNoAssist();
  }

  Future<void> test_childIntoChild_multiLine() async {
    await resolveTestCode('''
import 'package:flutter/material.dart';
void f() {
  Column(
    children: [
      Center(
        child: ^Padding(
          padding: const EdgeInsets.all(8.0),
          child: Center(
            heightFactor: 0.5,
            child: Text('foo'),
          ),
        ),
      ),
    ],
  );
}
''');
    await assertHasAssist('''
import 'package:flutter/material.dart';
void f() {
  Column(
    children: [
      Center(
        child: Center(
          heightFactor: 0.5,
          child: Text('foo'),
        ),
      ),
    ],
  );
}
''');
  }

  Future<void> test_childIntoChild_singleLine() async {
    await resolveTestCode('''
import 'package:flutter/material.dart';
void f() {
  Padding(
    padding: const EdgeInsets.all(8.0),
    child: ^Center(
      heightFactor: 0.5,
      child: Text('foo'),
    ),
  );
}
''');
    await assertHasAssist('''
import 'package:flutter/material.dart';
void f() {
  Padding(
    padding: const EdgeInsets.all(8.0),
    child: Text('foo'),
  );
}
''');
  }

  Future<void> test_childIntoChildren() async {
    await resolveTestCode('''
import 'package:flutter/material.dart';
void f() {
  Column(
    children: [
      Text('foo'),
      ^Center(
        heightFactor: 0.5,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text('bar'),
        ),
      ),
      Text('baz'),
    ],
  );
}
''');
    await assertHasAssist('''
import 'package:flutter/material.dart';
void f() {
  Column(
    children: [
      Text('foo'),
      Padding(
        padding: const EdgeInsets.all(8.0),
        child: Text('bar'),
      ),
      Text('baz'),
    ],
  );
}
''');
  }

  Future<void> test_childrenMultipleIntoChild() async {
    await resolveTestCode('''
import 'package:flutter/material.dart';
void f() {
  Center(
    child: ^Row(
      children: [
        Text('aaa'),
        Text('bbb'),
      ],
    ),
  );
}
''');
    await assertNoAssist();
  }

  Future<void> test_childrenOneIntoChild() async {
    await resolveTestCode('''
import 'package:flutter/material.dart';
void f() {
  Center(
    child: ^Column(
      children: [
        Text('foo'),
      ],
    ),
  );
}
''');
    await assertHasAssist('''
import 'package:flutter/material.dart';
void f() {
  Center(
    child: Text('foo'),
  );
}
''');
  }

  Future<void> test_childrenOneIntoReturn() async {
    await resolveTestCode('''
import 'package:flutter/material.dart';
Widget f() {
  return ^Column(
    children: [
      Text('foo'),
    ],
  );
}
''');
    await assertHasAssist('''
import 'package:flutter/material.dart';
Widget f() {
  return Text('foo');
}
''');
  }

  Future<void> test_does_not_work_for_non_widgets_child() async {
    await resolveTestCode('''
import 'package:flutter/material.dart';

class NotAWidget {
  final int child;

  NotAWidget({required this.child});
}

void f() {
  ^NotAWidget(
    child: 42,
  );
}
''');
    await assertNoAssist();
  }

  Future<void> test_does_not_work_for_non_widgets_children() async {
    await resolveTestCode('''
import 'package:flutter/material.dart';

class NotAWidget {
  final List<int> children;

  NotAWidget({required this.children});
}

void f() {
  ^NotAWidget(
    children: [42],
  );
}
''');
    await assertNoAssist();
  }

  Future<void> test_does_not_work_for_non_widgets_sliver() async {
    await resolveTestCode('''
import 'package:flutter/material.dart';

class NotAWidget {
  final int sliver;

  NotAWidget({required this.sliver});
}

void f() {
  ^NotAWidget(
    sliver: 42,
  );
}
''');
    await assertNoAssist();
  }

  Future<void> test_does_not_work_for_non_widgets_slivers() async {
    await resolveTestCode('''
import 'package:flutter/material.dart';

class NotAWidget {
  final List<int> slivers;

  NotAWidget({required this.slivers});
}

void f() {
  ^NotAWidget(
    slivers: [42],
  );
}
''');
    await assertNoAssist();
  }

  Future<void> test_doesNotRemoveWidgetWithoutArgumentWhenNotInList() async {
    await resolveTestCode('''
import 'package:flutter/material.dart';
void f() {
  ^Container();
}
''');
    await assertNoAssist();
  }

  Future<void> test_intoChildren() async {
    await resolveTestCode('''
import 'package:flutter/material.dart';
void f() {
  Column(
    children: [
      Text('aaa'),
      ^Column(
        children: [
          Row(
            children: [
              Text('bbb'),
              Text('ccc'),
            ],
          ),
          Row(
            children: [
              Text('ddd'),
              Text('eee'),
            ],
          ),
        ],
      ),
      Text('fff'),
    ],
  );
}
''');
    await assertHasAssist('''
import 'package:flutter/material.dart';
void f() {
  Column(
    children: [
      Text('aaa'),
      Row(
        children: [
          Text('bbb'),
          Text('ccc'),
        ],
      ),
      Row(
        children: [
          Text('ddd'),
          Text('eee'),
        ],
      ),
      Text('fff'),
    ],
  );
}
''');
  }

  Future<void> test_prefixedConstructor_onConstructor() async {
    await resolveTestCode('''
import 'package:flutter/material.dart';
import 'package:flutter/material.dart' as m;
void f() {
  Center(
    child: m.^Center(
      child: Text(''),
    ),
  );
}
''');
    await assertHasAssist('''
import 'package:flutter/material.dart';
import 'package:flutter/material.dart' as m;
void f() {
  Center(
    child: Text(''),
  );
}
''');
  }

  Future<void> test_prefixedConstructor_onPrefix() async {
    await resolveTestCode('''
import 'package:flutter/material.dart';
import 'package:flutter/material.dart' as m;
void f() {
  Center(
    child: ^m.Center(
      child: Text(''),
    ),
  );
}
''');
    await assertHasAssist('''
import 'package:flutter/material.dart';
import 'package:flutter/material.dart' as m;
void f() {
  Center(
    child: Text(''),
  );
}
''');
  }

  Future<void> test_removeWidgetWithoutArgumentWhenInList() async {
    await resolveTestCode('''
import 'package:flutter/material.dart';
void f() {
  Column(
    children: [
      ^Container(),
    ],
  );
}
''');
    await assertHasAssist('''
import 'package:flutter/material.dart';
void f() {
  Column(
    children: [
      ^
    ],
  );
}
''');
  }

  Future<void> test_removeWidgetWithoutArgumentWhenInListSliver() async {
    await resolveTestCode('''
import 'package:flutter/material.dart';
void f() {
  CustomScrollView(
    slivers: [
      ^SliverToBoxAdapter(),
    ],
  );
}
''');
    await assertHasAssist('''
import 'package:flutter/material.dart';
void f() {
  CustomScrollView(
    slivers: [
      ^
    ],
  );
}
''');
  }

  Future<void> test_sliver_childIntoChild_multiLine() async {
    await resolveTestCode('''
import 'package:flutter/material.dart';
void f() {
  CustomScrollView(
    slivers: [
      SliverPadding(
        padding: const EdgeInsets.all(8.0),
        sliver: ^DecoratedSliver(
          decoration: BoxDecoration(),
          sliver: SliverToBoxAdapter(
            child: Text('foo'),
          ),
        ),
      ),
    ],
  );
}
''');
    await assertHasAssist('''
import 'package:flutter/material.dart';
void f() {
  CustomScrollView(
    slivers: [
      SliverPadding(
        padding: const EdgeInsets.all(8.0),
        sliver: SliverToBoxAdapter(
          child: Text('foo'),
        ),
      ),
    ],
  );
}
''');
  }

  Future<void> test_sliver_childIntoChildren() async {
    await resolveTestCode('''
import 'package:flutter/material.dart';
void f() {
  CustomScrollView(
    slivers: [
      SliverToBoxAdapter(child: Text('foo')),
      ^DecoratedSliver(
        decoration: BoxDecoration(),
        sliver: SliverPadding(
          padding: const EdgeInsets.all(8.0),
          sliver: SliverToBoxAdapter(child: Text('bar')),
        ),
      ),
      SliverToBoxAdapter(child: Text('baz')),
    ],
  );
}
''');
    await assertHasAssist('''
import 'package:flutter/material.dart';
void f() {
  CustomScrollView(
    slivers: [
      SliverToBoxAdapter(child: Text('foo')),
      SliverPadding(
        padding: const EdgeInsets.all(8.0),
        sliver: SliverToBoxAdapter(child: Text('bar')),
      ),
      SliverToBoxAdapter(child: Text('baz')),
    ],
  );
}
''');
  }

  Future<void> test_sliver_childrenMultipleIntoChild() async {
    await resolveTestCode('''
import 'package:flutter/material.dart';
void f() {
  Center(
    child: ^CustomScrollView(
      slivers: [
        SliverToBoxAdapter(child: Text('aaa')),
        SliverToBoxAdapter(child: Text('bbb')),
      ],
    ),
  );
}
''');
    await assertNoAssist();
  }

  Future<void> test_sliver_childrenOneIntoChild() async {
    await resolveTestCode('''
import 'package:flutter/material.dart';
void f() {
  Center(
    child: ^CustomScrollView(
      slivers: [
        SliverToBoxAdapter(child: Text('foo')),
      ],
    ),
  );
}
''');
    await assertHasAssist('''
import 'package:flutter/material.dart';
void f() {
  Center(
    child: SliverToBoxAdapter(child: Text('foo')),
  );
}
''');
  }

  Future<void> test_sliver_childrenOneIntoReturn() async {
    await resolveTestCode('''
import 'package:flutter/material.dart';
Widget f() {
  return ^CustomScrollView(
    slivers: [
      SliverToBoxAdapter(child: Text('foo')),
    ],
  );
}
''');
    await assertHasAssist('''
import 'package:flutter/material.dart';
Widget f() {
  return SliverToBoxAdapter(child: Text('foo'));
}
''');
  }

  Future<void> test_sliver_intoChildren() async {
    await resolveTestCode('''
import 'package:flutter/material.dart';
void f() {
  CustomScrollView(
    slivers: [
      SliverToBoxAdapter(child: Text('aaa')),
      ^SliverList.list(
        children: [
          Row(
            children: [
              SliverToBoxAdapter(child: Text('bbb')),
              SliverToBoxAdapter(child: Text('ccc')),
            ],
          ),
          Row(
            children: [
              SliverToBoxAdapter(child: Text('ddd')),
              SliverToBoxAdapter(child: Text('eee')),
            ],
          ),
        ],
      ),
      SliverToBoxAdapter(child: Text('fff')),
    ],
  );
}
''');
    await assertHasAssist('''
import 'package:flutter/material.dart';
void f() {
  CustomScrollView(
    slivers: [
      SliverToBoxAdapter(child: Text('aaa')),
      Row(
        children: [
          SliverToBoxAdapter(child: Text('bbb')),
          SliverToBoxAdapter(child: Text('ccc')),
        ],
      ),
      Row(
        children: [
          SliverToBoxAdapter(child: Text('ddd')),
          SliverToBoxAdapter(child: Text('eee')),
        ],
      ),
      SliverToBoxAdapter(child: Text('fff')),
    ],
  );
}
''');
  }

  Future<void> test_sliver_prefixedConstructor_onConstructor() async {
    await resolveTestCode('''
import 'package:flutter/material.dart';
import 'package:flutter/material.dart' as m;
void f() {
  SliverPadding(
    padding: const EdgeInsets.all(8.0),
    sliver: m.^SliverToBoxAdapter(
      child: Text(''),
    ),
  );
}
''');
    await assertHasAssist('''
import 'package:flutter/material.dart';
import 'package:flutter/material.dart' as m;
void f() {
  SliverPadding(
    padding: const EdgeInsets.all(8.0),
    sliver: Text(''),
  );
}
''');
  }

  Future<void> test_sliver_prefixedConstructor_onPrefix() async {
    await resolveTestCode('''
import 'package:flutter/material.dart';
import 'package:flutter/material.dart' as m;
void f() {
  SliverPadding(
    padding: const EdgeInsets.all(8.0),
    sliver: ^m.SliverPadding(
      padding: const EdgeInsets.all(16.0),
      sliver: SliverToBoxAdapter(),
    ),
  );
}
''');
    await assertHasAssist('''
import 'package:flutter/material.dart';
import 'package:flutter/material.dart' as m;
void f() {
  SliverPadding(
    padding: const EdgeInsets.all(8.0),
    sliver: SliverToBoxAdapter(),
  );
}
''');
  }
}

@reflectiveTest
class RemoveContainerBulkTest extends BulkFixProcessorTest {
  @override
  String get lintCode => LintNames.avoid_unnecessary_containers;

  @override
  void setUp() {
    super.setUp();
    writeTestPackageConfig(flutter: true);
  }

  @FailingTest(reason: 'nested row container not being removed')
  Future<void> test_singleFile() async {
    await resolveTestCode('''
import 'package:flutter/material.dart';

Widget buildRow() {
  return Container(
      child: Row(
        children: [
          Text('...'),
          Container(
            child: Row(
              children: [
                 Text('...'),
              ],
            ),
          )
        ],
      )
  );
}
''');
    await assertHasFix('''
import 'package:flutter/material.dart';

Widget buildRow() {
  return Row(
    children: [
      Text('...'),
      Row(
        children: [
          Text('...'),
        ],
      )
    ],
  );
}
''');
  }
}

@reflectiveTest
class RemoveContainerTest extends FixProcessorLintTest {
  @override
  FixKind get kind => DartFixKind.removeUnnecessaryContainer;

  @override
  String get lintCode => LintNames.avoid_unnecessary_containers;

  @override
  void setUp() {
    super.setUp();
    writeTestPackageConfig(flutter: true);
  }

  Future<void> test_simple() async {
    await resolveTestCode('''
import 'package:flutter/material.dart';

Widget buildRow() {
  return Container(
      child: Row(
        children: [
          Text('...'),
        ],
      )
  );
}
''');
    await assertHasFix('''
import 'package:flutter/material.dart';

Widget buildRow() {
  return Row(
    children: [
      Text('...'),
    ],
  );
}
''');
  }
}
