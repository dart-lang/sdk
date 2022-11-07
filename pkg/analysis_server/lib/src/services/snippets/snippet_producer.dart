// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/util.dart';
import 'package:analysis_server/src/services/snippets/dart_snippet_request.dart';
import 'package:analysis_server/src/services/snippets/snippet.dart';
import 'package:analysis_server/src/utilities/flutter.dart';
import 'package:analyzer/dart/analysis/code_style_options.dart';
import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/analysis/session_helper.dart';
import 'package:analyzer/src/lint/linter.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_dart.dart';
import 'package:meta/meta.dart';

abstract class DartSnippetProducer extends SnippetProducer {
  final AnalysisSessionHelper sessionHelper;
  final CorrectionUtils utils;
  final LibraryElement libraryElement;
  final bool useSuperParams;

  DartSnippetProducer(super.request)
      : sessionHelper = AnalysisSessionHelper(request.analysisSession),
        utils = CorrectionUtils(request.unit),
        libraryElement = request.unit.libraryElement,
        useSuperParams = request.unit.libraryElement.featureSet
            .isEnabled(Feature.super_parameters);

  CodeStyleOptions get codeStyleOptions =>
      sessionHelper.session.analysisContext.analysisOptions.codeStyleOptions;

  bool get isInTestDirectory {
    final path = request.unit.path;
    return LinterContextImpl.testDirectories
        .any((testDir) => path.contains(testDir));
  }

  /// The nullable suffix to use in this library.
  NullabilitySuffix get nullableSuffix => libraryElement.isNonNullableByDefault
      ? NullabilitySuffix.question
      : NullabilitySuffix.none;
}

abstract class FlutterSnippetProducer extends DartSnippetProducer {
  final flutter = Flutter.instance;

  late ClassElement? classWidget;
  late ClassElement? classPlaceholder;

  FlutterSnippetProducer(super.request);

  Future<ClassElement?> getClass(String name) =>
      sessionHelper.getClass(flutter.widgetsUri, name);

  Future<MixinElement?> getMixin(String name) =>
      sessionHelper.getMixin(flutter.widgetsUri, name);

  DartType getType(
    InterfaceElement classElement, [
    NullabilitySuffix nullabilitySuffix = NullabilitySuffix.none,
  ]) =>
      classElement.instantiate(
        typeArguments: const [],
        nullabilitySuffix: nullabilitySuffix,
      );

  @override
  @mustCallSuper
  Future<bool> isValid() async {
    if ((classWidget = await getClass('Widget')) == null) {
      return false;
    }

    if ((classPlaceholder = await getClass('Placeholder')) == null) {
      return false;
    }

    return super.isValid();
  }
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
    final classPlaceholder = this.classPlaceholder!;

    // Add the build method.
    builder.writeln('  @override');
    builder.write('  ');
    builder.writeFunctionDeclaration(
      'build',
      returnType: getType(classWidget),
      parameterWriter: () {
        builder.writeParameter(
          'context',
          type: getType(classBuildContext),
        );
      },
      bodyWriter: () {
        builder.writeln('{');
        builder.write('    return ');
        builder.selectAll(() {
          builder.write('const ');
          builder.writeType(getType(classPlaceholder));
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
      keyType = getType(classKey, nullableSuffix);
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

abstract class SnippetProducer {
  final DartSnippetRequest request;

  SnippetProducer(this.request);

  Future<Snippet> compute();

  Future<bool> isValid() async {
    // File edit builders will not produce edits for files outside of the
    // analysis roots so we should not try to produce any snippets.
    final analysisContext = request.analysisSession.analysisContext;
    return analysisContext.contextRoot.isAnalyzed(request.filePath);
  }
}
