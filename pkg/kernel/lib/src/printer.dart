// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../ast.dart';
import 'text_util.dart';

/// AST printer strategy used by default in `Node.toString`.
///
/// Don't use this for testing. Instead use [astTextStrategyForTesting] or
/// make an explicit strategy for the test to avoid test dependency on the
/// `Node.toString` implementation.
const AstTextStrategy defaultAstTextStrategy = const AstTextStrategy();

/// Strategy used for printing AST nodes.
///
/// This is used to avoid dependency on the `Node.toString` implementations
/// in testing.
const AstTextStrategy astTextStrategyForTesting = const AstTextStrategy(
    includeLibraryNamesInMembers: true,
    includeLibraryNamesInTypes: true,
    includeAuxiliaryProperties: false,
    useMultiline: false);

class AstTextStrategy {
  /// If `true`, references to classes and typedefs in types are prefixed by the
  /// name of their enclosing library.
  final bool includeLibraryNamesInTypes;

  /// If `true`, references to members, classes and typedefs are prefixed by the
  /// name of their enclosing library.
  final bool includeLibraryNamesInMembers;

  /// If `true`, auxiliary node properties are on include in the textual
  /// representation.
  final bool includeAuxiliaryProperties;

  /// If `true`, only [Nullability.nullable] is shown on types.
  final bool showNullableOnly;

  /// If `true`, type parameter names qualified by the name of the declaring
  /// class or function.
  final bool useQualifiedTypeParameterNames;

  /// If `true`, newlines are used to separate statements.
  final bool useMultiline;

  /// If [useMultiline] is `true`, [indentation] is used for indentation.
  final String indentation;

  /// If non-null, a maximum of [maxStatementDepth] nested statements are
  /// printed. If exceeded, '...' is printed instead.
  final int? maxStatementDepth;

  /// If non-null, a maximum of [maxStatementsLength] statements are printed
  /// within the same block.
  final int? maxStatementsLength;

  /// If non-null, a maximum of [maxExpressionDepth] nested expression are
  /// printed. If exceeded, '...' is printed instead.
  final int? maxExpressionDepth;

  /// If non-null, a maximum of [maxExpressionsLength] expression are printed
  /// within the same list of expressions, for instance in list/set literals.
  /// If exceeded, '...' is printed instead.
  final int? maxExpressionsLength;

  /// If non-null, a maximum of [maxConstantDepth] nested constants are
  /// printed. If exceeded, '...' is printed instead.
  final int? maxConstantDepth;

  const AstTextStrategy(
      {this.includeLibraryNamesInTypes = false,
      this.includeLibraryNamesInMembers = false,
      this.includeAuxiliaryProperties = false,
      this.showNullableOnly = false,
      this.useQualifiedTypeParameterNames = true,
      this.useMultiline = true,
      this.indentation = '  ',
      this.maxStatementDepth = 50,
      this.maxStatementsLength = null,
      this.maxExpressionDepth = 50,
      this.maxExpressionsLength = null,
      this.maxConstantDepth = 10});
}

class AstPrinter {
  final AstTextStrategy _strategy;
  final StringBuffer _sb = new StringBuffer();
  int _statementLevel = 0;
  int _expressionLevel = 0;
  int _constantLevel = 0;
  int _indentationLevel = 0;
  late final Map<LabeledStatement, String> _labelNames = {};
  late final Map<VariableDeclaration, String> _variableNames = {};

  AstPrinter(this._strategy);

  bool get includeAuxiliaryProperties => _strategy.includeAuxiliaryProperties;

  void incIndentation() {
    _indentationLevel++;
  }

  void decIndentation() {
    _indentationLevel--;
  }

  void write(String value) {
    _sb.write(value);
  }

  void writeClassName(Reference? reference, {bool forType = false}) {
    _sb.write(qualifiedClassNameToStringByReference(reference,
        includeLibraryName: forType
            ? _strategy.includeLibraryNamesInTypes
            : _strategy.includeLibraryNamesInMembers));
  }

