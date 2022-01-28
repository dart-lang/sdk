// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../api.dart';
import '../executor.dart';

/// A mixin which provides a shared implementation of
/// [MacroExecutor.buildAugmentationLibrary].
mixin AugmentationLibraryBuilder on MacroExecutor {
  @override
  String buildAugmentationLibrary(Iterable<MacroExecutionResult> macroResults,
      Uri Function(Identifier) resolveIdentifier) {
    StringBuffer importsBuffer = new StringBuffer();
    StringBuffer directivesBuffer = new StringBuffer();
    Map<Uri, String> importPrefixes = {};
    int nextPrefix = 0;

    void buildCode(Code code) {
      for (Object part in code.parts) {
        if (part is String) {
          directivesBuffer.write(part);
        } else if (part is Code) {
          buildCode(part);
        } else if (part is Identifier) {
          Uri uri = resolveIdentifier(part);
          String prefix = importPrefixes.putIfAbsent(uri, () {
            String prefix = 'i${nextPrefix++}';
            importsBuffer.writeln("import '$uri' as $prefix;");
            return prefix;
          });
          directivesBuffer.write('$prefix.${part.name}');
        } else {
          throw new ArgumentError(
              'Code objects only support String, Identifier, and Code '
              'instances but got $part which was not one of those.');
        }
      }
    }

    for (MacroExecutionResult result in macroResults) {
      for (DeclarationCode augmentation in result.augmentations) {
        buildCode(augmentation);
        directivesBuffer.writeln();
      }
    }
    return '$importsBuffer\n\n$directivesBuffer';
  }
}
