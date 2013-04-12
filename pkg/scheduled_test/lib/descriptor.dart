// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// A library for declaratively describing a filesystem structure, usually for
/// the purpose of creating or validating it as part of a scheduled test.
///
/// You can use [dir] and [file] to define a filesystem structure. Then, you can
/// call [Descriptor.create] to schedule a task that will create that structure
/// on the physical filesystem, or [Descriptor.validate] to schedule an
/// assertion that that structure exists. For example:
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
library scheduled_test.descriptor;

import 'dart:async';

import 'package:pathos/path.dart' as path;

import 'scheduled_test.dart';
import 'src/descriptor/async_descriptor.dart';
import 'src/descriptor/descriptor.dart';
import 'src/descriptor/directory_descriptor.dart';
import 'src/descriptor/file_descriptor.dart';
import 'src/descriptor/nothing_descriptor.dart';
import 'src/descriptor/pattern_descriptor.dart';

export 'src/descriptor/async_descriptor.dart';
export 'src/descriptor/descriptor.dart';
export 'src/descriptor/directory_descriptor.dart';
export 'src/descriptor/file_descriptor.dart';
export 'src/descriptor/nothing_descriptor.dart';
export 'src/descriptor/pattern_descriptor.dart';

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

/// Creates a new text [FileDescriptor] with [name] and [contents].
FileDescriptor file(String name, [String contents='']) =>
  new FileDescriptor(name, contents);

/// Creates a new binary [FileDescriptor] descriptor with [name] and [contents].
FileDescriptor binaryFile(String name, List<int> contents) =>
  new FileDescriptor.binary(name, contents);

/// Creates a new [DirectoryDescriptor] descriptor with [name] and [contents].
DirectoryDescriptor dir(String name, [Iterable<Descriptor> contents]) =>
   new DirectoryDescriptor(name, contents == null? <Descriptor>[] : contents);

/// Creates a new descriptor wrapping a [Future]. This descriptor forwards all
/// asynchronous operations to the result of [future].
AsyncDescriptor async(Future<Descriptor> future) =>
  new AsyncDescriptor(future);

/// Creates a new [NothingDescriptor] descriptor that asserts that no entry
/// named [name] exists.
NothingDescriptor nothing(String name) => new NothingDescriptor(name);

/// Creates a new [PatternDescriptor] descriptor that asserts than an entry with
/// a name matching [pattern] exists, and matches the [Descriptor] returned
/// by [fn].
PatternDescriptor pattern(Pattern name, EntryCreator fn) =>
  new PatternDescriptor(name, fn);

/// A convenience method for creating a [PatternDescriptor] descriptor that
/// constructs a [FileDescriptor] descriptor.
PatternDescriptor filePattern(Pattern name, [String contents='']) =>
  pattern(name, (realName) => file(realName, contents));

/// A convenience method for creating a [PatternDescriptor] descriptor that
/// constructs a [DirectoryDescriptor] descriptor.
PatternDescriptor dirPattern(Pattern name, [Iterable<Descriptor> contents]) =>
  pattern(name, (realName) => dir(realName, contents));
