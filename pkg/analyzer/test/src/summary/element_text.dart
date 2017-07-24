// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/generated/utilities_dart.dart';
import 'package:analyzer/src/summary/idl.dart';
import 'package:test/test.dart';

/**
 * Set this path to automatically replace expectations in invocations of
 * [checkElementText] with the new actual texts.
 */
const String _testPath = null;

/**
 * The list of replacements that update expectations.
 */
final List<_Replacement> _replacements = [];

/**
 * The cached content of the file with the [_testPath].
 */
String _testCode;

/**
 * The cache line information for the [_testPath] file.
 */
LineInfo _testCodeLines;

void applyCheckElementTextReplacements() {
  if (_testPath != null && _replacements.isNotEmpty) {
    _replacements.sort((a, b) => b.offset - a.offset);
    String newCode = _testCode;
    _replacements.forEach((r) {
      newCode =
          newCode.substring(0, r.offset) + r.text + newCode.substring(r.end);
    });
    new File(_testPath).writeAsStringSync(newCode);
  }
}

/**
 * Write the given [library] elements into the canonical text presentation
 * taking into account the specified 'withX' options. Then compare the
 * actual text with the given [expected] one.
 */
void checkElementText(LibraryElement library, String expected,
    {bool withOffsets: false,
    bool withSyntheticAccessors: false,
    bool withSyntheticFields: false}) {
  var writer = new _ElementWriter(
      withOffsets: withOffsets,
      withSyntheticAccessors: withSyntheticAccessors,
      withSyntheticFields: withSyntheticFields);
  writer.writeLibraryElement(library);

  String actualText = writer.buffer.toString();
  actualText =
      actualText.split('\n').map((line) => line.trimRight()).join('\n');

  if (_testPath != null && actualText != expected) {
    if (_testCode == null) {
      _testCode = new File(_testPath).readAsStringSync();
      _testCodeLines = new LineInfo.fromContent(_testCode);
    }

    try {
      throw 42;
    } catch (e, trace) {
      String traceString = trace.toString();

      // Assuming traceString contains "$_testPath:$invocationLine:$column",
      // figure out the value of invocationLine.

      int testFilePathOffset = traceString.indexOf(_testPath);
      expect(testFilePathOffset, isNonNegative);

      // Sanity check: there must be ':' after the path.
      expect(traceString[testFilePathOffset + _testPath.length], ':');

      int lineOffset = testFilePathOffset + _testPath.length + ':'.length;
      int invocationLine = int.parse(traceString.substring(
          lineOffset, traceString.indexOf(':', lineOffset)));
      int invocationOffset = _testCodeLines.getOffsetOfLine(invocationLine - 1);

      const String rawStringPrefix = "r'''";
      int expectationOffset =
          _testCode.indexOf(rawStringPrefix, invocationOffset);

      // Sanity check: there must be no other strings or blocks.
      expect(_testCode.substring(invocationOffset, expectationOffset),
          isNot(anyOf(contains("'"), contains('"'), contains('}'))));

      expectationOffset += rawStringPrefix.length;
      int expectationEnd = _testCode.indexOf("'''", expectationOffset);

      _replacements.add(new _Replacement(
          expectationOffset, expectationEnd, '\n' + actualText));
    }
  }

  // Print the actual text to simplify copy/paste into the expectation.
//  if (actualText != expected) {
//    print('-------- Actual --------');
//    print(actualText + '------------------------');
//  }

  expect(actualText, expected);
}

/**
 * Writes the canonical text presentation of elements.
 */
class _ElementWriter {
  final bool withOffsets;
  final bool withConstElements;
  final bool withSyntheticAccessors;
  final bool withSyntheticFields;
  final StringBuffer buffer = new StringBuffer();

  _ElementWriter(
      {this.withOffsets: false,
      this.withConstElements: true,
      this.withSyntheticAccessors,
      this.withSyntheticFields: false});

  bool isDynamicType(DartType type) => type is DynamicTypeImpl;

  bool isEnumField(Element e) {
    Element enclosing = e.enclosingElement;
    return enclosing is ClassElement && enclosing.isEnum;
  }

  void newLineIfNotEmpty() {
    if (buffer.isNotEmpty) {
      buffer.writeln();
    }
  }

