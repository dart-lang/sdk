// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:typed_data';
import 'dart:collection';

import '../ir/ir.dart' as ir;

class ModulePrinter {
  final ir.Module _module;

  late final typeNamer =
      _TypeNamer(settings.scrubAbsoluteUris, _module, enqueueType);
  late final globalNamer =
      _GlobalNamer(settings.scrubAbsoluteUris, _module, enqueueGlobal);
  late final functionNamer =
      _FunctionNamer(settings.scrubAbsoluteUris, _module, enqueueFunction);
  late final tagNamer =
      _TagNamer(settings.scrubAbsoluteUris, _module, enqueueTag);
  late final tableNamer =
      _TableNamer(settings.scrubAbsoluteUris, _module, enqueueTable);

  final _types = <ir.DefType, String>{};
  final _tags = <ir.Tag, String>{};
  final _tables = <ir.Table, String>{};
  final _globals = <ir.Global, String>{};
  final _functions = <ir.BaseFunction, String>{};

  final _typeQueue = Queue<ir.DefType>();
  final _functionsQueue = Queue<ir.DefinedFunction>();

  /// Closure that tells us whether the body of a function should be printed or
  /// not.
  final ModulePrintSettings settings;

  ModulePrinter(this._module, {this.settings = const ModulePrintSettings()});

  IrPrinter newIrPrinter() => IrPrinter._(settings.preferMultiline, _module,
      typeNamer, globalNamer, functionNamer, tagNamer, tableNamer);

  void enqueueType(ir.DefType type) {
    if (!_types.containsKey(type)) {
      _types[type] = '';
      _generateDefType(type,
          includeConstituents: settings.printTypeConstituents(
              typeNamer.nameDefType(type, activateOnReferenceCallback: false)));
    }
  }

  void enqueueGlobal(ir.Global global) {
    if (!_globals.containsKey(global)) {
      _globals[global] = '';
      _generateGlobal(global,
          includeInitializer: settings.printGlobalInitializer(globalNamer
              .nameGlobal(global, activateOnReferenceCallback: false)));
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
      _generateTable(table,
          includeElements: settings.printTableElements(
              tableNamer.nameTable(table, activateOnReferenceCallback: false)));
    }
  }

  String print() {
    while (_functionsQueue.isNotEmpty || _typeQueue.isNotEmpty) {
      while (_functionsQueue.isNotEmpty) {
        final fun = _functionsQueue.removeFirst();

        _generateFunction(fun,
            includingBody: settings.printFunctionBody(functionNamer
                .nameFunction(fun, activateOnReferenceCallback: false)));
      }
    }

    final mp = IndentPrinter();
    mp.writeln('(module \$${_module.moduleName}');
    mp.withIndent(() {
      for (final group in _module.types.recursionGroups) {
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
      for (final fun in _module.functions.imported) {
        final s = _functions[fun];
        if (s != null) {
          mp.write(s);
          mp.writeln();
        }
      }
      for (final global in _module.globals.imported) {
        final s = _globals[global];
        if (s != null) {
          mp.write(s);
          mp.writeln();
        }
      }
      for (final table in _module.tables.imported) {
        final s = _tables[table];
        if (s != null) {
          mp.write(s);
          mp.writeln();
        }
      }
      for (final tag in _module.tags.defined) {
        final s = _tags[tag];
        if (s != null) {
          mp.write(s);
          mp.writeln();
        }
      }
      for (final global in _module.globals.defined) {
        final s = _globals[global];
        if (s != null) {
          mp.write(s);
          mp.writeln();
        }
      }
      for (final table in _module.tables.defined) {
        final s = _tables[table];
        if (s != null) {
          mp.write(s);
          mp.writeln();
        }
      }
      for (final fun in _module.functions.defined) {
        final s = _functions[fun];
        if (s != null) {
          mp.write(s);
          mp.writeln();
        }
      }
    });
    mp.write(')');
    return mp.getText();
  }

  void _generateTag(ir.Tag tag) {
    final p = newIrPrinter();
    tag.printTo(p);
    _tags[tag] = p.getText();
  }

  void _generateTable(ir.Table table, {required bool includeElements}) {
    final p = newIrPrinter();
    if (table is ir.DefinedTable) {
      table.printTo(p, includeElements: includeElements);
    } else if (table is ir.ImportedTable) {
      table.printTo(p, includeElements: includeElements);
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

  const ModulePrintSettings(
      {this.functionFilters = const [],
      this.tableFilters = const [],
      this.globalFilters = const [],
      this.typeFilters = const [],
      this.preferMultiline = false,
      this.scrubAbsoluteUris = false});

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

  final _TypeNamer _typeNamer;
  final _GlobalNamer _globalNamer;
  final _FunctionNamer _functionNamer;
  final _TagNamer _tagNamer;
  final _TableNamer _tableNamer;

  _LocalNamer? _localNamer;
  final _labelNamer = _LabelNamer();

  IrPrinter._(this.preferMultiline, this.module, this._typeNamer,
      this._globalNamer, this._functionNamer, this._tagNamer, this._tableNamer);

  /// Returns a new [IrPrinter] with same settings, but empty indentation,
  /// empty text content and no local namer.
  IrPrinter dup() => IrPrinter._(preferMultiline, module, _typeNamer,
      _globalNamer, _functionNamer, _tagNamer, _tableNamer);

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
    write(_localNamer!.nameLocal(local.index));
  }

  void writeLocalIndexReference(int localIndex) {
    write(_localNamer!.nameLocal(localIndex));
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
    final name = _typeNamer.nameDefType(type);
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
    write(_typeNamer.nameDefType(type));
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
    final name = _tableNamer.nameTable(table);
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
    write(_globalNamer.nameGlobal(global));
  }

  void writeFunctionReference(ir.BaseFunction function) {
    write(_functionNamer.nameFunction(function));
  }

  void writeTagReference(ir.Tag tag) {
    write(_tagNamer.nameTag(tag));
  }

  void writeDataReference(ir.BaseDataSegment dataSegment) {
    throw UnimplementedError();
  }

  void writeMemoryReference(ir.Memory memory) {
    throw UnimplementedError();
  }
}

class _Namer<T> {
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

  _Namer(this._scrubAbsoluteFileUris, this._module, this._onReference);

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
    final sanitizedName =
        name != null ? _sanitizeName(name) : '$unnamedPrefix${_nextId++}';
    final quotedName = '\$$sanitizedName';
    return activateOnReferenceCallback
        ? _names[key] ??= quotedName
        : quotedName;
  }
}

class _FunctionNamer extends _Namer<ir.BaseFunction> {
  _FunctionNamer(super.scrubAbsoluteUris, super.module, super.onReference);

