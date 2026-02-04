// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:typed_data';
import 'dart:collection';

import '../ir/ir.dart' as ir;

class ModulePrinter {
  final ir.Module _module;

  late final typeNamer =
      TypeNamer(settings.scrubAbsoluteUris, _module, enqueueType);
  late final globalNamer =
      GlobalNamer(settings.scrubAbsoluteUris, _module, enqueueGlobal);
  late final functionNamer =
      FunctionNamer(settings.scrubAbsoluteUris, _module, enqueueFunction);
  late final tagNamer =
      TagNamer(settings.scrubAbsoluteUris, _module, enqueueTag);
  late final tableNamer =
      TableNamer(settings.scrubAbsoluteUris, _module, enqueueTable);
  late final dataNamer =
      DataNamer(settings.scrubAbsoluteUris, _module, enqueueDataSegment);

  final _types = <ir.DefType, String>{};
  final _tags = <ir.Tag, String>{};
  final _tables = <ir.Table, String>{};
  final _elementSegments = <ir.ElementSegment>{};
  final _activeElementSegments = <ir.Table, Map<int, String>>{};
  final _declarativeElements = <ir.DeclarativeElementSegment, String>{};
  final _globals = <ir.Global, String>{};
  final _functions = <ir.BaseFunction, String>{};
  final _dataSegments = <ir.BaseDataSegment, String>{};

  final _typeQueue = Queue<ir.DefType>();
  final _functionsQueue = Queue<ir.DefinedFunction>();

  /// Closure that tells us whether the body of a function should be printed or
  /// not.
  final ModulePrintSettings settings;

  ModulePrinter(this._module, {this.settings = const ModulePrintSettings()});

  IrPrinter newIrPrinter() => IrPrinter._(settings.preferMultiline, _module,
      typeNamer, globalNamer, functionNamer, tagNamer, tableNamer, dataNamer);

  void enqueueType(ir.DefType type) {
    if (!_types.containsKey(type)) {
      _types[type] = '';
      _generateDefType(type,
          includeConstituents: settings.printTypeConstituents(
              typeNamer.name(type, activateOnReferenceCallback: false)));
    }
  }

  void enqueueGlobal(ir.Global global) {
    if (!_globals.containsKey(global)) {
      _globals[global] = '';
      _generateGlobal(global,
          includeInitializer: settings.printGlobalInitializer(
              globalNamer.name(global, activateOnReferenceCallback: false)));
    }
  }

  void enqueueFunction(ir.BaseFunction fun) {
    if (!_functions.containsKey(fun)) {
      _functions[fun] = '';
      if (fun is ir.ImportedFunction) {
        _generateImportedFunction(fun);
      } else {
        _functionsQueue.add(fun as ir.DefinedFunction);
      }
    }
  }

  void enqueueTag(ir.Tag tag) {
    if (!_tags.containsKey(tag)) {
      _tags[tag] = '';
      _generateTag(tag);
    }
  }

  void enqueueTable(ir.Table table) {
    if (!_tables.containsKey(table)) {
      _tables[table] = '';
      _generateTable(table);

      for (final segment in _module.elements.segments) {
        if (segment is ir.ActiveElementSegment && segment.table == table) {
          enqueueElementSegment(segment);
        }
      }
    }
  }

