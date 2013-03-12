// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// A library for declaratively describing a filesystem structure, usually for
/// the purpose of creating or validating it as part of a scheduled test.
///
/// You can use [dir] and [file] to define a filesystem structure. Then, you can
/// call [Entry.create] to schedule a task that will create that structure on
/// the physical filesystem, or [Entry.validate] to schedule an assertion that
/// that structure exists. For example:
///
///     import 'package:scheduled_test/descriptor.dart' as d;
///     import 'package:scheduled_test/scheduled_test.dart';
///
///     void main() {
///       test('Directory.rename', () {
///         d.dir('parent', [
///           d.file('sibling', 'sibling-contents'),
///           d.dir('old-name', [
///             d.file('child', 'child-contents')
///           ])
///         ]).create();
///
///         schedule(() =>
///             new Directory('parent/old-name').rename('parent/new-name'));
///
///         d.dir('parent', [
///           d.file('sibling', 'sibling-contents'),
///           d.dir('new-name', [
///             d.file('child', 'child-contents')
///           ])
///         ]).validate();
///       })
///     }
///
/// Usually you don't want your tests cluttering up your working directory with
/// fake filesystem entities. You can set [defaultRoot] to configure where
/// filesystem descriptors are rooted on the physical filesystem. For example,
/// to create a temporary directory for each test:
///
///     import 'package:scheduled_test/descriptor.dart' as d;
///     import 'package:scheduled_test/scheduled_test.dart';
///
///     void main() {
///       setUp(() {
///         var tempDir;
///         schedule(() {
///           return new Directory('').createTemp().then((dir) {
///             tempDir = dir;
///             d.defaultRoot = tempDir.path;
///           });
///         });
///
///         currentSchedule.onComplete.schedule(() {
///           d.defaultRoot = null;
///           return tempDir.delete(recursive: true);
///         });
///       });
///
///       // ...
///     }
library descriptor;

import 'dart:async';

import '../../../pkg/pathos/lib/path.dart' as path;

import 'scheduled_test.dart';
import 'src/descriptor/async.dart';
import 'src/descriptor/directory.dart';
import 'src/descriptor/entry.dart';
import 'src/descriptor/file.dart';
import 'src/descriptor/nothing.dart';

export 'src/descriptor/async.dart';
export 'src/descriptor/directory.dart';
export 'src/descriptor/entry.dart';
export 'src/descriptor/file.dart';
export 'src/descriptor/nothing.dart';

/// The root path for descriptors. Top-level descriptors will be created and
/// validated at this path. Defaults to the current working directory.
///
/// If this is set to `null`, it will reset itself to the current working
/// directory.
String get defaultRoot => _defaultRoot == null ? path.current : _defaultRoot;
set defaultRoot(String value) {
  _defaultRoot = value;
}
String _defaultRoot;

/// Creates a new text [File] descriptor with [name] and [contents].
File file(Pattern name, [String contents='']) => new File(name, contents);

/// Creates a new binary [File] descriptor with [name] and [contents].
File binaryFile(Pattern name, List<int> contents) =>
    new File.binary(name, contents);

/// Creates a new [Directory] descriptor with [name] and [contents].
Directory dir(Pattern name, [Iterable<Entry> contents]) =>
    new Directory(name, contents == null ? <Entry>[] : contents);

/// Creates a new descriptor wrapping a [Future]. This descriptor forwards all
/// asynchronous operations to the result of [future].
Async async(Future<Entry> future) => new Async(future);

/// Creates a new [Nothing] descriptor that asserts that no entry named [name]
/// exists.
Nothing nothing(Pattern name) => new Nothing(name);