  void writeTypedefName(Reference? reference) {
    _sb.write(qualifiedTypedefNameToStringByReference(reference,
        includeLibraryName: _strategy.includeLibraryNamesInTypes));
  }

  void writeExtensionName(Reference? reference) {
    _sb.write(qualifiedExtensionNameToStringByReference(reference,
        includeLibraryName: _strategy.includeLibraryNamesInMembers));
  }

  void writeExtensionTypeDeclarationName(Reference? reference) {
    _sb.write(qualifiedExtensionTypeDeclarationNameToStringByReference(
        reference,
        includeLibraryName: _strategy.includeLibraryNamesInMembers));
  }

  void writeQualifiedCanonicalNameToString(CanonicalName canonicalName) {
    _sb.write(qualifiedCanonicalNameToString(canonicalName,
        includeLibraryName: _strategy.includeLibraryNamesInMembers,
        includeLibraryNamesInTypes: _strategy.includeLibraryNamesInTypes));
  }

  void writeMemberName(Reference? reference) {
    _sb.write(qualifiedMemberNameToStringByReference(reference,
        includeLibraryName: _strategy.includeLibraryNamesInMembers));
  }

  void writeInterfaceMemberName(Reference? reference, Name? name) {
    if (name != null && (reference == null || reference.node == null)) {
      writeName(name);
    } else {
      write('{');
      _sb.write(qualifiedMemberNameToStringByReference(reference,
          includeLibraryName: _strategy.includeLibraryNamesInMembers));
      write('}');
    }
  }

  void writeName(Name? name) {
    _sb.write(nameToString(name,
        includeLibraryName: _strategy.includeLibraryNamesInMembers));
  }

  void writeNamedType(NamedType node) {
    node.toTextInternal(this);
  }

  void writeTypeParameterName(TypeParameter parameter) {
    _sb.write(_strategy.useQualifiedTypeParameterNames
        ? qualifiedTypeParameterNameToString(parameter,
            includeLibraryName: _strategy.includeLibraryNamesInTypes)
        : typeParameterNameToString(parameter));
  }

  void newLine() {
    if (_strategy.useMultiline) {
      _sb.writeln();
      _sb.write(_strategy.indentation * _indentationLevel);
    } else {
      _sb.write(' ');
    }
  }

  String getLabelName(LabeledStatement node) {
    return _labelNames[node] ??= 'label${_labelNames.length}';
  }

  String getVariableName(VariableDeclaration node) {
    String? name = node.name;
    if (name != null) {
      return name;
    }
    return _variableNames[node] ??= '#${_variableNames.length}';
  }

  String getSwitchCaseName(SwitchCase node) {
    if (node.isDefault) {
      return '"default:"';
    } else {
      return '"case ${node.expressions.first.toText(_strategy)}:"';
    }
  }

  void writeStatement(Statement node) {
    int oldStatementLevel = _statementLevel;
    _statementLevel++;
    if (_strategy.maxStatementDepth != null &&
        _statementLevel > _strategy.maxStatementDepth!) {
      _sb.write('...');
    } else {
      node.toTextInternal(this);
    }
    _statementLevel = oldStatementLevel;
  }

  void writeExpression(Expression node, {int? minimumPrecedence}) {
    int oldExpressionLevel = _expressionLevel;
    _expressionLevel++;
    if (_strategy.maxExpressionDepth != null &&
        _expressionLevel > _strategy.maxExpressionDepth!) {
      _sb.write('...');
    } else {
      bool needsParentheses =
          minimumPrecedence != null && node.precedence < minimumPrecedence;
      if (needsParentheses) {
        _sb.write('(');
      }
      node.toTextInternal(this);
      if (needsParentheses) {
        _sb.write(')');
      }
    }
    _expressionLevel = oldExpressionLevel;
  }

  void writeNamedExpression(NamedExpression node) {
    node.toTextInternal(this);
  }

  void writeCatch(Catch node) {
    node.toTextInternal(this);
  }

