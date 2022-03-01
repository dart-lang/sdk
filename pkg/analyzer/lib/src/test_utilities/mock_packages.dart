// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/file_system/physical_file_system.dart';

/// Helper for creating mock packages.
class MockPackages {
  final String packageRoot;

  MockPackages(this.packageRoot);

  /// Create a fake 'ffi' package that can be used by tests.
  void addFfiPackageFiles(Folder rootFolder) {
    var libFolder = rootFolder.getChildAssumingFolder('lib');
    libFolder.getChildAssumingFile('ffi.dart').writeAsStringSync(r'''
import 'dart:ffi';

const Allocator calloc = _CallocAllocator();

abstract class Allocator {
  Pointer<T> allocate<T extends NativeType>(int byteCount, {int? alignment});

  void free(Pointer pointer);
}

class Utf8 extends Opaque {}

class _CallocAllocator implements Allocator {
  @override
  Pointer<T> allocate<T extends NativeType>(int byteCount, {int? alignment})
      => throw '';

  @override
  void free(Pointer pointer) => throw '';
}
''');
  }

  /// Copy the content of the `pkg/js` into the [target] folder.
  void addJsPackageFiles(Folder target) {
    _copyPackageContent('js', target);
  }

  /// Copy the content of the `pkg/meta` into the [target] folder.
  void addMetaPackageFiles(Folder target) {
    _copyPackageContent('meta', target);
  }

  void _copyPackageContent(String packageName, Folder target) {
    var physicalProvider = PhysicalResourceProvider.INSTANCE;
    var physicalSource = physicalProvider.getFolder(
      physicalProvider.pathContext.join(packageRoot, packageName),
    );
    for (var child in physicalSource.getChildren()) {
      child.copyTo(target);
    }
  }
}
