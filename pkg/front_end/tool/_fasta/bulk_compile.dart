// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async' show Future;

import 'dart:convert' show utf8;

import 'package:front_end/src/api_prototype/compiler_options.dart'
    show CompilerOptions;

import 'package:front_end/src/api_prototype/file_system.dart'
    show FileSystem, FileSystemEntity, FileSystemException;

import 'package:front_end/src/api_prototype/standard_file_system.dart'
    show StandardFileSystem;

import 'package:front_end/src/base/processed_options.dart'
    show ProcessedOptions;

import 'package:front_end/src/compute_platform_binaries_location.dart'
    show computePlatformBinariesLocation;

import 'package:front_end/src/fasta/compiler_context.dart' show CompilerContext;

import 'package:front_end/src/kernel_generator_impl.dart'
    show CompilerResult, generateKernelInternal;

const String customScheme = "org-dartlang-bulkcompile";

final Uri mainUri = new Uri(scheme: customScheme, host: "", path: "/main.dart");

class BulkCompiler {
  final ProcessedOptions options;

  BulkCompiler(CompilerOptions options)
      : options = new ProcessedOptions(
            options
              ..packagesFileUri ??= Uri.base.resolve(".packages")
              ..linkedDependencies = <Uri>[
                computePlatformBinariesLocation().resolve("vm_platform.dill")
              ]
              ..fileSystem = (new FileBackedMemoryFileSystem()
                ..entities[mainUri.path] =
                    (new MemoryFileSystemEntity(mainUri)..bytes = <int>[])),
            false,
            <Uri>[mainUri]);

  Future<Null> compile(String source) {
    defineSource(mainUri.path, source);
    return CompilerContext.runWithOptions(options,
        (CompilerContext context) async {
      (await context.options.loadSdkSummary(null))?.computeCanonicalNames();
      CompilerResult result = await generateKernelInternal();
      result?.component?.unbindCanonicalNames();
      return null;
    });
  }

  void defineSource(String path, String source) {
    if (!path.startsWith("/")) {
      throw new ArgumentError("'path' should start with a slash ('/').");
    }
    Uri uri = new Uri(scheme: customScheme, host: "", path: path);
    MemoryFileSystemEntity entity = options.fileSystem.entityForUri(uri);
    entity.bytes = utf8.encode(source);
  }
}

class FileBackedMemoryFileSystem implements FileSystem {
  final Map<String, MemoryFileSystemEntity> entities =
      <String, MemoryFileSystemEntity>{};

  FileSystemEntity entityForUri(Uri uri) {
    if (uri.scheme == customScheme) {
      MemoryFileSystemEntity entity = entities[uri.path];
      if (entity == null) {
        entity = new MemoryFileSystemEntity(uri);
        entities[uri.path] = entity;
      }
      return entity;
    } else {
      return StandardFileSystem.instance.entityForUri(uri);
    }
  }
}

class MemoryFileSystemEntity implements FileSystemEntity {
  final Uri uri;

  List<int> bytes;

  MemoryFileSystemEntity(this.uri);

  Future<List<int>> readAsBytes() {
    return bytes == null
        ? new Future.error(new FileSystemException(uri, "Not found"))
        : new Future.value(bytes);
  }

  Future<String> readAsString() {
    throw "unsupported operation";
  }

  Future<bool> exists() => new Future.value(bytes != null);
}
