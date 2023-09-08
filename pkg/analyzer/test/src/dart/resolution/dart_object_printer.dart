// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/constant/value.dart';
import 'package:collection/collection.dart';

import '../../../util/element_printer.dart';
import '../../../util/tree_string_sink.dart';

/// Prints [DartObjectImpl] as a tree, with values and fields.
class DartObjectPrinter {
  final DartObjectPrinterConfiguration _configuration;
  final TreeStringSink _sink;
  final ElementPrinter _elementPrinter;

  DartObjectPrinter({
    required DartObjectPrinterConfiguration configuration,
    required TreeStringSink sink,
    required ElementPrinter elementPrinter,
  })  : _configuration = configuration,
        _sink = sink,
        _elementPrinter = elementPrinter;

  void write(DartObjectImpl? object) {
    if (object != null) {
      final type = object.type;
      final state = object.state;
      if (object.isUnknown) {
        _sink.write('<unknown> ');
        _elementPrinter.writeType(type);
      } else if (type.isDartCoreBool) {
        _sink.write('bool ');
        _sink.writeln(object.toBoolValue());
      } else if (type.isDartCoreDouble) {
        _sink.write('double ');
        _sink.writeln(object.toDoubleValue());
      } else if (type.isDartCoreInt) {
        _writeInteger(object);
      } else if (type.isDartCoreNull) {
        _sink.writeln('Null null');
      } else if (type.isDartCoreString) {
        _writeString(object);
      } else if (state is FunctionState) {
        _writeFunctionState(type, state);
      } else if (state is GenericState) {
        _writeGenericState(type, state);
      } else if (state is ListState) {
        _writeListState(state);
      } else if (state is MapState) {
        _writeMapState(state);
      } else if (state is RecordState) {
        _writeRecordState(type, state);
      } else if (state is SetState) {
        _writeSetState(state);
      } else if (state is TypeState) {
        _sink.write('Type ');
        _sink.writeln(state);
      } else {
        throw UnimplementedError();
      }
      _writeVariable(object);
    } else {
      _sink.writeln('<null>');
    }
  }

  void _writeFunctionState(DartType type, FunctionState state) {
    _elementPrinter.writeType(type);

    _sink.withIndent(() {
      _elementPrinter.writeNamedElement('element', state.element);
    });

    _writeTypeArguments(state.typeArguments);
  }

  void _writeGenericState(DartType type, GenericState state) {
    _writelnType(type);
    _sink.withIndent(() {
      final fields = state.fields;
      final sortedFields = fields.entries.sortedBy((e) => e.key);
      for (final entry in sortedFields) {
        _sink.writeIndent();
        _sink.write('${entry.key}: ');
        write(entry.value);
      }
    });
  }

  void _writeInteger(DartObjectImpl object) {
    _sink.write('int ');
    final intValue = object.toIntValue();
    if (_configuration.withHexIntegers && intValue != null) {
      _sink.writeln('0x${intValue.toRadixString(16)}');
    } else {
      _sink.writeln(intValue);
    }
  }

  void _writeListState(ListState state) {
    _sink.writeln('List');
    _sink.withIndent(() {
      _elementPrinter.writeNamedType('elementType', state.elementType);
      final elements = state.elements;
      if (elements.isNotEmpty) {
        _sink.writelnWithIndent('elements');
        _sink.withIndent(() {
          for (final element in elements) {
            _sink.writeIndent();
            write(element);
          }
        });
      }
    });
  }

  void _writelnType(DartType type) {
    _elementPrinter.writeType(type);

    if (_configuration.withTypeArguments) {
      if (type is InterfaceType) {
        _writeTypeArguments(type.typeArguments);
      }
    }
  }

  void _writeMapState(MapState state) {
    _sink.writeln('Map');
    _sink.withIndent(() {
      final entries = state.entries;
      if (entries.isNotEmpty) {
        _sink.writelnWithIndent('entries');
        _sink.withIndent(() {
          for (final entry in entries.entries) {
            _sink.writelnWithIndent('entry');
            _sink.withIndent(() {
              _sink.writeIndent();
              _sink.write('key: ');
              write(entry.key);

              _sink.writeIndent();
              _sink.write('value: ');
              write(entry.value);
            });
          }
        });
      }
    });
  }

  void _writeRecordState(DartType type, RecordState state) {
    _sink.write('Record');
    _elementPrinter.writeType(type);

    _sink.withIndent(() {
      final positionalFields = state.positionalFields;
      if (positionalFields.isNotEmpty) {
        _sink.writelnWithIndent('positionalFields');
        _sink.withIndent(() {
          positionalFields.forEachIndexed((index, field) {
            _sink.writeIndent();
            _sink.write('\$${index + 1}: ');
            write(field);
          });
        });
      }

      final namedFields = state.namedFields;
      if (namedFields.isNotEmpty) {
        _sink.writelnWithIndent('namedFields');
        _sink.withIndent(() {
          final entries = namedFields.entries.sortedBy((entry) => entry.key);
          for (final entry in entries) {
            _sink.writeIndent();
            _sink.write('${entry.key}: ');
            write(entry.value);
          }
        });
      }
    });
  }

  void _writeSetState(SetState state) {
    _sink.writeln('Set');
    _sink.withIndent(() {
      final elements = state.elements;
      if (elements.isNotEmpty) {
        _sink.writelnWithIndent('elements');
        _sink.withIndent(() {
          for (final element in elements) {
            _sink.writeIndent();
            write(element);
          }
        });
      }
    });
  }

  void _writeString(DartObjectImpl object) {
    _sink.write('String ');

    final stringValue = object.toStringValue();
    if (stringValue == null || stringValue.isEmpty) {
      _sink.writeln('<empty>');
    } else {
      _sink.writeln(stringValue);
    }
  }

  void _writeTypeArguments(List<DartType>? typeArguments) {
    _sink.withIndent(() {
      _elementPrinter.writeTypeList('typeArguments', typeArguments);
    });
  }

  void _writeVariable(DartObjectImpl object) {
    final variable = object.variable;
    if (variable != null) {
      _sink.withIndent(() {
        _elementPrinter.writeNamedElement('variable', variable);
      });
    }
  }
}

class DartObjectPrinterConfiguration {
  bool withHexIntegers = false;
  bool withTypeArguments = false;
}
