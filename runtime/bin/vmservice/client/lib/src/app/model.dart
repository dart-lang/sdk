// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of app;

class CodeInstruction extends Observable {
  @observable final int address;
  @observable final String machine;
  @observable final String human;
  @observable int ticks = 0;
  @observable double percent;
  @observable String formattedTicks() {
    if (percent == null || percent <= 0.0) {
      return '';
    }
    return '${percent.toStringAsFixed(2)}% (${ticks})';
  }
  @observable String formattedAddress() {
    return '0x${address.toRadixString(16)}';
  }
  CodeInstruction(this.address, this.machine, this.human);
  void updateTickString(Code code) {
    if ((code == null) || (code.inclusiveTicks == 0)) {
      percent = null;
      return;
    }
    percent = (ticks / code.inclusiveTicks) * 100.0;
    if (percent <= 0.00) {
      percent = null;
      return;
    }
  }
}

class CodeKind {
  final _value;
  const CodeKind._internal(this._value);
  String toString() => 'CodeKind.$_value';

  static CodeKind fromString(String s) {
    if (s == 'Native') {
      return Native;
    } else if (s == 'Dart') {
      return Dart;
    } else if (s == 'Collected') {
      return Collected;
    }
    throw new FallThroughError();
  }
  static const Native = const CodeKind._internal('Native');
  static const Dart = const CodeKind._internal('Dart');
  static const Collected = const CodeKind._internal('Collected');
}

class CodeTick {
  final int address;
  final int exclusive_ticks;
  final int inclusive_ticks;
  CodeTick(this.address, this.exclusive_ticks, this.inclusive_ticks);
}

class CodeCallCount {
  final Code code;
  final int count;
  CodeCallCount(this.code, this.count);
}

class Code extends Observable {
  final CodeKind kind;
  final int startAddress;
  final int endAddress;
  final List<CodeTick> ticks = [];
  final List<CodeCallCount> callers = [];
  final List<CodeCallCount> callees = [];
  int inclusiveTicks = 0;
  int exclusiveTicks = 0;
  @observable final List<CodeInstruction> instructions = toObservable([]);
  @observable Map functionRef = toObservable({});
  @observable Map codeRef = toObservable({});
  @observable String name;
  @observable String userName;

  Code(this.kind, this.name, this.startAddress, this.endAddress);

  Code.fromMap(Map map) :
    kind = CodeKind.Dart,
    startAddress = int.parse(map['start'], radix: 16),
    endAddress = int.parse(map['end'], radix: 16) {
    functionRef = toObservable(map['function']);
    codeRef = toObservable(map);
    name = map['name'];
    userName = map['user_name'];
    if (map['disassembly'] != null) {
      _loadInstructions(map['disassembly']);
    }
  }

  factory Code.fromProfileMap(Map map) {
    var kind = CodeKind.fromString(map['kind']);
    var startAddress;
    var endAddress;
    var name;
    var userName;
    var codeRef = map['code'];
    assert(codeRef != null);
    startAddress = int.parse(codeRef['start'], radix:16);
    endAddress = int.parse(codeRef['end'], radix:16);
    name = codeRef['name'];
    userName = codeRef['user_name'];
    var code = new Code(kind, name, startAddress, endAddress);
    code.codeRef = codeRef;
    code.functionRef = toObservable(codeRef['function']);;
    code.userName = userName;
    if (codeRef['disassembly'] != null) {
      code._loadInstructions(codeRef['disassembly']);
      // Throw the JSON version away after loading the disassembly.
      codeRef['disassembly'] = null;
    }
    return code;
  }