  void writeBodyModifiers(ExecutableElement e) {
    if (e.isAsynchronous) {
      expect(e.isSynchronous, isFalse);
      buffer.write(' async');
    }

    if (e.isSynchronous && e.isGenerator) {
      expect(e.isAsynchronous, isFalse);
      buffer.write(' sync');
    }

    writeIf(e.isGenerator, '*');
  }

  void writeClassElement(ClassElement e) {
    writeDocumentation(e);
    writeMetadata(e, '', '\n');

    writeIf(e.isAbstract, 'abstract ');

    if (e.isEnum) {
      buffer.write('enum ');
    } else {
      buffer.write('class ');
    }

    writeIf(e.isMixinApplication, 'alias ');

    writeName(e);
    writeTypeParameterElements(e.typeParameters);

    if (e.supertype != null && e.supertype.displayName != 'Object' ||
        e.mixins.isNotEmpty) {
      buffer.write(' extends ');
      writeType(e.supertype);
    }

    writeList(' with ', '', e.mixins, ', ', writeType);
    writeList(' implements ', '', e.interfaces, ', ', writeType);

    buffer.writeln(' {');

    e.fields.forEach(writePropertyInducingElement);
    e.accessors.forEach(writePropertyAccessorElement);

    if (e.isEnum) {
      expect(e.constructors, isEmpty);
    } else {
      expect(e.constructors, isNotEmpty);
    }

    if (e.constructors.length == 1 &&
        e.constructors[0].isSynthetic &&
        e.mixins.isEmpty) {
      expect(e.constructors[0].parameters, isEmpty);
    } else {
      e.constructors.forEach(writeConstructorElement);
    }

    e.methods.forEach(writeMethodElement);
    buffer.writeln('}');
  }

  void writeConstructorElement(ConstructorElement e) {
    writeDocumentation(e, '  ');
    writeMetadata(e, '  ', '\n');

    buffer.write('  ');

    writeIf(e.isSynthetic, 'synthetic ');
    writeIf(e.isExternal, 'external ');
    writeIf(e.isConst, 'const ');
    writeIf(e.isFactory, 'factory ');

    buffer.write(e.enclosingElement.name);
    if (e.name.isNotEmpty) {
      buffer.write('.');
      writeName(e);
    }

    writeParameterElements(e.parameters);

    {
      ConstructorElement redirected = e.redirectedConstructor;
      if (redirected != null) {
        buffer.write(' = ');
        buffer.write(redirected.returnType);
        if (redirected.name.isNotEmpty) {
          buffer.write('.');
          buffer.write(redirected.name);
        }
      }
    }

    if (e is ConstructorElementImpl) {
      if (e.constantInitializers != null) {
        writeList(' : ', '', e.constantInitializers, ', ', writeExpression);
      }
    }

    expect(e.isAsynchronous, isFalse);
    expect(e.isGenerator, isFalse);

    buffer.writeln(';');
  }

  void writeDocumentation(Element e, [String prefix = '']) {
    if (e.documentationComment != null) {
      buffer.write(prefix);
      buffer.writeln(e.documentationComment);
    }
  }

  void writeExportElement(ExportElement e) {
    writeMetadata(e, '', '\n');
    buffer.write('export ');
    writeUri(e.exportedLibrary?.source);

    e.combinators.forEach(writeNamespaceCombinator);

    buffer.writeln(';');
  }

