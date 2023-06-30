// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/scanner/token.dart';
import 'package:analysis_server/src/services/correction/dart/abstract_producer.dart';
import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server/src/utilities/strings.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/error/inheritance_override.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart' show Position;
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';

class CreateMissingOverrides extends ResolvedCorrectionProducer {
  int _numElements = 0;

  @override
  List<Object> get fixArguments => [_numElements, _numElements == 1 ? '' : 's'];

  @override
  FixKind get fixKind => DartFixKind.CREATE_MISSING_OVERRIDES;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    final targetClass = node;
    if (targetClass is! ClassDeclaration) {
      return;
    }
    utils.targetClassElement = targetClass.declaredElement;
    var signatures = [
      ...InheritanceOverrideVerifier.missingOverrides(targetClass),
      ...InheritanceOverrideVerifier.missingMustBeOverridden(targetClass)
    ];
    // sort by name, getters before setters
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

    var location =
        utils.prepareNewClassMemberLocation(targetClass, (_) => true);
    if (location == null) {
      return;
    }

    var prefix = utils.getIndent(1);
    await builder.addDartFileEdit(file, (builder) {
      final syntheticLeftBracket = targetClass.leftBracket.isSynthetic;
      if (syntheticLeftBracket) {
        var previousToLeftBracket = targetClass.leftBracket.previous!;
        builder.addSimpleInsertion(previousToLeftBracket.end, ' {');
      }

      builder.addInsertion(location.offset, (builder) {
        // Separator management.
        var numOfMembersWritten = 0;
        void addSeparatorBetweenDeclarations() {
          if (numOfMembersWritten == 0) {
            var locationPrefix = location.prefix;
            if (syntheticLeftBracket && locationPrefix.startsWith(eol)) {
              locationPrefix = locationPrefix.substring(eol.length);
            }
            builder.write(locationPrefix);
          } else {
            builder.write(eol); // after the previous member
            builder.write(eol); // empty line separator
            builder.write(prefix);
          }
          numOfMembersWritten++;
        }

        // merge getter/setter pairs into fields
        for (var i = 0; i < signatures.length; i++) {
          var element = signatures[i];
          if (element.kind == ElementKind.GETTER && i + 1 < signatures.length) {
            var nextElement = signatures[i + 1];
            if (nextElement.kind == ElementKind.SETTER) {
              // remove this and the next elements, adjust iterator
              signatures.removeAt(i + 1);
              signatures.removeAt(i);
              i--;
              _numElements--;
              // separator
              addSeparatorBetweenDeclarations();
              // @override
              builder.write('@override');
              builder.write(eol);
              // add field
              builder.write(prefix);
              builder.writeType(element.returnType2, required: true);
              builder.write(' ');
              builder.write(element.name);
              builder.write(';');
            }
          }
        }
        // add elements
        for (var element in signatures) {
          addSeparatorBetweenDeclarations();
          builder.writeOverride(element);
        }
        builder.write(location.suffix);

        if (targetClass.rightBracket.isSynthetic) {
          var next = targetClass.rightBracket.next!;
          if (next.type != TokenType.CLOSE_CURLY_BRACKET) {
            if (!syntheticLeftBracket) {
              builder.write(eol);
            }
            builder.write('}');
            if (syntheticLeftBracket) {
              builder.write(eol);
            }
          }
        }
      });
    });
    builder.setSelection(Position(file, location.offset));
  }
}
