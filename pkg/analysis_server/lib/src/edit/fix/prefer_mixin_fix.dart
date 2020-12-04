// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/protocol/protocol_generated.dart';
import 'package:analysis_server/src/edit/fix/dartfix_listener.dart';
import 'package:analysis_server/src/edit/fix/dartfix_registrar.dart';
import 'package:analysis_server/src/edit/fix/fix_code_task.dart';
import 'package:analysis_server/src/edit/fix/fix_lint_task.dart';
import 'package:analysis_server/src/services/correction/assist.dart';
import 'package:analysis_server/src/services/correction/assist_internal.dart';
import 'package:analysis_server/src/services/correction/change_workspace.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/instrumentation/service.dart';
import 'package:analyzer/src/dart/ast/utilities.dart';
import 'package:analyzer/src/lint/registry.dart';

class PreferMixinFix extends FixLintTask implements FixCodeTask {
  final classesToConvert = <Element>{};

  PreferMixinFix(DartFixListener listener) : super(listener);

  @override
  int get numPhases => 0;

  Future<void> convertClassToMixin(Element elem) async {
    var result = await listener.server.getResolvedUnit(elem.source?.fullName);

    for (var declaration in result.unit.declarations) {
      if (declaration is ClassOrMixinDeclaration &&
          declaration.name.name == elem.name) {
        var processor = AssistProcessor(
          DartAssistContextImpl(
              InstrumentationService.NULL_SERVICE,
              DartChangeWorkspace(listener.server.currentSessions),
              result,
              declaration.name.offset,
              0),
        );
        var assists = await processor
            .computeAssist(DartAssistKind.CONVERT_CLASS_TO_MIXIN);
        final location =
            listener.locationFor(result, elem.nameOffset, elem.nameLength);
        if (assists.isNotEmpty) {
          for (var assist in assists) {
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
  Future<void> finish() async {
    for (var elem in classesToConvert) {
      await convertClassToMixin(elem);
    }
  }

  @override
  Future<void> fixError(ResolvedUnitResult result, AnalysisError error) async {
    var node = NodeLocator(error.offset).searchWithin(result.unit);
    var type = node.thisOrAncestorOfType<TypeName>();
    if (type != null) {
      var element = type.name.staticElement;
      if (element.source?.fullName != null) {
        classesToConvert.add(element);
      }
    } else {
      // TODO(danrubel): Report if lint does not point to a type name
      final location = listener.locationFor(result, node.offset, node.length);
      listener.addRecommendation(
          'Cannot not convert $node to a mixin', location);
    }
  }

  @override
  Future<void> processPackage(Folder pkgFolder) async {}

  @override
  Future<void> processUnit(int phase, ResolvedUnitResult result) async {}

  static void task(DartFixRegistrar registrar, DartFixListener listener,
      EditDartfixParams params) {
    var task = PreferMixinFix(listener);
    registrar.registerLintTask(Registry.ruleRegistry['prefer_mixin'], task);
    registrar.registerCodeTask(task);
  }
}
