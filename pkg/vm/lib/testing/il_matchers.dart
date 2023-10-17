// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// A library to facilitate programmatic matching against flow graphs
/// collected during IL tests. See runtime/docs/infra/il_tests.md for more
/// info.
library;

import 'dart:io';

typedef Renamer = String Function(String);

/// Flow graph parsed from --print-flow-graph-as-json output.
class FlowGraph {
  final List<dynamic> blocks;
  final Map<String, InstructionDescriptor> descriptors;
  final Map<String, dynamic> flags;
  final Renamer rename;

  FlowGraph(this.blocks, Map<String, dynamic> desc, this.flags,
      {required this.rename})
      : descriptors = {
          for (var e in desc.entries)
            e.key: InstructionDescriptor.fromJson(e.value)
        };

  bool get soundNullSafety => flags['nnbd'];

  /// Match the sequence of blocks in this flow graph against the given
  /// sequence of matchers: `expected[i]` is expected to match `blocks[i]`,
  /// but there can be more blocks in the graph than matchers (the suffix is
  /// ignored).
  ///
  /// If [env] is provided it will be used as matching environment, otherwise
  /// a fresh instance of [Env] will be created and used.
  ///
  /// This function returns the populated matching environment.
  Env match(List<Matcher> expected, {Env? env}) {
    env ??= Env(rename: rename, descriptors: descriptors);

    for (var i = 0; i < expected.length; i++) {
      final result = expected[i].match(env, blocks[i]);
      if (result.isFail) {
        print('Failed to match: ${result.message}');
        dump();
        throw 'Failed to match';
      }
    }

    if (env.unboundNames.isNotEmpty) {
      throw 'Some names left unbound: ${env.unboundNames}';
    }

    return env;
  }

  Map<String, dynamic>? attributesFor(Map<String, dynamic> instr) {
    final attrs = descriptors[instr['o']]?.attributeIndex;
    if (attrs == null) return null;
    return {for (final e in attrs.entries) e.key: instr['d'][e.value]};
  }

  void _formatAttributes(
      StringBuffer buffer, Map<String, int> attributeIndex, List attributes) {
    bool addSeparator = false;
    for (final e in attributeIndex.entries) {
      final value = attributes[e.value];
      // Skip printing attributes with value false.
      if (value is bool && !value) continue;
      if (addSeparator) {
        buffer..write(', ');
      }
      buffer.write(e.key);
      if (value is! bool) {
        buffer
          ..write(': ')
          ..write(value);
      }
      addSeparator = true;
    }
  }

  void _formatInternal(StringBuffer buffer, Map<String, dynamic> instr) {
    buffer.write(instr['o']);
    final attrs = descriptors[instr['o']]?.attributeIndex;
    if (attrs != null) {
      buffer.write('[');
      _formatAttributes(buffer, attrs, instr['d']);
      buffer.write(']');
    }
    final condition = instr['cc'];
    if (condition != null) {
      buffer.write(' if ');
      _formatInternal(buffer, condition);
      buffer.write(' then');
    } else {
      final inputs = instr['i']?.map((v) => 'v$v') ?? [];
      buffer
        ..write('(')
        ..writeAll(inputs, ', ')
        ..write(')');
    }
    if (instr['s'] != null) {
      buffer
        ..write(' goto ')
        ..write(instr['s']);
    }
  }

  void formatInstruction(StringBuffer buffer, Map<String, dynamic> instr) {
    if (instr['v'] != null) {
      buffer
        ..write('v')
        ..write(instr['v'])
        ..write(' <- ');
    }
    _formatInternal(buffer, instr);
  }

  void _formatBlock(StringBuffer buffer, Map<String, dynamic> block) {
    buffer
      ..write(blockName(block))
      ..write('[')
      ..write(block['o'])
      ..write(']');
    final defs = block['d'] ?? [];
    if (defs.isNotEmpty) {
      buffer.writeln(' {');
      for (final instr in defs) {
        buffer.write('  ');
        formatInstruction(buffer, instr);
        buffer.writeln();
      }
      buffer.write('}');
    }
    buffer.writeln();
    for (final instr in block['is'] ?? []) {
      buffer.write('  ');
      formatInstruction(buffer, instr);
      buffer.writeln();
    }
  }

  String blockName(Map<String, dynamic> block) => 'B${block['b']}';

