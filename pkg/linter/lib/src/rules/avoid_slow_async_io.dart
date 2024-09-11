// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';

import '../analyzer.dart';
import '../extensions.dart';
import '../linter_lint_codes.dart';

const _desc = r'Avoid slow asynchronous `dart:io` methods.';

const _details = r'''
**AVOID** using the following asynchronous file I/O methods because they are
much slower than their synchronous counterparts.

* `Directory.exists`
* `Directory.stat`
* `File.lastModified`
* `File.exists`
* `File.stat`
* `FileSystemEntity.isDirectory`
* `FileSystemEntity.isFile`
* `FileSystemEntity.isLink`
* `FileSystemEntity.type`

**BAD:**
```dart
import 'dart:io';

Future<Null> someFunction() async {
  var file = File('/path/to/my/file');
  var now = DateTime.now();
  if ((await file.lastModified()).isBefore(now)) print('before'); // LINT
}
```

**GOOD:**
```dart
import 'dart:io';

Future<Null> someFunction() async {
  var file = File('/path/to/my/file');
  var now = DateTime.now();
  if (file.lastModifiedSync().isBefore(now)) print('before'); // OK
}
```

''';

const List<String> _dirMethodNames = <String>[
  'exists',
  'stat',
];

const List<String> _fileMethodNames = <String>[
  'lastModified',
  'exists',
  'stat',
];

const List<String> _fileSystemEntityMethodNames = <String>[
  'isDirectory',
  'isFile',
  'isLink',
  'type',
];

class AvoidSlowAsyncIo extends LintRule {
  AvoidSlowAsyncIo()
      : super(
          name: 'avoid_slow_async_io',
          description: _desc,
          details: _details,
        );

  @override
  LintCode get lintCode => LinterLintCode.avoid_slow_async_io;

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    var visitor = _Visitor(this);
    registry.addMethodInvocation(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final LintRule rule;

  _Visitor(this.rule);

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (node.argumentList.arguments.isEmpty) {
      var type = node.target?.staticType;
      _checkFileMethods(node, type);
      _checkDirectoryMethods(node, type);
      return;
    } else {
      _checkFileSystemEntityMethods(node);
      return;
    }
  }

  void _checkDirectoryMethods(MethodInvocation node, DartType? type) {
    if (type.extendsClass('Directory', 'dart.io')) {
      if (_dirMethodNames.contains(node.methodName.name)) {
        rule.reportLint(node);
      }
    }
  }

  void _checkFileMethods(MethodInvocation node, DartType? type) {
    if (type.extendsClass('File', 'dart.io')) {
      if (_fileMethodNames.contains(node.methodName.name)) {
        rule.reportLint(node);
      }
    }
  }

  void _checkFileSystemEntityMethods(MethodInvocation node) {
    var target = node.target;
    if (target is Identifier) {
      var elem = target.staticElement;
      if (elem is ClassElement && elem.name == 'FileSystemEntity') {
        if (_fileSystemEntityMethodNames.contains(node.methodName.name)) {
          rule.reportLint(node);
        }
      }
    }
  }
}
