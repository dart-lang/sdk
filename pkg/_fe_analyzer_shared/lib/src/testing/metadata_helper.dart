// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/metadata/ast.dart';

import '../metadata/evaluate.dart';

/// Returns the arguments expression, if [expression] is of the form
/// `Helper(foo)`, and [expression] otherwise.
///
/// This is used to simplify testing of metadata expression where most can
/// only occur as arguments to a constant constructor invocation. To avoid the
/// clutter, these tests use a `Helper` class which is omitted in the test
/// output.
Expression unwrap(Expression expression) {
  if (expression case ConstructorInvocation(
    type: NamedTypeAnnotation(reference: ClassReference(name: 'Helper')),
    constructor: ConstructorReference(name: 'new'),
    arguments: [PositionalArgument(expression: Expression argument)],
  )) {
    return argument;
  }
  return expression;
}

/// Creates a list containing structured and readable textual representation of
/// the [resolved] expression and the result of evaluating [resolved].
///
/// If [getFieldInitializer] is provided, it is used to dereference constant
/// field references during evaluation.
List<String> evaluationToText(
  Expression resolved, {
  GetFieldInitializer? getFieldInitializer,
}) {
  List<String> list = [];

  Expression unwrappedResolved = unwrap(resolved);
  list.add('resolved=${expressionToText(unwrappedResolved)}');

  Map<FieldReference, Expression> dereferences = {};
  Expression evaluated = evaluateExpression(
    unwrappedResolved,
    getFieldInitializer: getFieldInitializer,
    dereferences: dereferences,
  );
  list.add('evaluate=${expressionToText(evaluated)}');
  for (MapEntry<FieldReference, Expression> entry in dereferences.entries) {
    list.add('${entry.key.name}=${expressionToText(entry.value)}');
  }

  return list;
}

/// Creates a list containing structured and readable textual representation of
/// the [unresolved] and [resolved] expressions.
List<String> expressionsToText({
  required Expression unresolved,
  required Expression resolved,
}) {
  List<String> list = [];
  list.add('unresolved=${expressionToText(unwrap(unresolved))}');

  // The identifiers in [expression] haven't been resolved, so
  // we call [Expression.resolve] to convert the expression into
  // its resolved equivalent.
  Expression lateResolved = unresolved.resolve() ?? unresolved;

  Expression unwrappedResolved = unwrap(resolved);
  String earlyResolvedText = expressionToText(unwrappedResolved);
  String lateResolvedText = expressionToText(unwrap(lateResolved));

  // These should always be the same. If not we include both to
  // signal the error.
  if (earlyResolvedText == lateResolvedText) {
    list.add('resolved=${earlyResolvedText}');
  } else {
    list.add('early-resolved=${earlyResolvedText}');
    list.add('late-resolved=${lateResolvedText}');
  }

  return list;
}

/// Creates a structured and readable textual representation of [expression].
String expressionToText(Expression expression) {
  Writer writer = new Writer();
  return writer.expressionToText(expression);
}

/// Helper class for creating a structured and readable textual representation
/// of an [Expression] node.
class Writer {
  StringBuffer sb = new StringBuffer();
  bool _lastWasNewLine = true;
  int _indentLevel = 0;

  String expressionToText(Expression expression) {
    sb.clear();
    _expressionToText(expression);
    return sb.toString();
  }

  void _incIndent({int amount = 1, required bool addNewLine}) {
    _indentLevel += amount;
    if (addNewLine) {
      _addNewLine();
    }
  }

  void _decIndent({int amount = 1, bool addNewLine = false}) {
    _indentLevel -= amount;
    if (addNewLine) {
      _addNewLine();
    }
  }

  void _addNewLine() {
    sb.write('\n');
    _lastWasNewLine = true;
  }

  void _write(String value) {
    if (_lastWasNewLine) {
      sb.write('  ' * _indentLevel);
    }
    sb.write(value);
    _lastWasNewLine = false;
  }