  void enqueueElementSegment(ir.ElementSegment segment) {
    if (_elementSegments.add(segment)) {
      switch (segment) {
        case ir.ActiveFunctionElementSegment(
            startIndex: final start,
            table: final table,
            entries: final entries
          ):
          final printedEntries =
              _activeElementSegments.putIfAbsent(table, () => {});
          if (settings.printTableElements(tableNamer.name(segment.table,
              activateOnReferenceCallback: false))) {
            for (int i = 0; i < entries.length; ++i) {
              final index = start + i;
              final ip = newIrPrinter();
              ip.write('(');
              ir.RefFunc(entries[i]).printTo(ip);
              ip.write(')');
              printedEntries[index] = ip.getText();
            }
          }

          break;
        case ir.ActiveExpressionElementSegment(
            startIndex: final start,
            table: final table,
            expressions: final expressions
          ):
          final printedEntries =
              _activeElementSegments.putIfAbsent(table, () => {});
          if (settings.printTableElements(tableNamer.name(segment.table,
              activateOnReferenceCallback: false))) {
            for (int i = 0; i < expressions.length; ++i) {
              final index = start + i;
              final expression = expressions[i];
              final ip = newIrPrinter();
              for (int j = 0; j < expression.length; ++j) {
                ip.write(j > 0 ? ' (' : '(');
                expression[j].printTo(ip);
                ip.write(')');
              }
              printedEntries[index] = ip.getText();
            }
          }
          break;
        case ir.DeclarativeElementSegment(entries: final entries):
          final ip = newIrPrinter();
          ip.write('(elem declare');
          if (ip.preferMultiline) {
            ip.indent();
          }
          for (final entry in entries) {
            if (ip.preferMultiline) {
              ip.writeln();
            } else {
              ip.write(' ');
            }
            ip.write('(');
            ir.RefFunc(entry).printTo(ip);
            ip.write(')');
          }
          if (ip.preferMultiline) {
            ip.deindent();
          }
          ip.write(')');
          _declarativeElements[segment] = ip.getText();
          break;
      }
    }
  }

  void enqueueDataSegment(ir.BaseDataSegment dataSegment) {
    if (!_dataSegments.containsKey(dataSegment)) {
      // Since below `printTo` will call namer to name the data segment which
      // will trigger this callback again if not pre-initialized to ''.
      _dataSegments[dataSegment] = '';
      final ip = newIrPrinter();
      dataSegment.printTo(ip);
      _dataSegments[dataSegment] = ip.getText();
    }
  }

  String print() {
    while (_functionsQueue.isNotEmpty || _typeQueue.isNotEmpty) {
      while (_functionsQueue.isNotEmpty) {
        final fun = _functionsQueue.removeFirst();

        _generateFunction(fun,
            includingBody: settings.printFunctionBody(
                functionNamer.name(fun, activateOnReferenceCallback: false)));
      }
    }

    final mp = IndentPrinter();
    mp.writeln('(module \$${_module.moduleName}');
    mp.withIndent(() {
      final groups = _module.types.recursionGroups
          .where((group) => group.any((t) => _types.containsKey(t)))
          .toList();
      if (settings.printInSortedOrder) {
        groups.sort((a, b) {
          final firstA = typeNamer.name(
              a.firstWhere((t) => !typeNamer
                  .name(t, activateOnReferenceCallback: false)
                  .startsWith('\$brand')),
              activateOnReferenceCallback: false);
          final firstB = typeNamer.name(
              b.firstWhere((t) => !typeNamer
                  .name(t, activateOnReferenceCallback: false)
                  .startsWith('\$brand')),
              activateOnReferenceCallback: false);
          return firstA.compareTo(firstB);
        });
      }

      for (final group in groups) {
        final filtered = group.where((t) => _types.containsKey(t)).toList();
        if (filtered.isNotEmpty) {
          if (filtered.length == 1) {
            mp.write(_types[filtered.single]!);
            mp.writeln();
          } else {
            mp.writeln('(rec');
            mp.withIndent(() {
              for (final type in filtered) {
                mp.write(_types[type]!);
                mp.writeln();
              }
            });
            mp.writeln(')');
          }
        }
      }

      void printOrdered<T>(
          List<T> all, Namer<T> namer, Map<T, String> enqueued) {
        /// Either we print the elements in the name order (defined by a
        /// [Namer]) or we print them in same order as they appear in the wasm
        /// module.
        final filtered = all.where((v) => enqueued.containsKey(v)).toList();
        for (final key in (settings.printInSortedOrder
            ? namer.sort(filtered)
            : filtered)) {
          mp.write(enqueued[key]!);
          mp.writeln();
        }
      }

      printOrdered(_module.functions.imported, functionNamer, _functions);
      printOrdered(_module.globals.imported, globalNamer, _globals);
      printOrdered(_module.tables.imported, tableNamer, _tables);
      printOrdered(_module.tables.defined, tableNamer, _tables);
      printOrdered(_module.tags.defined, tagNamer, _tags);
      printOrdered(_module.globals.defined, globalNamer, _globals);

      _activeElementSegments.forEach((table, values) {
        final ip = newIrPrinter();
        ip.write('(elem ');
        ip.writeTableReference(table, alwaysPrint: true);
        if (values.isEmpty) {
          ip.write(' <...>');
        } else {
          ip.withIndent(() {
            final indices = values.keys.toList()..sort();
            for (int i = 0; i < indices.length; ++i) {
              ip.writeln();
              final index = indices[i];
              final value = values[index]!;
              ip.write('(set $index $value)');
            }
          });
        }
        ip.write(')');
        mp.writeln(ip.getText());
      });
      _declarativeElements.forEach((_, value) {
        mp.writeln(value);
      });

      printOrdered(_module.functions.defined, functionNamer, _functions);
      printOrdered(_module.dataSegments.defined, dataNamer, _dataSegments);
    });
    mp.write(')');
    return mp.getText();
  }