  void writeExpression(AstNode e, [Expression enclosing]) {
    bool needsParenthesis = e is Expression &&
        enclosing != null &&
        e.precedence < enclosing.precedence;

    if (needsParenthesis) {
      buffer.write('(');
    }

    if (e is Annotation) {
      buffer.write('@');
      writeExpression(e.name);
      if (e.constructorName != null) {
        buffer.write('.');
        writeExpression(e.constructorName);
      }
      if (e.arguments != null) {
        writeList('(', ')', e.arguments.arguments, ', ', writeExpression,
            includeEmpty: true);
      }
    } else if (e is AssertInitializer) {
      buffer.write('assert(');
      writeExpression(e.condition);
      if (e.message != null) {
        buffer.write(', ');
        writeExpression(e.message);
      }
      buffer.write(')');
    } else if (e is BinaryExpression) {
      writeExpression(e.leftOperand, e);
      buffer.write(' ');
      buffer.write(e.operator.lexeme);
      buffer.write(' ');
      writeExpression(e.rightOperand, e);
    } else if (e is BooleanLiteral) {
      buffer.write(e.value);
    } else if (e is ConditionalExpression) {
      writeExpression(e.condition);
      buffer.write(' ? ');
      writeExpression(e.thenExpression);
      buffer.write(' : ');
      writeExpression(e.elseExpression);
    } else if (e is ConstructorFieldInitializer) {
      writeExpression(e.fieldName);
      buffer.write(' = ');
      writeExpression(e.expression);
    } else if (e is ConstructorName) {
      writeExpression(e.type);
      if (e.name != null) {
        buffer.write('.');
        writeExpression(e.name);
      }
    } else if (e is DoubleLiteral) {
      buffer.write(e.value);
    } else if (e is InstanceCreationExpression) {
      buffer.write(e.keyword.lexeme);
      buffer.write(' ');
      writeExpression(e.constructorName);
      writeList('(', ')', e.argumentList.arguments, ', ', writeExpression,
          includeEmpty: true);
    } else if (e is IntegerLiteral) {
      buffer.write(e.value);
    } else if (e is InterpolationExpression) {
      buffer.write(r'${');
      writeExpression(e.expression);
      buffer.write(r'}');
    } else if (e is InterpolationString) {
      buffer.write(e.value.replaceAll("'", r"\'"));
    } else if (e is ListLiteral) {
      if (e.constKeyword != null) {
        buffer.write('const ');
      }
      if (e.typeArguments != null) {
        writeList('<', '>', e.typeArguments.arguments, ', ', writeExpression);
      }
      writeList('[', ']', e.elements, ', ', writeExpression,
          includeEmpty: true);
    } else if (e is Label) {
      writeExpression(e.label);
      buffer.write(': ');
    } else if (e is MapLiteral) {
      if (e.constKeyword != null) {
        buffer.write('const ');
      }
      if (e.typeArguments != null) {
        writeList('<', '>', e.typeArguments.arguments, ', ', writeExpression);
      }
      writeList('{', '}', e.entries, ', ', writeExpression, includeEmpty: true);
    } else if (e is MapLiteralEntry) {
      writeExpression(e.key);
      buffer.write(': ');
      writeExpression(e.value);
    } else if (e is NamedExpression) {
      writeExpression(e.name);
      buffer.write(e.expression);
    } else if (e is NullLiteral) {
      buffer.write('null');
    } else if (e is PrefixExpression) {
      buffer.write(e.operator.lexeme);
      writeExpression(e.operand, e);
    } else if (e is PrefixedIdentifier) {
      writeExpression(e.prefix);
      buffer.write('.');
      writeExpression(e.identifier);
    } else if (e is PropertyAccess) {
      writeExpression(e.target, e);
      buffer.write('.');
      writeExpression(e.propertyName);
    } else if (e is RedirectingConstructorInvocation) {
      buffer.write('this');
      if (e.constructorName != null) {
        buffer.write('.');
        writeExpression(e.constructorName);
      }
      writeList('(', ')', e.argumentList.arguments, ', ', writeExpression,
          includeEmpty: true);
    } else if (e is SimpleIdentifier) {
      if (withConstElements) {
        buffer.writeln();
        buffer.write('  ' * 4);
        buffer.write(e.name);
        buffer.write('/*');
        buffer.write('location: ');
        buffer.write(_getElementLocationString(e.staticElement));
        buffer.write('*/');
      } else {
        buffer.write(e.name);
      }
    } else if (e is SimpleStringLiteral) {
      buffer.write("'");
      buffer.write(e.value.replaceAll("'", r"\'"));
      buffer.write("'");
    } else if (e is StringInterpolation) {
      buffer.write("'");
      e.elements.forEach(writeExpression);
      buffer.write("'");
    } else if (e is SuperConstructorInvocation) {
      buffer.write('super');
      if (e.constructorName != null) {
        buffer.write('.');
        writeExpression(e.constructorName);
      }
      writeList('(', ')', e.argumentList.arguments, ', ', writeExpression,
          includeEmpty: true);
    } else if (e is SuperExpression) {
      buffer.write('super');
    } else if (e is SymbolLiteral) {
      buffer.write('#');
      writeList('', '', e.components, '.',
          (Token token) => buffer.write(token.lexeme));
    } else if (e is ThisExpression) {
      buffer.write('this');
    } else if (e is TypeName) {
      writeExpression(e.name);
      if (e.typeArguments != null) {
        writeList('<', '>', e.typeArguments.arguments, ', ', writeExpression);
      }
    } else {
      fail('Unsupported expression type: ${e.runtimeType}');
    }

    if (needsParenthesis) {
      buffer.write(')');
    }
  }