  void _expressionToText(Expression expression) {
    switch (expression) {
      case InvalidExpression():
        _write('InvalidExpression()');
      case StaticGet():
        _write('StaticGet(');
        _referenceToText(expression.reference);
        _write(')');
      case FunctionTearOff():
        _write('FunctionTearOff(');
        _referenceToText(expression.reference);
        _write(')');
      case ConstructorTearOff():
        _write('ConstructorTearOff(');
        _typeAnnotationToText(expression.type);
        _write('.');
        _referenceToText(expression.reference);
        _write(')');
      case ConstructorInvocation():
        _write('ConstructorInvocation(');
        _incIndent(addNewLine: true);
        _typeAnnotationToText(expression.type);
        _write('.');
        _referenceToText(expression.constructor);
        _argumentsToText(expression.arguments);
        _decIndent();
        _write(')');
      case IntegerLiteral():
        _write('IntegerLiteral(');
        if (expression.text != null) {
          _write(expression.text!);
        } else {
          _write('value=${expression.value}');
        }
        _write(')');
      case DoubleLiteral():
        _write('DoubleLiteral(');
        _write(expression.text);
        _write(')');
      case BooleanLiteral():
        _write('BooleanLiteral(');
        _write('${expression.value}');
        _write(')');
      case NullLiteral():
        _write('NullLiteral()');
      case SymbolLiteral():
        _write('SymbolLiteral(');
        _write(expression.parts.join());
        _write(')');
      case StringLiteral():
        _write('StringLiteral(');
        _stringPartsToText(expression.parts);
        _write(')');
      case AdjacentStringLiterals():
        _write('AdjacentStringLiterals(');
        _incIndent(addNewLine: false);
        _expressionsToText(expression.expressions, delimiter: '');
        _decIndent();
        _write(')');
      case ImplicitInvocation():
        _write('ImplicitInvocation(');
        _incIndent(addNewLine: true);
        _expressionToText(expression.receiver);
        _typeArgumentsToText(expression.typeArguments);
        _argumentsToText(expression.arguments);
        _decIndent();
        _write(')');
      case StaticInvocation():
        _write('StaticInvocation(');
        _incIndent(addNewLine: true);
        _referenceToText(expression.function);
        _typeArgumentsToText(expression.typeArguments);
        _argumentsToText(expression.arguments);
        _decIndent();
        _write(')');
      case Instantiation():
        _write('Instantiation(');
        _expressionToText(expression.receiver);
        _typeArgumentsToText(expression.typeArguments);
        _write(')');
      case MethodInvocation():
        _write('MethodInvocation(');
        _incIndent(addNewLine: true);
        _expressionToText(expression.receiver);
        _write('.');
        _write(expression.name);
        _typeArgumentsToText(expression.typeArguments);
        _argumentsToText(expression.arguments);
        _decIndent();
        _write(')');
      case PropertyGet():
        _write('PropertyGet(');
        _expressionToText(expression.receiver);
        _write('.');
        _write(expression.name);
        _write(')');
      case NullAwarePropertyGet():
        _write('NullAwarePropertyGet(');
        _expressionToText(expression.receiver);
        _write('?.');
        _write(expression.name);
        _write(')');
      case TypeLiteral():
        _write('TypeLiteral(');
        _typeAnnotationToText(expression.typeAnnotation);
        _write(')');
      case ParenthesizedExpression():
        _write('ParenthesizedExpression(');
        _expressionToText(expression.expression);
        _write(')');
      case ConditionalExpression():
        _write('ConditionalExpression(');
        _incIndent(addNewLine: true);
        _expressionToText(expression.condition);
        _incIndent(addNewLine: true);
        _write('? ');
        _incIndent(addNewLine: false);
        _expressionToText(expression.then);
        _decIndent(addNewLine: true);
        _write(': ');
        _incIndent(addNewLine: false);
        _expressionToText(expression.otherwise);
        _decIndent(amount: 3);
        _write(')');
      case ListLiteral():
        _write('ListLiteral(');
        _typeArgumentsToText(expression.typeArguments);
        _write('[');
        _elementsToText(expression.elements);
        _write('])');
      case SetOrMapLiteral():
        _write('SetOrMapLiteral(');
        _typeArgumentsToText(expression.typeArguments);
        _write('{');
        _elementsToText(expression.elements);
        _write('})');
      case RecordLiteral():
        _write('RecordLiteral(');
        _recordFieldsToText(expression.fields);
        _write(')');
        break;
      case IfNull():
        _write('IfNull(');
        _incIndent(addNewLine: true);
        _expressionToText(expression.left);
        _addNewLine();
        _write(' ?? ');
        _addNewLine();
        _expressionToText(expression.right);
        _decIndent(addNewLine: true);
        _write(')');
      case LogicalExpression():
        _write('LogicalExpression(');
        _expressionToText(expression.left);
        _write(' ');
        _write(expression.operator.text);
        _write(' ');
        _expressionToText(expression.right);
        _write(')');
      case EqualityExpression():
        _write('EqualityExpression(');
        _expressionToText(expression.left);
        _write(expression.isNotEquals ? ' != ' : ' == ');
        _expressionToText(expression.right);
        _write(')');
      case BinaryExpression():
        _write('BinaryExpression(');
        _expressionToText(expression.left);
        _write(' ');
        _write(expression.operator.text);
        _write(' ');
        _expressionToText(expression.right);
        _write(')');
      case UnaryExpression():
        _write('UnaryExpression(');
        _write(expression.operator.text);
        _expressionToText(expression.expression);
        _write(')');
      case IsTest():
        _write('IsTest(');
        _expressionToText(expression.expression);
        _write(' is');
        if (expression.isNot) {
          _write('!');
        }
        _write(' ');
        _typeAnnotationToText(expression.type);
        _write(')');
      case AsExpression():
        _write('AsExpression(');
        _expressionToText(expression.expression);
        _write(' as ');
        _typeAnnotationToText(expression.type);
        _write(')');
      case NullCheck():
        _write('NullCheck(');
        _expressionToText(expression.expression);
        _write(')');
      case UnresolvedExpression():
        _write('UnresolvedExpression(');
        _unresolvedToText(expression.unresolved);
        _write(')');
    }
  }

