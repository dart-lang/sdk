// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart';
import 'package:kernel/core_types.dart' show CoreTypes;

void _convertDartTypeToC(
  StringBuffer buffer,
  CoreTypes? coreTypes,
  DartType type,
) {
  if (coreTypes == null) {
    buffer.write('Dart_Handle');
  } else if (type is VoidType) {
    buffer.write('void');
  } else if (type == coreTypes.intNonNullableRawType) {
    buffer.write('int64_t');
  } else if (type == coreTypes.doubleNonNullableRawType) {
    buffer.write('double');
  } else {
    buffer.write('Dart_Handle');
  }
}

String _getCReturnType(CoreTypes? coreTypes, DartType type) {
  if (coreTypes == null) {
    return 'Dart_Handle';
  } else if (type is VoidType) {
    return 'void';
  } else if (type == coreTypes.intNonNullableRawType) {
    return 'int64_t';
  } else if (type == coreTypes.doubleNonNullableRawType) {
    return 'double';
  } else {
    return 'Dart_Handle';
  }
}

void _convertCValueToDart(
  StringBuffer buffer,
  CoreTypes coreTypes,
  DartType type,
  void Function(StringBuffer) bodyWriter,
) {
  assert(type is! VoidType);
  if (type == coreTypes.intNonNullableRawType) {
    buffer.write('Dart_NewInteger(');
    bodyWriter(buffer);
    buffer.write(')');
  } else if (type == coreTypes.doubleNonNullableRawType) {
    buffer.write('Dart_NewDouble(');
    bodyWriter(buffer);
    buffer.write(')');
  } else {
    bodyWriter(buffer);
  }
}

void _convertDartValueToC(
  StringBuffer buffer,
  CoreTypes coreTypes,
  DartType type,
  void Function(StringBuffer) bodyWriter,
) {
  if (type is VoidType) {
    buffer.write('CheckError(');
    bodyWriter(buffer);
    buffer.write(')');
  } else if (type == coreTypes.intNonNullableRawType) {
    buffer.write('IntFromHandle(');
    bodyWriter(buffer);
    buffer.write(')');
  } else if (type == coreTypes.doubleNonNullableRawType) {
    buffer.write('DoubleFromHandle(');
    bodyWriter(buffer);
    buffer.write(')');
  } else {
    bodyWriter(buffer);
  }
}

class EntryPointShimParameter {
  final String name;
  final DartType type;

  EntryPointShimParameter._(this.name, {DartType? type})
    : type = type ?? DynamicType();

  void writeAsParameter(StringBuffer buffer, [CoreTypes? coreTypes]) {
    assert(type is! VoidType);
    _convertDartTypeToC(buffer, coreTypes, type);
    buffer.write(' $name');
  }

  void writeAsArgument(StringBuffer buffer, [CoreTypes? coreTypes]) {
    if (coreTypes != null) {
      _convertCValueToDart(buffer, coreTypes, type, (b) => b.write(name));
    } else {
      buffer.write(name);
    }
  }

  @override
  String toString() {
    final b = StringBuffer();
    writeAsArgument(b);
    return b.toString();
  }
}

class EntryPointShimTypeParameter extends EntryPointShimParameter {
  static int counter = 0;
  static String get gensym => 'tp${counter++}';

  EntryPointShimTypeParameter._(String name) : super._('t_' + name);

  factory EntryPointShimTypeParameter.fromTypeParameter(TypeParameter p) {
    return EntryPointShimTypeParameter._(p.name ?? gensym);
  }
}

class EntryPointShimValueParameter extends EntryPointShimParameter {
  static int counter = 0;
  static String get gensym => '${counter++}';

  EntryPointShimValueParameter._(String name, {super.type})
    : super._('v_' + name);

  factory EntryPointShimValueParameter.fromDeclaration(VariableDeclaration v) {
    return EntryPointShimValueParameter._(v.name ?? gensym, type: v.type);
  }
}