  void dump() {
    final buffer = StringBuffer();
    for (var block in blocks) {
      _formatBlock(buffer, block);
    }
    print(buffer);
  }
}

class InstructionDescriptor {
  final List<String> attributes;
  final Map<String, int> attributeIndex;

  InstructionDescriptor.fromJson(List attrs) : this._(attrs.cast<String>());

  InstructionDescriptor._(List<String> attrs)
      : attributes = attrs,
        attributeIndex = {for (var i = 0; i < attrs.length; i++) attrs[i]: i};
}

/// Matching environment.
///
/// This is fundamentally just a name to id mapping which allows to track
/// correspondence between names given to some matchers and blocks/instructions
/// which matched those matchers.
///
/// This object is also used to carry around auxiliary information which might
/// be needed for matching, e.g. [Renamer].
class Env {
  final Map<String, InstructionDescriptor> descriptors;
  final Renamer rename;
  final Map<String, int> nameToId = {};
  final Set<String> unboundNames = {};

  Env({required this.rename, required this.descriptors});

  void bind(String name, Map<String, dynamic> instrOrBlock) {
    final id = instrOrBlock['v'] ?? instrOrBlock['b'];

    if (id == null) {
      throw 'Instruction is not a definition or a block: ${instrOrBlock['o']}';
    }

    if (nameToId.containsKey(name)) {
      if (nameToId[name] != id) {
        throw 'Binding mismatch for $name: got ${nameToId[name]} and $id';
      }
      unboundNames.remove(name);
      return;
    }

    nameToId[name] = id;
  }
}

abstract class Matcher {
  /// Try matching this matcher against the given value. Returns
  /// [MatchStatus.matched] if match succeeded and an instance of
  /// [MatchStatus.fail] otherwise.
  MatchStatus match(Env e, dynamic v);
}

class MatchStatus {
  final String? message;

  const MatchStatus._matched() : message = null;
  const MatchStatus.fail(String message) : message = message;

  bool get isMatch => message == null;
  bool get isFail => message != null;

  static const MatchStatus matched = MatchStatus._matched();

  void expectMatched(String s) {
    if (message != null) {
      throw 'Failed to match: $message';
    }
  }
}

/// Matcher which always succeeds.
class _AnyMatcher implements Matcher {
  const _AnyMatcher();

  @override
  MatchStatus match(Env e, v) => MatchStatus.matched;

  @override
  String toString() {
    return '*';
  }
}

/// Matcher which updates matching environment when it succeeds.
class _BoundMatcher implements Matcher {
  final String name;
  final Matcher nested;

  _BoundMatcher(this.name, this.nested);

  @override
  MatchStatus match(Env e, dynamic v) {
    final result = nested.match(e, v);
    if (result.isMatch) {
      e.bind(name, v);
    }
    return result;
  }

  @override
  String toString() {
    return '$name <- $nested';
  }
}

/// Matcher which matches a specified value [v].
class _EqualsMatcher implements Matcher {
  final dynamic expected;

  _EqualsMatcher(this.expected);

  @override
  MatchStatus match(Env e, got) {
    if (expected == got) {
      return MatchStatus.matched;
    }

    // Some instructions refer to obfuscated names, try to rename
    // the expectation and try again. For strings of form "Instance of C"
    // apply renaming to class name part only.
    if (expected is String && got is String) {
      const instanceOfPrefix = "Instance of ";

      final String renamed;
      if (expected.startsWith(instanceOfPrefix)) {
        final className = expected.substring(instanceOfPrefix.length);
        renamed = instanceOfPrefix + e.rename(className);
      } else {
        renamed = e.rename(expected);
      }

      if (renamed == got) {
        return MatchStatus.matched;
      }
    }

    return MatchStatus.fail('expected $expected got $got');
  }

  @override
  String toString() => '$expected';
}

/// Matcher which matches the value which is equivalent to the binding
/// with the given [name] in the matching environment.
///
/// If this matcher is [binding] then it will populate the binding in the
/// matching environment if the [name] is not bound yet on the first call
/// to [match]. Otherwise if the [name] is not bound when [match] is called
/// an exception will be thrown.
///
/// Binding matchers are used when we might see the use of a value before its
/// definition (e.g. we usually use the name of the block in the `Goto` or
/// `Branch` before we see the block itself).
class _RefMatcher implements Matcher {
  final String name;
  final bool binding;

  _RefMatcher(this.name, {this.binding = false});

