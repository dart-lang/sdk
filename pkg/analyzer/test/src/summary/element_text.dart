// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
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
import 'package:analyzer/src/task/inference_error.dart';
import 'package:meta/meta.dart';
import 'package:test/test.dart';

import 'resolved_ast_printer.dart';

/// Set this path to automatically replace expectations in invocations of
/// [checkElementText] with the new actual texts.
const String _testPath = null;

/// The list of replacements that update expectations.
final List<_Replacement> _replacements = [];

/// The cached content of the file with the [_testPath].
String _testCode;

/// The cache line information for the [_testPath] file.
LineInfo _testCodeLines;

void applyCheckElementTextReplacements() {
  if (_testPath != null && _replacements.isNotEmpty) {
    _replacements.sort((a, b) => b.offset - a.offset);
    String newCode = _testCode;
    _replacements.forEach((r) {
      newCode =
          newCode.substring(0, r.offset) + r.text + newCode.substring(r.end);
    });
    File(_testPath).writeAsStringSync(newCode);
  }
}

/// Write the given [library] elements into the canonical text presentation
/// taking into account the specified 'withX' options. Then compare the
/// actual text with the given [expected] one.
void checkElementText(
  LibraryElement library,
  String expected, {
  bool withCodeRanges = false,
  bool withConstElements = true,
  bool withExportScope = false,
  bool withFullyResolvedAst = false,
  bool withOffsets = false,
  bool withSyntheticAccessors = false,
  bool withSyntheticFields = false,
  bool withTypes = false,
  bool withTypeParameterVariance = false,
}) {
  var writer = _ElementWriter(
    selfUriStr: '${library.source.uri}',
    withCodeRanges: withCodeRanges,
    withConstElements: withConstElements,
    withExportScope: withExportScope,
    withFullyResolvedAst: withFullyResolvedAst,
    withOffsets: withOffsets,
    withSyntheticAccessors: withSyntheticAccessors,
    withSyntheticFields: withSyntheticFields,
    withTypes: withTypes,
    withTypeParameterVariance: withTypeParameterVariance,
  );
  writer.writeLibraryElement(library);

  String actualText = writer.buffer.toString();
  actualText =
      actualText.split('\n').map((line) => line.trimRight()).join('\n');

  if (_testPath != null && actualText != expected) {
    if (_testCode == null) {
      _testCode = File(_testPath).readAsStringSync();
      _testCodeLines = LineInfo.fromContent(_testCode);
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

      _replacements.add(
          _Replacement(expectationOffset, expectationEnd, '\n' + actualText));
    }
  }

  // Print the actual text to simplify copy/paste into the expectation.
//  if (actualText != expected) {
//    print('-------- Actual --------');
//    print(actualText + '------------------------');
//  }

  expect(actualText, expected);
}

/// Writes the canonical text presentation of elements.
class _ElementWriter {
  final String selfUriStr;
  final bool withCodeRanges;
  final bool withExportScope;
  final bool withFullyResolvedAst;
  final bool withOffsets;
  final bool withConstElements;
  final bool withSyntheticAccessors;
  final bool withSyntheticFields;
  final bool withTypes;
  final bool withTypeParameterVariance;
  final StringBuffer buffer = StringBuffer();

  String indent = '';

  _ElementWriter({
    this.selfUriStr,
    this.withCodeRanges,
    this.withConstElements = true,
    this.withExportScope = false,
    this.withFullyResolvedAst = false,
    this.withOffsets = false,
    this.withSyntheticAccessors = false,
    this.withSyntheticFields = false,
    this.withTypes = false,
    this.withTypeParameterVariance,
  });

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

    writeIf(e.isAbstract && !e.isMixin, 'abstract ');
    writeIf(!e.isSimplyBounded, 'notSimplyBounded ');

    if (e.isEnum) {
      buffer.write('enum ');
    } else if (e.isMixin) {
      buffer.write('mixin ');
    } else {
      buffer.write('class ');
    }

    writeIf(e.isMixinApplication, 'alias ');

    writeName(e);
    writeCodeRange(e);
    writeTypeParameterElements(e.typeParameters, withDefault: true);