  void _generateTag(ir.Tag tag) {
    final p = newIrPrinter();
    tag.printTo(p);
    _tags[tag] = p.getText();
  }

  void _generateTable(ir.Table table) {
    final p = newIrPrinter();
    if (table is ir.DefinedTable) {
      table.printTo(p);
    } else if (table is ir.ImportedTable) {
      table.printTo(p);
    } else {
      return;
    }
    _tables[table] = p.getText();
  }

  void _generateGlobal(ir.Global global, {required bool includeInitializer}) {
    final p = newIrPrinter();
    global.printTo(p, includeInitializer: includeInitializer);
    _globals[global] = p.getText();
  }

  void _generateImportedFunction(ir.ImportedFunction fun) {
    final p = newIrPrinter();
    fun.printTo(p);
    _functions[fun] = p.getText();
  }

  void _generateFunction(ir.DefinedFunction fun,
      {required bool includingBody}) {
    final p = newIrPrinter();
    if (includingBody) {
      fun.printTo(p);
    } else {
      fun.printDeclarationTo(p);
    }
    _functions[fun] = p.getText().trimRight();
  }

  void _generateDefType(ir.DefType type, {required bool includeConstituents}) {
    final p = newIrPrinter();
    type.printTypeDefTo(p, includeConstituents: includeConstituents);
    _types[type] = p.getText();
  }
}

class ModulePrintSettings {
  final List<RegExp> functionFilters;
  final List<RegExp> tableFilters;
  final List<RegExp> globalFilters;
  final List<RegExp> typeFilters;
  final bool preferMultiline;
  final bool scrubAbsoluteUris;
  final bool printInSortedOrder;

  const ModulePrintSettings(
      {this.functionFilters = const [],
      this.tableFilters = const [],
      this.globalFilters = const [],
      this.typeFilters = const [],
      this.preferMultiline = false,
      this.scrubAbsoluteUris = false,
      this.printInSortedOrder = false});

  bool printFunctionBody(String name) {
    if (functionFilters.isEmpty) return true;
    if (name.isEmpty) return false;
    return functionFilters.any((pattern) => name.contains(pattern));
  }

  bool printTableElements(String name) {
    if (tableFilters.isEmpty) return true;
    if (name.isEmpty) return false;
    return tableFilters.any((pattern) => name.contains(pattern));
  }

  bool printGlobalInitializer(String name) {
    if (globalFilters.isEmpty) return true;
    if (name.isEmpty) return false;
    return globalFilters.any((pattern) => name.contains(pattern));
  }

  bool printTypeConstituents(String name) {
    if (typeFilters.isEmpty) return true;
    if (name.isEmpty) return false;
    return typeFilters.any((pattern) => name.contains(pattern));
  }

  bool get hasFilters =>
      functionFilters.isNotEmpty ||
      tableFilters.isNotEmpty ||
      globalFilters.isNotEmpty ||
      typeFilters.isNotEmpty;
}

class IndentPrinter {
  final _buffer = StringBuffer();
  int _indent = 0;
  bool _startOfLine = true;

  void write(String s) {
    final lines = s.split('\n');
    for (int i = 0; i < lines.length; ++i) {
      _writePartOfLine(lines[i]);
      if (i < (lines.length - 1)) {
        _writeNewLine();
      }
    }
  }

  void writeImport(String module, String name) {
    write('(import "');
    write(_escapeString(module));
    write('" "');
    write(_escapeString(name));
    write('")');
  }