  @override
  MatchStatus match(Env e, v) {
    if (e.nameToId.containsKey(name)) {
      return e.nameToId[name] == v
          ? MatchStatus.matched
          : MatchStatus.fail(
              'expected $name to bind to ${e.nameToId[name]} but got $v');
    }

    if (!binding) {
      throw UnimplementedError('Unbound reference to ${name}');
    }

    e.unboundNames.add(name);
    e.nameToId[name] = v;
    return MatchStatus.matched;
  }

  @override
  String toString() {
    return name;
  }
}

/// A wrapper which matches a list of matchers against a list of values.
class _ListMatcher implements Matcher {
  final List<Matcher> expected;

  _ListMatcher(this.expected);

  @override
  MatchStatus match(Env e, dynamic got) {
    if (got is! List) {
      return MatchStatus.fail('expected List, got ${got.runtimeType}');
    }

    if (expected.length > got.length) {
      return MatchStatus.fail(
          'expected at least ${expected.length} elements got ${got.length}');
    }

    for (var i = 0; i < expected.length; i++) {
      final result = expected[i].match(e, got[i]);
      if (result.isFail) {
        return MatchStatus.fail(
            'mismatch at index ${i}, expected ${expected[i]} '
            'got ${got[i]}: ${result.message}');
      }
    }

    if (expected.last is _AnyMatcher || expected.length == got.length) {
      return MatchStatus.matched;
    }

    return MatchStatus.fail(
        'expected exactly ${expected.length} elements got ${got.length}');
  }

  @override
  String toString() => '[${expected.join(',')}]';
}

/// A matcher which matches a block of the specified [kind] and contents.
///
/// Contents are specified as a sequence of matchers ([body]). For each of
/// those matchers a matching block is expected to contain at least one
/// instruction that matches it. Matching is done in order: first we scan
/// the block until we find the match for the first matcher in body, then
/// we continue scanning until we find the match for the second and so on.
class _BlockMatcher implements Matcher {
  final String kind;
  final List<Matcher> body;

  _BlockMatcher(this.kind, [this.body = const []]);

  @override
  MatchStatus match(Env e, covariant Map<String, dynamic> block) {
    if (block['o'] != '${kind}Entry') {
      return MatchStatus.fail(
          'Expected block of kind ${kind} got ${block['o']} '
          'when matching B${block['b']}');
    }

    final gotBody = [...?block['d'], ...?block['is']];

    var matcherIndex = 0;
    for (int i = 0; i < gotBody.length && matcherIndex < body.length; i++) {
      if (body[matcherIndex].match(e, gotBody[i]).isMatch) {
        matcherIndex++;
      }
    }
    if (matcherIndex != body.length) {
      return MatchStatus.fail('Unmatched instruction: ${body[matcherIndex]} '
          'in block B${block['b']}');
    }
    return MatchStatus.matched;
  }
}

/// A matcher for instruction's named attributes.
///
/// Attributes are resolved to their indices through [Env.descriptors].
class _AttributesMatcher implements Matcher {
  final String op;
  final Map<String, Matcher> matchers;

  _ListMatcher? impl;

  _AttributesMatcher(this.op, this.matchers);

  @override
  MatchStatus match(Env e, dynamic v) {
    impl ??= _ListMatcher(e.descriptors[op]!.attributes
        .map((name) => matchers[name] ?? const _AnyMatcher())
        .toList());
    return impl!.match(e, v);
  }

  @override
  String toString() {
    return matchers.toString();
  }
}

/// Matcher which matches an instruction with opcode [op] and properties
/// specified in [matchers] map.
class InstructionMatcher implements Matcher {
  final String op;
  final Map<String, Matcher> matchers;

  InstructionMatcher(
      {required String op, List<Matcher>? data, List<Matcher>? inputs})
      : this._(op: op, matchers: {
          if (data != null) 'd': _ListMatcher(data),
          if (inputs != null) 'i': _ListMatcher(inputs),
        });

  InstructionMatcher._({
    required this.op,
    required this.matchers,
  });

  @override
  MatchStatus match(Env e, covariant Map<String, dynamic> instr) {
    if (instr['o'] != op) {
      return MatchStatus.fail('expected instruction ${op} got ${instr['o']}');
    }

    for (var entry in matchers.entries) {
      final result = entry.value.match(e, instr[entry.key]);
      if (result.isFail) {
        return result;
      }
    }

    return MatchStatus.matched;
  }