  void _referenceToText(Reference reference) {
    switch (reference) {
      case FieldReference():
        _write(reference.name);
      case FunctionReference():
        _write(reference.name);
      case ConstructorReference():
        _write(reference.name);
      case TypeReference():
        _write(reference.name);
      case ClassReference():
        _write(reference.name);
      case TypedefReference():
        _write(reference.name);
      case ExtensionReference():
        _write(reference.name);
      case ExtensionTypeReference():
        _write(reference.name);
      case EnumReference():
        _write(reference.name);
      case MixinReference():
        _write(reference.name);
      case FunctionTypeParameterReference():
        _write(reference.name);
    }
  }

  void _typeAnnotationToText(TypeAnnotation typeAnnotation) {
    switch (typeAnnotation) {
      case NamedTypeAnnotation():
        _referenceToText(typeAnnotation.reference);
        _typeArgumentsToText(typeAnnotation.typeArguments);
      case NullableTypeAnnotation():
        _typeAnnotationToText(typeAnnotation.typeAnnotation);
        _write('?');
      case VoidTypeAnnotation():
        _write('void');
      case DynamicTypeAnnotation():
        _write('dynamic');
      case InvalidTypeAnnotation():
        _write('{invalid-type-annotation}');
      case UnresolvedTypeAnnotation():
        _write('{unresolved-type-annotation:');
        _unresolvedToText(typeAnnotation.unresolved);
        _write('}');
      case FunctionTypeAnnotation(:TypeAnnotation? returnType):
        if (returnType != null) {
          _typeAnnotationToText(returnType);
          _write(' ');
        }
        _write('Function');
        if (typeAnnotation.typeParameters.isNotEmpty) {
          _write('<');
        }
        _formalParametersToText(typeAnnotation.formalParameters);
      case FunctionTypeParameterType():
        _write(typeAnnotation.functionTypeParameter.name);
      case RecordTypeAnnotation():
        _write('(');
        String comma = '';
        for (RecordTypeEntry entry in typeAnnotation.positional) {
          _write(comma);
          _metadataToText(entry.metadata);
          _typeAnnotationToText(entry.typeAnnotation);
          if (entry.name != null) {
            _write(' ');
            _write(entry.name!);
          }
          comma = ', ';
        }
        if (typeAnnotation.named.isNotEmpty) {
          _write(comma);
          sb.write('{');
          comma = '';
          for (RecordTypeEntry entry in typeAnnotation.named) {
            _write(comma);
            _metadataToText(entry.metadata);
            _typeAnnotationToText(entry.typeAnnotation);
            if (entry.name != null) {
              _write(' ');
              _write(entry.name!);
            }
            comma = ', ';
          }
          sb.write('}');
        } else if (typeAnnotation.positional.length == 1) {
          sb.write(',');
        }
        _write(')');
    }
  }