  void writeExport(String name) {
    write('(export "${_escapeString(name)}")');
  }

  void writeln([String? s]) {
    if (s != null) {
      write(s);
    }
    write('\n');
  }

  void withIndent(void Function() fun) {
    final before = _indent;
    _indent++;
    fun();
    assert(before == (_indent - 1));
    _indent = before;
  }

  void indent() {
    _indent++;
  }

  void deindent() {
    _indent--;
    assert(_indent >= 0);
  }

  void _writePartOfLine(String text) {
    assert(!text.contains('\n'));
    if (text.isEmpty) return;
    if (_startOfLine) {
      _buffer.write('  ' * _indent);
      _startOfLine = false;
    }
    _buffer.write(text);
  }

  void _writeNewLine() {
    _buffer.write('\n');
    _startOfLine = true;
  }

  String getText() => '$_buffer';
}

class IrPrinter extends IndentPrinter {
  final bool preferMultiline;
  final ir.Module module;

  final TypeNamer _typeNamer;
  final GlobalNamer _globalNamer;
  final FunctionNamer _functionNamer;
  final TagNamer _tagNamer;
  final TableNamer _tableNamer;
  final DataNamer _dataNamer;

  _LocalNamer? _localNamer;
  final _labelNamer = _LabelNamer();

  IrPrinter._(
      this.preferMultiline,
      this.module,
      this._typeNamer,
      this._globalNamer,
      this._functionNamer,
      this._tagNamer,
      this._tableNamer,
      this._dataNamer);

  /// Returns a new [IrPrinter] with same settings, but empty indentation,
  /// empty text content and no local namer.
  IrPrinter dup() => IrPrinter._(preferMultiline, module, _typeNamer,
      _globalNamer, _functionNamer, _tagNamer, _tableNamer, _dataNamer);

  void beginLabeledBlock(ir.Instruction? instruction) {
    _labelNamer.stack.add(LabelInfo(instruction));
  }

  LabelInfo? endLabeledBlock() {
    if (_labelNamer.stack.isEmpty) return null;
    final last = _labelNamer.stack.removeLast();
    return last;
  }

  void writeLabelDefinition(int labelIndex) {
    write(_labelNamer.nameLabel(labelIndex, use: false));
  }

  void writeLabelReference(int labelIndex) {
    write(_labelNamer.nameLabel(labelIndex));
  }

  void writeLocalReference(ir.Local local) {
    write(_localNamer!.name(local.index));
  }

  void writeLocalIndexReference(int localIndex) {
    write(_localNamer!.name(localIndex));
  }

  void withLocalNames(Map<int, String> names, void Function() fun) {
    _localNamer =
        _LocalNamer(_functionNamer._scrubAbsoluteFileUris, module, names);
    fun();
    _localNamer = null;
  }

  void writeStorageTypeTypeReference(ir.StorageType type, {bool ref = true}) {
    if (type is ir.PackedType) {
      write('$type');
      return;
    }
    writeValueType(type as ir.ValueType);
  }

  String _defTypeName(ir.DefType type, bool nullable, bool ref) {
    final name = _typeNamer.name(type);
    if (ref) {
      return nullable ? '(ref null $name)' : '(ref $name)';
    }
    return nullable ? 'null $name' : name;
  }

  void writeRefTypeReference(ir.RefType type) {
    writeValueType(type, ref: false);
  }

  void writeValueType(ir.ValueType type, {bool ref = true}) {
    if (type is ir.NumType) {
      write('$type');
      return;
    }
    if (type is ir.RefType) {
      final heapType = type.heapType;
      if (heapType is ir.DefType) {
        write(_defTypeName(heapType, type.nullable, ref));
        return;
      }

      if (heapType.nullableByDefault == true && type.nullable) {
        write('$type');
        return;
      }
      if (heapType.nullableByDefault != true && !type.nullable) {
        write('$type');
        return;
      }
    }

    write('($type)');
  }

  void writeDefTypeReference(ir.DefType type) {
    write(_typeNamer.name(type));
  }

  void writeFunctionType(ir.FunctionType type) {
    type.printOneLineSignatureTo(this);
  }

