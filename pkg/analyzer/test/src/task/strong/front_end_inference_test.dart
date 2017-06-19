// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/analysis/driver.dart';
import 'package:analyzer/src/generated/parser.dart';
import 'package:analyzer/src/generated/scanner.dart';
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
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../dart/analysis/base.dart';

main() {
  // Use a group() wrapper to specify the timeout.
  group('front_end_inference_test', () {
    defineReflectiveSuite(() {
      defineReflectiveTests(RunFrontEndInferenceTest);
    });
  }, timeout: new Timeout(const Duration(seconds: 120)));
}

/// Set this to `true` to cause expectation comments to be updated.
const bool fixProblems = false;

@reflectiveTest
class RunFrontEndInferenceTest {
  test_run() async {
    String pkgPath = _findPkgRoot();
    String fePath = pathos.join(pkgPath, 'front_end', 'testcases', 'inference');
    List<File> dartFiles = new Directory(fePath)
        .listSync()
        .where((entry) => entry is File && entry.path.endsWith('.dart'))
        .map((entry) => entry as File)
        .toList();

    var allProblems = new StringBuffer();
    for (File file in dartFiles) {
      var test = new _FrontEndInferenceTest();
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

class _ElementNamer {
  final ConstructorElement currentFactoryConstructor;

  _ElementNamer(this.currentFactoryConstructor);

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

class _FrontEndInferenceTest extends BaseAnalysisDriverTest {
  Future<String> runTest(String path, String code) async {
    Uri uri = provider.pathContext.toUri(path);

    List<int> lineStarts = new LineInfo.fromContent(code).lineStarts;
    fasta.CompilerContext.current.uriToSource[relativizeUri(uri).toString()] =
        new fasta.Source(lineStarts, UTF8.encode(code));

    var validation = new fasta.ValidatingInstrumentation();
    await validation.loadExpectations(uri);

    _addFileAndImports(path, code);

    AnalysisResult result = await driver.getResult(path);
    result.unit.accept(new _InstrumentationVisitor(validation, uri));

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

/// Instance of [InstrumentationValue] describing an [ExecutableElement].
class _InstrumentationValueForExecutableElement
    extends fasta.InstrumentationValue {
  final ExecutableElement element;
  final _ElementNamer elementNamer;

  _InstrumentationValueForExecutableElement(this.element, this.elementNamer);

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
class _InstrumentationValueForType extends fasta.InstrumentationValue {
  final DartType type;
  final _ElementNamer elementNamer;

  _InstrumentationValueForType(this.type, this.elementNamer);

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
        _appendTypeArguments(buffer, type.typeArguments);
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
}

/**
 * Instance of [InstrumentationValue] describing a list of [DartType]s.
 */
class _InstrumentationValueForTypeArgs extends fasta.InstrumentationValue {
  final List<DartType> types;
  final _ElementNamer elementNamer;

  const _InstrumentationValueForTypeArgs(this.types, this.elementNamer);

  @override
  String toString() => types
      .map((type) =>
          new _InstrumentationValueForType(type, elementNamer).toString())
      .join(', ');
}

/**
 * Visitor for ASTs that reports instrumentation for types.
 */
class _InstrumentationVisitor extends RecursiveAstVisitor<Null> {
  final fasta.Instrumentation _instrumentation;
  final Uri uri;
  _ElementNamer elementNamer = new _ElementNamer(null);

  _InstrumentationVisitor(this._instrumentation, this.uri);

  visitBinaryExpression(BinaryExpression node) {
    super.visitBinaryExpression(node);
    _recordTarget(node.operator.charOffset, node.staticElement);
  }

  @override
  visitConstructorDeclaration(ConstructorDeclaration node) {
    _ElementNamer oldElementNamer = elementNamer;
    if (node.factoryKeyword != null) {
      // Factory constructors are represented in kernel as static methods, so
      // their type parameters get replicated, e.g.:
      //     class C<T> {
      //       factory C.ctor() {
      //         T t; // Refers to C::T
      //         ...
      //       }
      //     }
      // gets converted to:
      //     class C<T> {
      //       static C<T> C.ctor<T>() {
      //         T t; // Refers to C::ctor::T
      //         ...
      //       }
      //     }
      // So to match kernel behavior, we have to arrange for this renaming to
      // happen during output.
      elementNamer = new _ElementNamer(node.element);
    }
    super.visitConstructorDeclaration(node);
    elementNamer = oldElementNamer;
  }

  @override
  visitDeclaredIdentifier(DeclaredIdentifier node) {
    super.visitDeclaredIdentifier(node);
    if (node.type == null) {
      _recordType(node.identifier.offset, node.element.type);
    }
  }

  visitFunctionExpression(FunctionExpression node) {
    super.visitFunctionExpression(node);
    if (node.parent is! FunctionDeclaration) {
      DartType type = node.staticType;
      if (type is FunctionType) {
        _instrumentation.record(uri, node.parameters.offset, 'returnType',
            new _InstrumentationValueForType(type.returnType, elementNamer));
        List<FormalParameter> parameters = node.parameters.parameters;
        for (int i = 0; i < parameters.length; i++) {
          FormalParameter parameter = parameters[i];
          NormalFormalParameter normalParameter =
              parameter is DefaultFormalParameter
                  ? parameter.parameter
                  : parameter;
          if (normalParameter is SimpleFormalParameter &&
              normalParameter.type == null) {
            _recordType(parameter.offset, type.parameters[i].type);
          }
        }
      }
    }
  }

  @override
  visitFunctionExpressionInvocation(FunctionExpressionInvocation node) {
    super.visitFunctionExpressionInvocation(node);
    var receiverType = node.function.staticType;
    if (receiverType is InterfaceType) {
      // This is a hack since analyzer doesn't record .call targets
      var target = receiverType.element.lookUpMethod('call', null) ??
          receiverType.element.lookUpGetter('call', null);
      if (target != null) {
        _recordTarget(node.argumentList.offset, target);
      }
    }
    if (node.typeArguments == null) {
      var inferredTypeArguments = _getInferredFunctionTypeArguments(
              node.function.staticType,
              node.staticInvokeType,
              node.typeArguments)
          .toList();
      if (inferredTypeArguments.isNotEmpty) {
        _recordTypeArguments(node.argumentList.offset, inferredTypeArguments);
      }
    }
  }

  visitIndexExpression(IndexExpression node) {
    super.visitIndexExpression(node);
    _recordTarget(node.leftBracket.charOffset, node.staticElement);
  }

  visitInstanceCreationExpression(InstanceCreationExpression node) {
    super.visitInstanceCreationExpression(node);
    DartType type = node.staticType;
    if (type is InterfaceType) {
      if (type.typeParameters.isNotEmpty &&
          node.constructorName.type.typeArguments == null) {
        _recordTypeArguments(node.constructorName.offset, type.typeArguments);
      }
    }
  }

  visitListLiteral(ListLiteral node) {
    super.visitListLiteral(node);
    if (node.typeArguments == null) {
      DartType type = node.staticType;
      if (type is InterfaceType) {
        _recordTypeArguments(node.offset, type.typeArguments);
      }
    }
  }

  visitMapLiteral(MapLiteral node) {
    super.visitMapLiteral(node);
    if (node.typeArguments == null) {
      DartType type = node.staticType;
      if (type is InterfaceType) {
        _recordTypeArguments(node.offset, type.typeArguments);
      }
    }
  }

  @override
  visitMethodDeclaration(MethodDeclaration node) {
    super.visitMethodDeclaration(node);
    if (node.element.enclosingElement is ClassElement) {
      if (node.isGetter && node.returnType == null) {
        _recordTopType(node.name.offset, node.element.returnType);
      }
      if (node.isSetter) {
        for (var parameter in node.parameters.parameters) {
          // Note: it's tempting to check `parameter.type == null`, but that
          // doesn't work because of function-typed formal parameter syntax.
          if (parameter.element.hasImplicitType) {
            _recordTopType(parameter.identifier.offset, parameter.element.type);
          }
        }
      }
    }
  }

  visitMethodInvocation(MethodInvocation node) {
    super.visitMethodInvocation(node);
    if (node.typeArguments == null) {
      var inferredTypeArguments = _getInferredFunctionTypeArguments(
              node.function.staticType,
              node.staticInvokeType,
              node.typeArguments)
          .toList();
      if (inferredTypeArguments.isNotEmpty) {
        _recordTypeArguments(node.methodName.offset, inferredTypeArguments);
      }
    }
  }

  visitPrefixExpression(PrefixExpression node) {
    super.visitPrefixExpression(node);
    if (node.operator.type != TokenType.PLUS_PLUS &&
        node.operator.type != TokenType.MINUS_MINUS) {
      _recordTarget(node.operator.charOffset, node.staticElement);
    }
  }

  visitSimpleIdentifier(SimpleIdentifier node) {
    super.visitSimpleIdentifier(node);
    Element element = node.staticElement;
    if (_elementRequiresMethodDispatch(element) &&
        !node.inDeclarationContext() &&
        (node.inGetterContext() || node.inSetterContext())) {
      _recordTarget(node.offset, element);
    }
    void recordPromotions(DartType elementType) {
      if (node.inGetterContext() && !node.inDeclarationContext()) {
        int offset = node.offset;
        DartType type = node.staticType;
        if (!identical(type, elementType)) {
          _instrumentation.record(uri, offset, 'promotedType',
              new _InstrumentationValueForType(type, elementNamer));
        }
      }
    }

    if (element is LocalVariableElement) {
      recordPromotions(element.type);
    } else if (element is ParameterElement) {
      recordPromotions(element.type);
    }
  }

  visitVariableDeclarationList(VariableDeclarationList node) {
    super.visitVariableDeclarationList(node);
    if (node.type == null) {
      for (VariableDeclaration variable in node.variables) {
        VariableElement element = variable.element;
        if (element is LocalVariableElement) {
          _recordType(variable.name.offset, element.type);
        } else if (!element.isStatic || element.initializer != null) {
          _recordTopType(variable.name.offset, element.type);
        }
      }
    }
  }

  bool _elementRequiresMethodDispatch(Element element) {
    if (element is ConstructorElement) {
      return false;
    } else if (element is ClassMemberElement) {
      return !element.isStatic;
    } else if (element is ExecutableElement &&
        element.enclosingElement is ClassElement) {
      return !element.isStatic;
    } else {
      return false;
    }
  }

  /// Based on DDC code generator's `_emitFunctionTypeArguments`
  Iterable<DartType> _getInferredFunctionTypeArguments(
      DartType g, DartType f, TypeArgumentList typeArgs) {
    if (g is FunctionType &&
        g.typeFormals.isNotEmpty &&
        f is FunctionType &&
        f.typeFormals.isEmpty) {
      return _recoverTypeArguments(g, f);
    } else {
      return const [];
    }
  }

  void _recordTarget(int offset, Element element) {
    if (element is ExecutableElement) {
      _instrumentation.record(uri, offset, 'target',
          new _InstrumentationValueForExecutableElement(element, elementNamer));
    }
  }

  void _recordTopType(int offset, DartType type) {
    _instrumentation.record(uri, offset, 'topType',
        new _InstrumentationValueForType(type, elementNamer));
  }

  void _recordType(int offset, DartType type) {
    _instrumentation.record(uri, offset, 'type',
        new _InstrumentationValueForType(type, elementNamer));
  }

  void _recordTypeArguments(int offset, List<DartType> typeArguments) {
    _instrumentation.record(uri, offset, 'typeArgs',
        new _InstrumentationValueForTypeArgs(typeArguments, elementNamer));
  }

  /// Based on DDC code generator's `_recoverTypeArguments`
  Iterable<DartType> _recoverTypeArguments(FunctionType g, FunctionType f) {
    assert(identical(g.element, f.element));
    assert(g.typeFormals.isNotEmpty && f.typeFormals.isEmpty);
    assert(g.typeFormals.length + g.typeArguments.length ==
        f.typeArguments.length);
    return f.typeArguments.skip(g.typeArguments.length);
  }
}
