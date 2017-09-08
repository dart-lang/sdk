// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/analysis/driver.dart';
import 'package:analyzer/src/dart/scanner/reader.dart';
import 'package:analyzer/src/dart/scanner/scanner.dart';
import 'package:analyzer/src/generated/engine.dart' show AnalysisOptionsImpl;
import 'package:analyzer/src/generated/parser.dart';
import 'package:analyzer/src/generated/resolver.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/generated/utilities_dart.dart';
import 'package:front_end/src/base/instrumentation.dart' as fasta;
import 'package:front_end/src/fasta/compiler_context.dart' as fasta;
import 'package:front_end/src/fasta/testing/validating_instrumentation.dart'
    as fasta;
import 'package:front_end/src/fasta/util/relativize.dart' show relativizeUri;
import 'package:kernel/kernel.dart' as fasta;
import 'package:path/path.dart' as pathos;
import 'package:test/test.dart';

import '../../dart/analysis/base.dart';

/// Set this to `true` to cause expectation comments to be updated.
const bool fixProblems = false;

class ElementNamer {
  final ConstructorElement currentFactoryConstructor;

  ElementNamer(this.currentFactoryConstructor);

  void appendElementName(StringBuffer buffer, Element element) {
    // Synthetic FunctionElement(s) don't have a name or enclosing library.
    if (element.isSynthetic && element is FunctionElement) {
      return;
    }

    var enclosing = element.enclosingElement;
    if (enclosing is CompilationUnitElement) {
      enclosing = enclosing.enclosingElement;
    } else if (enclosing is ClassElement &&
        currentFactoryConstructor != null &&
        identical(enclosing, currentFactoryConstructor.enclosingElement) &&
        element is TypeParameterElement) {
      enclosing = currentFactoryConstructor;
    }
    if (enclosing != null) {
      if (enclosing is LibraryElement &&
          (enclosing.name == 'dart.core' ||
              enclosing.name == 'dart.async' ||
              enclosing.name == 'test')) {
        // For brevity, omit library name
      } else {
        appendElementName(buffer, enclosing);
        buffer.write('::');
      }
    }

    String name = element.name ?? '';
    if (element is ConstructorElement && name == '') {
      name = '•';
    } else if (name.endsWith('=') &&
        element is PropertyAccessorElement &&
        element.isSetter) {
      name = name.substring(0, name.length - 1);
    }
    buffer.write(name);
  }
}

/// Instance of [InstrumentationValue] describing an [ExecutableElement].
class InstrumentationValueForExecutableElement
    extends fasta.InstrumentationValue {
  final ExecutableElement element;
  final ElementNamer elementNamer;

  InstrumentationValueForExecutableElement(this.element, this.elementNamer);

  @override
  String toString() {
    StringBuffer buffer = new StringBuffer();
    elementNamer.appendElementName(buffer, element);
    return buffer.toString();
  }
}

/**
 * Instance of [InstrumentationValue] describing a [DartType].
 */
class InstrumentationValueForType extends fasta.InstrumentationValue {
  final DartType type;
  final ElementNamer elementNamer;

  InstrumentationValueForType(this.type, this.elementNamer);

  @override
  String toString() {
    StringBuffer buffer = new StringBuffer();
    _appendType(buffer, type);
    return buffer.toString();
  }

  void _appendList<T>(StringBuffer buffer, String open, String close,
      List<T> items, String separator, writeItem(T item),
      {bool includeEmpty: false}) {
    if (!includeEmpty && items.isEmpty) {
      return;
    }
    buffer.write(open);
    bool first = true;
    for (T item in items) {
      if (!first) {
        buffer.write(separator);
      }
      writeItem(item);
      first = false;
    }
    buffer.write(close);
  }

  void _appendParameters(
      StringBuffer buffer, List<ParameterElement> parameters) {
    buffer.write('(');
    bool first = true;
    ParameterKind lastKind = ParameterKind.REQUIRED;
    for (var parameter in parameters) {
      if (!first) {
        buffer.write(', ');
      }
      if (lastKind != parameter.parameterKind) {
        if (parameter.parameterKind == ParameterKind.POSITIONAL) {
          buffer.write('[');
        } else if (parameter.parameterKind == ParameterKind.NAMED) {
          buffer.write('{');
        }
      }
      if (parameter.parameterKind == ParameterKind.NAMED) {
        buffer.write(parameter.name);
        buffer.write(': ');
      }
      _appendType(buffer, parameter.type);
      lastKind = parameter.parameterKind;
      first = false;
    }
    if (lastKind == ParameterKind.POSITIONAL) {
      buffer.write(']');
    } else if (lastKind == ParameterKind.NAMED) {
      buffer.write('}');
    }
    buffer.write(')');
  }

  void _appendType(StringBuffer buffer, DartType type) {
    if (type is FunctionType) {
      if (type.typeFormals.isNotEmpty) {
        _appendTypeFormals(buffer, type.typeFormals);
      }
      _appendParameters(buffer, type.parameters);
      buffer.write(' -> ');
      _appendType(buffer, type.returnType);
    } else if (type is InterfaceType) {
      ClassElement element = type.element;
      elementNamer.appendElementName(buffer, element);
      _appendTypeArguments(buffer, type.typeArguments);
    } else if (type.isBottom) {
      buffer.write('<BottomType>');
    } else if (type is TypeParameterType) {
      elementNamer.appendElementName(buffer, type.element);
    } else {
      buffer.write(type.toString());
    }
  }

