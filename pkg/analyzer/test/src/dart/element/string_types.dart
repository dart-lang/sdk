// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/dart/element/type_visitor.dart';
import 'package:test/test.dart';

import '../../../generated/type_system_base.dart';

mixin StringTypes on AbstractTypeSystemTest {
  final Map<String, DartType> _types = {};

  void assertExpectedString(DartType type, String? expectedString) {
    if (expectedString != null) {
      var typeStr = typeString(type);

      expect(typeStr, expectedString);
    }
  }

  void defineStringTypes() {
    _defineType('dynamic', dynamicType);
    _defineType('InvalidType', invalidType);
    _defineType('void', voidNone);

    _defineType('Never', neverNone);
    _defineType('Never?', neverQuestion);

    _defineType('Null?', nullQuestion);

    _defineType('Object', objectNone);
    _defineType('Object?', objectQuestion);

    _defineType('Comparable<Object>', comparableNone(objectNone));
    _defineType('Comparable<num>', comparableNone(numNone));
    _defineType('Comparable<int>', comparableNone(intNone));

    _defineType('num', numNone);
    _defineType('num?', numQuestion);

    _defineType('int', intNone);
    _defineType('int?', intQuestion);

    _defineType('double', doubleNone);
    _defineType('double?', doubleQuestion);

    _defineType('List<Object>', listNone(objectNone));
    _defineType('List<num>', listNone(numNone));
    _defineType('List<int>', listNone(intNone));
    _defineType('List<int>?', listQuestion(intNone));
    _defineType('List<int?>', listNone(intQuestion));

    _defineType(
      'List<Comparable<Object>>',
      listNone(
        comparableNone(objectNone),
      ),
    );
    _defineType(
      'List<Comparable<num>>',
      listNone(
        comparableNone(numNone),
      ),
    );
    _defineType(
      'List<Comparable<Comparable<num>>>',
      listNone(
        comparableNone(
          comparableNone(numNone),
        ),
      ),
    );

    _defineType('Iterable<Object>', iterableNone(objectNone));
    _defineType('Iterable<num>', iterableNone(numNone));
    _defineType('Iterable<int>', iterableNone(intNone));

    _defineFunctionTypes();
    _defineFutureTypes();
    _defineRecordTypes();
  }

  DartType typeOfString(String str) {
    var type = _types[str];
    if (type == null) {
      fail('No DartType for: $str');
    }
    return type;
  }

  String typesString(List<DartType> types) {
    var str = types.map(typeString).join('\n');
    return '$str\n';
  }

  String typeString(DartType type) {
    return type.getDisplayString() + _typeParametersStr(type);
  }

  void _defineFunctionTypes() {
    _defineType('Function', functionNone);
    _defineType('Function?', functionQuestion);

    _defineType(
      'void Function()',
      functionTypeNone(
        returnType: voidNone,
      ),
    );

    _defineType(
      'int Function()',
      functionTypeNone(
        returnType: intNone,
      ),
    );
    _defineType(
      'int Function()?',
      functionTypeQuestion(
        returnType: intNone,
      ),
    );

    _defineType(
      'num Function(num)',
      functionTypeNone(
        parameters: [requiredParameter(type: numNone)],
        returnType: numNone,
      ),
    );
    _defineType(
      'num Function(num)?',
      functionTypeQuestion(
        parameters: [requiredParameter(type: numNone)],
        returnType: numNone,
      ),
    );

    _defineType(
      'num Function(int)',
      functionTypeNone(
        parameters: [requiredParameter(type: intNone)],
        returnType: numNone,
      ),
    );
    _defineType(
      'num Function(int)?',
      functionTypeQuestion(
        parameters: [requiredParameter(type: intNone)],
        returnType: numNone,
      ),
    );

    _defineType(
      'int Function(num)',
      functionTypeNone(
        parameters: [requiredParameter(type: numNone)],
        returnType: intNone,
      ),
    );
    _defineType(
      'int Function(int)',
      functionTypeNone(
        parameters: [requiredParameter(type: intNone)],
        returnType: intNone,
      ),
    );

    _defineType(
      'num Function(num?)',
      functionTypeNone(
        parameters: [requiredParameter(type: numQuestion)],
        returnType: numNone,
      ),
    );
    _defineType(
      'num? Function(num)',
      functionTypeNone(
        parameters: [requiredParameter(type: numNone)],
        returnType: numQuestion,
      ),
    );
    _defineType(
      'num? Function(num?)',
      functionTypeNone(
        parameters: [requiredParameter(type: numQuestion)],
        returnType: numQuestion,
      ),
    );

    _defineType(
      'num Function({num x})',
      functionTypeNone(
        parameters: [namedParameter(name: 'x', type: numNone)],
        returnType: numNone,
      ),
    );
    _defineType(
      'num Function({num? x})',
      functionTypeNone(
        parameters: [namedParameter(name: 'x', type: numQuestion)],
        returnType: numNone,
      ),
    );
    _defineType(
      'num? Function({num x})',
      functionTypeNone(
        parameters: [namedParameter(name: 'x', type: numNone)],
        returnType: numQuestion,
      ),
    );
    _defineType(
      'num? Function({num? x})',
      functionTypeNone(
        parameters: [namedParameter(name: 'x', type: numQuestion)],
        returnType: numQuestion,
      ),
    );

    _defineType(
      'num Function([num])',
      functionTypeNone(
        parameters: [positionalParameter(type: numNone)],
        returnType: numNone,
      ),
    );
    _defineType(
      'num Function([num?])',
      functionTypeNone(
        parameters: [positionalParameter(type: numQuestion)],
        returnType: numNone,
      ),
    );
    _defineType(
      'num? Function([num])',
      functionTypeNone(
        parameters: [positionalParameter(type: numNone)],
        returnType: numQuestion,
      ),
    );
    _defineType(
      'num? Function([num?])',
      functionTypeNone(
        parameters: [positionalParameter(type: numQuestion)],
        returnType: numQuestion,
      ),
    );
  }

  void _defineFutureTypes() {
    _defineType('FutureOr<Object>', futureOrNone(objectNone));
    _defineType('FutureOr<Object>?', futureOrQuestion(objectNone));
    _defineType('FutureOr<Object?>', futureOrNone(objectQuestion));
    _defineType('FutureOr<Object?>?', futureOrQuestion(objectQuestion));

    _defineType('FutureOr<num>', futureOrNone(numNone));
    _defineType('FutureOr<num?>', futureOrNone(numQuestion));
    _defineType('FutureOr<num>?', futureOrQuestion(numNone));
    _defineType('FutureOr<num?>?', futureOrQuestion(numQuestion));

    _defineType('Future<num>', futureNone(numNone));
    _defineType('Future<num>?', futureQuestion(numNone));
    _defineType('Future<num?>', futureNone(numQuestion));
    _defineType('Future<num?>?', futureQuestion(numQuestion));

    _defineType('FutureOr<int>', futureOrNone(intNone));
    _defineType('FutureOr<int>?', futureOrQuestion(intNone));
    _defineType('FutureOr<int?>', futureOrNone(intQuestion));
    _defineType('FutureOr<int?>?', futureOrQuestion(intQuestion));

    _defineType('Future<int>', futureNone(intNone));
    _defineType('Future<int>?', futureQuestion(intNone));
    _defineType('Future<int?>', futureNone(intQuestion));
    _defineType('Future<int?>?', futureQuestion(intQuestion));

    _defineType('Future<Object>', futureNone(objectNone));
    _defineType(
      'FutureOr<Future<Object>>',
      futureOrNone(
        futureNone(objectNone),
      ),
    );
    _defineType(
      'FutureOr<Future<Object>>?',
      futureOrQuestion(
        futureNone(objectNone),
      ),
    );
    _defineType(
      'FutureOr<Future<Object>?>',
      futureOrNone(
        futureQuestion(objectNone),
      ),
    );
    _defineType(
      'FutureOr<Future<Object>?>?',
      futureOrQuestion(
        futureQuestion(objectNone),
      ),
    );

    _defineType(
      'Future<Future<num>>?',
      futureQuestion(
        futureNone(numNone),
      ),
    );
    _defineType(
      'Future<Future<num?>?>?',
      futureQuestion(
        futureQuestion(numQuestion),
      ),
    );

    _defineType(
      'Future<Future<Future<num>>>?',
      futureQuestion(
        futureNone(
          futureNone(numNone),
        ),
      ),
    );
    _defineType(
      'Future<Future<Future<num?>?>?>?',
      futureQuestion(
        futureQuestion(
          futureQuestion(numQuestion),
        ),
      ),
    );

    _defineType(
      'FutureOr<FutureOr<FutureOr<num>>?>',
      futureOrNone(
        futureOrQuestion(
          futureOrNone(numNone),
        ),
      ),
    );
    _defineType(
      'FutureOr<FutureOr<FutureOr<num?>>>',
      futureOrNone(
        futureOrNone(
          futureOrNone(numQuestion),
        ),
      ),
    );
  }

  void _defineRecordTypes() {
    _defineType('Record', recordNone);

    void mixed(
      String str,
      List<DartType> positionalTypes,
      Map<String, DartType> namedTypes,
    ) {
      var type = recordTypeNone(
        positionalTypes: positionalTypes,
        namedTypes: namedTypes,
      );
      _defineType(str, type);
    }

    void allPositional(String str, List<DartType> types) {
      mixed(str, types, const {});
    }

    void allPositionalQuestion(String str, List<DartType> types) {
      var type = recordTypeQuestion(
        positionalTypes: types,
      );
      _defineType(str, type);
    }

    allPositional('(double,)', [doubleNone]);
    allPositional('(int,)', [intNone]);
    allPositional('(int?,)', [intQuestion]);
    allPositional('(num,)', [numNone]);
    allPositional('(Never,)', [neverNone]);

    allPositionalQuestion('(int,)?', [intNone]);
    allPositionalQuestion('(int?,)?', [intQuestion]);

    allPositional('(double, int)', [doubleNone, intNone]);
    allPositional('(int, double)', [intNone, doubleNone]);
    allPositional('(int, int)', [intNone, intNone]);
    allPositional('(int, Object)', [intNone, objectNone]);
    allPositional('(int, String)', [intNone, stringNone]);
    allPositional('(num, num)', [numNone, numNone]);
    allPositional('(num, Object)', [numNone, objectNone]);
    allPositional('(num, String)', [numNone, stringNone]);
    allPositional('(Never, Never)', [neverNone, neverNone]);

    void allNamed(String str, Map<String, DartType> types) {
      mixed(str, const [], types);
    }

    void allNamedQuestion(String str, Map<String, DartType> types) {
      var type = recordTypeQuestion(
        namedTypes: types,
      );
      _defineType(str, type);
    }

    allNamed('({double f1})', {'f1': doubleNone});
    allNamed('({int f1})', {'f1': intNone});
    allNamed('({int? f1})', {'f1': intQuestion});
    allNamed('({num f1})', {'f1': numNone});
    allNamed('({int f2})', {'f2': intNone});
    allNamed('({Never f1})', {'f1': neverNone});
    allNamed(r'({int $1})', {r'$1': intNone});

    allNamedQuestion('({int f1})?', {'f1': intNone});
    allNamedQuestion('({int? f1})?', {'f1': intQuestion});

    allNamed('({double f1, int f2})', {'f1': doubleNone, 'f2': intNone});
    allNamed('({int f1, double f2})', {'f1': intNone, 'f2': doubleNone});
    allNamed('({int f1, int f2})', {'f1': intNone, 'f2': intNone});
    allNamed('({int f1, Object f2})', {'f1': intNone, 'f2': objectNone});
    allNamed('({int f1, String f2})', {'f1': intNone, 'f2': stringNone});
    allNamed('({num f1, num f2})', {'f1': numNone, 'f2': numNone});
    allNamed('({num f1, Object f2})', {'f1': numNone, 'f2': objectNone});
    allNamed('({num f1, String f2})', {'f1': numNone, 'f2': stringNone});
    allNamed('({Never f1, Never f2})', {'f1': neverNone, 'f2': neverNone});

    mixed('(int, {Object f2})', [intNone], {'f2': objectNone});
    mixed('(int, {String f2})', [intNone], {'f2': stringNone});
  }

  void _defineType(String str, DartType type) {
    if (typeString(type) != str) {
      fail('Expected: $str\nActual: ${typeString(type)}');
    }

    for (var entry in _types.entries) {
      var key = entry.key;
      if (key == 'Never' || typeString(type) == 'Never') {
        // We have aliases for Never.
      } else {
        var value = entry.value;
        if (key == str) {
          fail('Duplicate type: $str;  existing: $value;  new: $type');
        }
        if (typeString(value) == typeString(type)) {
          fail('Duplicate type: $str');
        }
      }
    }
    _types[str] = type;
  }

  String _typeParametersStr(DartType type) {
    var typeStr = '';

    var typeParameterCollector = _TypeParameterCollector();
    type.accept(typeParameterCollector);
    for (var typeParameter in typeParameterCollector.typeParameters) {
      typeStr += ', $typeParameter';
    }
    return typeStr;
  }
}

