// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library trydart.messages;

const Map<String, dynamic> messages = const <String, dynamic> {
  'alwaysRunInWorker':
    'Always run in Worker thread.',

  'alwaysRunInIframe':
    'Always run in inline frame.',

  'communicateViaBlobs':
    'Use blobs to send source code between components.',

  'verboseCompiler':
    'Verbose compiler output.',

  'minified':
    'Generate compact (minified) JavaScript.',

  'onlyAnalyze':
    'Only analyze program.',

  'enableDartMind':
    'Talk to "Dart Mind" server.',

  'compilationPaused':
    'Pause compilation.',

  'codeFont': const [
      'Code font:',
      'Enter a size and font, for example, 11pt monospace'],

  'currentSample':
    'N/A',

  'theme':
    'Theme:',

  'incrementalCompilation':
    'Enable incremental compilation (EXPERIMENTAL).',

  'hasSelectionModify':
    'Use Selection.modify.',
};
