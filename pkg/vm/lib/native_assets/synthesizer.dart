// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:kernel/kernel.dart';
import 'package:vm/kernel_front_end.dart';

import 'diagnostic_message.dart';
import 'json_to_kernel_constant.dart';
import 'validator.dart';

final _dummyFileUri = Uri.parse('dummy');

class NativeAssetsSynthesizer {
  /// Returns a [Class] that another component may use to refer to
  /// pragma.
  ///
  /// Since uses are of symbolic nature, this class itself doesn't
  /// have to be serialized - it's needed since kernel AST needs
  /// non-symbolic AST nodes / References in-memory (when serializing
  /// they will be string-based, symbolic references)
  static Class _pragmaClass() {
    final corelibUri = Uri.parse('dart:core');
    final pragma = Class(
      name: 'pragma',
      fileUri: corelibUri,
      fields: [
        Field.immutable(Name('name'), fileUri: _dummyFileUri),
        Field.immutable(Name('options'), fileUri: _dummyFileUri),
      ],
    );
    Component(
      libraries: [
        Library(
          corelibUri,
          fileUri: _dummyFileUri,
          classes: [pragma],
        )
      ],
    );
    return pragma;
  }

  /// Synthesizes a [Library] to be included in a kernel snapshot for the VM.
  ///
  /// [nativeAssetsYaml] must have been validated with [NativeAssetsValidator].
  ///
  /// The VM consumes this component in runtime/vm/ffi/native_assets.cc.
  static Library synthesizeLibrary(
    Map nativeAssetsYaml, {
    Class? pragmaClass,
  }) {
    // We don't need the format-version in the VM.
    final jsonForVM = nativeAssetsYaml['native-assets'] as Map;
    final nativeAssetsConstant = jsonToKernelConstant(jsonForVM);

    pragmaClass ??= _pragmaClass();
    final pragmaName =
        pragmaClass.fields.singleWhere((f) => f.name.text == 'name');
    final pragmaOptions =
        pragmaClass.fields.singleWhere((f) => f.name.text == 'options');

    return Library(
      Uri.parse('vm:ffi:native-assets'),
      fileUri: _dummyFileUri,
      annotations: [
        ConstantExpression(InstanceConstant(pragmaClass.reference, [], {
          pragmaName.fieldReference: StringConstant('vm:ffi:native-assets'),
          pragmaOptions.fieldReference: nativeAssetsConstant,
        }))
      ],
    );
  }

  /// Loads [nativeAssetsYamlString], validates the contents, and synthesizes
  /// a [Library] for the VM.
  ///
  /// Takes a nullable [nativeAssetsYamlString] to ease code-flow on call site.
  ///
  /// Errors are reported with [errorDetector].
  static Future<Library?> synthesizeLibraryFromYamlString(
    String? nativeAssetsYamlString,
    ErrorDetector errorDetector, {
    Class? pragmaClass,
  }) async {
    if (nativeAssetsYamlString == null) {
      return null;
    }

    final nativeAssetsYaml = NativeAssetsValidator(errorDetector)
        .parseAndValidate(nativeAssetsYamlString);
    if (nativeAssetsYaml == null) {
      return null;
    }
    return NativeAssetsSynthesizer.synthesizeLibrary(
      nativeAssetsYaml,
      pragmaClass: pragmaClass,
    );
  }

  /// Loads [nativeAssetsUri], validates the contents, and synthesizes
  /// a [Library] for the VM.
  ///
  /// Takes a nullable [nativeAssetsUri] to ease code-flow on call site.
  ///
  /// Errors are reported with [errorDetector].
  static Future<Library?> synthesizeLibraryFromYamlFile(
    Uri? nativeAssetsUri,
    ErrorDetector errorDetector, {
    Class? pragmaClass,
  }) async {
    if (nativeAssetsUri == null) {
      return null;
    }

    final nativeAssetsFile = File.fromUri(nativeAssetsUri);
    if (!await nativeAssetsFile.exists()) {
      errorDetector(NativeAssetsDiagnosticMessage(
        message:
            "Native assets file ${nativeAssetsUri.toFilePath()} doesn't exist.",
        involvedFiles: [nativeAssetsUri],
      ));
      return null;
    }
    final nativeAssetsYamlString = await nativeAssetsFile.readAsString();

    return synthesizeLibraryFromYamlString(
      nativeAssetsYamlString,
      errorDetector,
      pragmaClass: pragmaClass,
    );
  }
}