  void writeSwitchCase(SwitchCase node) {
    node.toTextInternal(this);
  }

  void writeType(DartType node) {
    node.toTextInternal(this);
  }

  void writeNullability(Nullability nullability) {
    if (!_strategy.showNullableOnly || nullability == Nullability.nullable) {
      write(nullabilityToString(nullability));
    }
  }

  void writeConstant(Constant node) {
    int oldConstantLevel = _constantLevel;
    _constantLevel++;
    if (_strategy.maxConstantDepth != null &&
        _constantLevel > _strategy.maxConstantDepth!) {
      _sb.write('...');
    } else {
      node.toTextInternal(this);
    }
    _constantLevel = oldConstantLevel;
  }

  void writeMapEntry(MapLiteralEntry node) {
    node.toTextInternal(this);
  }

  /// Writes [types] to the printer buffer separated by ', '.
  void writeTypes(List<DartType> types) {
    for (int index = 0; index < types.length; index++) {
      if (index > 0) {
        _sb.write(', ');
      }
      writeType(types[index]);
    }
  }

  /// If [types] is non-empty, writes [types] to the printer buffer delimited by
  /// '<' and '>', and separated by ', '.
  void writeTypeArguments(List<DartType> types) {
    if (types.isNotEmpty) {
      _sb.write('<');
      writeTypes(types);
      _sb.write('>');
    }
  }

  /// If [typeParameters] is non-empty, writes [typeParameters] to the printer
  /// buffer delimited by '<' and '>', and separated by ', '.
  ///
  /// The bound of a type parameter is included, as 'T extends Bound', if the
  /// bound is neither `Object?` nor `Object*`.
  void writeTypeParameters(List<TypeParameter> typeParameters) {
    if (typeParameters.isNotEmpty) {
      _sb.write("<");
      String comma = "";
      for (TypeParameter typeParameter in typeParameters) {
        _sb.write(comma);
        _sb.write(typeParameter.name);
        DartType bound = typeParameter.bound;

        bool isTopObject(DartType type) {
          if (type is InterfaceType &&
              type.classReference.node != null &&
              type.classNode.name == 'Object') {
            Uri uri = type.classNode.enclosingLibrary.importUri;
            return uri.isScheme('dart') &&
                uri.path == 'core' &&
                (type.nullability == Nullability.legacy ||
                    type.nullability == Nullability.nullable);
          }
          return false;
        }

        if (!isTopObject(bound) || isTopObject(typeParameter.defaultType)) {
          // Include explicit bounds only.
          _sb.write(' extends ');
          writeType(bound);
        }
        comma = ", ";
      }
      _sb.write(">");
    }
  }

  /// Writes [expressions] to the printer buffer separated by ', '.
  void writeExpressions(List<Expression> expressions) {
    if (expressions.isNotEmpty &&
        _strategy.maxExpressionDepth != null &&
        _expressionLevel + 1 > _strategy.maxExpressionDepth!) {
      // The maximum expression depth will be exceeded for all [expressions].
      // Print the list as one occurrence '...' instead one per expression.
      _sb.write('...');
    } else if (_strategy.maxExpressionsLength != null &&
        expressions.length > _strategy.maxExpressionsLength!) {
      _sb.write('...');
    } else {
      for (int index = 0; index < expressions.length; index++) {
        if (index > 0) {
          _sb.write(', ');
        }
        writeExpression(expressions[index]);
      }
    }
  }

  /// Writes [statements] to the printer buffer delimited by '{' and '}'.
  ///
  /// If using a multiline strategy, the statements printed on separate lines
  /// that are indented one level.
  void writeBlock(List<Statement> statements) {
    if (statements.isEmpty) {
      write('{}');
    } else {
      write('{');
      incIndentation();
      writeStatements(statements);
      decIndentation();
      newLine();
      write('}');
    }
  }

