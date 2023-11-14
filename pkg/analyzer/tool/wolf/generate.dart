// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';

import 'package:analyzer_utilities/package_root.dart' as pkg_root;
import 'package:analyzer_utilities/tools.dart';
import 'package:collection/collection.dart';
import 'package:path/path.dart';

Future<void> main() async {
  await GeneratedContent.generateAll(analyzerPkgPath, allTargets);
}

final allTargets = [
  GeneratedFile(
      'lib/src/wolf/ir/ir.g.dart', (pkgPath) async => _IrGenerator().run())
];

final analyzerPkgPath = normalize(join(pkg_root.packageRoot, 'analyzer'));

final _instructions = _Instructions();

sealed class _Encoding {
  final String type;

  const _Encoding(this.type);

  @override
  int get hashCode => type.hashCode;

  @override
  operator ==(other) => other is _Encoding && type == other.type;

  _Parameter call(String name) => _Parameter._(name, this);

  String decode(String value);

  String encode(String value);

  String stringInterpolation(String value);
}

class _Instruction {
  final String name;
  final List<_Parameter> parameters;
  final int parameterShapeId;

  _Instruction(this.name, this.parameters, this.parameterShapeId);

  String get className => '_${name.capitalized}Instruction';

  String get signature {
    var parametersString =
        [for (var p in parameters) '${p.encoding.type} ${p.name}'].join(', ');
    return '$name($parametersString)';
  }
}

class _Instructions {
  late final sorted = all.toList()..sort((a, b) => a.name.compareTo(b.name));

  final all = <_Instruction>[];

  final encodings = <_NontrivialEncoding>[];

  final parameterShapeMap = <_ParameterShape, int>{};

  _Instructions() {
    // Encodings
    var functionFlags =
        encoding('FunctionFlags', fieldName: '_flags', constructorName: '_');
    var literal = encoding('LiteralRef');
    var type = encoding('TypeRef');

    // Primitive operations
    _addInstruction('literal', [literal('value')]);
    // Stack manipulation
    _addInstruction('drop', []);
    // Flow control
    _addInstruction('function', [type('type'), functionFlags('flags')]);
    _addInstruction('end', []);
  }

  _NontrivialEncoding encoding(String type,
      {String fieldName = 'index', String constructorName = ''}) {
    var encoding = _NontrivialEncoding(type,
        fieldName: fieldName, constructorName: constructorName);
    encodings.add(encoding);
    return encoding;
  }

  void _addInstruction(String name, List<_Parameter> parameters) {
    var parameterShapeId = parameterShapeMap.putIfAbsent(
        _ParameterShape(parameters), () => parameterShapeMap.length);
    all.add(_Instruction(name, parameters, parameterShapeId));
  }
}

class _IrGenerator {
  final _substringsToOutput = <String>[];

  void blankLine() {
    output('\n');
  }

  void output(String s) {
    _substringsToOutput.add(s);
  }

  void outputIRToStringMixin() {
    output('''
mixin IRToStringMixin implements RawIRContainerInterface {
  String instructionToString(int address) {
    switch (opcodeAt(address)) {
''');
    _instructions.all.forEachSeparated(blankLine, (instruction) {
      var opcode = 'Opcode.${instruction.name}';
      var interpolation = instruction.name.demangled;
      if (instruction.parameters.isNotEmpty) {
        var interpolationParts = <String>[];
        for (var p in instruction.parameters) {
          interpolationParts.add(p.encoding.stringInterpolation(
              '$opcode.decode${p.name.capitalized}(this, address)'));
        }
        interpolation += '(${interpolationParts.join(', ')})';
      }
      output('''
      case $opcode:
        return '$interpolation';
''');
    });
    output('''
      default:
        return '???';
    }
  }
}

''');
  }

