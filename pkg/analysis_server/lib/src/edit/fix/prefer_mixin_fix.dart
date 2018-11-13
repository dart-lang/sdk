// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/plugin/edit/assist/assist_core.dart';
import 'package:analysis_server/src/edit/edit_dartfix.dart';
import 'package:analysis_server/src/services/correction/assist.dart';
import 'package:analysis_server/src/services/correction/assist_internal.dart';
import 'package:analyzer/analyzer.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/dart/analysis/driver.dart';

class PreferMixinFix extends LinterFix {
  final classesToConvert = new Set<Element>();

  PreferMixinFix(EditDartFix dartFix) : super(dartFix);

  @override
  Future<void> applyLocalFixes(AnalysisResult result) {
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
    AnalysisResult result =
        await dartFix.server.getAnalysisResult(elem.source?.fullName);

    for (CompilationUnitMember declaration in result.unit.declarations) {
      if (declaration is ClassOrMixinDeclaration &&
          declaration.name.name == elem.name) {
        AssistProcessor processor = new AssistProcessor(
            new EditDartFixAssistContext(
                dartFix, elem.source, result.unit, declaration.name));
        List<Assist> assists = await processor
            .computeAssist(DartAssistKind.CONVERT_CLASS_TO_MIXIN);
        final location =
            dartFix.locationFor(result, elem.nameOffset, elem.nameLength);
        if (assists.isNotEmpty) {
          for (Assist assist in assists) {
            dartFix.addFix('Convert ${elem.displayName} to a mixin', location,
                assist.change);
          }
        } else {
          // TODO(danrubel): If assists is empty, then determine why
          // assist could not be performed and report that in the description.
          dartFix.addRecommendation(
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
    String filePath = element.source?.fullName;
    if (filePath != null && dartFix.isIncluded(filePath)) {
      classesToConvert.add(element);
    }
  }
}