  /// Writes [statements] to the printer buffer.
  ///
  /// If using a multiline strategy, the statements printed on separate lines
  /// that are indented one level.
  void writeStatements(List<Statement> statements) {
    if (statements.isNotEmpty &&
        _strategy.maxStatementDepth != null &&
        _statementLevel + 1 > _strategy.maxStatementDepth!) {
      // The maximum statement depth will be exceeded for all [statements].
      // Print the list as one occurrence '...' instead one per statement.
      _sb.write(' ...');
    } else if (_strategy.maxStatementsLength != null &&
        statements.length > _strategy.maxStatementsLength!) {
      _sb.write(' ...');
    } else {
      for (Statement statement in statements) {
        newLine();
        writeStatement(statement);
      }
    }
  }

  /// Writes arguments [node] to the printer buffer.
  ///
  /// If [includeTypeArguments] is `true` type arguments in [node] are included.
  /// Otherwise only the positional and named arguments are included.
  void writeArguments(Arguments node, {bool includeTypeArguments = true}) {
    node.toTextInternal(this, includeTypeArguments: includeTypeArguments);
  }

  /// Writes the variable declaration [node] to the printer buffer.
  ///
  /// If [includeModifiersAndType] is `true`, the declaration is prefixed by
  /// the modifiers and declared type of the variable. Otherwise only the
  /// name and the initializer, if present, are included.
  ///
  /// If [isLate] and [type] are provided, these values are used instead of
  /// the corresponding properties on [node].
  void writeVariableDeclaration(VariableDeclaration node,
      {bool includeModifiersAndType = true,
      bool? isLate,
      DartType? type,
      bool includeInitializer = true}) {
    if (includeModifiersAndType) {
      if (node.isRequired) {
        _sb.write('required ');
      }
      if (isLate ?? node.isLate) {
        _sb.write('late ');
      }
      if (node.isFinal) {
        _sb.write('final ');
      }
      if (node.isConst) {
        _sb.write('const ');
      }
      writeType(type ?? node.type);
      _sb.write(' ');
    }
    _sb.write(getVariableName(node));
    if (includeInitializer && node.initializer != null && !node.isRequired) {
      _sb.write(' = ');
      writeExpression(node.initializer!);
    }
  }

  void writeFunctionNode(FunctionNode node, String name) {
    writeType(node.returnType);
    _sb.write(' ');
    _sb.write(name);
    if (node.typeParameters.isNotEmpty) {
      _sb.write('<');
      for (int index = 0; index < node.typeParameters.length; index++) {
        if (index > 0) {
          _sb.write(', ');
        }
        _sb.write(node.typeParameters[index].name);
        _sb.write(' extends ');
        writeType(node.typeParameters[index].bound);
      }
      _sb.write('>');
    }
    _sb.write('(');
    for (int index = 0; index < node.positionalParameters.length; index++) {
      if (index > 0) {
        _sb.write(', ');
      }
      if (index == node.requiredParameterCount) {
        _sb.write('[');
      }
      writeVariableDeclaration(node.positionalParameters[index]);
    }
    if (node.requiredParameterCount < node.positionalParameters.length) {
      _sb.write(']');
    }
    if (node.namedParameters.isNotEmpty) {
      if (node.positionalParameters.isNotEmpty) {
        _sb.write(', ');
      }
      _sb.write('{');
      for (int index = 0; index < node.namedParameters.length; index++) {
        if (index > 0) {
          _sb.write(', ');
        }
        writeVariableDeclaration(node.namedParameters[index]);
      }
      _sb.write('}');
    }
    _sb.write(')');
    Statement? body = node.body;
    if (body != null) {
      if (body is ReturnStatement) {
        _sb.write(' => ');
        writeExpression(body.expression!);
      } else {
        _sb.write(' ');
        writeStatement(body);
      }
    } else {
      _sb.write(';');
    }
  }

  void writeConstantMapEntry(ConstantMapEntry node) {
    node.toTextInternal(this);
  }

  /// Returns the text written to this printer.
  String getText() => _sb.toString();
}