  void _typeArgumentsToText(List<TypeAnnotation> typeArguments) {
    if (typeArguments.isNotEmpty) {
      _write('<');
      String comma = '';
      for (TypeAnnotation typeArgument in typeArguments) {
        _write(comma);
        _typeAnnotationToText(typeArgument);
        comma = ',';
      }
      _write('>');
    }
  }

  void _formalParametersToText(List<FormalParameter> formalParameters) {
    _write('(');
    String comma = '';
    bool inNamed = false;
    for (FormalParameter formalParameter in formalParameters) {
      _write(comma);
      if (!inNamed && formalParameter.isNamed) {
        _write('{');
        inNamed = true;
      }
      if (formalParameter.metadata.isNotEmpty) {
        _metadataToText(formalParameter.metadata);
      }
      if (inNamed && formalParameter.isRequired) {
        _write('required ');
      }
      if (formalParameter.typeAnnotation != null) {
        _typeAnnotationToText(formalParameter.typeAnnotation!);
        if (formalParameter.name != null) {
          _write(' ');
        }
      }
      if (formalParameter.name != null) {
        _write(formalParameter.name!);
      }
      if (formalParameter.defaultValue != null) {
        _write(' = ');
        _expressionToText(formalParameter.defaultValue!);
      }
      comma = ', ';
    }
    if (inNamed) {
      _write('}');
    }
    _write(')');
  }

  void _argumentToText(Argument argument) {
    switch (argument) {
      case PositionalArgument():
        _expressionToText(argument.expression);
      case NamedArgument():
        _write(argument.name);
        _write(': ');
        _expressionToText(argument.expression);
    }
  }

  static final int _newLine = '\n'.codeUnitAt(0);
  static final int _backSlash = r'\'.codeUnitAt(0);
  static final int _dollar = r'$'.codeUnitAt(0);
  static final int _quote = "'".codeUnitAt(0);

  String _escape(String text) {
    StringBuffer sb = new StringBuffer();
    for (int c in text.codeUnits) {
      if (c == _newLine) {
        sb.write(r'\n');
      } else if (c == _backSlash) {
        sb.write(r'\\');
      } else if (c == _dollar) {
        sb.write(r'\$');
      } else if (c == _quote) {
        sb.write(r"\'");
      } else if (c < 0x20 || c >= 0x80) {
        String hex = c.toRadixString(16);
        hex = ("0" * (4 - hex.length)) + hex;
        sb.write('\\u$hex');
      } else {
        sb.writeCharCode(c);
      }
    }
    return sb.toString();
  }

  void _stringPartsToText(List<StringLiteralPart> parts) {
    _write("'");
    for (StringLiteralPart part in parts) {
      switch (part) {
        case StringPart():
          _write(_escape(part.text));
        case InterpolationPart():
          _write(r'${');
          _expressionToText(part.expression);
          _write('}');
      }
    }
    _write("'");
  }

  void _listToText<E>(
    List<E> list,
    void Function(E) elementToText, {
    required String delimiter,
    bool useNewLine = false,
    String prefix = '',
  }) {
    if (list.isNotEmpty) {
      bool hasNewLine = useNewLine && list.length > 1;
      if (hasNewLine) {
        _incIndent(addNewLine: false);
      }
      String comma = '';
      for (E element in list) {
        _write(comma);
        if (hasNewLine) {
          _addNewLine();
        }
        _write(prefix);
        elementToText(element);
        comma = delimiter;
      }
      if (hasNewLine) {
        _decIndent();
      }
    }
  }