abstract class EntryPointFunctionShim {
  final NamedNode node;
  final CoreTypes coreTypes;
  final List<EntryPointShimParameter> parameters;
  // The target may be the instance for instance members or a type if the
  // enclosing class is generic and thus needs instantiation.
  final EntryPointShimParameter? target;

  static EntryPointShimParameter? targetOf(
    NamedNode node,
    CoreTypes coreTypes,
  ) {
    if (node is! Member) return null;

    if (node.isInstanceMember) {
      // For instance methods, the instance contains the instantiation of the
      // class type parameters.
      return EntryPointShimValueParameter._(
        "_inst",
        type: node.enclosingClass!.getThisType(
          coreTypes,
          Nullability.nonNullable,
        ),
      );
    }
    final cls = node.enclosingClass;
    if (cls != null && cls.typeParameters.isNotEmpty) {
      // Need to handle type parameters on the enclosing class. Defer this
      // by requiring the user provide the appropriate instantiated
      // non-nullable type.
      return EntryPointShimTypeParameter._("_T");
    }
    return null;
  }

  static List<EntryPointShimParameter> parametersOf(NamedNode node) {
    if (node is Procedure || node is Constructor) {
      final function = (node as dynamic).function as FunctionNode;
      assert(function.namedParameters.isEmpty);
      assert(
        function.requiredParameterCount == function.positionalParameters.length,
      );
      return function.positionalParameters
          .map(EntryPointShimValueParameter.fromDeclaration)
          .toList();
    }
    if (node is Class) {
      return node.typeParameters
          .map(EntryPointShimTypeParameter.fromTypeParameter)
          .toList();
    }
    return const [];
  }

  EntryPointFunctionShim._({
    required this.node,
    required this.coreTypes,
    List<EntryPointShimParameter>? parameters,
    EntryPointShimParameter? target,
  }) : parameters = parameters ?? parametersOf(node),
       target = target ?? targetOf(node, coreTypes);

  static final _cachedBaseNames = <Reference, String>{};
  static final _cachedPrefixedNames = <Reference, String>{};

  static String _baseName(NamedNode node) {
    if (!_cachedBaseNames.containsKey(node.reference)) {
      var name = (node as dynamic).name;
      if (name is Name) {
        assert(name.isPrivate == name.text.startsWith('_'));
        name = name.text;
      }
      _cachedBaseNames[node.reference] = name as String;
    }
    return _cachedBaseNames[node.reference]!;
  }

  static String _prefixedName(NamedNode node) {
    if (!_cachedPrefixedNames.containsKey(node.reference)) {
      String prefixedName = _baseName(node);
      if (node is Member) {
        final cls = node.enclosingClass;
        if (cls != null) {
          final prefix = _prefixedName(cls);
          if (prefixedName.isEmpty || prefixedName == '_') {
            prefixedName = '$prefix$prefixedName';
          } else {
            prefixedName = '${prefix}_$prefixedName';
          }
        }
      }
      _cachedPrefixedNames[node.reference] = prefixedName;
    }
    return _cachedPrefixedNames[node.reference]!;
  }

  String get baseName => _baseName(node);
  String get prefixedName => _prefixedName(node);

  String get functionName;
  DartType get returnType;

  void _writeTarget(StringBuffer buffer) {
    if (target != null) {
      target!.writeAsArgument(buffer, coreTypes);
      return;
    }
    final n = node;
    Class? cls;
    if (n is Member) {
      cls = n.enclosingClass;
      if (cls != null && cls.typeParameters.isNotEmpty) {
        // The shim should have had a target parameter created.
        throw "Unexpected attempt to write target";
      }
    } else if (n is Class) {
      cls = n;
    }
    if (cls == null) {
      buffer.write('PackageState::instance()->PackageLibrary()');
    } else if (cls.typeParameters.isEmpty) {
      buffer.write(
        'PackageState::instance()->TypeWithDefaults("${_baseName(cls)}")',
      );
    } else {
      assert(node is Class);
      assert(parameters.isNotEmpty);
      buffer.write(
        'Dart_GetNonNullableType(PackageState::instance()->PackageLibrary(), Dart_NewStringFromCString("$baseName"), ',
      );
      _writeArgumentsListCountAndPointer(buffer);
      buffer.write(')');
    }
  }

