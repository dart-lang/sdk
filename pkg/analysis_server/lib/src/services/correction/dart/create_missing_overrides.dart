// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/dart/abstract_producer.dart';
import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server/src/utilities/strings.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/error/inheritance_override.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart' show Position;
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';

class CreateMissingOverrides extends CorrectionProducer {
  int _numElements;

  @override
  List<Object> get fixArguments => [_numElements];

  @override
  FixKind get fixKind => DartFixKind.CREATE_MISSING_OVERRIDES;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    if (node.parent is! ClassDeclaration) {
      return;
    }
    var targetClass = node.parent as ClassDeclaration;
    var targetClassElement = targetClass.declaredElement;
    utils.targetClassElement = targetClassElement;
    var signatures =
        InheritanceOverrideVerifier.missingOverrides(targetClass).toList();
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

    var prefix = utils.getIndent(1);
    await builder.addDartFileEdit(file, (builder) {
      builder.addInsertion(location.offset, (builder) {
        // Separator management.
        var numOfMembersWritten = 0;
        void addSeparatorBetweenDeclarations() {
          if (numOfMembersWritten == 0) {
            builder.write(location.prefix);
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
              builder.writeType(element.returnType, required: true);
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
      });
    });
    builder.setSelection(Position(file, location.offset));
  }

  /// Return an instance of this class. Used as a tear-off in `FixProcessor`.
  static CreateMissingOverrides newInstance() => CreateMissingOverrides();
}
