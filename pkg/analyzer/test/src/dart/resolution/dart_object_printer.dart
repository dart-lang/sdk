// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/constant/value.dart';
import 'package:analyzer/src/dart/element/element.dart';
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
        _sink.write('int ');
        _sink.writeln(object.toIntValue());
      } else if (type.isDartCoreNull) {
        _sink.writeln('Null null');
      } else if (type.isDartCoreString) {
        _sink.write('String ');
        _sink.writeln(object.toStringValue());
      } else if (type is InterfaceType && state is ListState) {
        _sink.writeln('List');
        _sink.withIndent(() {
          // TODO(scheglov) ListState must know its element type.
          _elementPrinter.writeNamedType(
            'elementType',
            type.typeArguments[0],
          );
          final elements = object.toListValue()!;
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
      } else if (object.isUserDefinedObject) {
        _writelnType(type);
        _sink.withIndent(() {
          final fields = object.fields;
          if (fields != null) {
            final sortedFields = fields.entries.sortedBy((e) => e.key);
            for (final entry in sortedFields) {
              _sink.writeIndent();
              _sink.write('${entry.key}: ');
              write(entry.value);
            }
          }
        });
      } else if (state is RecordState) {
        _writeRecord(type, state);
      } else if (state is FunctionState) {
        _writeFunction(type, state);
      } else {
        throw UnimplementedError();
      }
      _writeVariable(object);
    } else {
      _sink.writeln('<null>');
    }
  }

  void _writeFunction(DartType type, FunctionState state) {
    _elementPrinter.writeType(type);

    _sink.withIndent(() {
      _elementPrinter.writeElement('element', state.element);
    });

    _writeTypeArguments(state.typeArguments);
  }

  void _writelnType(DartType type) {
    _elementPrinter.writeType(type);

    if (_configuration.withTypeArguments) {
      if (type is InterfaceType) {
        _writeTypeArguments(type.typeArguments);
      }
    }
  }

  void _writeRecord(DartType type, RecordState state) {
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

  void _writeTypeArguments(List<DartType>? typeArguments) {
    _sink.withIndent(() {
      _elementPrinter.writeTypeList('typeArguments', typeArguments);
    });
  }

  void _writeVariable(DartObjectImpl object) {
    final variable = object.variable;
    // TODO(scheglov) must be always
    if (variable is VariableElementImpl) {
      _sink.withIndent(() {
        _elementPrinter.writeElement('variable', variable);
      });
    }
  }
}

class DartObjectPrinterConfiguration {
  bool withTypeArguments = false;
}
