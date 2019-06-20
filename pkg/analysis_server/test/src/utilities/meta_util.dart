// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/file_system/memory_file_system.dart';

const String metaPkgLibPath = '/packages/meta/lib';

/**
 * Add a meta library and types to the given [provider] and return
 * the `lib` folder.
 */
Folder configureMetaPackage(MemoryResourceProvider provider) {
  File newFile(String path, String content) =>
      provider.newFile(provider.convertPath(path), content ?? '');

  Folder newFolder(String path) =>
      provider.newFolder(provider.convertPath(path));

  newFile('$metaPkgLibPath/meta.dart', r'''
library meta;

const _AlwaysThrows alwaysThrows = const _AlwaysThrows();

@deprecated
const _Checked checked = const _Checked();

const _Experimental experimental = const _Experimental();

const _Factory factory = const _Factory();

const Immutable immutable = const Immutable();

const _IsTest isTest = const _IsTest();

const _IsTestGroup isTestGroup = const _IsTestGroup();

const _Literal literal = const _Literal();

const _MustCallSuper mustCallSuper = const _MustCallSuper();

const _OptionalTypeArgs optionalTypeArgs = const _OptionalTypeArgs();

const _Protected protected = const _Protected();

const Required required = const Required();

const _Sealed sealed = const _Sealed();

@deprecated
const _Virtual virtual = const _Virtual();

const _VisibleForOverriding visibleForOverriding =
    const _VisibleForOverriding();

const _VisibleForTesting visibleForTesting = const _VisibleForTesting();

class Immutable {
  final String reason;
  const Immutable([this.reason]);
}

class Required {
  final String reason;
  const Required([this.reason]);
}

class _AlwaysThrows {
  const _AlwaysThrows();
}

class _Checked {
  const _Checked();
}

class _Experimental {
  const _Experimental();
}

class _Factory {
  const _Factory();
}

class _IsTest {
  const _IsTest();
}

class _IsTestGroup {
  const _IsTestGroup();
}

class _Literal {
  const _Literal();
}

class _MustCallSuper {
  const _MustCallSuper();
}

class _OptionalTypeArgs {
  const _OptionalTypeArgs();
}

class _Protected {
  const _Protected();
}

class _Sealed {
  const _Sealed();
}

@deprecated
class _Virtual {
  const _Virtual();
}

class _VisibleForOverriding {
  const _VisibleForOverriding();
}

class _VisibleForTesting {
  const _VisibleForTesting();
}
''');

  return newFolder(metaPkgLibPath);
}
