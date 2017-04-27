// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/analysis/driver.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:front_end/src/base/instrumentation.dart' as fasta;
import 'package:front_end/src/fasta/compiler_context.dart' as fasta;
import 'package:front_end/src/fasta/testing/validating_instrumentation.dart'
    as fasta;
import 'package:kernel/kernel.dart' as fasta;
import 'package:path/path.dart' as pathos;
import 'package:test/test.dart';

import '../../dart/analysis/base.dart';

Future<Null> main() async {
  await _runFrontEndInferenceTests();
}

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

Future<Null> _runFrontEndInferenceTests() async {
  String pkgPath = _findPkgRoot();
  String fePath = pathos.join(pkgPath, 'front_end', 'testcases', 'inference');
  List<File> dartFiles = new Directory(fePath)
      .listSync()
      .where((entry) => entry is File && entry.path.endsWith('.dart'))
      .map((entry) => entry as File)
      .toList();

  for (File file in dartFiles) {
    var test = new _FrontEndInferenceTest();
    await test.setUp();
    try {
      String code = file.readAsStringSync();
      await test.runTest(file.path, code);
    } catch (_) {
      print(_);
    } finally {
      await test.tearDown();
    }
  }
}

class _FrontEndInferenceTest extends BaseAnalysisDriverTest {
  Future<Null> runTest(String path, String code) async {
    Uri uri = provider.pathContext.toUri(path);

    List<int> lineStarts = new LineInfo.fromContent(code).lineStarts;
    fasta.CompilerContext.current.uriToSource[uri.toString()] =
        new fasta.Source(lineStarts, UTF8.encode(code));

    var validation = new fasta.ValidatingInstrumentation();
    await validation.loadExpectations(uri);

    provider.newFile(path, code);

    AnalysisResult result = await driver.getResult(path);
    result.unit.accept(new _InstrumentationVisitor(validation, uri));

    validation.finish();

    if (validation.hasProblems) {
      fail(validation.problemsAsString);
    }
  }
}

/**
 * Instance of [InstrumentationValue] describing a [DartType].
 */
class _InstrumentationValueForType extends fasta.InstrumentationValue {
  final DartType type;

  _InstrumentationValueForType(this.type);

  @override
  String toString() {
    StringBuffer buffer = new StringBuffer();
    _appendType(buffer, type);
    return buffer.toString();
  }

  void _appendElementName(StringBuffer buffer, Element element) {
    String name = element.name;
    String libraryName = element.library.name;
    if (libraryName == '') {
      throw new StateError('The element $name must be in a named library.');
    }
    if (libraryName != 'dart.core' &&
        libraryName != 'dart.async' &&
        libraryName != 'test') {
      buffer.write('$libraryName::$name');
    } else {
      buffer.write('$name');
    }
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
    _appendList<ParameterElement>(buffer, '(', ')', parameters, ', ',
        (parameter) {
      _appendType(buffer, type);
      buffer.write(' ');
      buffer.write(parameter.name);
    }, includeEmpty: true);
  }

  void _appendType(StringBuffer buffer, DartType type) {
    if (type is FunctionType) {
      Element element = type.element;
      _appendElementName(buffer, element);
      _appendTypeArguments(buffer, type.typeArguments);
      _appendParameters(buffer, type.parameters);
      buffer.write(' → ');
      _appendType(buffer, type.returnType);
    } else if (type is InterfaceType) {
      ClassElement element = type.element;
      _appendElementName(buffer, element);
      _appendTypeArguments(buffer, type.typeArguments);
    } else {
      buffer.write(type.toString());
    }
  }

  void _appendTypeArguments(StringBuffer buffer, List<DartType> typeArguments) {
    _appendList<DartType>(buffer, '<', '>', typeArguments, ', ',
        (type) => _appendType(buffer, type));
  }
}

/**
 * Instance of [InstrumentationValue] describing a list of [DartType]s.
 */
class _InstrumentationValueForTypeArgs extends fasta.InstrumentationValue {
  final List<DartType> types;

  const _InstrumentationValueForTypeArgs(this.types);

  @override
  String toString() => types
      .map((type) => new _InstrumentationValueForType(type).toString())
      .join(', ');
}

/**
 * Visitor for ASTs that reports instrumentation for types.
 */
class _InstrumentationVisitor extends RecursiveAstVisitor<Null> {
  final fasta.Instrumentation _instrumentation;
  final Uri uri;

  _InstrumentationVisitor(this._instrumentation, this.uri);

  visitFunctionExpression(FunctionExpression node) {
    super.visitFunctionExpression(node);
    if (node.parent is! FunctionDeclaration) {
      DartType type = node.staticType;
      if (type is FunctionType) {
        _instrumentation.record(uri, node.offset, 'returnType',
            new _InstrumentationValueForType(type.returnType));
        List<FormalParameter> parameters = node.parameters.parameters;
        for (int i = 0; i < parameters.length; i++) {
          FormalParameter parameter = parameters[i];
          if (parameter is SimpleFormalParameter && parameter.type == null) {
            _recordType(parameter.offset, type.parameters[i].type);
          }
        }
      }
    }
  }

  visitInstanceCreationExpression(InstanceCreationExpression node) {
    super.visitInstanceCreationExpression(node);
    DartType type = node.staticType;
    if (type is InterfaceType) {
      if (type.typeParameters.isNotEmpty &&
          node.constructorName.type.typeArguments == null) {
        _recordTypeArguments(node.offset, type.typeArguments);
      }
    }
  }

  visitSimpleIdentifier(SimpleIdentifier node) {
    super.visitSimpleIdentifier(node);
    Element element = node.staticElement;
    if (element is LocalVariableElement && node.inGetterContext()) {
      int offset = node.offset;
      DartType type = node.staticType;
      if (identical(type, element.type)) {
        _instrumentation.record(uri, offset, 'promotedType',
            const fasta.InstrumentationValueLiteral('none'));
      } else {
        _instrumentation.record(uri, offset, 'promotedType',
            new _InstrumentationValueForType(type));
      }
    }
  }

  visitVariableDeclarationList(VariableDeclarationList node) {
    super.visitVariableDeclarationList(node);
    if (node.type == null) {
      for (VariableDeclaration variable in node.variables) {
        VariableElement element = variable.element;
        if (element is LocalVariableElement) {
          _recordType(variable.name.offset, element.type);
        } else {
          _recordTopType(variable.name.offset, element.type);
        }
      }
    }
  }

  void _recordTopType(int offset, DartType type) {
    _instrumentation.record(
        uri, offset, 'topType', new _InstrumentationValueForType(type));
  }

  void _recordType(int offset, DartType type) {
    _instrumentation.record(
        uri, offset, 'type', new _InstrumentationValueForType(type));
  }

  void _recordTypeArguments(int offset, List<DartType> typeArguments) {
    _instrumentation.record(uri, offset, 'typeArgs',
        new _InstrumentationValueForTypeArgs(typeArguments));
  }
}
