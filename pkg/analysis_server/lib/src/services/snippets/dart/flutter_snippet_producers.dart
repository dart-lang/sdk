// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/snippets/dart/snippet_manager.dart';
import 'package:analysis_server/src/utilities/flutter.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/analysis/session_helper.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:meta/meta.dart';

abstract class FlutterSnippetProducer extends SnippetProducer {
  final flutter = Flutter.instance;
  final AnalysisSessionHelper sessionHelper;

  late ClassElement? classWidget;

  FlutterSnippetProducer(DartSnippetRequest request)
      : sessionHelper = AnalysisSessionHelper(request.analysisSession),
        super(request);

  @override
  @mustCallSuper
  Future<bool> isValid() async {
    classWidget = await _getClass('Widget');

    return classWidget != null;
  }

  Future<ClassElement?> _getClass(String name) =>
      sessionHelper.getClass(flutter.widgetsUri, name);

  DartType _getType(
    ClassElement classElement, [
    NullabilitySuffix nullabilitySuffix = NullabilitySuffix.none,
  ]) =>
      classElement.instantiate(
        typeArguments: const [],
        nullabilitySuffix: nullabilitySuffix,
      );
}

/// Contributes snippets useful in Flutter applications, such as creating
/// Flutter widget classes.
class FlutterStatelessWidgetSnippetProducer extends FlutterSnippetProducer {
  static const prefix = 'stless';
  static const label = 'Flutter Stateless Widget';

  late ClassElement? classStatelessWidget;
  late ClassElement? classBuildContext;
  late ClassElement? classKey;

  FlutterStatelessWidgetSnippetProducer(DartSnippetRequest request)
      : super(request);

  @override
  Future<Snippet> compute() async {
    final builder = ChangeBuilder(session: request.analysisSession);

    // Checked by isValid().
    final classStatelessWidget = this.classStatelessWidget!;
    final classWidget = this.classWidget!;
    final classBuildContext = this.classBuildContext!;
    final classKey = this.classKey!;

    // Only include `?` for nulable types like Key? if in a null-safe library.
    final nullableSuffix = request.unit.libraryElement.isNonNullableByDefault
        ? NullabilitySuffix.question
        : NullabilitySuffix.none;

    final className = 'MyWidget';
    await builder.addDartFileEdit(request.filePath, (builder) {
      builder.addReplacement(request.replacementRange, (builder) {
        builder.writeClassDeclaration(
          className,
          nameGroupName: 'name',
          superclass: _getType(classStatelessWidget),
          membersWriter: () {
            // Add the constructor.
            builder.write('  ');
            builder.writeConstructorDeclaration(
              className,
              classNameGroupName: 'name',
              isConst: true,
              parameterWriter: () {
                builder.write('{');
                builder.writeParameter(
                  'key',
                  type: _getType(classKey, nullableSuffix),
                );
                builder.write('}');
              },
              initializerWriter: () => builder.write('super(key: key)'),
            );
            builder.writeln();
            builder.writeln();

            // Add the build method.
            builder.writeln('  @override');
            builder.write('  ');
            builder.writeFunctionDeclaration(
              'build',
              returnType: _getType(classWidget),
              parameterWriter: () {
                builder.writeParameter(
                  'context',
                  type: _getType(classBuildContext),
                );
              },
              bodyWriter: () {
                builder.writeln('{');
                builder.write('    ');
                builder.selectHere();
                builder.writeln('');
                builder.writeln('  }');
              },
            );
          },
        );
      });
    });

    return Snippet(
      prefix,
      label,
      'Insert a StatelessWidget',
      builder.sourceChange,
    );
  }

  @override
  Future<bool> isValid() async {
    if (!await super.isValid()) {
      return false;
    }

    classStatelessWidget = await _getClass('StatelessWidget');
    if (classStatelessWidget == null) {
      return false;
    }

    classBuildContext = await _getClass('BuildContext');
    if (classBuildContext == null) {
      return false;
    }

    classKey = await _getClass('Key');
    if (classKey == null) {
      return false;
    }

    return true;
  }

  static FlutterStatelessWidgetSnippetProducer newInstance(
          DartSnippetRequest request) =>
      FlutterStatelessWidgetSnippetProducer(request);
}