  void _writeArguments(StringBuffer buffer) {
    bool first = true;
    for (final p in parameters) {
      if (!first) buffer.write(', ');
      p.writeAsArgument(buffer, coreTypes);
      first = false;
    }
  }

  void _writeArgumentsListCountAndPointer(StringBuffer buffer) {
    buffer.write('${parameters.length}, ');
    if (parameters.isEmpty) {
      // No arguments list created.
      buffer.write('nullptr');
    } else {
      buffer.write('parameter_list.data()');
    }
  }

  void _writeReturnType(StringBuffer buffer) {
    _convertDartTypeToC(buffer, coreTypes, returnType);
  }

  String get isolateName => 'dart_isolate';

  void _writeFunctionHeader(StringBuffer buffer) {
    buffer.write('PACKAGE_EXPORT ');
    _writeReturnType(buffer);
    buffer.write(' $functionName(Dart_Isolate $isolateName');
    if (target != null) {
      buffer.write(', ');
      target!.writeAsParameter(buffer, coreTypes);
    }
    for (final p in parameters) {
      buffer.write(', ');
      p.writeAsParameter(buffer, coreTypes);
    }
    buffer.write(')');
  }

  void writeDeclaration(StringBuffer buffer) {
    _writeFunctionHeader(buffer);
    buffer.writeln(';');
  }

  void _writeReturnBody(StringBuffer buffer);

  void writeDefinition(StringBuffer buffer) {
    _writeFunctionHeader(buffer);
    buffer.writeln(''' {
  IsolateScope isolate_scope($isolateName);
  DartScope scope;''');
    if (parameters.isNotEmpty) {
      buffer.write('''
  std::vector parameter_list{''');
      _writeArguments(buffer);
      buffer.writeln('};');
    }
    buffer.write('  ');
    if (returnType is! VoidType) {
      buffer.write('return ');
    }
    _convertDartValueToC(buffer, coreTypes, returnType, _writeReturnBody);
    buffer
      ..writeln(';')
      ..writeln('}')
      ..writeln('');
  }

  void write(StringBuffer declaration, StringBuffer definition) {
    writeDeclaration(declaration);
    writeDefinition(definition);
  }

  @override
  String toString() {
    final b = StringBuffer();
    writeDefinition(b);
    return b.toString();
  }
}

class EntryPointGetterShim extends EntryPointFunctionShim {
  @override
  final Member node;

  EntryPointGetterShim._({required this.node, required super.coreTypes})
    : super._(node: node, parameters: const []);

  factory EntryPointGetterShim.fromMember(Member node, CoreTypes coreTypes) {
    assert(node is Field || (node is Procedure && node.isGetter));
    return EntryPointGetterShim._(node: node, coreTypes: coreTypes);
  }

  @override
  String get functionName => 'Get_$prefixedName';

  @override
  DartType get returnType => node.getterType;

  @override
  void _writeReturnBody(StringBuffer buffer) {
    buffer.write('Dart_GetField(');
    _writeTarget(buffer);
    buffer.write(', Dart_NewStringFromCString("$baseName"))');
  }
}

class EntryPointClosureShim extends EntryPointGetterShim {
  @override
  final Procedure node;

  EntryPointClosureShim._({required this.node, required super.coreTypes})
    : super._(node: node);

  factory EntryPointClosureShim.fromProcedure(
    Procedure node,
    CoreTypes coreTypes,
  ) {
    assert(!node.isGetter && !node.isFactory);
    return EntryPointClosureShim._(node: node, coreTypes: coreTypes);
  }

  @override
  String get functionName => '${super.functionName}_Closure';
}

class EntryPointSetterShim extends EntryPointFunctionShim {
  @override
  final Member node;

  EntryPointSetterShim._({required this.node, required super.coreTypes})
    : super._(
        node: node,
        parameters: [
          EntryPointShimValueParameter._("value", type: node.setterType),
        ],
      );