  void _appendTypeArguments(StringBuffer buffer, List<DartType> typeArguments) {
    _appendList<DartType>(buffer, '<', '>', typeArguments, ', ',
        (type) => _appendType(buffer, type));
  }

  void _appendTypeFormals(
      StringBuffer buffer, List<TypeParameterElement> typeFormals) {
    _appendList<TypeParameterElement>(buffer, '<', '>', typeFormals, ', ',
        (formal) {
      buffer.write(formal.name);
      buffer.write(' extends ');
      if (formal.bound == null) {
        buffer.write('Object');
      } else {
        _appendType(buffer, formal.bound);
      }
    });
  }
}

/**
 * Instance of [InstrumentationValue] describing a list of [DartType]s.
 */
class InstrumentationValueForTypeArgs extends fasta.InstrumentationValue {
  final List<DartType> types;
  final ElementNamer elementNamer;

  const InstrumentationValueForTypeArgs(this.types, this.elementNamer);

  @override
  String toString() => types
      .map((type) =>
          new InstrumentationValueForType(type, elementNamer).toString())
      .join(', ');
}

abstract class RunFrontEndTest {
  String get testSubdir;

  test_run() async {
    String pkgPath = _findPkgRoot();
    String fePath = pathos.join(pkgPath, 'front_end', 'testcases', testSubdir);
    List<File> dartFiles = new Directory(fePath)
        .listSync()
        .where((entry) => entry is File && entry.path.endsWith('.dart'))
        .map((entry) => entry as File)
        .toList();

    var allProblems = new StringBuffer();
    for (File file in dartFiles) {
      var test = new _FrontEndInferenceTest(this);
      await test.setUp();
      try {
        String code = file.readAsStringSync();
        String problems = await test.runTest(file.path, code);
        if (problems != null) {
          allProblems.writeln(problems);
        }
      } finally {
        await test.tearDown();
      }
    }
    if (allProblems.isNotEmpty) {
      fail(allProblems.toString());
    }
  }

  void visitUnit(TypeProvider typeProvider, CompilationUnit unit,
      fasta.ValidatingInstrumentation validation, Uri uri);

  /**
   * Expects that the [Platform.script] is a test inside of `pkg/analyzer/test`
   * folder, and return the absolute path of the `pkg` folder.
   */
  String _findPkgRoot() {
    String scriptPath = pathos.fromUri(Platform.script);
    List<String> parts = pathos.split(scriptPath);
    for (int i = 0; i < parts.length - 2; i++) {
      if (parts[i] == 'pkg' &&
          parts[i + 1] == 'analyzer' &&
          parts[i + 2] == 'test') {
        return pathos.joinAll(parts.sublist(0, i + 1));
      }
    }
    throw new StateError('Unable to find sdk/pkg/ in $scriptPath');
  }
}

class _FrontEndInferenceTest extends BaseAnalysisDriverTest {
  final RunFrontEndTest _frontEndTestRunner;

  _FrontEndInferenceTest(this._frontEndTestRunner);

  @override
  AnalysisOptionsImpl createAnalysisOptions() =>
      super.createAnalysisOptions()..enableAssertInitializer = true;

  Future<String> runTest(String path, String code) {
    return fasta.CompilerContext.runWithDefaultOptions((_) async {
      Uri uri = provider.pathContext.toUri(path);

      List<int> lineStarts = new LineInfo.fromContent(code).lineStarts;
      fasta.CompilerContext.current.uriToSource[relativizeUri(uri).toString()] =
          new fasta.Source(lineStarts, UTF8.encode(code));

      var validation = new fasta.ValidatingInstrumentation();
      await validation.loadExpectations(uri);

      _addFileAndImports(path, code);

      AnalysisResult result = await driver.getResult(path);
      _frontEndTestRunner.visitUnit(
          result.typeProvider, result.unit, validation, uri);

      validation.finish();

      if (validation.hasProblems) {
        if (fixProblems) {
          validation.fixSource(uri, true);
          return null;
        } else {
          return validation.problemsAsString;
        }
      } else {
        return null;
      }
    });
  }

  void _addFileAndImports(String path, String code) {
    provider.newFile(path, code);
    var source = null;
    var analysisErrorListener = null;
    var scanner = new Scanner(
        source, new CharSequenceReader(code), analysisErrorListener);
    var token = scanner.tokenize();
    var compilationUnit =
        new Parser(source, analysisErrorListener).parseDirectives(token);
    for (var directive in compilationUnit.directives) {
      if (directive is UriBasedDirective) {
        Uri uri = Uri.parse(directive.uri.stringValue);
        if (uri.scheme == 'dart') {
          // Ignore these--they should be in the mock SDK.
        } else if (uri.scheme == '') {
          var pathSegments = uri.pathSegments;
          // For these tests we don't support any directory traversal; we just
          // assume the URI is the name of a file in the same directory as all
          // the other tests.
          if (pathSegments.length != 1) fail('URI too complex: $uri');
          var referencedPath =
              pathos.join(pathos.dirname(path), pathSegments[0]);
          if (!provider.getFile(referencedPath).exists) {
            var referencedCode = new File(referencedPath).readAsStringSync();
            _addFileAndImports(referencedPath, referencedCode);
          }
        }
      }
    }
  }
}