  void _argumentsToText(List<Argument> arguments) {
    _write('(');
    _listToText(arguments, _argumentToText, delimiter: ', ', useNewLine: true);
    _write(')');
  }

  void _expressionsToText(
    List<Expression> expressions, {
    required String delimiter,
    String prefix = '',
  }) {
    _listToText(
      expressions,
      _expressionToText,
      delimiter: delimiter,
      useNewLine: true,
    );
  }

  void _metadataToText(List<Expression> metadata) {
    if (metadata.isNotEmpty) {
      _expressionsToText(metadata, delimiter: ' ', prefix: '@');
      _write(' ');
    }
  }

  void _elementToText(Element element) {
    switch (element) {
      case ExpressionElement():
        _write('ExpressionElement(');
        if (element.isNullAware) {
          _write('?');
        }
        _expressionToText(element.expression);
        _write(')');
      case MapEntryElement():
        _write('MapEntryElement(');
        if (element.isNullAwareKey) {
          _write('?');
        }
        _expressionToText(element.key);
        _write(':');
        if (element.isNullAwareValue) {
          _write('?');
        }
        _expressionToText(element.value);
        _write(')');
      case SpreadElement():
        _write('SpreadElement(');
        if (element.isNullAware) {
          _write('?');
        }
        _write('...');
        _expressionToText(element.expression);
        _write(')');
      case IfElement():
        _write('IfElement(');
        _incIndent(addNewLine: true);
        _expressionToText(element.condition);
        _write(',');
        _addNewLine();
        _elementToText(element.then);
        if (element.otherwise != null) {
          _write(',');
          _addNewLine();
          _elementToText(element.otherwise!);
        }
        _decIndent();
        _write(')');
    }
  }

  void _elementsToText(List<Element> elements) {
    _listToText(elements, _elementToText, delimiter: ', ', useNewLine: true);
  }

  void _recordFieldToText(RecordField field) {
    switch (field) {
      case RecordNamedField():
        _write(field.name);
        _write(': ');
        _expressionToText(field.expression);
      case RecordPositionalField():
        _expressionToText(field.expression);
    }
  }

  void _recordFieldsToText(List<RecordField> fields) {
    _listToText(fields, _recordFieldToText, delimiter: ', ');
  }

  void _unresolvedToText(Unresolved unresolved) {
    switch (unresolved) {
      case UnresolvedIdentifier():
        _write('UnresolvedIdentifier(');
        _write(unresolved.name);
        _write(')');
      case UnresolvedAccess():
        _write('UnresolvedAccess(');
        _incIndent(addNewLine: true);
        _protoToText(unresolved.prefix);
        _write('.');
        _write(unresolved.name);
        _decIndent();
        _write(')');
      case UnresolvedInstantiate():
        _write('UnresolvedInstantiate(');
        _incIndent(addNewLine: true);
        _protoToText(unresolved.prefix);
        _typeArgumentsToText(unresolved.typeArguments);
        _decIndent();
        _write(')');
      case UnresolvedInvoke():
        _write('UnresolvedInvoke(');
        _incIndent(addNewLine: true);
        _protoToText(unresolved.prefix);
        _addNewLine();
        _argumentsToText(unresolved.arguments);
        _decIndent();
        _write(')');
    }
  }