  factory EntryPointSetterShim.fromMember(Member node, CoreTypes coreTypes) {
    assert(node is Field || (node is Procedure && node.isSetter));
    return EntryPointSetterShim._(node: node, coreTypes: coreTypes);
  }

  @override
  String get functionName => 'Set_$prefixedName';

  @override
  DartType get returnType => VoidType();

  @override
  void _writeReturnBody(StringBuffer buffer) {
    buffer.write('Dart_SetField(');
    _writeTarget(buffer);
    buffer.write(', Dart_NewStringFromCString("$baseName"), ');
    _writeArguments(buffer);
    buffer.write(')');
  }
}

class EntryPointClassShim extends EntryPointFunctionShim {
  @override
  final Class node;

  EntryPointClassShim._({required this.node, required super.coreTypes})
    : super._(node: node, parameters: const []);

  factory EntryPointClassShim.fromClass(Class node, CoreTypes coreTypes) {
    return EntryPointClassShim._(node: node, coreTypes: coreTypes);
  }

  @override
  String get functionName => 'Get_${prefixedName}_Class';

  @override
  DartType get returnType => coreTypes.typeNonNullableRawType;

  @override
  void _writeReturnBody(StringBuffer buffer) =>
  // Don't use _writeTarget, since we want the default type arguments for
  // generic classes.
  buffer.write('PackageState::instance()->TypeWithDefaults("$baseName")');
}

class EntryPointNullableTypeShim extends EntryPointFunctionShim {
  @override
  final Class node;

  EntryPointNullableTypeShim._({required this.node, required super.coreTypes})
    : super._(node: node);

  factory EntryPointNullableTypeShim.fromClass(
    Class node,
    CoreTypes coreTypes,
  ) {
    return EntryPointNullableTypeShim._(node: node, coreTypes: coreTypes);
  }

  @override
  String get functionName => 'Get_${prefixedName}_NullableType';

  @override
  DartType get returnType => coreTypes.typeNonNullableRawType;

  @override
  void _writeReturnBody(StringBuffer buffer) {
    buffer.write('Dart_TypeToNullableType(');
    _writeTarget(buffer);
    buffer.write(')');
  }
}

class EntryPointNonNullableTypeShim extends EntryPointFunctionShim {
  @override
  final Class node;

  EntryPointNonNullableTypeShim._({
    required this.node,
    required super.coreTypes,
  }) : super._(node: node);

  factory EntryPointNonNullableTypeShim.fromClass(
    Class node,
    CoreTypes coreTypes,
  ) {
    return EntryPointNonNullableTypeShim._(node: node, coreTypes: coreTypes);
  }

  @override
  String get functionName => 'Get_${prefixedName}_NonNullableType';

  @override
  DartType get returnType => coreTypes.typeNonNullableRawType;

  @override
  void _writeReturnBody(StringBuffer buffer) => _writeTarget(buffer);
}

class EntryPointAllocationShim extends EntryPointFunctionShim {
  @override
  final Class node;

  EntryPointAllocationShim._({required this.node, required super.coreTypes})
    : super._(node: node);

  factory EntryPointAllocationShim.fromClass(Class node, CoreTypes coreTypes) {
    return EntryPointAllocationShim._(node: node, coreTypes: coreTypes);
  }

  @override
  String get functionName => 'Allocate_${prefixedName}';

  @override
  DartType get returnType => DynamicType(); // to avoid C conversions

  @override
  void _writeReturnBody(StringBuffer buffer) {
    buffer.write('Dart_Allocate(');
    _writeTarget(buffer);
    buffer.write(')');
  }
}

class EntryPointNewShim extends EntryPointFunctionShim {
  @override
  final Constructor node;

  EntryPointNewShim._({required this.node, required super.coreTypes})
    : super._(node: node);

  factory EntryPointNewShim.fromConstructor(
    Constructor node,
    CoreTypes coreTypes,
  ) {
    return EntryPointNewShim._(node: node, coreTypes: coreTypes);
  }