    if (e.supertype != null && e.supertype.element.name != 'Object' ||
        e.mixins.isNotEmpty) {
      buffer.write(' extends ');
      writeType(e.supertype);
    }

    if (e.isMixin) {
      if (e.superclassConstraints.isEmpty) {
        throw StateError('At least Object is expected.');
      }
      writeList(' on ', '', e.superclassConstraints, ', ', writeType);
    }

    writeList(' with ', '', e.mixins, ', ', writeType);
    writeList(' implements ', '', e.interfaces, ', ', writeType);

    buffer.writeln(' {');

    _withIndent(() {
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
    });

    buffer.writeln('}');

    if (withFullyResolvedAst) {
      _withIndent(() {
        _writeResolvedMetadata(e.metadata);
        _writeResolvedTypeParameters(e.typeParameters);
      });
    }
  }

  void writeCodeRange(Element e) {
    if (withCodeRanges) {
      var elementImpl = e as ElementImpl;
      buffer.write('/*codeOffset=');
      buffer.write(elementImpl.codeOffset);
      buffer.write(', codeLength=');
      buffer.write(elementImpl.codeLength);
      buffer.write('*/');
    }
  }

  void writeConstructorElement(ConstructorElement e) {
    writeDocumentation(e, '  ');
    writeMetadata(e, '  ', '\n');

    buffer.write('  ');

    writeIf(e.isSynthetic, 'synthetic ');
    writeIf(e.isExternal, 'external ');
    writeIf(e.isConst, 'const ');
    writeIf(e.isFactory, 'factory ');
    expect(e.isAbstract, isFalse);

    buffer.write(e.enclosingElement.name);
    if (e.name.isNotEmpty) {
      buffer.write('.');
      writeName(e);
    }
    if (!e.isSynthetic) {
      writeCodeRange(e);
    }

    writeParameterElements(e.parameters);

    {
      ConstructorElement redirected = e.redirectedConstructor;
      if (redirected != null) {
        buffer.write(' = ');
        writeType(redirected.returnType);
        if (redirected.name.isNotEmpty) {
          buffer.write('.');
          buffer.write(redirected.name);
        }
      }
    }

    var initializers = (e as ConstructorElementImpl).constantInitializers;
    if (withFullyResolvedAst) {
      buffer.writeln(';');
      _withIndent(() {
        if (initializers != null && initializers.isNotEmpty) {
          _writelnWithIndent('constantInitializers');
          _withIndent(() {
            for (var initializer in initializers) {
              _writeResolvedNode(initializer);
            }
          });
        }
        _writeParameterElementDefaultValues(e.parameters);
      });
    } else {
      if (initializers != null) {
        writeList(' : ', '', initializers, ', ', writeNode);
      }
      buffer.writeln(';');
    }

    expect(e.isAsynchronous, isFalse);
    expect(e.isGenerator, isFalse);
  }

  void writeDocumentation(Element e, [String prefix = '']) {
    String comment = e.documentationComment;
    if (comment != null) {
      if (comment.startsWith('///')) {
        comment = comment.split('\n').join('\n$prefix');
      }
      buffer.write(prefix);
      buffer.writeln(comment);
    }
  }

  void writeExportElement(ExportElement e) {
    writeMetadata(e, '', '\n');
    buffer.write('export ');
    writeUri(e.exportedLibrary?.source);

    e.combinators.forEach(writeNamespaceCombinator);

    buffer.writeln(';');
  }

  void writeExportScope(LibraryElement e) {
    if (!withExportScope) return;

    buffer.writeln();
    buffer.writeln('-' * 20);
    buffer.writeln('Exports:');

    var map = e.exportNamespace.definedNames;
    var names = map.keys.toList()..sort();
    for (var name in names) {
      var element = map[name];
      var elementLocationStr = _getElementLocationString(element);
      buffer.writeln('  $name: $elementLocationStr');
    }
  }

  void writeExtensionElement(ExtensionElement e) {
    writeDocumentation(e);
    writeMetadata(e, '', '\n');

    buffer.write('extension ');
    writeName(e);
    writeCodeRange(e);
    writeTypeParameterElements(e.typeParameters, withDefault: false);
    if (e.extendedType != null) {
      buffer.write(' on ');
      writeType(e.extendedType);
    }

    buffer.writeln(' {');

    _withIndent(() {
      e.fields.forEach(writePropertyInducingElement);
      e.accessors.forEach(writePropertyAccessorElement);
      e.methods.forEach(writeMethodElement);
    });

    buffer.writeln('}');

    if (withFullyResolvedAst) {
      _withIndent(() {
        _writeResolvedMetadata(e.metadata);
        _writeResolvedTypeParameters(e.typeParameters);
      });
    }
  }

  void writeFunctionElement(FunctionElement e) {
    writeDocumentation(e);
    writeMetadata(e, '', '\n');

    writeIf(e.isExternal, 'external ');

    writeType2(e.returnType);

    writeName(e);
    writeCodeRange(e);

    writeTypeParameterElements(e.typeParameters, withDefault: false);
    writeParameterElements(e.parameters);

    writeBodyModifiers(e);

    buffer.writeln(' {}');

    if (withFullyResolvedAst) {
      _withIndent(() {
        _writeParameterElementDefaultValues(e.parameters);
      });
    }
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

      if (withFullyResolvedAst) {
        _withIndent(() {
          _writeResolvedMetadata(e.metadata);
        });
      }
    }
  }

  void writeInterfaceTypeArgsComment(Expression e) {
    var typeArguments = (e.staticType as InterfaceType).typeArguments;
    writeList('/*typeArgs=', '*/', typeArguments, ',', writeType);
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

    writeExportScope(e);
  }

  void writeList<T>(String open, String close, List<T> items, String separator,
      Function(T item) writeItem,
      {bool includeEmpty = false}) {
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
    if (withFullyResolvedAst) {
      return;
    }

    if (e.metadata.isNotEmpty) {
      writeList(prefix, '', e.metadata, '$separator$prefix', (a) {
        writeNode((a as ElementAnnotationImpl).annotationAst);
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
    writeCodeRange(e);
    writeTypeInferenceError(e);

    writeTypeParameterElements(e.typeParameters, withDefault: false);
    writeParameterElements(e.parameters);

    writeBodyModifiers(e);

    if (e.isAbstract) {
      buffer.writeln(';');
    } else {
      buffer.writeln(' {}');
    }

    if (withFullyResolvedAst) {
      _withIndent(() {
        _writeResolvedTypeParameters(e.typeParameters);
        _writeResolvedMetadata(e.metadata);
        _writeParameterElementDefaultValues(e.parameters);
      });
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

  void writeNode(AstNode e, {Expression enclosing}) {
    bool needsParenthesis = e is Expression &&
        enclosing != null &&
        e.precedence < enclosing.precedence;

    if (needsParenthesis) {
      buffer.write('(');
    }

    if (e == null) {
      buffer.write('<null>');
    } else if (e is SimpleIdentifier && e.name == '#invalidConst') {
      buffer.write('#invalidConst');
    } else if (e is AdjacentStrings) {
      writeList("'", "'", e.strings, '',
          (StringLiteral s) => buffer.write(s.stringValue),
          includeEmpty: true);
    } else if (e is Annotation) {
      buffer.write('@');
      writeNode(e.name);
      if (e.constructorName != null) {
        buffer.write('.');
        writeNode(e.constructorName);
      }
      if (e.arguments != null) {
        writeList('(', ')', e.arguments.arguments, ', ', writeNode,
            includeEmpty: true);
      }
    } else if (e is AsExpression) {
      writeNode(e.expression);
      buffer.write(' as ');
      writeNode(e.type);
    } else if (e is AssertInitializer) {
      buffer.write('assert(');
      writeNode(e.condition);
      if (e.message != null) {
        buffer.write(', ');
        writeNode(e.message);
      }
      buffer.write(')');
    } else if (e is BinaryExpression) {
      writeNode(e.leftOperand, enclosing: e);
      buffer.write(' ');
      buffer.write(e.operator.lexeme);
      buffer.write(' ');
      writeNode(e.rightOperand, enclosing: e);
    } else if (e is BooleanLiteral) {
      buffer.write(e.value);
    } else if (e is ConditionalExpression) {
      writeNode(e.condition);
      buffer.write(' ? ');
      writeNode(e.thenExpression);
      buffer.write(' : ');
      writeNode(e.elseExpression);
    } else if (e is ConstructorFieldInitializer) {
      writeNode(e.fieldName);
      buffer.write(' = ');
      writeNode(e.expression);
    } else if (e is ConstructorName) {
      writeNode(e.type);
      if (e.name != null) {
        buffer.write('.');
        writeNode(e.name);
      }
    } else if (e is DoubleLiteral) {
      buffer.write(e.value);
    } else if (e is GenericFunctionType) {
      if (e.returnType != null) {
        writeNode(e.returnType);
        buffer.write(' ');
      }
      buffer.write('Function');
      if (e.typeParameters != null) {
        writeList('<', '>', e.typeParameters.typeParameters, ', ', writeNode);
      }
      writeList('(', ')', e.parameters.parameters, ', ', writeNode,
          includeEmpty: true);
    } else if (e is InstanceCreationExpression) {
      if (e.keyword != null) {
        buffer.write(e.keyword.lexeme);
        buffer.write(' ');
      }
      if (withTypes && e.constructorName.type.typeArguments == null) {
        writeInterfaceTypeArgsComment(e);
      }
      writeNode(e.constructorName);
      writeList('(', ')', e.argumentList.arguments, ', ', writeNode,
          includeEmpty: true);
    } else if (e is IntegerLiteral) {
      buffer.write(e.value);
    } else if (e is InterpolationExpression) {
      buffer.write(r'${');
      writeNode(e.expression);
      buffer.write(r'}');
    } else if (e is InterpolationString) {
      buffer.write(e.value.replaceAll("'", r"\'"));
    } else if (e is IsExpression) {
      writeNode(e.expression);
      buffer.write(e.notOperator == null ? ' is ' : ' is! ');
      writeNode(e.type);
    } else if (e is ListLiteral) {
      if (e.constKeyword != null) {
        buffer.write('const ');
      }
      if (e.typeArguments != null) {
        writeList('<', '>', e.typeArguments.arguments, ', ', writeNode);
      } else if (withTypes) {
        writeInterfaceTypeArgsComment(e);
      }
      writeList('[', ']', e.elements, ', ', writeNode, includeEmpty: true);
    } else if (e is Label) {
      writeNode(e.label);
      buffer.write(': ');
    } else if (e is SetOrMapLiteral) {
      if (e.constKeyword != null) {
        buffer.write('const ');
      }
      if (e.typeArguments != null) {
        writeList('<', '>', e.typeArguments.arguments, ', ', writeNode);
      } else if (withTypes) {
        writeInterfaceTypeArgsComment(e);
      }
      writeList('{', '}', e.elements, ', ', writeNode, includeEmpty: true);
      if (e.isMap) {
        buffer.write('/*isMap*/');
      }
      if (e.isSet) {
        buffer.write('/*isSet*/');
      }
    } else if (e is MapLiteralEntry) {
      writeNode(e.key);
      buffer.write(': ');
      writeNode(e.value);
    } else if (e is MethodInvocation) {
      if (e.target != null) {
        writeNode(e.target);
        buffer.write(e.operator);
      }
      writeNode(e.methodName);
      if (e.typeArguments != null) {
        writeList('<', '>', e.typeArguments.arguments, ', ', writeNode);
      }
      writeList('(', ')', e.argumentList.arguments, ', ', writeNode,
          includeEmpty: true);
    } else if (e is NamedExpression) {
      writeNode(e.name);
      buffer.write(e.expression);
    } else if (e is NullLiteral) {
      buffer.write('null');
    } else if (e is ParenthesizedExpression) {
      writeNode(e.expression, enclosing: e);
    } else if (e is PrefixExpression) {
      buffer.write(e.operator.lexeme);
      writeNode(e.operand, enclosing: e);
    } else if (e is PrefixedIdentifier) {
      writeNode(e.prefix);
      buffer.write('.');
      writeNode(e.identifier);
    } else if (e is PropertyAccess) {
      writeNode(e.target, enclosing: e);
      buffer.write('.');
      writeNode(e.propertyName);
    } else if (e is RedirectingConstructorInvocation) {
      buffer.write('this');
      if (e.constructorName != null) {
        buffer.write('.');
        writeNode(e.constructorName);
      }
      writeList('(', ')', e.argumentList.arguments, ', ', writeNode,
          includeEmpty: true);
    } else if (e is SimpleFormalParameter) {
      writeNode(e.type);
      if (e.identifier != null) {
        buffer.write(' ');
        buffer.write(e.identifier.name);
      }
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
      e.elements.forEach(writeNode);
      buffer.write("'");
    } else if (e is SuperConstructorInvocation) {
      buffer.write('super');
      if (e.constructorName != null) {
        buffer.write('.');
        writeNode(e.constructorName);
      }
      writeList('(', ')', e.argumentList.arguments, ', ', writeNode,
          includeEmpty: true);
    } else if (e is SuperExpression) {
      buffer.write('super');
    } else if (e is SymbolLiteral) {
      buffer.write('#');
      writeList('', '', e.components, '.',
          (Token token) => buffer.write(token.lexeme));
    } else if (e is ThisExpression) {
      buffer.write('this');
    } else if (e is ThrowExpression) {
      buffer.write('throw ');
      writeNode(e.expression);
    } else if (e is TypeName) {
      writeNode(e.name);
      if (e.typeArguments != null) {
        writeList('<', '>', e.typeArguments.arguments, ', ', writeNode);
      }
    } else if (e is SpreadElement) {
      buffer.write(e.spreadOperator.lexeme);
      writeNode(e.expression);
    } else if (e is IfElement) {
      buffer.write('if (');
      writeNode(e.condition);
      buffer.write(') ');
      writeNode(e.thenElement);
      var elseElement = e.elseElement;
      if (elseElement != null) {
        buffer.write(' else ');
        writeNode(elseElement);
      }
    } else {
      fail('Unsupported expression type: ${e.runtimeType}');
    }

    if (needsParenthesis) {
      buffer.write(')');
    }
  }

  void writeParameterElement(ParameterElement e) {
    String defaultValueSeparator;
    Expression defaultValue;
    String closeString;
    if (e.isRequiredPositional) {
      closeString = '';
    } else if (e.isOptionalPositional) {
      buffer.write('[');
      defaultValueSeparator = ' = ';
      defaultValue = (e as ConstVariableElement).constantInitializer;
      closeString = ']';
    } else if (e.isNamed) {
      buffer.write('{');
      defaultValueSeparator = ': ';
      defaultValue = (e as ConstVariableElement).constantInitializer;
      closeString = '}';
    } else {
      fail('Unknown parameter kind');
    }

    writeMetadata(e, '', ' ');

    writeIf(e.isCovariant, 'covariant ');
    writeIf(e.isFinal, 'final ');

    writeType2(e.type);

    if (e is FieldFormalParameterElement) {
      buffer.write('this.');
    }

    writeName(e);
    writeCodeRange(e);

    if (!withFullyResolvedAst) {
      if (e.parameters.isNotEmpty) {
        buffer.write('/*');
        writeList('(', ')', e.parameters, ', ', writeParameterElement);
        buffer.write('*/');
      }

      if (defaultValue != null) {
        buffer.write(defaultValueSeparator);
        writeNode(defaultValue);
      }
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

      var variableEnclosing = variable.enclosingElement;
      if (variableEnclosing is CompilationUnitElement) {
        expect(variableEnclosing.topLevelVariables, contains(variable));
      } else if (variableEnclosing is ClassElement) {
        expect(variableEnclosing.fields, contains(variable));
      }

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

    if (e.isAbstract || e.isExternal) {
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
      _assertSyntheticAccessorEnclosing(e, e.getter);

      if (e.setter != null) {
        _assertSyntheticAccessorEnclosing(e, e.setter);
      }
    }

    if (e.enclosingElement is ClassElement ||
        e.enclosingElement is ExtensionElement) {
      writeDocumentation(e, '  ');
      writeMetadata(e, '  ', '\n');

      buffer.write('  ');

      writeIf(e.isSynthetic, 'synthetic ');
      writeIf(e.isStatic, 'static ');
      writeIf(e is FieldElementImpl && e.isAbstract, 'abstract ');
      writeIf(e is FieldElementImpl && e.isCovariant, 'covariant ');
      writeIf(e is FieldElementImpl && e.isExternal, 'external ');
    } else {
      writeDocumentation(e);
      writeMetadata(e, '', '\n');
      writeIf(e is TopLevelVariableElementImpl && e.isExternal, 'external ');
    }

    writeIf(e.isLate, 'late ');
    writeIf(e.isFinal, 'final ');
    writeIf(e.isConst, 'const ');
    writeType2(type);

    writeName(e);
    writeCodeRange(e);

    writeTypeInferenceError(e);

    if (withFullyResolvedAst) {
      buffer.writeln(';');
      _withIndent(() {
        _writeResolvedMetadata(e.metadata);
        if (e is ConstVariableElement) {
          var initializer = (e as ConstVariableElement).constantInitializer;
          if (initializer != null) {
            _writelnWithIndent('constantInitializer');
            _withIndent(() {
              _writeResolvedNode(initializer);
            });
          }
        }
      });
    } else {
      if (e is ConstVariableElement) {
        Expression initializer =
            (e as ConstVariableElement).constantInitializer;
        if (initializer != null) {
          buffer.write(' = ');
          writeNode(initializer);
        }
      }
      buffer.writeln(';');
    }

    // TODO(scheglov) Paul: One of the things that was hardest to get right
    // when resynthesizing the element model was the synthetic function for the
    // initializer.  Can we write that out (along with its return type)?
  }

  void writeType(DartType type) {
    var typeStr = _typeStr(type);
    buffer.write(typeStr);
  }

  void writeType2(DartType type) {
    writeType(type);
    buffer.write(' ');
  }

  void writeTypeAliasElement(TypeAliasElement e) {
    writeDocumentation(e);
    writeMetadata(e, '', '\n');
    writeIf(!e.isSimplyBounded, 'notSimplyBounded ');

    buffer.write('typedef ');
    writeName(e);
    writeCodeRange(e);
    writeTypeParameterElements(e.typeParameters, withDefault: true);

    buffer.write(' = ');

    var aliasedElement = e.aliasedElement;
    if (aliasedElement is GenericFunctionTypeElement) {
      writeType(aliasedElement.returnType);
      buffer.write(' Function');
      writeTypeParameterElements(aliasedElement.typeParameters,
          withDefault: false);
      writeParameterElements(aliasedElement.parameters);
    } else {
      writeType(e.aliasedType);
    }

    buffer.writeln(';');
  }

  void writeTypeInferenceError(Element e) {
    TopLevelInferenceError inferenceError;
    if (e is MethodElementImpl) {
      inferenceError = e.typeInferenceError;
    } else if (e is PropertyInducingElementImpl) {
      inferenceError = e.typeInferenceError;
    }

    if (inferenceError != null) {
      String kindName = inferenceError.kind.toString();
      if (kindName.startsWith('TopLevelInferenceErrorKind.')) {
        kindName = kindName.substring('TopLevelInferenceErrorKind.'.length);
      }
      buffer.write('/*error: $kindName*/');
    }
  }

  void writeTypeParameterElement(
    TypeParameterElement e, {
    @required bool withDefault,
  }) {
    var impl = e as TypeParameterElementImpl;

    writeMetadata(e, '', '\n');

    // TODO (kallentu) : Clean up TypeParameterElementImpl casting once
    // variance is added to the interface.
    if (withTypeParameterVariance) {
      var variance = impl.variance;
      buffer.write(variance.toString() + ' ');
    }

    writeName(e);
    writeCodeRange(e);
    if (e.bound != null && !e.bound.isDartCoreObject) {
      buffer.write(' extends ');
      writeType(e.bound);
    }

    if (withDefault) {
      var defaultType = impl.defaultType;
      if (defaultType is! DynamicTypeImpl) {
        buffer.write(' = ');
        writeType(defaultType);
      }
    }
  }

  void writeTypeParameterElements(
    List<TypeParameterElement> elements, {
    @required bool withDefault,
  }) {
    if (!withFullyResolvedAst) {
      writeList('<', '>', elements, ', ', (e) {
        writeTypeParameterElement(e, withDefault: withDefault);
      });
    }
  }

  void writeUnitElement(CompilationUnitElement e) {
    if (e.library.definingCompilationUnit != e) {
      buffer.writeln('-' * 20);
      buffer.writeln('unit: ${e.source?.shortName}');
      buffer.writeln();
    }
    e.typeAliases.forEach(writeTypeAliasElement);
    e.enums.forEach(writeClassElement);
    e.types.forEach(writeClassElement);
    e.mixins.forEach(writeClassElement);
    e.extensions.forEach(writeExtensionElement);
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

  /// Assert that the [accessor] of the [property] is correctly linked to
  /// the same enclosing element as the [property].
  void _assertSyntheticAccessorEnclosing(
      PropertyInducingElement property, PropertyAccessorElement accessor) {
    expect(accessor.isSynthetic, isTrue);
    expect(accessor.variable, same(property));

    var propertyEnclosing = property.enclosingElement;
    expect(accessor.enclosingElement, same(propertyEnclosing));

    if (propertyEnclosing is CompilationUnitElement) {
      expect(propertyEnclosing.accessors, contains(accessor));
    } else if (propertyEnclosing is ClassElement) {
      expect(propertyEnclosing.accessors, contains(accessor));
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
    if (components.isNotEmpty) {
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

  String _typeStr(DartType type) {
    return type?.getDisplayString(
      withNullability: true,
    );
  }

  void _withIndent(void Function() f) {
    var indent = this.indent;
    this.indent = '$indent  ';
    f();
    this.indent = indent;
  }

  void _writelnTypeWithIndent(String name, DartType type) {
    buffer.write(indent);
    buffer.write('$name: ');
    buffer.writeln(_typeStr(type));
  }

  void _writelnWithIndent(String line) {
    buffer.write(indent);
    buffer.writeln(line);
  }

  void _writeParameterElementDefaultValues(
    List<ParameterElement> parameters, {
    String enclosingNames = '',
  }) {
    for (var parameter in parameters) {
      if (parameter is DefaultParameterElementImpl) {
        var defaultValue = parameter.constantInitializer;
        if (defaultValue != null) {
          _writelnWithIndent(enclosingNames + parameter.name);
          _withIndent(() {
            _writeResolvedNode(defaultValue);
          });
        }
      }
      var subParameters = parameter.parameters;
      _withIndent(() {
        _writeParameterElementDefaultValues(
          subParameters,
          enclosingNames: enclosingNames + parameter.name + '::',
        );
      });
    }
  }

  void _writeResolvedMetadata(List<ElementAnnotation> metadata) {
    if (metadata.isNotEmpty) {
      _writelnWithIndent('metadata');
      _withIndent(() {
        for (ElementAnnotationImpl annotation in metadata) {
          _writeResolvedNode(annotation.annotationAst);
        }
      });
    }
  }

  void _writeResolvedNode(AstNode node) {
    buffer.write(indent);
    node.accept(
      ResolvedAstPrinter(
        selfUriStr: selfUriStr,
        sink: buffer,
        indent: indent,
        withNullability: true,
      ),
    );
  }

  void _writeResolvedTypeParameters(List<TypeParameterElement> elements) {
    if (elements.isNotEmpty) {
      _writelnWithIndent('typeParameters');
      _withIndent(() {
        for (TypeParameterElementImpl e in elements) {
          _writelnWithIndent(e.name);
          _withIndent(() {
            _writelnTypeWithIndent('bound', e.bound);
            _writelnTypeWithIndent('defaultType', e.defaultType);
            _writeResolvedMetadata(e.metadata);
          });
        }
      });
    }
  }
}

class _Replacement {
  final int offset;
  final int end;
  final String text;

  _Replacement(this.offset, this.end, this.text);
}