  void writeFunctionElement(FunctionElement e) {
    writeDocumentation(e);
    writeMetadata(e, '', '\n');

    writeIf(e.isExternal, 'external ');

    writeType2(e.returnType);

    writeName(e);

    writeTypeParameterElements(e.typeParameters);
    writeParameterElements(e.parameters);

    writeBodyModifiers(e);

    buffer.writeln(' {}');
  }

  void writeFunctionTypeAliasElement(FunctionTypeAliasElement e) {
    writeDocumentation(e);
    writeMetadata(e, '', '\n');

    if (e is GenericTypeAliasElement) {
      buffer.write('typedef ');
      writeName(e);
      writeTypeParameterElements(e.typeParameters);

      buffer.write(' = ');

      writeType(e.function.returnType);
      buffer.write(' Function');
      writeTypeParameterElements(e.function.typeParameters);
      writeParameterElements(e.function.parameters);
    } else {
      buffer.write('typedef ');
      writeType2(e.returnType);

      writeName(e);

      writeTypeParameterElements(e.typeParameters);
      writeParameterElements(e.parameters);
    }

    buffer.writeln(';');
  }

  void writeIf(bool flag, String str) {
    if (flag) {
      buffer.write(str);
    }
  }

  void writeImportElement(ImportElement e) {
    if (!e.isSynthetic) {
      writeMetadata(e, '', '\n');
      buffer.write('import ');
      writeUri(e.importedLibrary?.source);

      writeIf(e.isDeferred, ' deferred');

      if (e.prefix != null) {
        buffer.write(' as ');
        writeName(e.prefix);
        if (withOffsets) {
          buffer.write('(${e.prefixOffset})');
        }
      }

      e.combinators.forEach(writeNamespaceCombinator);

      buffer.writeln(';');
    }
  }

  void writeLibraryElement(LibraryElement e) {
    if (e.documentationComment != null) {
      buffer.writeln(e.documentationComment);
    }

    if (e.displayName != '') {
      writeMetadata(e, '', '\n');
      buffer.write('library ');
      writeName(e);
      buffer.writeln(';');
    }

    e.imports.forEach(writeImportElement);
    e.exports.forEach(writeExportElement);
    e.parts.forEach(writePartElement);

    e.units.forEach(writeUnitElement);
  }

