// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/dart/abstract_producer.dart';
import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server/src/utilities/strings.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/error/inheritance_override.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';

class CreateMissingOverrides extends ResolvedCorrectionProducer {
  int _numElements = 0;

  @override
  CorrectionApplicability get applicability =>
      // TODO(applicability): comment on why.
      CorrectionApplicability.singleLocation;

  @override
  List<String> get fixArguments =>
      [_numElements.toString(), _numElements == 1 ? '' : 's'];

  @override
  FixKind get fixKind => DartFixKind.CREATE_MISSING_OVERRIDES;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    var targetDeclaration = node;
    if (targetDeclaration is! NamedCompilationUnitMember) {
      return;
    }
    if (targetDeclaration is! ClassDeclaration &&
        targetDeclaration is! EnumDeclaration) {
      return;
    }
    var signatures = [
      ...InheritanceOverrideVerifier.missingOverrides(targetDeclaration),
      ...InheritanceOverrideVerifier.missingMustBeOverridden(targetDeclaration)
    ];
    // Sort by name, getters before setters.
    signatures.sort((ExecutableElement a, ExecutableElement b) {
      var names = compareStrings(a.displayName, b.displayName);
      if (names != 0) {
        return names;
      }
      if (a.kind == ElementKind.GETTER) {
        return -1;
      }
      return 1;
    });
    _numElements = signatures.length;

    var prefix = utils.oneIndent;
    await builder.addDartFileEdit(file, (builder) {
      builder.insertIntoUnitMember(targetDeclaration, (builder) {
        // Separator management.
        var numOfMembersWritten = 0;
        void addSeparatorBetweenDeclarations() {
          if (numOfMembersWritten == 0) {
            if (_numElements > 1) {
              // Set the selection to the offset of the first member inserted.
              builder.selectHere();
            }
          } else {
            builder.write(eol); // After the previous member.
            builder.write(eol); // Empty line separator.
            builder.write(prefix);
          }
          numOfMembersWritten++;
        }

        // Merge getter/setter pairs into fields.
        for (var i = 0; i < signatures.length; i++) {
          var element = signatures[i];
          if (element.kind == ElementKind.GETTER && i + 1 < signatures.length) {
            var nextElement = signatures[i + 1];
            if (nextElement.kind == ElementKind.SETTER) {
              // Remove this and the next elements, adjust iterator.
              signatures.removeAt(i + 1);
              signatures.removeAt(i);
              i--;
              _numElements--;
              // Add a separator.
              addSeparatorBetweenDeclarations();
              // Add `@override`.
              builder.write('@override');
              builder.write(eol);
              // Add field.
              builder.write(prefix);
              if (targetDeclaration is EnumDeclaration) {
                builder.write(Keyword.FINAL.lexeme);
                builder.write(' ');
              }
              builder.writeType(element.returnType, required: true);
              builder.write(' ');
              builder.write(element.name);
              builder.write(';');
            }
          }
        }
        // Add elements.
        for (var element in signatures) {
          addSeparatorBetweenDeclarations();
          // When only 1 override is being added, we delegate the
          // selection-setting to `builder.writeOverride`.
          builder.writeOverride(element, setSelection: _numElements == 1);
        }
      });
    });
  }
}