  static FunctionType functionType(Constructor node) =>
      node.function.computeThisFunctionType(Nullability.nonNullable);

  @override
  String get functionName => 'New_$prefixedName';

  @override
  DartType get returnType => node.function.returnType;

  @override
  void _writeReturnBody(StringBuffer buffer) {
    buffer.write('Dart_New(');
    _writeTarget(buffer);
    buffer.write(', Dart_NewStringFromCString("$baseName"), ');
    _writeArgumentsListCountAndPointer(buffer);
    buffer.write(')');
  }
}

class EntryPointInitializationShim extends EntryPointFunctionShim {
  @override
  final Constructor node;

  EntryPointInitializationShim._({required this.node, required super.coreTypes})
    : super._(
        node: node,
        target: EntryPointShimValueParameter._(
          "_instance",
          type: node.enclosingClass.getThisType(
            coreTypes,
            Nullability.nonNullable,
          ),
        ),
      );

  factory EntryPointInitializationShim.fromConstructor(
    Constructor node,
    CoreTypes coreTypes,
  ) {
    return EntryPointInitializationShim._(node: node, coreTypes: coreTypes);
  }

  static FunctionType functionType(Constructor node) {
    final type = node.function.computeThisFunctionType(Nullability.nonNullable);
    return FunctionType(
      type.positionalParameters,
      VoidType(),
      type.declaredNullability,
      namedParameters: type.namedParameters,
      typeParameters: type.typeParameters,
      requiredParameterCount: type.requiredParameterCount,
    );
  }

  @override
  String get functionName => 'Initialize_$prefixedName';

  @override
  DartType get returnType => VoidType();

  @override
  void _writeReturnBody(StringBuffer buffer) {
    buffer.write('Dart_InvokeConstructor(');
    _writeTarget(buffer);
    buffer.write(', Dart_NewStringFromCString("$baseName"), ');
    _writeArgumentsListCountAndPointer(buffer);
    buffer.write(')');
  }
}

class EntryPointCallShim extends EntryPointFunctionShim {
  @override
  final Member node;

  EntryPointCallShim._({
    required this.node,
    required super.coreTypes,
    super.parameters,
  }) : super._(node: node);

  factory EntryPointCallShim.fromMember(Member node, CoreTypes coreTypes) {
    final FunctionType type = functionType(node);
    assert(type.typeParameters.isEmpty);
    assert(type.namedParameters.isEmpty);
    assert(
      type.requiredPositionalParameterCount == type.positionalParameters.length,
    );
    List<EntryPointShimParameter>? parameters;
    if (_isGetter(node)) {
      parameters = <EntryPointShimParameter>[];
      for (int i = 0; i < type.positionalParameters.length; ++i) {
        parameters.add(
          EntryPointShimValueParameter._(
            i.toString(),
            type: type.positionalParameters[i],
          ),
        );
      }
    }

    return EntryPointCallShim._(
      node: node,
      coreTypes: coreTypes,
      parameters: parameters,
    );
  }

  static bool _isGetter(Member node) =>
      node is Field || (node is Procedure && node.isGetter);

  static FunctionType functionType(Member node) =>
      _isGetter(node)
          ? node.getterType as FunctionType
          : (node as Procedure).computeSignatureOrFunctionType();

  @override
  String get functionName => 'Call_$prefixedName';

  @override
  DartType get returnType => functionType(node).returnType;

  @override
  void _writeReturnBody(StringBuffer buffer) {
    var isDartHandle = _getCReturnType(coreTypes, returnType) == 'Dart_Handle';

    if (isDartHandle) {
      buffer.write('Dart_NewPersistentHandle(');
    }
    buffer.write('Dart_Invoke(');
    _writeTarget(buffer);
    buffer.write(', Dart_NewStringFromCString("$baseName"), ');
    _writeArgumentsListCountAndPointer(buffer);
    buffer.write(')');
    if (isDartHandle) {
      buffer.write(')');
    }
  }
}
