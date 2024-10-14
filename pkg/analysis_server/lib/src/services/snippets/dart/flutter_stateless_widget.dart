// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/snippets/snippet.dart';
import 'package:analysis_server/src/services/snippets/snippet_producer.dart';
import 'package:analyzer/dart/element/element2.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';

/// Produces a [Snippet] that creates a Flutter StatelessWidget.
class FlutterStatelessWidget extends FlutterSnippetProducer
    with FlutterWidgetSnippetProducerMixin {
  static const prefix = 'stless';
  static const label = 'Flutter Stateless Widget';

  late ClassElement2? classStatelessWidget;

  @override
  late ClassElement2? classBuildContext;

  @override
  late ClassElement2? classKey;

  FlutterStatelessWidget(super.request, {required super.elementImportCache});

  @override
  String get snippetPrefix => prefix;

  @override
  Future<Snippet> compute() async {
    var builder = ChangeBuilder(session: request.analysisSession);

    // Checked by isValid().
    var classStatelessWidget = this.classStatelessWidget!;

    await builder.addDartFileEdit(request.filePath, (builder) async {
      await addImports(builder);

      builder.addReplacement(request.replacementRange, (builder) {
        builder.writeClassDeclaration(
          widgetClassName,
          nameGroupName: 'name',
          superclass: getType(classStatelessWidget),
          membersWriter: () {
            writeWidgetConstructor(builder);
            builder.writeln();
            builder.writeln();

            writeBuildMethod(builder);
          },
        );
      });
    });

    return Snippet(
      prefix,
      label,
      'Insert a Flutter StatelessWidget.',
      builder.sourceChange,
    );
  }

  @override
  Future<bool> isValid() async {
    if (!await super.isValid()) {
      return false;
    }

    if ((classStatelessWidget = await getClass('StatelessWidget')) == null ||
        (classBuildContext = await getClass('BuildContext')) == null ||
        (classKey = await getClass('Key')) == null) {
      return false;
    }

    return true;
  }
}
