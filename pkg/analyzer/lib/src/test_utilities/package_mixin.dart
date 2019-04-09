// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/test_utilities/resource_provider_mixin.dart';

/// A mixin for test classes that provides support for creating packages.
mixin PackageMixin implements ResourceProviderMixin {
  /// Return the map from package names to lists of folders that is used to
  /// resolve 'package:' URIs.
  Map<String, List<Folder>> get packageMap;

  /// Create a fake 'meta' package that can be used by tests.
  void addMetaPackage() {
    Folder lib = addPubPackage('meta');
    newFile(join(lib.path, 'meta.dart'), content: r'''
library meta;

const _AlwaysThrows alwaysThrows = const _AlwaysThrows();
const _Factory factory = const _Factory();
const Immutable immutable = const Immutable();
const _Literal literal = const _Literal();
const _MustCallSuper mustCallSuper = const _MustCallSuper();
const _OptionalTypeArgs optionalTypeArgs = const _OptionalTypeArgs();
const _Protected protected = const _Protected();
const Required required = const Required();
const _Sealed sealed = const _Sealed();
const _VisibleForTesting visibleForTesting = const _VisibleForTesting();

class Immutable {
  final String reason;
  const Immutable([this.reason]);
}
class _AlwaysThrows {
  const _AlwaysThrows();
}
class _Factory {
  const _Factory();
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
class Required {
  final String reason;
  const Required([this.reason]);
}
class _Sealed {
  const _Sealed();
}
class _VisibleForTesting {
  const _VisibleForTesting();
}
''');
  }

  /// Return a newly created directory in which the contents of a pub package
  /// with the given [packageName] can be written. The package will be added to
  /// the package map so that the package can be referenced from the code being
  /// analyzed.
  Folder addPubPackage(String packageName) {
    // TODO(brianwilkerson) Consider renaming this to `addPackage` and passing
    //  in a `PackageStyle` (pub, bazel, gn, build, plain) in order to support
    //  creating other styles of packages.
    Folder lib = getFolder('/.pub-cache/$packageName/lib');
    packageMap[packageName] = [lib];
    return lib;
  }
}
