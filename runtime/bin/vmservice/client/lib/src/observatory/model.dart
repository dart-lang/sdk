// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of observatory;

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
  final int ticks;
  CodeTick(this.address, this.ticks);
}

class Code extends Observable {
  final CodeKind kind;
  final int startAddress;
  final int endAddress;
  final List<CodeTick> ticks = [];
  int inclusiveTicks = 0;
  int exclusiveTicks = 0;
  @observable final List<CodeInstruction> instructions = toObservable([]);
  @observable Map functionRef = toObservable({});
  @observable Map codeRef = toObservable({});
  @observable String name;
  @observable String user_name;

  Code(this.kind, this.name, this.startAddress, this.endAddress);

  Code.fromMap(Map m) :
    kind = CodeKind.Dart,
    startAddress = int.parse(m['start'], radix:16),
    endAddress = int.parse(m['end'], radix:16) {
    functionRef = toObservable(m['function']);
    codeRef = {
      'type': '@Code',
      'id': m['id'],
      'name': m['name'],
      'user_name': m['user_name']
    };
    name = m['name'];
    user_name = m['user_name'];
    _loadInstructions(m['disassembly']);
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
  Profile.fromMap(this.isolate, Map m) {
    var codes = m['codes'];
    totalSamples = m['samples'];
    Logger.root.info('Creating profile from ${totalSamples} samples '
                     'and ${codes.length} code objects.');
    isolate.resetCodeTicks();
    codes.forEach((code) {
      try {
        _processCode(code);
      } catch (e, st) {
        Logger.root.warning('Error processing code object. $e $st', e, st);
      }
    });
  }
  int totalSamples = 0;

  Code _processDartCode(Map dartCode) {
    var codeObject = dartCode['code'];
    if ((codeObject == null)) {
      // Detached code objects are handled like 'other' code.
      return _processOtherCode(CodeKind.Dart, dartCode);
    }
    var code = new Code.fromMap(codeObject);
    return code;
  }

  Code _processOtherCode(CodeKind kind, Map otherCode) {
    var startAddress = int.parse(otherCode['start'], radix:16);
    var endAddress = int.parse(otherCode['end'], radix: 16);
    var name = otherCode['name'];
    assert(name != null);
    return new Code(kind, name, startAddress, endAddress);
  }

  void _processCode(Map profileCode) {
    if (profileCode['type'] != 'ProfileCode') {
      return;
    }
    var kind = CodeKind.fromString(profileCode['kind']);
    var address;
    if (kind == CodeKind.Dart) {
      if (profileCode['code'] != null) {
        address = int.parse(profileCode['code']['start'], radix:16);
      } else {
        address = int.parse(profileCode['start'], radix:16);
      }
    } else {
      address = int.parse(profileCode['start'], radix:16);
    }
    assert(address != null);
    var code = isolate.findCodeByAddress(address);
    if (code == null) {
      if (kind == CodeKind.Dart) {
        code = _processDartCode(profileCode);
      } else {
        code = _processOtherCode(kind, profileCode);
      }
      assert(code != null);
      isolate.codes.add(code);
    }
    // Load code object tick counts and set them.
    var inclusive = int.parse(profileCode['inclusive_ticks']);
    var exclusive = int.parse(profileCode['exclusive_ticks']);
    code.inclusiveTicks = inclusive;
    code.exclusiveTicks = exclusive;
    // Load address specific ticks.
    List ticksList = profileCode['ticks'];
    if (ticksList != null && (ticksList.length > 0)) {
      for (var i = 0; i < ticksList.length; i += 2) {
        var address = int.parse(ticksList[i], radix:16);
        var ticks = int.parse(ticksList[i + 1]);
        var codeTick = new CodeTick(address, ticks);
        code.ticks.add(codeTick);
      }
    }
    if ((code.ticks.length > 0) && (code.instructions.length > 0)) {
      // Apply address ticks to instruction stream.
      code.ticks.forEach((CodeTick tick) {
        code.tick(tick.address, tick.ticks);
      });
      code.instructions.forEach((i) {
        i.updateTickString(code);
      });
    }
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

  List<Code> topInclusive(int count) {
    List<Code> inclusive = isolate.codes;
    inclusive.sort((Code a, Code b) {
      return b.inclusiveTicks - a.inclusiveTicks;
    });
    if ((inclusive.length < count) || (count == 0)) {
      return inclusive;
    }
    return inclusive.sublist(0, count);
  }
}