  void outputOpcode() {
    output('''
/// TODO(paulberry): when extension types are supported, make this an extension
/// type, as well as all the `_ParameterShape` classes.
class Opcode {
  final int index;

  const Opcode._(this.index);

''');
    _instructions.all.forEachIndexed((i, instruction) {
      var shapeId = instruction.parameterShapeId;
      output('  static const ${instruction.name} = '
          '_ParameterShape$shapeId._(${i++});\n');
    });
    output('''

  String describe() => opcodeNameTable[index];

  static const opcodeNameTable = [
''');
    _instructions.all.forEachIndexed((i, instruction) {
      output('    ${json.encode(instruction.name.demangled)},');
    });
    output('''
  ];
}

''');
  }

  void outputParameterShapes() {
    _instructions.parameterShapeMap.forEach((parameterShape, id) {
      output('''
class _ParameterShape$id extends Opcode {
  const _ParameterShape$id._(super.index) : super._();
''');
      var i = 0;
      for (var parameter in parameterShape._parameters) {
        var returnType = parameter.encoding.type;
        var name = 'decode${parameter.name.capitalized}';
        var value = parameter.encoding.decode('ir._params${i++}[address]');
        output('''

  $returnType $name(RawIRContainerInterface ir, int address) {
    assert(ir.opcodeAt(address).index == index);
    return $value;
  }
''');
      }
      output('''
}

''');
    });
  }

  void outputRawIRWriterMixin() {
    output('''
mixin _RawIRWriterMixin implements _RawIRWriterMixinInterface {
''');
    _instructions.sorted.forEachSeparated(blankLine, (instruction) {
      output('''
  void ${instruction.signature} {
    _opcodes.add(Opcode.${instruction.name});
''');
      var i = 0;
      for (var p in instruction.parameters) {
        output('    _params${i++}.add(${p.encoding.encode(p.name)});\n');
      }
      while (i < 2) {
        output('    _params${i++}.add(0);\n');
      }
      output('''
  }
''');
    });
    output('}\n\n');
  }

  String run() {
    output(r'''
// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// THIS FILE IS GENERATED. DO NOT EDIT.
//
// Instead modify 'pkg/analyzer/tool/wolf/generate.dart' and run
// 'dart run pkg/analyzer/tool/wolf/generate.dart' to update.

part of 'ir.dart';

''');
    outputRawIRWriterMixin();
    outputIRToStringMixin();
    outputParameterShapes();
    outputOpcode();
    return _substringsToOutput.join('');
  }
}

class _NontrivialEncoding extends _Encoding {
  final String fieldName;
  final String constructorName;

  _NontrivialEncoding(super.type,
      {required this.fieldName, required this.constructorName});

  @override
  String decode(String value) =>
      '$type${constructorName.isEmpty ? '' : '.$constructorName'}($value)';

  @override
  String encode(String value) => '$value.$fieldName';

  @override
  String stringInterpolation(String value) =>
      '\${${type.uncapitalized}ToString($value)}';
}

class _Parameter {
  final String name;
  final _Encoding encoding;

  _Parameter._(this.name, this.encoding);

  String get fieldName => '_$name';

  @override
  int get hashCode => Object.hash(name, encoding);

  @override
  bool operator ==(other) =>
      other is _Parameter && name == other.name && encoding == other.encoding;
}

class _ParameterShape {
  final List<_Parameter> _parameters;

  _ParameterShape(this._parameters);

  @override
  int get hashCode => Object.hashAll(_parameters);

  @override
  bool operator ==(other) {
    if (other is! _ParameterShape ||
        _parameters.length != other._parameters.length) {
      return false;
    }
    for (var i = 0; i < _parameters.length; i++) {
      if (_parameters[i] != other._parameters[i]) return false;
    }
    return true;
  }
}

extension<T> on List<T> {
  forEachSeparated(void Function() separator, void Function(T) callback) {
    void Function()? nextSeparator;
    for (var item in this) {
      nextSeparator?.call();
      callback(item);
      nextSeparator = separator;
    }
  }
}

extension on String {
  String get capitalized => '${this[0].toUpperCase()}${substring(1)}';

  String get demangled => endsWith('_') ? substring(0, length - 1) : this;

  String get uncapitalized => '${this[0].toLowerCase()}${substring(1)}';
}
