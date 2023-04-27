// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/messages/diagnostic_message.dart';
import 'package:front_end/src/api_prototype/compiler_options.dart';
import 'package:front_end/src/api_prototype/kernel_generator.dart';
import 'package:front_end/src/api_prototype/terminal_color_support.dart';
import 'package:front_end/src/compute_platform_binaries_location.dart';
import 'package:front_end/src/fasta/command_line_reporting.dart';
import 'package:front_end/src/fasta/fasta_codes.dart';
import 'package:front_end/src/kernel_generator_impl.dart';
import 'package:kernel/ast.dart';
import 'package:kernel/class_hierarchy.dart';
import 'package:kernel/core_types.dart';
import 'package:kernel/src/redirecting_factory_body.dart';
import 'package:kernel/type_environment.dart';

typedef PerformAnalysisFunction = void Function(
    DiagnosticMessageHandler onDiagnostic, Component component);
typedef UriFilter = bool Function(Uri uri);

Future<void> runAnalysis(
    List<Uri> entryPoints, PerformAnalysisFunction performAnalysis) async {
  CompilerOptions options = new CompilerOptions();
  options.sdkRoot = computePlatformBinariesLocation(forceBuildDir: true);
  options.packagesFileUri = Uri.base.resolve('.dart_tool/package_config.json');

  options.onDiagnostic = (DiagnosticMessage message) {
    printDiagnosticMessage(message, print);
  };
  InternalCompilerResult compilerResult = await kernelForProgramInternal(
          entryPoints.first, options,
          retainDataForTesting: true,
          requireMain: false,
          additionalSources: entryPoints.skip(1).toList())
      as InternalCompilerResult;

  performAnalysis(options.onDiagnostic!, compilerResult.component!);
}

class StaticTypeVisitorBase extends RecursiveVisitor {
  final TypeEnvironment typeEnvironment;

  StaticTypeContext? staticTypeContext;

  StaticTypeVisitorBase(Component component, ClassHierarchy classHierarchy)
      : typeEnvironment =
            new TypeEnvironment(new CoreTypes(component), classHierarchy);

  @override
  void visitProcedure(Procedure node) {
    if (node.kind == ProcedureKind.Factory && isRedirectingFactory(node)) {
      // Don't visit redirecting factories.
      return;
    }
    staticTypeContext = new StaticTypeContext(node, typeEnvironment);
    super.visitProcedure(node);
    staticTypeContext = null;
  }

  @override
  void visitField(Field node) {
    if (isRedirectingFactoryField(node)) {
      // Skip synthetic .dill members.
      return;
    }
    staticTypeContext = new StaticTypeContext(node, typeEnvironment);
    super.visitField(node);
    staticTypeContext = null;
  }

  @override
  void visitConstructor(Constructor node) {
    staticTypeContext = new StaticTypeContext(node, typeEnvironment);
    super.visitConstructor(node);
    staticTypeContext = null;
  }
}

class AnalysisVisitor extends StaticTypeVisitorBase {
  final DiagnosticMessageHandler onDiagnostic;
  final Component component;
  final UriFilter? uriFilter;
  late final AnalysisInterface interface;

  Map<String, Map<String, List<FormattedMessage>>> _messages = {};

  AnalysisVisitor(this.onDiagnostic, this.component, this.uriFilter)
      : super(component,
            new ClassHierarchy(component, new CoreTypes(component))) {
    interface = new AnalysisInterface(this);
  }

  @override
  void visitLibrary(Library node) {
    if (uriFilter != null) {
      if (uriFilter!(node.importUri)) {
        super.visitLibrary(node);
      }
    } else {
      super.visitLibrary(node);
    }
  }

  void registerMessage(TreeNode node, String message) {
    Location location = node.location!;
    Uri uri = location.file;
    String uriString = relativizeUri(uri)!;
    Map<String, List<FormattedMessage>> actualMap = _messages.putIfAbsent(
        uriString, () => <String, List<FormattedMessage>>{});
    if (uri.isScheme('org-dartlang-sdk')) {
      location = new Location(Uri.base.resolve(uri.path.substring(1)),
          location.line, location.column);
    }
    LocatedMessage locatedMessage = templateUnspecified
        .withArguments(message)
        .withLocation(uri, node.fileOffset, noLength);
    FormattedMessage diagnosticMessage = locatedMessage.withFormatting(
        format(locatedMessage, Severity.warning,
            location: location, uriToSource: component.uriToSource),
        location.line,
        location.column,
        Severity.warning,
        []);
    actualMap
        .putIfAbsent(message, () => <FormattedMessage>[])
        .add(diagnosticMessage);
  }

  void forEachMessage(
      void Function(String, Map<String, List<FormattedMessage>>) f) {
    _messages.forEach(f);
  }

  Map<String, List<FormattedMessage>>? getMessagesForUri(String uri) {
    return _messages[uri];
  }

  void printMessages() {
    forEachMessage((String uri, Map<String, List<FormattedMessage>> messages) {
      messages.forEach((String message, List<FormattedMessage> actualMessages) {
        for (FormattedMessage message in actualMessages) {
          onDiagnostic(message);
        }
      });
    });
  }
}

/// Convenience interface for performing analysis.
class AnalysisInterface {
  final AnalysisVisitor _visitor;
  final ComponentLookup _componentLookup;

