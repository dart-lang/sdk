// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// ignore: deprecated_member_use
import 'dart:cli' as cli;
import 'dart:convert';
import 'dart:io' as io;
import 'dart:typed_data';

import 'package:_fe_analyzer_shared/src/macros/bootstrap.dart';
import 'package:_fe_analyzer_shared/src/macros/executor/serialization.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/file_system/memory_file_system.dart';
import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:analyzer/src/summary2/macro.dart';
import 'package:analyzer/src/util/uri.dart';
import 'package:analyzer_utilities/package_root.dart' as package_root;
import 'package:front_end/src/api_prototype/compiler_options.dart' as fe;
import 'package:front_end/src/api_prototype/file_system.dart' as fe;
import 'package:front_end/src/fasta/kernel/utils.dart' as fe;
import 'package:kernel/target/targets.dart' as fe;
import 'package:path/path.dart' as package_path;
import 'package:vm/kernel_front_end.dart' as fe;
import 'package:vm/target/vm.dart' as fe;

final Uri _platformDillUri = Uri.parse('org-dartlang-sdk://vm.dill');

/// Implementation of [MacroKernelBuilder] that can run in Dart SDK repository.
///
/// This is a temporary implementation, to be replaced with a more stable
/// approach, e.g. a `dart:` API for compilation, shipping `front_end`
/// with SDK, etc.
class DartRepositoryMacroKernelBuilder implements MacroKernelBuilder {
  final Uint8List platformDillBytes;

  DartRepositoryMacroKernelBuilder(this.platformDillBytes);

  @override
  Uint8List build({
    required MacroFileSystem fileSystem,
    required List<MacroLibrary> libraries,
  }) {
    var options = fe.CompilerOptions()
      ..sdkSummary = _platformDillUri
      ..target = fe.VmTarget(fe.TargetFlags(enableNullSafety: true));

    var macroMainContent = bootstrapMacroIsolate(
      {
        for (var library in libraries)
          library.uri.toString(): {
            for (var c in library.classes) c.name: c.constructors
          },
      },
      SerializationMode.byteDataClient,
    );

    var macroMainBytes = utf8.encode(macroMainContent) as Uint8List;
    var macroMainPath = '${libraries.first.path}.macro';
    var macroMainUri = fileSystem.pathContext.toUri(macroMainPath);

    options.fileSystem = _FileSystem(
      fileSystem,
      platformDillBytes,
      macroMainUri,
      macroMainBytes,
    );

    // TODO(scheglov) For now we convert async into sync.
    // ignore: deprecated_member_use
    var compilationResults = cli.waitFor(
      fe.compileToKernel(
        macroMainUri,
        options,
        environmentDefines: {},
      ),
    );

    return fe.serializeComponent(
      compilationResults.component!,
      filter: (library) {
        return !library.importUri.isScheme('dart');
      },
      includeSources: false,
    );
  }
}

/// Environment for compiling macros to kernels, expecting that we run
/// a test in the Dart SDK repository.
///
/// Just like [DartRepositoryMacroKernelBuilder], this is a temporary
/// implementation.
class MacrosEnvironment {
  static final instance = MacrosEnvironment._();

  final _resourceProvider = MemoryResourceProvider(context: package_path.posix);
  late final Uint8List platformDillBytes;
  late final Folder packageAnalyzerFolder;

  MacrosEnvironment._() {
    var physical = PhysicalResourceProvider.INSTANCE;

    var packageRoot = physical.pathContext.normalize(package_root.packageRoot);
    physical
        .getFolder(packageRoot)
        .getChildAssumingFolder('_fe_analyzer_shared/lib/src/macros')
        .copyTo(
          packageSharedFolder.getChildAssumingFolder('lib/src'),
        );
    packageAnalyzerFolder =
        physical.getFolder(packageRoot).getChildAssumingFolder('analyzer');

    platformDillBytes = physical
        .getFile(io.Platform.resolvedExecutable)
        .parent
        .parent
        .getChildAssumingFolder('lib')
        .getChildAssumingFolder('_internal')
        .getChildAssumingFile('vm_platform_strong.dill')
        .readAsBytesSync();
  }

  Folder get packageSharedFolder {
    return _resourceProvider.getFolder('/packages/_fe_analyzer_shared');
  }
}

class _BytesFileSystemEntity implements fe.FileSystemEntity {
  @override
  final Uri uri;

  final Uint8List bytes;

  _BytesFileSystemEntity(this.uri, this.bytes);

  @override
  Future<bool> exists() async => true;

  @override
  Future<bool> existsAsyncIfPossible() => exists();

  @override
  Future<List<int>> readAsBytes() async => bytes;

  @override
  Future<List<int>> readAsBytesAsyncIfPossible() => readAsBytes();

  @override
  Future<String> readAsString() async {
    var bytes = await readAsBytes();
    return utf8.decode(bytes);
  }
}

class _FileSystem implements fe.FileSystem {
  final MacroFileSystem fileSystem;
  final Uint8List platformDillBytes;
  final Uri macroMainUri;
  final Uint8List macroMainBytes;

  _FileSystem(
    this.fileSystem,
    this.platformDillBytes,
    this.macroMainUri,
    this.macroMainBytes,
  );

  @override
  fe.FileSystemEntity entityForUri(Uri uri) {
    if (uri == _platformDillUri) {
      return _BytesFileSystemEntity(uri, platformDillBytes);
    } else if (uri == macroMainUri) {
      return _BytesFileSystemEntity(uri, macroMainBytes);
    } else if (uri.isScheme('file')) {
      var path = fileUriToNormalizedPath(fileSystem.pathContext, uri);
      return _FileSystemEntity(
        uri,
        fileSystem.getFile(path),
      );
    } else {
      throw fe.FileSystemException(uri, 'Only supports file: URIs');
    }
  }
}

class _FileSystemEntity implements fe.FileSystemEntity {
  @override
  final Uri uri;

  final MacroFileEntry file;

  _FileSystemEntity(this.uri, this.file);

  @override
  Future<bool> exists() async => file.exists;

  @override
  Future<bool> existsAsyncIfPossible() => exists();

  @override
  Future<List<int>> readAsBytes() async {
    var string = await readAsString();
    return utf8.encode(string);
  }

  @override
  Future<List<int>> readAsBytesAsyncIfPossible() => readAsBytes();

  @override
  Future<String> readAsString() async => file.content;
}
