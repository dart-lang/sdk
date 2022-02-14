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
      ResolvedIdentifier Function(Identifier) resolveIdentifier) {
    StringBuffer importsBuffer = new StringBuffer();
    StringBuffer directivesBuffer = new StringBuffer();
    Map<Uri, String> importPrefixes = {};
    int nextPrefix = 0;

    // Keeps track of the last part written in `lastDirectivePart`.
    String lastDirectivePart = '';
    void writeDirectivePart(String part) {
      lastDirectivePart = part;
      directivesBuffer.write(part);
    }

    void buildCode(Code code) {
      for (Object part in code.parts) {
        if (part is String) {
          writeDirectivePart(part);
        } else if (part is Code) {
          buildCode(part);
        } else if (part is Identifier) {
          ResolvedIdentifier resolved = resolveIdentifier(part);
          String? prefix;
          if (resolved.uri != null) {
            prefix = importPrefixes.putIfAbsent(resolved.uri!, () {
              String prefix = 'i${nextPrefix++}';
              importsBuffer.writeln("import '${resolved.uri}' as $prefix;");
              return prefix;
            });
          }
          if (resolved.kind == IdentifierKind.instanceMember) {
            // Qualify with `this.` if we don't have a receiver.
            if (!lastDirectivePart.trimRight().endsWith('.')) {
              writeDirectivePart('this.');
            }
          } else if (prefix != null) {
            writeDirectivePart('${prefix}.');
          }
          if (resolved.kind == IdentifierKind.staticInstanceMember) {
            writeDirectivePart('${resolved.staticScope!}.');
          }
          writeDirectivePart('${part.name}');
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