  void writeHeapTypeReference(ir.HeapType heapType) {
    if (heapType is ir.DefType) {
      write(_defTypeName(heapType, false, false));
      return;
    }
    write('$heapType');
  }

  void writeTableReference(ir.Table? table, {bool alwaysPrint = false}) {
    final name = _tableNamer.name(table);
    if (alwaysPrint) {
      write(name);
      return;
    }
    if (module.tables.length > 1) {
      write(' ');
      write(name);
    }
  }

  void writeFieldReference(ir.StructType type, int fieldIndex) {
    final name = type.fieldNames[fieldIndex] ?? 'field$fieldIndex';
    write(_defTypeName(type, false, false));
    write(' \$$name');
  }

  void writeGlobalReference(ir.Global global) {
    write(_globalNamer.name(global));
  }

  void writeFunctionReference(ir.BaseFunction function) {
    write(_functionNamer.name(function));
  }

  void writeTagReference(ir.Tag tag) {
    write(_tagNamer.name(tag));
  }

  void writeDataReference(ir.BaseDataSegment dataSegment) {
    write(_dataNamer.name(dataSegment));
  }

  void writeMemoryReference(ir.Memory memory) {
    throw UnimplementedError();
  }
}

abstract class Namer<T> {
  final ir.Module _module;
  final bool _scrubAbsoluteFileUris;

  int _nextId = 0;

  final Map<T, String> _names = {};
  final void Function(T) _onReference;

  late final Map<ir.Exportable, String> _exportNames = (() {
    final map = <ir.Exportable, String>{};
    for (final export in _module.exports.exported) {
      final ir.Exportable? key = switch (export) {
        ir.TableExport(table: var table) => table,
        ir.TagExport(tag: var tag) => tag,
        ir.GlobalExport(global: var global) => global,
        ir.MemoryExport(memory: var memory) => memory,
        ir.FunctionExport(function: var function) => function,
        _ => null,
      };
      if (key != null) {
        map[key] = export.name;
      }
    }
    return map;
  })();

  Namer(this._scrubAbsoluteFileUris, this._module, this._onReference);

  String name(T key, {bool activateOnReferenceCallback = true});

  String _name(T key, String? name, String unnamedPrefix,
      bool activateOnReferenceCallback) {
    final existing = _names[key];
    if (existing != null) return existing;

    if (activateOnReferenceCallback) {
      _onReference(key);
    }
    if (name == null) {
      if (key is ir.Import) {
        name = '${key.module}.${key.name}';
      } else if (key is ir.Exportable) {
        name = _exportNames[key];
      }
    }
    if (name != null && _scrubAbsoluteFileUris) {
      name = _sanitizeAbsoluteFileUris(name);
    }
    final sanitizedName = name != null
        ? _sanitizeName(name)
        : '$unnamedPrefix${activateOnReferenceCallback ? _nextId++ : 0}';
    final quotedName = '\$$sanitizedName';
    return activateOnReferenceCallback
        ? _names[key] ??= quotedName
        : quotedName;
  }

  List<T> filter(List<T> values, bool Function(String) filter) => values
      .where((value) => filter(name(value, activateOnReferenceCallback: false)))
      .toList();

  List<T> sort(List<T> values) => values.toList()
    ..sort((a, b) {
      return name(a, activateOnReferenceCallback: false)
          .compareTo(name(b, activateOnReferenceCallback: false));
    });
}

class FunctionNamer extends Namer<ir.BaseFunction> {
  FunctionNamer(super.scrubAbsoluteUris, super.module, super.onReference);

  @override
  String name(ir.BaseFunction function,
      {bool activateOnReferenceCallback = true}) {
    return super._name(
        function, function.functionName, '', activateOnReferenceCallback);
  }
}

class TagNamer extends Namer<ir.Tag> {
  TagNamer(super.scrubAbsoluteUris, super.module, super.onReference);

  @override
  String name(ir.Tag tag, {bool activateOnReferenceCallback = true}) {
    return super._name(tag, null, 'tag', activateOnReferenceCallback);
  }
}

class TableNamer extends Namer<ir.Table> {
  TableNamer(super.scubUris, super.module, super.onReference);