  AnalysisInterface(this._visitor)
      : _componentLookup = new ComponentLookup(_visitor.component);

  void reportMessage(TreeNode node, String message) {
    _visitor.registerMessage(node, message);
  }

  InterfaceType createInterfaceType(String className,
      {String? uri, List<DartType>? typeArguments}) {
    LibraryLookup libraryLookup =
        _componentLookup.getLibrary(Uri.parse(uri ?? 'dart:core'));
    ClassLookup classLookup = libraryLookup.getClass(className);
    Class cls = classLookup.cls;
    return new InterfaceType(
        cls,
        Nullability.nonNullable,
        typeArguments ??
            new List<DartType>.generate(
                cls.typeParameters.length, (index) => const DynamicType()));
  }

  bool isSubtypeOf(DartType subtype, DartType supertype) {
    return _visitor.typeEnvironment
        .isSubtypeOf(subtype, supertype, SubtypeCheckMode.withNullabilities);
  }
}

typedef GeneralAnalysisFunction = void Function(
    TreeNode node, AnalysisInterface interface);

/// Generalized analyzer that uses a single [GeneralAnalysisFunction] on all
/// [TreeNode]s.
class GeneralAnalyzer extends AnalysisVisitor {
  final GeneralAnalysisFunction analyzer;

  GeneralAnalyzer(DiagnosticMessageHandler onDiagnostic, Component component,
      bool Function(Uri uri)? analyzedUrisFilter, this.analyzer)
      : super(onDiagnostic, component, analyzedUrisFilter);

  @override
  void defaultTreeNode(TreeNode node) {
    analyzer(node, interface);
    super.defaultTreeNode(node);
  }
}

/// Returns a function that will perform [analysisFunction] on [TreeNode]s
/// in a component, using [uriFilter] to filter which libraries that will be
/// visited.
PerformAnalysisFunction performGeneralAnalysis(
    UriFilter? uriFilter, GeneralAnalysisFunction analysisFunction) {
  return (DiagnosticMessageHandler onDiagnostic, Component component) {
    GeneralAnalyzer analyzer = new GeneralAnalyzer(
        onDiagnostic, component, uriFilter, analysisFunction);
    component.accept(analyzer);
    analyzer.printMessages();
  };
}

/// Helper class for looking up libraries in a [Component].
class ComponentLookup {
  final Component _component;

  ComponentLookup(this._component);

  Map<Uri, LibraryLookup>? _libraries;

  LibraryLookup getLibrary(Uri uri) {
    LibraryLookup? libraryLookup = (_libraries ??= new Map.fromIterable(
        _component.libraries,
        key: (library) => library.importUri,
        value: (library) => new LibraryLookup(library)))[uri];
    if (libraryLookup == null) {
      throw "Couldn't find library for '$uri'.";
    }
    return libraryLookup;
  }
}

/// Helper class for looking up classes and members in a [Library].
// TODO(johnniwinther): Support member lookup.
class LibraryLookup {
  final Library library;

  LibraryLookup(this.library);

  Map<String, ClassLookup>? _classes;

  ClassLookup getClass(String name) {
    ClassLookup? classLookup = (_classes ??= new Map.fromIterable(
        library.classes,
        key: (cls) => cls.name,
        value: (cls) => new ClassLookup(cls)))[name];
    if (classLookup == null) {
      throw "Couldn't find class '$name' in ${library.importUri}.";
    }
    return classLookup;
  }
}

/// Helper class for looking up members in a [Class].
// TODO(johnniwinther): Support member lookup.
class ClassLookup {
  final Class cls;

  ClassLookup(this.cls);
}

/// Entry points used for analyzing cfe source code.
// TODO(johnniwinther): Update this to include all files in the cfe, and not
//  only those reachable from 'compiler.dart'.
final List<Uri> cfeOnlyEntryPoints = [
  Uri.base.resolve('pkg/front_end/tool/_fasta/compile.dart')
];

/// Filter function used to only analyze cfe source code.
bool cfeOnly(Uri uri) {
  String text = '$uri';
  for (String path in [
    'package:_fe_analyzer_shared/',
    'package:kernel/',
    'package:front_end/',
  ]) {
    if (text.startsWith(path)) {
      return true;
    }
  }
  return false;
}

/// Entry points used for analyzing cfe and backend source code.
// TODO(johnniwinther): Update this to include all files in cfe and backends,
//  and not only those reachable from these entry points.
List<Uri> cfeAndBackendsEntryPoints = [
  Uri.base.resolve('pkg/front_end/tool/_fasta/compile.dart'),
  Uri.base.resolve('pkg/vm/lib/kernel_front_end.dart'),
  Uri.base.resolve('pkg/compiler/bin/dart2js.dart'),
  Uri.base.resolve('pkg/dev_compiler/bin/dartdevc.dart'),
  Uri.base.resolve('pkg/frontend_server/bin/frontend_server_starter.dart'),
];

/// Filter function used to only analyze cfe and backend source code.
bool cfeAndBackends(Uri uri) {
  String text = '$uri';
  for (String path in [
    'package:_fe_analyzer_shared/',
    'package:kernel/',
    'package:front_end/',
    'package:frontend_server/',
    'package:vm/',
    'package:compiler/',
    'package:dartdevc/',
    'package:_js_interop_checks/',
  ]) {
    if (text.startsWith(path)) {
      return true;
    }
  }
  return false;
}