  // Refresh tick counts, etc for a code object.
  void _refresh(Map map) {
    inclusiveTicks = int.parse(map['inclusive_ticks']);
    exclusiveTicks = int.parse(map['exclusive_ticks']);
    // Load address ticks.
    var ticksList = map['ticks'];
    if ((ticksList != null) && (ticksList.length > 0)) {
      assert((ticks.length % 3) == 0);
      for (var i = 0; i < ticksList.length; i += 3) {
        var address = int.parse(ticksList[i], radix:16);
        var inclusive_ticks = int.parse(ticksList[i + 1]);
        var exclusive_ticks = int.parse(ticksList[i + 2]);
        var codeTick = new CodeTick(address, exclusive_ticks, inclusive_ticks);
        ticks.add(codeTick);
      }
    }
  }

  /// Sum all caller counts.
  int sumCallersCount() => _sumCallCount(callers);
  /// Specific caller count.
  int callersCount(Code code) => _callCount(callers, code);
  /// Sum of callees count.
  int sumCalleesCount() => _sumCallCount(callees);
  /// Specific callee count.
  int calleesCount(Code code) => _callCount(callees, code);

  int _sumCallCount(List<CodeCallCount> calls) {
    var sum = 0;
    for (CodeCallCount caller in calls) {
      sum += caller.count;
    }
    return sum;
  }

  int _callCount(List<CodeCallCount> calls, Code code) {
    for (CodeCallCount caller in calls) {
      if (caller.code == code) {
        return caller.count;
      }
    }
    return 0;
  }

  void resolveCalls(Map code, List<Code> codes) {
    _resolveCalls(callers, code['callers'], codes);
    _resolveCalls(callees, code['callees'], codes);
  }

  void _resolveCalls(List<CodeCallCount> calls, List data, List<Code> codes) {
    // Clear.
    calls.clear();
    // Resolve.
    for (var i = 0; i < data.length; i += 2) {
      var index = int.parse(data[i]);
      var count = int.parse(data[i + 1]);
      assert(index >= 0);
      assert(index < codes.length);
      calls.add(new CodeCallCount(codes[index], count));
    }
    // Sort to descending count order.
    calls.sort((a, b) => b.count - a.count);
  }

  /// Resets all tick counts to 0.
  void resetTicks() {
    inclusiveTicks = 0;
    exclusiveTicks = 0;
    ticks.clear();
    for (var instruction in instructions) {
      instruction.ticks = 0;
    }
  }

  /// Adds [count] to the tick count for the instruction at [address].
  void tick(int address, int count) {
    for (var instruction in instructions) {
      if (instruction.address == address) {
        instruction.ticks += count;
        return;
      }
    }
  }

  /// Clears [instructions] and then adds all instructions from
  /// [instructionList].
  void _loadInstructions(List instructionList) {
    instructions.clear();
    // Load disassembly into code object.
    for (int i = 0; i < instructionList.length; i += 3) {
      if (instructionList[i] == '') {
        // Code comment.
        // TODO(johnmccutchan): Insert code comments into instructions.
        continue;
      }
      var address = int.parse(instructionList[i]);
      var machine = instructionList[i + 1];
      var human = instructionList[i + 2];
      instructions.add(new CodeInstruction(address, machine, human));
    }
  }

  /// returns true if [address] is inside the address range.
  bool contains(int address) {
    return (address >= startAddress) && (address < endAddress);
  }
}

class Profile {
  final Isolate isolate;
  final List<Code> _codeObjectsInImportOrder = new List<Code>();
  int totalSamples = 0;

  Profile.fromMap(this.isolate, Map m) {
    var codes = m['codes'];
    totalSamples = m['samples'];
    Logger.root.info('Creating profile from ${totalSamples} samples '
                     'and ${codes.length} code objects.');
    isolate.resetCodeTicks();
    _codeObjectsInImportOrder.clear();
    codes.forEach((code) {
      try {
        _processCode(code);
      } catch (e, st) {
        Logger.root.warning('Error processing code object. $e $st', e, st);
      }
    });
    // Now that code objects have been loaded, post-process them
    // and resolve callers and callees.
    assert(_codeObjectsInImportOrder.length == codes.length);
    for (var i = 0; i < codes.length; i++) {
      Code code = _codeObjectsInImportOrder[i];
      code.resolveCalls(codes[i], _codeObjectsInImportOrder);
    }
    _codeObjectsInImportOrder.clear();
  }

