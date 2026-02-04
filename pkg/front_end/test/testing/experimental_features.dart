// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/experiments/flags.dart' as shared;
import 'package:_fe_analyzer_shared/src/parser/experimental_features.dart'
    as parser;
import 'package:_fe_analyzer_shared/src/scanner/scanner.dart'
    show LanguageVersionToken, Scanner, ScannerConfiguration;
import 'package:front_end/src/api_prototype/experimental_flags.dart' as cfe;
import 'package:kernel/ast.dart';

class ExperimentalFeaturesFromFlags implements parser.ExperimentalFeatures {
  Version? _version;
  Map<cfe.ExperimentalFlag, bool> _explicitExperimentalFlags;

  ExperimentalFeaturesFromFlags(this._explicitExperimentalFlags);

  @override
  bool isExperimentEnabled(shared.ExperimentalFlag flag) {
    cfe.ExperimentalFlag experimentalFlag = cfe.fromSharedExperimentalFlag(
      flag,
    );

    if (_version != null) {
      return cfe.isExperimentEnabledInLibraryByVersion(
        experimentalFlag,
        dummyUri,
        _version!,
        explicitExperimentalFlags: _explicitExperimentalFlags,
      );
    } else {
      return cfe.isExperimentEnabled(
        experimentalFlag,
        explicitExperimentalFlags: _explicitExperimentalFlags,
      );
    }
  }

  /// Updates the experimental flags and scanner configuration according to the
  /// [languageVersion].
  void onLanguageVersionChanged(
    Scanner scanner,
    LanguageVersionToken languageVersion,
  ) {
    _version = new Version(languageVersion.major, languageVersion.minor);

    scanner.configuration = scannerConfiguration;
  }

  /// Returns the current [ScannerConfiguration] given the explicit experimental
  /// flags and current language version.
  ScannerConfiguration get scannerConfiguration => new ScannerConfiguration(
    enableTripleShift: isExperimentEnabled(shared.ExperimentalFlag.tripleShift),
    forAugmentationLibrary: isExperimentEnabled(
      shared.ExperimentalFlag.augmentations,
    ),
  );
}