  @override
  String toString() {
    return '$op($matchers)';
  }
}

/// This class uses `noSuchMethod` to allow writing code like
///
/// ```
/// match.Op(in0, ..., inN, attr0: a0, ..., attrK: aK)
/// ```
///
/// This will produce an instruction matcher which matches opcode `Op` and
/// expects `in0, ..., inN` to match instructions inputs, while `a0, ...`
/// matchers are expected to match attributes with names `attr0, ...`.
class Matchers {
  _BlockMatcher block(String kind, [List<dynamic> body = const []]) {
    return _BlockMatcher(kind, List<Matcher>.from(body));
  }

  final _AnyMatcher any = const _AnyMatcher();

  // ignore: non_constant_identifier_names
  InstructionMatcher Goto(String dest) =>
      InstructionMatcher._(op: 'Goto', matchers: {
        's': _ListMatcher([_blockRef(dest)])
      });

  // ignore: non_constant_identifier_names
  InstructionMatcher Branch(InstructionMatcher compare,
          {String? ifTrue, String? ifFalse}) =>
      InstructionMatcher._(op: 'Branch', matchers: {
        'cc': compare,
        's': _ListMatcher([
          ifTrue != null ? _blockRef(ifTrue) : any,
          ifFalse != null ? _blockRef(ifFalse) : any,
        ]),
      });

  @override
  Object? noSuchMethod(Invocation invocation) {
    final data = {
      for (var e in invocation.namedArguments.entries)
        getName(e.key): Matchers._toAttributeMatcher(e.value),
    };
    final op = getName(invocation.memberName);
    final binding = op == 'Phi'; // Allow Phis to have undeclared arguments.
    final inputs = invocation.positionalArguments
        .map((v) => Matchers._toInputMatcher(v, binding: binding))
        .toList();
    return InstructionMatcher._(op: op, matchers: {
      if (data.isNotEmpty) 'd': _AttributesMatcher(op, data),
      if (inputs.isNotEmpty) 'i': _ListMatcher(inputs),
    });
  }

  static Matcher _blockRef(String name) => _RefMatcher(name, binding: true);

  static Matcher _toAttributeMatcher(dynamic v) {
    if (v is Matcher) {
      return v;
    } else {
      return _EqualsMatcher(v);
    }
  }

  static Matcher _toInputMatcher(dynamic v, {bool binding = false}) {
    if (v is Matcher) {
      return v;
    } else if (v is String) {
      return _RefMatcher(v, binding: binding);
    } else {
      throw ArgumentError.value(
          v, 'v', 'Expected either a Matcher or a String (binding name)');
    }
  }
}

/// Extension which enables `'name' << matcher` syntax for creating bound
/// matchers.
extension BindingExtension on String {
  Matcher operator <<(Matcher matcher) {
    return _BoundMatcher(this, matcher);
  }
}

final dynamic match = Matchers();

/// This file should not depend on dart:mirrors because it is imported into
/// tests, which are compiled in AOT mode. So instead we let compare_il driver
/// set this field.
late String Function(Symbol) getName;

const testRunnerKey = 'test_runner.configuration';

final bool isSimulator = (() {
  if (bool.hasEnvironment(testRunnerKey)) {
    const config = String.fromEnvironment(testRunnerKey);
    return config.contains('-sim');
  }
  final runtimeConfiguration = Platform.environment['DART_CONFIGURATION'];
  if (runtimeConfiguration == null) {
    throw 'Expected DART_CONFIGURATION to be defined';
  }
  return runtimeConfiguration.contains('SIM');
})();

final bool is32BitConfiguration = (() {
  if (bool.hasEnvironment(testRunnerKey)) {
    const config = String.fromEnvironment(testRunnerKey);
    // No IA32 as AOT mode is unsupported there.
    return config.endsWith('arm') ||
        config.endsWith('arm_x64') ||
        config.endsWith('riscv32');
  }
  final runtimeConfiguration = Platform.environment['DART_CONFIGURATION'];
  if (runtimeConfiguration == null) {
    throw 'Expected DART_CONFIGURATION to be defined';
  }
  // No IA32 as AOT mode is unsupported there.
  return runtimeConfiguration.endsWith('ARM') ||
      runtimeConfiguration.endsWith('ARM_X64') ||
      runtimeConfiguration.endsWith('RISCV32');
})();