  int _extractCodeStartAddress(Map code) {
    return int.parse(code['code']['start'], radix:16);
  }

  void _processCode(Map profileCode) {
    if (profileCode['type'] != 'ProfileCode') {
      return;
    }
    int address = _extractCodeStartAddress(profileCode);
    var code = isolate.findCodeByAddress(address);
    if (code == null) {
      // Never seen a code object at this address before, create a new one.
      code = new Code.fromProfileMap(profileCode);
      isolate.codes.add(code);
    }
    code._refresh(profileCode);
    _codeObjectsInImportOrder.add(code);
  }

  List<Code> topExclusive(int count) {
    List<Code> exclusive = isolate.codes;
    exclusive.sort((Code a, Code b) {
      return b.exclusiveTicks - a.exclusiveTicks;
    });
    if ((exclusive.length < count) || (count == 0)) {
      return exclusive;
    }
    return exclusive.sublist(0, count);
  }
}

class ScriptLine extends Observable {
  @observable final int line;
  @observable int hits = -1;
  @observable String text = '';
  /// Is this a line of executable code?
  bool get executable => hits >= 0;
  /// Has this line executed before?
  bool get covered => hits > 0;
  ScriptLine(this.line);
}

class Script extends Observable {
  @observable String kind = null;
  @observable Map scriptRef = toObservable({});
  @published String shortName;
  @observable Map libraryRef = toObservable({});
  @observable final List<ScriptLine> lines =
      toObservable(new List<ScriptLine>());
  bool _needsSource = true;
  bool get needsSource => _needsSource;
  Script.fromMap(Map map) {
    scriptRef = toObservable({
      'id': map['id'],
      'name': map['name'],
      'user_name': map['user_name']
    });
    shortName = map['name'].substring(map['name'].lastIndexOf('/') + 1);
    libraryRef = toObservable(map['library']);
    kind = map['kind'];
    _processSource(map['source']);
  }

  // Iterable of lines for display. Skips line '0'.
  @observable Iterable get linesForDisplay {
    return lines.skip(1);
  }

  // Fetch (possibly create) the ScriptLine for [lineNumber].
  ScriptLine _getLine(int lineNumber) {
    assert(lineNumber != 0);
    if (lineNumber >= lines.length) {
      // Grow lines list.
      lines.length = lineNumber + 1;
    }
    var line = lines[lineNumber];
    if (line == null) {
      // Create this line.
      line = new ScriptLine(lineNumber);
      lines[lineNumber] = line;
    }
    return line;
  }

  void _processSource(String source) {
    if (source == null) {
      return;
    }
    Logger.root.info('Loading source for ${scriptRef['name']}');
    var sourceLines = source.split('\n');
    _needsSource = sourceLines.length == 0;
    for (var i = 0; i < sourceLines.length; i++) {
      var line = _getLine(i + 1);
      line.text = sourceLines[i];
    }
  }

  void _processCoverageHits(List hits) {
    for (var i = 0; i < hits.length; i += 2) {
      var line = _getLine(hits[i]);
      line.hits = hits[i + 1];
    }
    notifyPropertyChange(#coveredPercentageFormatted, '',
                         coveredPercentageFormatted());
  }

  /// What percentage of lines in this script have been covered?
  @observable double coveredPercentage() {
    int coveredLines = 0;
    int executableLines = 0;
    for (var line in lines) {
      if (line == null) {
        continue;
      }
      if (!line.executable) {
        continue;
      }
      executableLines++;
      if (!line.covered) {
        continue;
      }
      coveredLines++;
    }
    if (executableLines == 0) {
      return 0.0;
    }
    return (coveredLines / executableLines) * 100.0;
  }

  @observable String coveredPercentageFormatted() {
    return '(' + coveredPercentage().toStringAsFixed(1) + '% covered)';
  }
}
