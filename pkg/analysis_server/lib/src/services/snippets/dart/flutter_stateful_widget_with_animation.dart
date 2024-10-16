// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/snippets/snippet.dart';
import 'package:analysis_server/src/services/snippets/snippet_producer.dart';
import 'package:analyzer/dart/element/element2.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';

/// Produces a [Snippet] that creates a Flutter StatefulWidget with an
/// AnimationController and related State class.
class FlutterStatefulWidgetWithAnimationController
    extends FlutterSnippetProducer with FlutterWidgetSnippetProducerMixin {
  static const prefix = 'stanim';
  static const label = 'Flutter Widget with AnimationController';

  late ClassElement2? classStatefulWidget;
  late ClassElement2? classState;
  @override
  late ClassElement2? classBuildContext;
  @override
  late ClassElement2? classKey;
  late ClassElement2? classAnimationController;
  late MixinElement2? classSingleTickerProviderStateMixin;

  FlutterStatefulWidgetWithAnimationController(super.request,
      {required super.elementImportCache});

  @override
  String get snippetPrefix => prefix;

  @override
  Future<Snippet> compute() async {
    var builder = ChangeBuilder(session: request.analysisSession);

    // Checked by isValid().
    var classStatefulWidget = this.classStatefulWidget!;
    var classState = this.classState!;
    var classAnimationController = this.classAnimationController!;
    var classSingleTickerProviderStateMixin =
        this.classSingleTickerProviderStateMixin!;

    await builder.addDartFileEdit(request.filePath, (builder) async {
      await addImports(builder);

      builder.addReplacement(request.replacementRange, (builder) {
        // Write the StatefulWidget class
        builder.writeClassDeclaration(
          widgetClassName,
          nameGroupName: 'name',
          superclass: getType(classStatefulWidget),
          membersWriter: () {
            writeWidgetConstructor(builder);
            builder.writeln();
            builder.writeln();

            writeCreateStateMethod(builder);
          },
        );
        builder.writeln();
        builder.writeln();

        // Write the State class.
        builder.write('class _');
        builder.addSimpleLinkedEdit('name', widgetClassName);
        builder.write('State extends ');
        builder.writeReference2(classState);
        builder.write('<');
        builder.addSimpleLinkedEdit('name', widgetClassName);
        builder.writeln('>');
        builder.write('    with ');
        builder.writeReference2(classSingleTickerProviderStateMixin);
        builder.writeln(' {');
        builder.write('  late ');
        builder.writeReference2(classAnimationController);
        builder.writeln(' _controller;');
        builder.writeln();
        {
          // Add the initState method.
          builder.writeln('  @override');
          builder.write('  ');
          builder.writeFunctionDeclaration(
            'initState',
            returnType: VoidTypeImpl.instance,
            bodyWriter: () {
              builder.writeln('{');
              builder.writeln('    super.initState();');
              builder.write('    _controller = ');
              builder.writeReference2(classAnimationController);
              builder.writeln('(vsync: this);');
              builder.writeln('  }');
            },
          );
        }
        builder.writeln();
        {
          // Add the dispose method.
          builder.writeln('  @override');
          builder.write('  ');
          builder.writeFunctionDeclaration(
            'dispose',
            returnType: VoidTypeImpl.instance,
            bodyWriter: () {
              builder.writeln('{');
              builder.writeln('    _controller.dispose();');
              builder.writeln('    super.dispose();');
              builder.writeln('  }');
            },
          );
        }
        builder.writeln();
        {
          writeBuildMethod(builder);
        }
        builder.write('}');
      });
    });

    return Snippet(
      prefix,
      label,
      'Insert a Flutter StatefulWidget with an AnimationController.',
      builder.sourceChange,
    );
  }

  @override
  Future<bool> isValid() async {
    if (!await super.isValid()) {
      return false;
    }

    if ((classStatefulWidget = await getClass('StatefulWidget')) == null ||
        (classState = await getClass('State')) == null ||
        (classBuildContext = await getClass('BuildContext')) == null ||
        (classKey = await getClass('Key')) == null ||
        (classAnimationController = await getClass('AnimationController')) ==
            null ||
        (classSingleTickerProviderStateMixin =
                await getMixin('SingleTickerProviderStateMixin')) ==
            null) {
      return false;
    }

    return true;
  }
}