  String nameFunction(ir.BaseFunction function,
      {bool activateOnReferenceCallback = true}) {
    return super._name(
        function, function.functionName, '', activateOnReferenceCallback);
  }
}

class _TagNamer extends _Namer<ir.Tag> {
  _TagNamer(super.scrubAbsoluteUris, super.module, super.onReference);

  String nameTag(ir.Tag tag, {bool activateOnReferenceCallback = true}) {
    return super._name(tag, null, 'tag', activateOnReferenceCallback);
  }
}

class _TableNamer extends _Namer<ir.Table> {
  _TableNamer(super.scubUris, super.module, super.onReference);

  String nameTable(ir.Table? table, {bool activateOnReferenceCallback = true}) {
    table ??= _module.tables.defined.first;

    // Try to use cache first to avoid O(n) scan in the exports.
    final existing = _names[table];
    if (existing != null) return existing;

    final prefix = table is ir.ImportedTable ? 'itable' : 'dtable';
    return super._name(table, null, prefix, activateOnReferenceCallback);
  }
}

class _TypeNamer extends _Namer<ir.DefType> {
  _TypeNamer(super.scrubAbsoluteUris, super.module, super.onReference);

  String nameDefType(ir.DefType type,
      {bool activateOnReferenceCallback = true}) {
    return super._name(type, type is ir.DataType ? type.name : null, 'type',
        activateOnReferenceCallback);
  }
}

class _LocalNamer extends _Namer<int> {
  final Map<int, String> _namedVariables;

  _LocalNamer(bool scrubAbsoluteUris, ir.Module module, this._namedVariables)
      : super(scrubAbsoluteUris, module, (_) {});

  String nameLocal(int index, {bool activateOnReferenceCallback = true}) {
    return super._name(
        index, _namedVariables[index], 'var', activateOnReferenceCallback);
  }
}

class _GlobalNamer extends _Namer<ir.Global> {
  _GlobalNamer(super.scrubAbsoluteUris, super.module, super.onReference);

  String nameGlobal(ir.Global global,
      {bool activateOnReferenceCallback = true}) {
    String? gn = global.globalName;
    if (gn == null && global is ir.ImportedGlobal) {
      gn = '${global.module}.${global.name}';
    }
    return super._name(global, gn, 'global', activateOnReferenceCallback);
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