  @override
  String name(ir.Table? table, {bool activateOnReferenceCallback = true}) {
    table ??= _module.tables.defined.first;

    // Try to use cache first to avoid O(n) scan in the exports.
    final existing = _names[table];
    if (existing != null) return existing;

    final prefix = table is ir.ImportedTable ? 'itable' : 'dtable';
    return super._name(table, null, prefix, activateOnReferenceCallback);
  }
}

class TypeNamer extends Namer<ir.DefType> {
  TypeNamer(super.scrubAbsoluteUris, super.module, super.onReference);

  @override
  String name(ir.DefType type, {bool activateOnReferenceCallback = true}) {
    return super._name(type, type is ir.DataType ? type.name : null, 'type',
        activateOnReferenceCallback);
  }
}

class _LocalNamer extends Namer<int> {
  final Map<int, String> _namedVariables;

  _LocalNamer(bool scrubAbsoluteUris, ir.Module module, this._namedVariables)
      : super(scrubAbsoluteUris, module, (_) {});

  @override
  String name(int index, {bool activateOnReferenceCallback = true}) {
    return super._name(
        index, _namedVariables[index], 'var', activateOnReferenceCallback);
  }
}

class GlobalNamer extends Namer<ir.Global> {
  GlobalNamer(super.scrubAbsoluteUris, super.module, super.onReference);

  @override
  String name(ir.Global global, {bool activateOnReferenceCallback = true}) {
    String? gn = global.globalName;
    if (gn == null && global is ir.ImportedGlobal) {
      gn = '${global.module}.${global.name}';
    }
    return super._name(global, gn, 'global', activateOnReferenceCallback);
  }
}

class DataNamer extends Namer<ir.BaseDataSegment> {
  DataNamer(super.scubUris, super.module, super.onReference);

  @override
  String name(ir.BaseDataSegment data,
      {bool activateOnReferenceCallback = true}) {
    return super._name(data, null, 'data', true);
  }
}

class _LabelNamer {
  int _nextId = 0;
  final stack = <LabelInfo>[];
  _LabelNamer();

  String nameLabel(int n, {bool use = true}) {
    final index = stack.length - 1 - n;
    final info = stack[index];
    if (use) info.used = true;
    return info.name ??= '\$label${_nextId++}';
  }
}

class LabelInfo {
  // This is optional as the function (body) itself introduces a label that a
  // branch instruction can break to (aka return).
  final ir.Instruction? target;

  String? name;
  bool used = false;

  LabelInfo(this.target);
}

String _escapeString(String s) {
  final units = s.codeUnits;
  final sb = StringBuffer();
  int startIndex = 0;
  while (startIndex < units.length) {
    int endIndex = units.length;
    int endUnit = 0;
    for (int i = startIndex; i < units.length; ++i) {
      final unit = units[i];
      if (unit < 0x20 ||
          0x7e < unit ||
          unit == _backslash ||
          unit == _doubleQuote) {
        endUnit = unit;
        endIndex = i;
        break;
      }
    }
    sb.write(s.substring(startIndex, endIndex));
    startIndex = endIndex + 1;
    if (endIndex < units.length) {
      if (endUnit == _backslash) {
        sb.write('\\\\');
        continue;
      }
      if (endUnit == _doubleQuote) {
        sb.write('\\"');
        continue;
      }
      if (endUnit == _newline) {
        sb.write('\\n');
        continue;
      }
      if (endUnit == _cr) {
        sb.write('\\r');
        continue;
      }
      if (endUnit == _tab) {
        sb.write('\\t');
        continue;
      }
      if (endUnit.isLeadSurrogate) {
        if ((endIndex + 1) < units.length) {
          final tail = units[endIndex + 1];
          if (tail.isTailSurrogate) {
            startIndex++;
            sb.writeEscapedPairedRune(endUnit, tail);
            continue;
          }
        }
      }
      sb.writeEscapedUnpairedRune(endUnit);
      continue;
    }
  }
  return '$sb';
}