  void _protoToText(Proto proto) {
    switch (proto) {
      case UnresolvedIdentifier():
        _unresolvedToText(proto);
      case UnresolvedAccess():
        _unresolvedToText(proto);
      case UnresolvedInstantiate():
        _unresolvedToText(proto);
      case UnresolvedInvoke():
        _unresolvedToText(proto);
      case ClassProto():
        _write('ClassProto(');
        _referenceToText(proto.reference);
        _write(')');
      case GenericClassProto():
        _write('GenericClassProto(');
        _referenceToText(proto.reference);
        _typeArgumentsToText(proto.typeArguments);
        _write(')');
      case EnumProto():
        _write('EnumProto(');
        _referenceToText(proto.reference);
        _write(')');
      case GenericEnumProto():
        _write('GenericEnumProto(');
        _referenceToText(proto.reference);
        _typeArgumentsToText(proto.typeArguments);
        _write(')');
      case MixinProto():
        _write('MixinProto(');
        _referenceToText(proto.reference);
        _write(')');
      case GenericMixinProto():
        _write('GenericMixinProto(');
        _referenceToText(proto.reference);
        _typeArgumentsToText(proto.typeArguments);
        _write(')');
      case ExtensionProto():
        _write('ExtensionProto(');
        _referenceToText(proto.reference);
        _write(')');
      case ExtensionTypeProto():
        _write('ExtensionTypeProto(');
        _referenceToText(proto.reference);
        _write(')');
      case GenericExtensionTypeProto():
        _write('GenericExtensionTypeProto(');
        _referenceToText(proto.reference);
        _typeArgumentsToText(proto.typeArguments);
        _write(')');
      case TypedefProto():
        _write('TypedefProto(');
        _referenceToText(proto.reference);
        _write(')');
      case GenericTypedefProto():
        _write('GenericTypedefProto(');
        _referenceToText(proto.reference);
        _typeArgumentsToText(proto.typeArguments);
        _write(')');
      case VoidProto():
        _write('VoidProto(');
        _referenceToText(proto.reference);
        _write(')');
      case DynamicProto():
        _write('DynamicProto(');
        _referenceToText(proto.reference);
        _write(')');
      case ConstructorProto():
        _write('ConstructorProto(');
        _referenceToText(proto.type);
        _referenceToText(proto.reference);
        _typeArgumentsToText(proto.typeArguments);
        _write(')');
      case FieldProto():
        _write('FieldProto(');
        _referenceToText(proto.reference);
        _write(')');
      case FunctionProto():
        _write('FunctionProto(');
        _referenceToText(proto.reference);
        _write(')');
      case FunctionInstantiationProto():
        _write('FunctionInstantiationProto(');
        _referenceToText(proto.reference);
        _typeArgumentsToText(proto.typeArguments);
        _write(')');
      case PrefixProto():
        _write('PrefixProto(');
        _write(proto.prefix);
        _write(')');
      case IdentifierProto():
        _write('IdentifierProto(');
        _write(proto.text);
        if (proto.typeArguments != null) {
          _typeArgumentsToText(proto.typeArguments!);
        }
        if (proto.arguments != null) {
          _argumentsToText(proto.arguments!);
        }
        _write(')');
      case InstanceAccessProto():
        _write('InstanceAccessProto(');
        _protoToText(proto.receiver);
        if (proto.isNullAware) {
          _write('?.');
        } else {
          _write('.');
        }
        _write(proto.text);
        _write(')');
      case ExpressionInstantiationProto():
        _write('ExpressionInstantiationProto(');
        _protoToText(proto.receiver);
        _typeArgumentsToText(proto.typeArguments);
        _write(')');
      case InstanceInvocationProto():
        _write('InstanceInvocationProto(');
        _protoToText(proto.receiver);
        _typeArgumentsToText(proto.typeArguments);
        _argumentsToText(proto.arguments);
        _write(')');
      case InvalidAccessProto():
        _write('InvalidAccessProto(');
        _protoToText(proto.receiver);
        _write(proto.text);
        _write(')');
      case InvalidInstantiationProto():
        _write('InvalidInstantiationProto(');
        _protoToText(proto.receiver);
        _typeArgumentsToText(proto.typeArguments);
        _write(')');
      case InvalidInvocationProto():
        _write('InvalidInvocationProto(');
        _protoToText(proto.receiver);
        _typeArgumentsToText(proto.typeArguments);
        _argumentsToText(proto.arguments);
        _write(')');
      case ExpressionProto():
        _write('ExpressionProto(');
        _expressionToText(proto.expression);
        _write(')');
      case FunctionTypeParameterProto():
        _write('FunctionTypeParameterProto(');
        _write(proto.functionTypeParameter.name);
        _write(')');
    }
  }
}
