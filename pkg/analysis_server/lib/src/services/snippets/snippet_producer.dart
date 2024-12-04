// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/snippets/dart_snippet_request.dart';
import 'package:analysis_server/src/services/snippets/snippet.dart';
import 'package:analysis_server_plugin/edit/correction_utils.dart';
import 'package:analyzer/dart/analysis/code_style_options.dart';
import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/element/element2.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/analysis/session_helper.dart';
import 'package:analyzer/src/utilities/extensions/ast.dart';
import 'package:analyzer/src/utilities/extensions/flutter.dart';
import 'package:analyzer_plugin/src/utilities/change_builder/change_builder_dart.dart'
    show DartFileEditBuilderImpl;
import 'package:analyzer_plugin/utilities/change_builder/change_builder_dart.dart';
import 'package:meta/meta.dart';

abstract class DartSnippetProducer extends SnippetProducer {
  final AnalysisSessionHelper sessionHelper;
  final CorrectionUtils utils;
  final LibraryElement2 libraryElement;
  final bool useSuperParams;

  /// Elements that need to be imported for generated code to be valid.
  ///
  /// Calling [addImports] will add any required imports to the supplied
  /// builder.
  final Set<Element2> requiredElementImports = {};

  /// A cache of mappings from Elements to their public Library Elements.
  ///
  /// Callers can share this cache across multiple snippet producers to avoid
  /// repeated searches where they may add imports for the same elements.
  final Map<Element2, LibraryElement2?> _elementImportCache;

  DartSnippetProducer(
    super.request, {
    required Map<Element2, LibraryElement2?> elementImportCache,
  }) : sessionHelper = AnalysisSessionHelper(request.analysisSession),
       utils = CorrectionUtils(request.unit),
       libraryElement = request.unit.libraryElement2,
       useSuperParams = request.unit.libraryElement2.featureSet.isEnabled(
         Feature.super_parameters,
       ),
       _elementImportCache = elementImportCache;

  CodeStyleOptions get codeStyleOptions =>
      sessionHelper.session.analysisContext
          .getAnalysisOptionsForFile(request.unit.file)
          .codeStyleOptions;

  bool get isInTestDirectory => request.unit.unit.inTestDir;

  /// Adds public imports for any elements fetched by [getClass] and [getMixin]
  /// to [builder].
  Future<void> addImports(DartFileEditBuilder builder) async {
    var dartBuilder = builder as DartFileEditBuilderImpl;
    await Future.wait(
      requiredElementImports.map(
        (element) => dartBuilder.importElementLibrary2(
          element,
          resultCache: _elementImportCache,
        ),
      ),
    );
  }
}

abstract class FlutterSnippetProducer extends DartSnippetProducer {
  late ClassElement2? classWidget;
  late ClassElement2? classPlaceholder;

  FlutterSnippetProducer(super.request, {required super.elementImportCache});

  Future<ClassElement2?> getClass(String name) async {
    var class_ = await sessionHelper.getFlutterClass2(name);
    if (class_ != null) {
      requiredElementImports.add(class_);
    }
    return class_;
  }

  Future<MixinElement2?> getMixin(String name) async {
    var mixin = await sessionHelper.getMixin2(widgetsUri, name);
    if (mixin != null) {
      requiredElementImports.add(mixin);
    }
    return mixin;
  }

  DartType getType(
    InterfaceElement2 classElement, [
    NullabilitySuffix nullabilitySuffix = NullabilitySuffix.none,
  ]) => classElement.instantiate(
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
  ClassElement2? get classBuildContext;
  ClassElement2? get classKey;
  String get widgetClassName => 'MyWidget';

  void writeBuildMethod(DartEditBuilder builder) {
    // Checked by isValid() before this will be called.
    var classBuildContext = this.classBuildContext!;
    var classWidget = this.classWidget!;
    var classPlaceholder = this.classPlaceholder!;

    // Add the build method.
    builder.writeln('  @override');
    builder.write('  ');
    builder.writeFunctionDeclaration(
      'build',
      returnType: getType(classWidget),
      parameterWriter: () {
        builder.writeParameter('context', type: getType(classBuildContext));
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
    var classKey = this.classKey!;

    String keyName;
    DartType? keyType;
    void Function()? keyInitializer;
    if (useSuperParams) {
      keyName = 'super.key';
    } else {
      keyName = 'key';
      keyType = getType(classKey, NullabilitySuffix.question);
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

  /// The prefix a user types to use this snippet.
  String get snippetPrefix;

  Future<Snippet> compute();

  Future<bool> isValid() async {
    // File edit builders will not produce edits for files outside of the
    // analysis roots so we should not try to produce any snippets.
    var analysisContext = request.analysisSession.analysisContext;
    return analysisContext.contextRoot.isAnalyzed(request.filePath);
  }
}