  void writeList<T>(String open, String close, List<T> items, String separator,
      writeItem(T item),
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

  void writeMetadata(Element e, String prefix, String separator) {
    if (e.metadata.isNotEmpty) {
      writeList(prefix, '', e.metadata, '$separator$prefix', (a) {
        writeExpression((a as ElementAnnotationImpl).annotationAst);
      });
      buffer.write(separator);
    }
  }

  void writeMethodElement(MethodElement e) {
    writeDocumentation(e, '  ');
    writeMetadata(e, '  ', '\n');

    buffer.write('  ');

    writeIf(e.isExternal, 'external ');
    writeIf(e.isStatic, 'static ');

    writeType2(e.returnType);

    writeName(e);

    writeTypeParameterElements(e.typeParameters);
    writeParameterElements(e.parameters);

    writeBodyModifiers(e);

    if (e.isAbstract) {
      buffer.writeln(';');
    } else {
      buffer.writeln(' {}');
    }
  }

  void writeName(Element e) {
    buffer.write(e.displayName);
    if (withOffsets) {
      buffer.write('@');
      buffer.write(e.nameOffset);
    }
  }

  void writeNamespaceCombinator(NamespaceCombinator e) {
    if (e is ShowElementCombinator) {
      buffer.write(' show ');
      buffer.write(e.shownNames.join(', '));
    } else if (e is HideElementCombinator) {
      buffer.write(' hide ');
      buffer.write(e.hiddenNames.join(', '));
    }
  }

  void writeParameterElement(ParameterElement e) {
    String defaultValueSeparator;
    Expression defaultValue;
    String closeString;
    ParameterKind kind = e.parameterKind;
    if (kind == ParameterKind.REQUIRED) {
      closeString = '';
    } else if (kind == ParameterKind.POSITIONAL) {
      buffer.write('[');
      defaultValueSeparator = ' = ';
      defaultValue = (e as ConstVariableElement).constantInitializer;
      closeString = ']';
    } else if (kind == ParameterKind.NAMED) {
      buffer.write('{');
      defaultValueSeparator = ': ';
      defaultValue = (e as ConstVariableElement).constantInitializer;
      closeString = '}';
    } else {
      fail('Unknown parameter kind: $kind');
    }

    // Kernel desugars omitted default parameter values to 'null'.
    // Analyzer does not set initializer at all.
    // It is not an interesting distinction, so we skip NullLiteral(s).
    if (defaultValue is NullLiteral) {
      defaultValue = null;
    }

    writeMetadata(e, '', ' ');

    writeIf(e.isCovariant, 'covariant ');
    writeIf(e.isFinal, 'final ');

    writeType2(e.type);

    if (e is FieldFormalParameterElement) {
      buffer.write('this.');
    }

    writeName(e);

    writeVariableTypeInferenceError(e);

    if (defaultValue != null) {
      buffer.write(defaultValueSeparator);
      writeExpression(defaultValue);
    }

    buffer.write(closeString);
  }

  void writeParameterElements(List<ParameterElement> elements) {
    writeList('(', ')', elements, ', ', writeParameterElement,
        includeEmpty: true);
  }

  void writePartElement(CompilationUnitElement e) {
    writeMetadata(e, '', '\n');
    buffer.write('part ');
    writeUri(e.source);
    buffer.writeln(';');
  }

  void writePropertyAccessorElement(PropertyAccessorElement e) {
    if (e.isSynthetic && !withSyntheticAccessors) {
      return;
    }

    if (!e.isSynthetic) {
      PropertyInducingElement variable = e.variable;
      expect(variable, isNotNull);
      expect(variable.isSynthetic, isTrue);
      if (e.isGetter) {
        expect(variable.getter, same(e));
        if (variable.setter != null) {
          expect(variable.setter.variable, same(variable));
        }
      } else {
        expect(variable.setter, same(e));
        if (variable.getter != null) {
          expect(variable.getter.variable, same(variable));
        }
      }
    }

    if (e.enclosingElement is ClassElement) {
      writeDocumentation(e, '  ');
      writeMetadata(e, '  ', '\n');

      buffer.write('  ');

      writeIf(e.isSynthetic, 'synthetic ');
      writeIf(e.isStatic, 'static ');
    } else {
      writeDocumentation(e);
      writeMetadata(e, '', '\n');
      writeIf(e.isSynthetic, 'synthetic ');
    }

    writeIf(e.isExternal, 'external ');

    writeType2(e.returnType);

    if (e.isGetter) {
      buffer.write('get ');
    } else {
      buffer.write('set ');
    }

    writeName(e);

    if (e.isSetter || e.parameters.isNotEmpty) {
      writeParameterElements(e.parameters);
    }

    expect(e.typeParameters, isEmpty);

    expect(e.isSynchronous, isTrue);
    expect(e.isAsynchronous, isFalse);
    expect(e.isGenerator, isFalse);

    if (e.isAbstract) {
      buffer.writeln(';');
    } else {
      buffer.writeln(' {}');
    }
  }

  void writePropertyInducingElement(PropertyInducingElement e) {
    if (e.isSynthetic && !withSyntheticFields && !isEnumField(e)) {
      return;
    }

    DartType type = e.type;
    expect(type, isNotNull);

    if (!e.isSynthetic) {
      expect(e.getter, isNotNull);
      expect(e.getter.isSynthetic, isTrue);
      expect(e.getter.variable, same(e));
      if (e.isFinal || e.isConst) {
        expect(e.setter, isNull);
      } else {
        expect(e.setter, isNotNull);
        expect(e.setter.isSynthetic, isTrue);
        expect(e.setter.variable, same(e.getter.variable));
      }
    }

    if (e.enclosingElement is ClassElement) {
      writeDocumentation(e, '  ');
      writeMetadata(e, '  ', '\n');

      buffer.write('  ');

      writeIf(e.isSynthetic, 'synthetic ');
      writeIf(e.isStatic, 'static ');
      writeIf(e is FieldElementImpl && e.isCovariant, 'covariant ');
    } else {
      writeDocumentation(e);
      writeMetadata(e, '', '\n');
    }

    writeIf(e.isFinal, 'final ');
    writeIf(e.isConst, 'const ');
    writeType2(type);

    writeName(e);

    writeVariableTypeInferenceError(e);

    if (e is ConstVariableElement) {
      Expression initializer = (e as ConstVariableElement).constantInitializer;
      if (initializer != null) {
        buffer.write(' = ');
        writeExpression(initializer);
      }
    }

    // TODO(scheglov) Paul: One of the things that was hardest to get right
    // when resynthesizing the element model was the synthetic function for the
    // initializer.  Can we write that out (along with its return type)?

    buffer.writeln(';');
  }

  void writeType(DartType type) {
    if (type is InterfaceType) {
      buffer.write(type.element.name);
      if (type.element.typeParameters.isNotEmpty) {
        writeList('<', '>', type.typeArguments, ', ', writeType);
      }
    } else {
      buffer.write(type.displayName);
    }
  }

  void writeType2(DartType type) {
    writeType(type);
    buffer.write(' ');
  }

  void writeTypeParameterElement(TypeParameterElement e) {
    writeName(e);
    if (e.bound != null) {
      buffer.write(' extends ');
      writeType(e.bound);
    }
  }

  void writeTypeParameterElements(List<TypeParameterElement> elements) {
    writeList('<', '>', elements, ', ', writeTypeParameterElement);
  }

  void writeUnitElement(CompilationUnitElement e) {
    if (e.library.definingCompilationUnit != e) {
      buffer.writeln('-' * 20);
      buffer.writeln('unit: ${e.source?.shortName}');
      buffer.writeln();
    }
    e.functionTypeAliases.forEach(writeFunctionTypeAliasElement);
    e.enums.forEach(writeClassElement);
    e.types.forEach(writeClassElement);
    e.topLevelVariables.forEach(writePropertyInducingElement);
    e.accessors.forEach(writePropertyAccessorElement);
    e.functions.forEach(writeFunctionElement);
  }

  void writeUri(Source source) {
    if (source != null) {
      Uri uri = source.uri;
      String uriStr = uri.toString();
      if (uri.isScheme('file')) {
        uriStr = uri.pathSegments.last;
      }
      buffer.write('\'$uriStr\'');
    } else {
      buffer.write('\'<unresolved>\'');
    }
  }

  void writeVariableTypeInferenceError(VariableElement e) {
    if (e is VariableElementImpl) {
      TopLevelInferenceError inferenceError = e.typeInferenceError;
      if (inferenceError != null) {
        String kindName = inferenceError.kind.toString();
        if (kindName.startsWith('TopLevelInferenceErrorKind.')) {
          kindName = kindName.substring('TopLevelInferenceErrorKind.'.length);
        }
        buffer.write('/*error: $kindName*/');
      }
    }
  }

  String _getElementLocationString(Element element) {
    if (element == null) {
      return 'null';
    }

    String onlyName(String uri) {
      if (uri.startsWith('file:///')) {
        return uri.substring(uri.lastIndexOf('/') + 1);
      }
      return uri;
    }

    ElementLocation location = element.location;
    List<String> components = location.components.toList();
    if (components.length >= 1) {
      components[0] = onlyName(components[0]);
    }
    if (components.length >= 2) {
      components[1] = onlyName(components[1]);
      if (components[0] == components[1]) {
        components.removeAt(0);
      }
    }
    return components.join(';');
  }
}

class _Replacement {
  final int offset;
  final int end;
  final String text;
  _Replacement(this.offset, this.end, this.text);
}
