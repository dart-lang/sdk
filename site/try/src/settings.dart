// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library trydart.settings;

import 'user_option.dart';

const BooleanUserOption _alwaysRunInWorker =
    const BooleanUserOption('alwaysRunInWorker');

bool get alwaysRunInWorker => _alwaysRunInWorker.value;

void set alwaysRunInWorker(bool b) {
  _alwaysRunInWorker.value = b;
}

const BooleanUserOption _verboseCompiler =
    const BooleanUserOption('verboseCompiler');

bool get verboseCompiler => _verboseCompiler.value;

void set verboseCompiler(bool b) {
  _verboseCompiler.value = b;
}

const BooleanUserOption _minified =
    const BooleanUserOption('minified');

bool get minified => _minified.value;

void set minified(bool b) {
  _minified.value = b;
}

const BooleanUserOption _onlyAnalyze =
    const BooleanUserOption('onlyAnalyze');

bool get onlyAnalyze => _onlyAnalyze.value;

void set onlyAnalyze(bool b) {
  _onlyAnalyze.value = b;
}

const BooleanUserOption _enableDartMind =
    const BooleanUserOption('enableDartMind', isHidden: true);

bool get enableDartMind => _enableDartMind.value;

void set enableDartMind(bool b) {
  _enableDartMind.value = b;
}

const BooleanUserOption _compilationPaused =
    const BooleanUserOption('compilationPaused');

bool get compilationPaused => _compilationPaused.value;

void set compilationPaused(bool b) {
  _compilationPaused.value = b;
}

const StringUserOption _codeFont =
    const StringUserOption('codeFont');

String get codeFont => _codeFont.value;

void set codeFont(String b) {
  _codeFont.value = b;
}

const StringUserOption _currentSample =
    const StringUserOption('currentSample', isHidden: true);

String get currentSample => _currentSample.value;

void set currentSample(String b) {
  _currentSample.value = b;
}

const StringUserOption _theme =
    const StringUserOption('theme');

String get theme => _theme.value;

void set theme(String b) {
  _theme.value = b;
}

const BooleanUserOption enableCodeCompletion =
    const BooleanUserOption('enableCodeCompletion', isHidden: true);

const BooleanUserOption incrementalCompilation =
    const BooleanUserOption('incrementalCompilation');

const BooleanUserOption live = const BooleanUserOption('live', isHidden: true);

const BooleanUserOption alwaysRunInIframe =
    const BooleanUserOption('alwaysRunInIframe', isHidden: true);

const BooleanUserOption communicateViaBlobs =
    const BooleanUserOption('communicateViaBlobs', isHidden: true);

const BooleanUserOption hasSelectionModify =
    const BooleanUserOption('hasSelectionModify', isHidden: true);

const List<UserOption> options = const <UserOption>[
    _alwaysRunInWorker,
    _verboseCompiler,
    _minified,
    _onlyAnalyze,
    _enableDartMind,
    _compilationPaused,
    incrementalCompilation,
    live,
    enableCodeCompletion,
    _codeFont,
    _theme,
    _currentSample,
    alwaysRunInIframe,
    communicateViaBlobs,
    hasSelectionModify,
  ];
