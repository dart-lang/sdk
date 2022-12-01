// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/kernel.dart';
import 'package:vm/native_assets/validator.dart';

import 'json_to_kernel_constant.dart';

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
    nonNullableByDefaultCompiledMode = NonNullableByDefaultCompiledMode.Strong,
  }) {
    // We don't need the format-version in the VM.
    final jsonForVM = nativeAssetsYaml['native-assets'] as Map;
    final nativeAssetsConstant = jsonToKernelConstant(jsonForVM);

    final pragma = _pragmaClass();
    final pragmaName = pragma.fields.singleWhere((f) => f.name.text == 'name');
    final pragmaOptions =
        pragma.fields.singleWhere((f) => f.name.text == 'options');

    return Library(
      Uri.parse('vm:ffi:native-assets'),
      fileUri: _dummyFileUri,
      annotations: [
        ConstantExpression(InstanceConstant(pragma.reference, [], {
          pragmaName.fieldReference: StringConstant('vm:ffi:native-assets'),
          pragmaOptions.fieldReference: nativeAssetsConstant,
        }))
      ],
    )..nonNullableByDefaultCompiledMode = nonNullableByDefaultCompiledMode;
  }
}