class _TypeParameterCollector extends TypeVisitor<void> {
  final Set<String> typeParameters = {};

  /// We don't need to print bounds for these type parameters, because
  /// they are already included into the function type itself, and cannot
  /// be promoted.
  final Set<TypeParameterElement> functionTypeParameters = {};

  @override
  void visitDynamicType(DynamicType type) {}

  @override
  void visitFunctionType(FunctionType type) {
    functionTypeParameters.addAll(type.typeFormals);
    for (var typeParameter in type.typeFormals) {
      var bound = typeParameter.bound;
      if (bound != null) {
        bound.accept(this);
      }
    }
    for (var parameter in type.parameters) {
      parameter.type.accept(this);
    }
    type.returnType.accept(this);
  }

  @override
  void visitInterfaceType(InterfaceType type) {
    for (var typeArgument in type.typeArguments) {
      typeArgument.accept(this);
    }
  }

  @override
  void visitInvalidType(InvalidType type) {}

  @override
  void visitNeverType(NeverType type) {}

  @override
  void visitRecordType(RecordType type) {
    var fields = [
      ...type.positionalFields,
      ...type.namedFields,
    ];
    for (var field in fields) {
      field.type.accept(this);
    }
  }

  @override
  void visitTypeParameterType(TypeParameterType type) {
    if (!functionTypeParameters.contains(type.element)) {
      var bound = type.element.bound;

      if (bound == null) {
        return;
      }

      var str = '';

      var boundStr = bound.getDisplayString();
      str += '${type.element.name} extends $boundStr';

      typeParameters.add(str);
    }
  }

  @override
  void visitVoidType(VoidType type) {}
}
