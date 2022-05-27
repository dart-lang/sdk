// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/snippets/dart/dart_snippet_producers.dart';
import 'package:analysis_server/src/services/snippets/dart/snippet_manager.dart';
import 'package:analysis_server/src/utilities/flutter.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_dart.dart';
import 'package:meta/meta.dart';

abstract class FlutterSnippetProducer extends DartSnippetProducer {
  final flutter = Flutter.instance;

  late ClassElement? classWidget;
  late ClassElement? classContainer;

  FlutterSnippetProducer(super.request);

  @override
  @mustCallSuper
  Future<bool> isValid() async {
    if ((classWidget = await _getClass('Widget')) == null) {
      return false;
    }

    if ((classContainer = await _getClass('Container')) == null) {
      return false;
    }

    return super.isValid();
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

/// Produces a [Snippet] that creates a Flutter StatefulWidget and related State
/// class.
class FlutterStatefulWidgetSnippetProducer extends FlutterSnippetProducer
    with FlutterWidgetSnippetProducerMixin {
  static const prefix = 'stful';
  static const label = 'Flutter Stateful Widget';

  late ClassElement? classStatefulWidget;
  late ClassElement? classState;
  @override
  late ClassElement? classBuildContext;
  @override
  late ClassElement? classKey;

  FlutterStatefulWidgetSnippetProducer._(super.request);

  @override
  Future<Snippet> compute() async {
    final builder = ChangeBuilder(session: request.analysisSession);

    // Checked by isValid().
    final classStatefulWidget = this.classStatefulWidget!;
    final classState = this.classState!;

    await builder.addDartFileEdit(request.filePath, (builder) {
      builder.addReplacement(request.replacementRange, (builder) {
        // Write the StatefulWidget class
        builder.writeClassDeclaration(
          widgetClassName,
          nameGroupName: 'name',
          superclass: _getType(classStatefulWidget),
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
        builder.writeReference(classState);
        builder.write('<');
        builder.addSimpleLinkedEdit('name', widgetClassName);
        builder.writeln('> {');
        {
          writeBuildMethod(builder);
        }
        builder.write('}');
      });
    });

    return Snippet(
      prefix,
      label,
      'Insert a Flutter StatefulWidget.',
      builder.sourceChange,
    );
  }

  @override
  Future<bool> isValid() async {
    if (!await super.isValid()) {
      return false;
    }

    if ((classStatefulWidget = await _getClass('StatefulWidget')) == null ||
        (classState = await _getClass('State')) == null ||
        (classBuildContext = await _getClass('BuildContext')) == null ||
        (classKey = await _getClass('Key')) == null) {
      return false;
    }

    return true;
  }

  static FlutterStatefulWidgetSnippetProducer newInstance(
          DartSnippetRequest request) =>
      FlutterStatefulWidgetSnippetProducer._(request);
}

/// Produces a [Snippet] that creates a Flutter StatefulWidget with a
/// AnimationController and related State class.
class FlutterStatefulWidgetWithAnimationControllerSnippetProducer
    extends FlutterSnippetProducer with FlutterWidgetSnippetProducerMixin {
  static const prefix = 'stanim';
  static const label = 'Flutter Widget with AnimationController';

  late ClassElement? classStatefulWidget;
  late ClassElement? classState;
  @override
  late ClassElement? classBuildContext;
  @override
  late ClassElement? classKey;
  late ClassElement? classAnimationController;
  late ClassElement? classSingleTickerProviderStateMixin;

  FlutterStatefulWidgetWithAnimationControllerSnippetProducer._(super.request);

  @override
  Future<Snippet> compute() async {
    final builder = ChangeBuilder(session: request.analysisSession);

    // Checked by isValid().
    final classStatefulWidget = this.classStatefulWidget!;
    final classState = this.classState!;
    final classAnimationController = this.classAnimationController!;
    final classSingleTickerProviderStateMixin =
        this.classSingleTickerProviderStateMixin!;

    await builder.addDartFileEdit(request.filePath, (builder) {
      builder.addReplacement(request.replacementRange, (builder) {
        // Write the StatefulWidget class
        builder.writeClassDeclaration(
          widgetClassName,
          nameGroupName: 'name',
          superclass: _getType(classStatefulWidget),
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
        builder.writeReference(classState);
        builder.write('<');
        builder.addSimpleLinkedEdit('name', widgetClassName);
        builder.writeln('>');
        builder.write('    with ');
        builder.writeReference(classSingleTickerProviderStateMixin);
        builder.writeln(' {');
        builder.write('  late ');
        builder.writeReference(classAnimationController);
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
              builder.writeReference(classAnimationController);
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

    if ((classStatefulWidget = await _getClass('StatefulWidget')) == null ||
        (classState = await _getClass('State')) == null ||
        (classBuildContext = await _getClass('BuildContext')) == null ||
        (classKey = await _getClass('Key')) == null ||
        (classAnimationController = await _getClass('AnimationController')) ==
            null ||
        (classSingleTickerProviderStateMixin =
                await _getClass('SingleTickerProviderStateMixin')) ==
            null) {
      return false;
    }

    return true;
  }

  static FlutterStatefulWidgetWithAnimationControllerSnippetProducer
      newInstance(DartSnippetRequest request) =>
          FlutterStatefulWidgetWithAnimationControllerSnippetProducer._(
              request);
}

/// Produces a [Snippet] that creates a Flutter StatelessWidget.
class FlutterStatelessWidgetSnippetProducer extends FlutterSnippetProducer
    with FlutterWidgetSnippetProducerMixin {
  static const prefix = 'stless';
  static const label = 'Flutter Stateless Widget';

  late ClassElement? classStatelessWidget;
  @override
  late ClassElement? classBuildContext;
  @override
  late ClassElement? classKey;

  FlutterStatelessWidgetSnippetProducer._(super.request);

  @override
  Future<Snippet> compute() async {
    final builder = ChangeBuilder(session: request.analysisSession);

    // Checked by isValid().
    final classStatelessWidget = this.classStatelessWidget!;

    await builder.addDartFileEdit(request.filePath, (builder) {
      builder.addReplacement(request.replacementRange, (builder) {
        builder.writeClassDeclaration(
          widgetClassName,
          nameGroupName: 'name',
          superclass: _getType(classStatelessWidget),
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

    if ((classStatelessWidget = await _getClass('StatelessWidget')) == null ||
        (classBuildContext = await _getClass('BuildContext')) == null ||
        (classKey = await _getClass('Key')) == null) {
      return false;
    }

    return true;
  }

  static FlutterStatelessWidgetSnippetProducer newInstance(
          DartSnippetRequest request) =>
      FlutterStatelessWidgetSnippetProducer._(request);
}

/// A mixin that provides some common methods for producers that build snippets
/// for Flutter widget classes.
mixin FlutterWidgetSnippetProducerMixin on FlutterSnippetProducer {
  ClassElement? get classBuildContext;
  ClassElement? get classKey;
  String get widgetClassName => 'MyWidget';

  void writeBuildMethod(DartEditBuilder builder) {
    // Checked by isValid() before this will be called.
    final classBuildContext = this.classBuildContext!;
    final classWidget = this.classWidget!;
    final classContainer = this.classContainer!;

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
        builder.write('    return ');
        builder.selectAll(() {
          builder.writeType(_getType(classContainer));
          builder.write('()');
        });
        builder.writeln(';');
        builder.writeln('  }');
      },
    );
  }

  void writeCreateStateMethod(DartEditBuilder builder) {
    builder.writeln('  @override');
    builder.write('  State<');
    builder.addSimpleLinkedEdit('name', widgetClassName);
    builder.write('> createState() => _');
    builder.addSimpleLinkedEdit('name', widgetClassName);
    builder.writeln('State();');
  }

  void writeWidgetConstructor(DartEditBuilder builder) {
    // Checked by isValid() before this will be called.
    final classKey = this.classKey!;

    String keyName;
    DartType? keyType;
    void Function()? keyInitializer;
    if (useSuperParams) {
      keyName = 'super.key';
    } else {
      keyName = 'key';
      keyType = _getType(classKey, nullableSuffix);
      keyInitializer = () => builder.write('super(key: key)');
    }

    builder.write('  ');
    builder.writeConstructorDeclaration(
      widgetClassName,
      classNameGroupName: 'name',
      isConst: true,
      parameterWriter: () {
        builder.write('{');
        builder.writeParameter(keyName, type: keyType);
        builder.write('}');
      },
      initializerWriter: keyInitializer,
    );
  }
}