String _sanitizeAbsoluteFileUris(String name) {
  int globalStart = 0;
  while (true) {
    final start = name.indexOf('file:///', globalStart);
    if (start < 0) {
      break;
    }
    final end = name.indexOf('.dart', start);
    if (end < 0) {
      break;
    }
    final uri = name.substring(start, end);
    final slash = uri.lastIndexOf('/');
    final first = name.substring(0, start);
    final filename = name.substring(start + slash + 1, end);
    final last = name.substring(end + '.dart'.length);
    name = '${first}file:///.../$filename.dart$last';
    globalStart = name.length - last.length;
  }
  return name;
}

String _sanitizeName(String s) {
  final units = s.codeUnits;
  for (int i = 0; i < units.length; ++i) {
    final unit = units[i];
    final sanitizedUnit = _nameAsciiMapping[unit & 0x7f];
    if (unit != sanitizedUnit) {
      return '''"${_escapeString(s)}"''';
    }
  }
  return s;
}

final Uint8List _nameAsciiMapping = (() {
  // Names are only allowed to have certain characters in them in the wat
  // format. See allowed characters at
  // https://webassembly.github.io/spec/core/text/values.html#text-id
  final map = Uint8List(128);
  for (int unit = 'a'.ordinal; unit <= 'z'.ordinal; ++unit) {
    map[unit] = unit;
  }
  for (int unit = 'A'.ordinal; unit <= 'Z'.ordinal; ++unit) {
    map[unit] = unit;
  }
  for (int unit = '0'.ordinal; unit <= '9'.ordinal; ++unit) {
    map[unit] = unit;
  }
  map['!'.ordinal] = '!'.ordinal;
  map['#'.ordinal] = '#'.ordinal;
  map['\$'.ordinal] = '\$'.ordinal;
  map['%'.ordinal] = '%'.ordinal;
  map['&'.ordinal] = '&'.ordinal;
  map['\''.ordinal] = '\''.ordinal;
  map['*'.ordinal] = '*'.ordinal;
  map['+'.ordinal] = '+'.ordinal;
  map['-'.ordinal] = '-'.ordinal;
  map['.'.ordinal] = '.'.ordinal;
  map['/'.ordinal] = '/'.ordinal;
  map[':'.ordinal] = ':'.ordinal;
  map['<'.ordinal] = '<'.ordinal;
  map['='.ordinal] = '='.ordinal;
  map['>'.ordinal] = '>'.ordinal;
  map['?'.ordinal] = '?'.ordinal;
  map['@'.ordinal] = '@'.ordinal;
  map['\\'.ordinal] = '\\'.ordinal;
  map['^'.ordinal] = '^'.ordinal;
  map['_'.ordinal] = '_'.ordinal;
  map['`'.ordinal] = '`'.ordinal;
  map['|'.ordinal] = '|'.ordinal;
  map['~'.ordinal] = '~'.ordinal;
  return map;
})();

extension on String {
  int get ordinal => codeUnitAt(0);
}

extension on StringBuffer {
  void writeEscapedUnpairedRune(int rune) {
    if (rune < 0x7ff) {
      writeHex(0xC0 | (rune >> 6));
      writeHex(0x80 | (rune & 0x3f));
      return;
    }
    writeHex(0xE0 | (rune >> 12));
    writeHex(0x80 | ((rune >> 6) & 0x3f));
    writeHex(0x80 | (rune & 0x3f));
  }

  void writeEscapedPairedRune(int leadSurrogate, int tailSurrogate) {
    final rune = _combineSurrogatePair(leadSurrogate, tailSurrogate);
    writeHex(0xF0 | (rune >> 18));
    writeHex(0x80 | ((rune >> 12) & 0x3f));
    writeHex(0x80 | ((rune >> 6) & 0x3f));
    writeHex(0x80 | (rune & 0x3f));
  }

  void writeHex(int value) {
    write('\\');
    write((value >> 4).toRadixString(16));
    write((value & 0xf).toRadixString(16));
  }
}

extension on int {
  bool get isLeadSurrogate => (this & 0xFC00) == 0xD800;
  bool get isTailSurrogate => (this & 0xFC00) == 0xDC00;
}

int _combineSurrogatePair(int lead, int tail) {
  return 0x10000 + ((lead & 0x3ff) << 10) + (tail & 0x3ff);
}

const _doubleQuote = 0x22;
const _tab = 0x9;
const _newline = 0x0a;
const _cr = 0xd;
const _backslash = 0x5c;
