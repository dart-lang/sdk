// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/plugin/edit/assist/assist_core.dart';
import 'package:analysis_server/src/edit/fix/dartfix_listener.dart';
import 'package:analysis_server/src/edit/fix/dartfix_registrar.dart';
import 'package:analysis_server/src/edit/fix/fix_lint_task.dart';
import 'package:analysis_server/src/services/correction/assist.dart';
import 'package:analysis_server/src/services/correction/assist_internal.dart';
import 'package:analysis_server/src/services/correction/change_workspace.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/src/lint/registry.dart';

class PreferMixinFix extends FixLintTask {
  static String useMixinSetup(
      DartFixRegistrar registrar, DartFixListener listener) {
    registrar.registerLintTask(
      Registry.ruleRegistry['prefer_mixin'],
      new PreferMixinFix(listener),
    );
    return null;
  }

  final classesToConvert = new Set<Element>();

  PreferMixinFix(DartFixListener listener) : super(listener);

  @override
  Future<void> applyLocalFixes(ResolvedUnitResult result) {
    // All fixes applied in [applyRemainingFixes]
    return null;
  }

  @override
  Future<void> applyRemainingFixes() async {
    for (Element elem in classesToConvert) {
      await convertClassToMixin(elem);
    }
  }

  Future<void> convertClassToMixin(Element elem) async {
    ResolvedUnitResult result =
        await listener.server.getResolvedUnit(elem.source?.fullName);

    for (CompilationUnitMember declaration in result.unit.declarations) {
      if (declaration is ClassOrMixinDeclaration &&
          declaration.name.name == elem.name) {
        AssistProcessor processor = new AssistProcessor(
          new DartAssistContextImpl(
              DartChangeWorkspace(listener.server.currentSessions),
              result,
              declaration.name.offset,
              0),
        );
        List<Assist> assists = await processor
            .computeAssist(DartAssistKind.CONVERT_CLASS_TO_MIXIN);
        final location =
            listener.locationFor(result, elem.nameOffset, elem.nameLength);
        if (assists.isNotEmpty) {
          for (Assist assist in assists) {
            listener.addSourceChange('Convert ${elem.displayName} to a mixin',
                location, assist.change);
          }
        } else {
          // TODO(danrubel): If assists is empty, then determine why
          // assist could not be performed and report that in the description.
          listener.addRecommendation(
              'Could not convert ${elem.displayName} to a mixin'
              ' because the class contains a constructor',
              location);
        }
      }
    }
  }

  @override
  void reportErrorForNode(ErrorCode errorCode, AstNode node,
      [List<Object> arguments]) {
    TypeName type = node;
    Element element = type.name.staticElement;
    if (element.source?.fullName != null) {
      classesToConvert.add(element);
    }
  }
}
