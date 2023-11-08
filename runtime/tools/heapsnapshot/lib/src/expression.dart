// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:math' as math;

import 'package:vm_service/vm_service.dart';

import 'analysis.dart';
import 'completion.dart';

abstract class SetExpression {
  IntSet? evaluate(NamedSets namedSets, Analysis analysis, Output output);
}

class FilterExpression extends SetExpression {
  final SetExpression expr;
  final List<String> patterns;

  FilterExpression(this.expr, this.patterns);

  IntSet? evaluate(NamedSets namedSets, Analysis analysis, Output output) {
    final oids = expr.evaluate(namedSets, analysis, output);
    if (oids == null) return null;

    final patterns = this
        .patterns
        .map((String pattern) {
          if (pattern == 'String') {
            return ['_OneByteString', '_TwoByteString'];
          } else if (pattern == 'List') {
            return ['_List', '_GrowableList', '_ImmutableList'];
          } else if (pattern == 'Map') {
            return ['_HashMap', '_Map', '_ConstMap'];
          } else if (pattern == 'Set') {
            return ['_HashSet', '_Set', '_ConstSet'];
          }
          return [pattern];
        })
        .expand((l) => l)
        .toList();

    return analysis.filterByClassPatterns(oids, patterns);
  }
}

class DFilterExpression extends SetExpression {
  final SetExpression expr;
  final List<String> patterns;

  DFilterExpression(this.expr, this.patterns);

  IntSet? evaluate(NamedSets namedSets, Analysis analysis, Output output) {
    final oids = expr.evaluate(namedSets, analysis, output);
    if (oids == null) return null;
    final predicates = patterns.map((String pattern) {
      final l = pattern.startsWith('<');
      final le = pattern.startsWith('<=');
      final e = pattern.startsWith('==');
      final ge = pattern.startsWith('>=');
      final g = pattern.startsWith('>');

      if (l || le || e || ge || g) {
        final value = pattern.substring((le || e || ge) ? 2 : 1);
        int limit = int.parse(value);

        if (l)
          return (o) {
            final len = analysis.variableLengthOf(o);
            return len != -1 && len < limit;
          };
        if (le)
          return (o) {
            final len = analysis.variableLengthOf(o);
            return len != -1 && len <= limit;
          };
        if (e)
          return (o) {
            final len = analysis.variableLengthOf(o);
            return len != -1 && len == limit;
          };
        if (ge)
          return (o) {
            final len = analysis.variableLengthOf(o);
            return len != -1 && len >= limit;
          };
        if (g)
          return (o) {
            final len = analysis.variableLengthOf(o);
            return len != -1 && len > limit;
          };
        throw 'unreachable';
      }

      if (pattern.startsWith('^')) {
        pattern = pattern.substring(1);
        final regexp = RegExp(pattern);
        return (HeapSnapshotObject object) {
          final data = object.data;
          if (data is String) {
            return !regexp.hasMatch(data);
          }
          return false;
        };
      }

      final regexp = RegExp(pattern);
      return (HeapSnapshotObject object) {
        final data = object.data;
        if (data is String) {
          return regexp.hasMatch(data);
        }
        return false;
      };
    }).toList();

    return analysis.filter(
        oids, (object) => !predicates.any((p) => !p(object)));
  }
}

class MinusExpression extends SetExpression {
  final SetExpression expr;
  final List<SetExpression> operands;

  MinusExpression(this.expr, this.operands);

  IntSet? evaluate(NamedSets namedSets, Analysis analysis, Output output) {
    final result = expr.evaluate(namedSets, analysis, output)?.toSet();
    if (result == null) return null;

    for (int i = 0; i < operands.length; ++i) {
      final oids = operands[i].evaluate(namedSets, analysis, output);
      if (oids == null) return null;
      result.removeAll(oids);
    }

    return result;
  }
}

class OrExpression extends SetExpression {
  final List<SetExpression> exprs;

  OrExpression(this.exprs);

  IntSet? evaluate(NamedSets namedSets, Analysis analysis, Output output) {
    final result = SpecializedIntSet(analysis.graph.objects.length);
    for (int i = 0; i < exprs.length; ++i) {
      final oids = exprs[i].evaluate(namedSets, analysis, output);
      if (oids == null) return null;
      result.addAll(oids);
    }
    return result;
  }
}

class AndExpression extends SetExpression {
  final SetExpression expr;
  final List<SetExpression> operands;

  AndExpression(this.expr, this.operands);

  IntSet? evaluate(NamedSets namedSets, Analysis analysis, Output output) {
    final nullableResult = expr.evaluate(namedSets, analysis, output)?.toSet();
    if (nullableResult == null) return null;

    IntSet result = nullableResult;
    for (int i = 0; i < operands.length; ++i) {
      final oids = operands[i].evaluate(namedSets, analysis, output);
      if (oids == null) return null;
      result = result.intersection(oids);
    }
    return result;
  }
}

class SampleExpression extends SetExpression {
  static final _random = math.Random();

  final SetExpression expr;
  final int count;

  SampleExpression(this.expr, this.count);

  IntSet? evaluate(NamedSets namedSets, Analysis analysis, Output output) {
    final oids = expr.evaluate(namedSets, analysis, output);
    if (oids == null) return null;

    if (oids.isEmpty) return oids;

    final result = IntSet();
    final l = oids.toList();
    while (result.length < count && result.length < oids.length) {
      result.add(l[_random.nextInt(oids.length)]);
    }

    return result;
  }
}

class ClosureExpression extends SetExpression {
  final SetExpression expr;
  final List<String> patterns;

  ClosureExpression(this.expr, this.patterns);

  IntSet? evaluate(NamedSets namedSets, Analysis analysis, Output output) {
    final roots = expr.evaluate(namedSets, analysis, output);
    if (roots == null) return null;

    final filter = analysis.parseTraverseFilter(patterns);
    if (filter == null &&
        roots.length == analysis.roots.length &&
        roots.intersection(analysis.roots).length == roots.length) {
      // The analysis needs to calculate the set of reachable objects
      // already, so we re-use it instead of computing it again.
      return analysis.reachableObjects;
    }
    return analysis.transitiveGraph(roots, filter);
  }
}

class UserClosureExpression extends SetExpression {
  final SetExpression expr;
  final List<String> patterns;

  UserClosureExpression(this.expr, this.patterns);

  IntSet? evaluate(NamedSets namedSets, Analysis analysis, Output output) {
    final roots = expr.evaluate(namedSets, analysis, output);
    if (roots == null) return null;

    final filter = analysis.parseTraverseFilter(patterns);
    return analysis.reverseTransitiveGraph(roots, filter);
  }
}

class FollowExpression extends SetExpression {
  final SetExpression objs;
  final List<String> patterns;

  FollowExpression(this.objs, this.patterns);

  IntSet? evaluate(NamedSets namedSets, Analysis analysis, Output output) {
    final oids = objs.evaluate(namedSets, analysis, output);
    if (oids == null) return null;

    return analysis.findReferences(oids, patterns);
  }
}

class UserFollowExpression extends SetExpression {
  final SetExpression objs;
  final List<String> patterns;

  UserFollowExpression(this.objs, this.patterns);

  IntSet? evaluate(NamedSets namedSets, Analysis analysis, Output output) {
    final oids = objs.evaluate(namedSets, analysis, output);
    if (oids == null) return null;

    return analysis.findUsers(oids, patterns);
  }
}

class NamedExpression extends SetExpression {
  final String name;

  NamedExpression(this.name);

  IntSet? evaluate(NamedSets namedSets, Analysis analysis, Output output) {
    final oids = namedSets.getSet(name);
    if (oids == null) {
      output.printError('"$name" does not refer to a command or named set.');
      return null;
    }
    return oids;
  }
}

class SetNameExpression extends SetExpression {
  final String name;
  final SetExpression expr;

  SetNameExpression(this.name, this.expr);

  IntSet? evaluate(NamedSets namedSets, Analysis analysis, Output output) {
    final oids = expr.evaluate(namedSets, analysis, output);
    if (oids == null) return null;

    namedSets.nameSet(oids, name);
    return oids;
  }
}

IntSet? parseAndEvaluate(
    NamedSets namedSets, Analysis analysis, String text, Output output) {
  final sexpr = parseExpression(text, output, namedSets.names.toSet());
  if (sexpr == null) return null;
  return sexpr.evaluate(namedSets, analysis, output);
}

SetExpression? parseExpression(
    String text, Output output, Set<String> namedSets) {
  const help = 'See `help eval` for available expression types and arguments.';

  final tokens = _TokenIterator(text);
  final sexpr = parse(tokens, output, namedSets);
  if (sexpr == null) {
    output.printError(help);
    return null;
  }
  if (tokens.moveNext()) {
    tokens.movePrev();
    output.printError(
        'Found unexpected "${tokens.remaining}" after ${sexpr.runtimeType}.');
    output.printError(help);
    return null;
  }
  return sexpr;
}

final Map<String, SetExpression? Function(_TokenIterator, Output, Set<String>)>
    parsingFunctions = {
  // Filtering expressions.
  'filter': (_TokenIterator tokens, Output output, Set<String> namedSets) {
    final s = parse(tokens, output, namedSets);
    if (s == null) return null;
    final patterns = _parsePatterns(tokens, output);
    return FilterExpression(s, patterns);
  },
  'dfilter': (_TokenIterator tokens, Output output, Set<String> namedSets) {
    final s = parse(tokens, output, namedSets);
    if (s == null) return null;
    final patterns = _parsePatterns(tokens, output);
    return DFilterExpression(s, patterns);
  },

  // Traversing expressions.
  'follow': (_TokenIterator tokens, Output output, Set<String> namedSets) {
    final objs = parse(tokens, output, namedSets);
    if (objs == null) return null;
    final patterns = _parsePatterns(tokens, output);
    return FollowExpression(objs, patterns);
  },
  'users': (_TokenIterator tokens, Output output, Set<String> namedSets) {
    final objs = parse(tokens, output, namedSets);
    if (objs == null) return null;
    final patterns = _parsePatterns(tokens, output);
    return UserFollowExpression(objs, patterns);
  },
  'closure': (_TokenIterator tokens, Output output, Set<String> namedSets) {
    final s = parse(tokens, output, namedSets);
    if (s == null) return null;
    final patterns = _parsePatterns(tokens, output);
    return ClosureExpression(s, patterns);
  },
  'uclosure': (_TokenIterator tokens, Output output, Set<String> namedSets) {
    final s = parse(tokens, output, namedSets);
    if (s == null) return null;
    final patterns = _parsePatterns(tokens, output);
    return UserClosureExpression(s, patterns);
  },

  // Set operations
  'minus': (_TokenIterator tokens, Output output, Set<String> namedSets) {
    final s = parse(tokens, output, namedSets);
    if (s == null) return null;
    final operands = _parseExpressions(tokens, output, namedSets);
    if (operands == null) return null;
    return MinusExpression(s, operands);
  },
  'or': (_TokenIterator tokens, Output output, Set<String> namedSets) {
    final operands = _parseExpressions(tokens, output, namedSets);
    if (operands == null) return null;
    return OrExpression(operands);
  },
  'and': (_TokenIterator tokens, Output output, Set<String> namedSets) {
    final s = parse(tokens, output, namedSets);
    if (s == null) return null;
    final operands = _parseExpressions(tokens, output, namedSets);
    if (operands == null) return null;
    return AndExpression(s, operands);
  },

  // Sample expression
  'sample': (_TokenIterator tokens, Output output, Set<String> namedSets) {
    final s = parse(tokens, output, namedSets);
    if (s == null) return null;

    int count = 1;
    if (tokens.moveNext()) {
      if (tokens.current == ')') {
        tokens.movePrev();
      } else {
        tokens.current;
        final value = int.tryParse(tokens.current);
        if (value == null) {
          output.printError(
              '"sample" expression expects integer as 2nd argument.');
          return null;
        }
        count = value;
      }
    }
    return SampleExpression(s, count);
  },

  // Sub-expression
  '(': (_TokenIterator tokens, Output output, Set<String> namedSets) {
    final expr = parse(tokens, output, namedSets);
    if (expr == null) return null;

    if (!tokens.moveNext()) {
      output.printError('Expected closing ")" after "${tokens._text}".');
      return null;
    }
    if (tokens.current != ')') {
      output.printError('Expected closing ")" but found "${tokens.current}".');
      tokens.movePrev();
      return null;
    }
    return expr;
  },
};

SetExpression? parse(
    _TokenIterator tokens, Output output, Set<String> namedSets) {
  if (!tokens.moveNext()) {
    output.printError('Reached end of input: expected expression');
    return null;
  }

  final current = tokens.current;
  final parserFun = parsingFunctions[current];
  if (parserFun != null) return parserFun(tokens, output, namedSets);

  if (current == ')') {
    output.printError('Unexpected ).');
    return null;
  }
  if (tokens.moveNext()) {
    if (tokens.current == '=') {
      final expr = parse(tokens, output, namedSets);
      if (expr == null) return null;
      return SetNameExpression(current, expr);
    }
    tokens.movePrev();
  }
  if (!namedSets.contains(current)) {
    output.printError('There is no set with name "$current". See `info`.');

    // We're at the end - it may be beneficial to suggest completion.
    if (tokens.isAtEnd && tokens._text.endsWith(current)) {
      final pc = PostfixCompleter(tokens._text);
      final candidate = pc.tryComplete(current, namedSets.toList()) ??
          pc.tryComplete(current, parsingFunctions.keys.toList());
      if (candidate != null) {
        output.suggestCompletion(candidate);
      }
    }

    return null;
  }
  return NamedExpression(current);
}

class _TokenIterator {
  final String _text;

  String? _current = null;
  int _index = 0;

  _TokenIterator(this._text);

  String get current => _current!;

  bool get isAtEnd => _index == _text.length;

  bool moveNextPattern() {
    _current = null;

    int start = _index;
    while (
        start < _text.length && _text.codeUnitAt(start) == ' '.codeUnitAt(0)) {
      start++;
    }
    if (start == _text.length) return false;

    int openCount = 0;
    int end = start;
    while (end < _text.length) {
      final char = _text.codeUnitAt(end);

      if (char == '('.codeUnitAt(0)) {
        openCount++;
        end++;
        continue;
      }
      if (char == ')'.codeUnitAt(0)) {
        openCount--;
        if (openCount >= 0) {
          end++;
          continue;
        }
        // This ) has no corresponding (.
        if (start == end) return false;
        _current = _text.substring(start, end);
        _index = end;
        return true;
      }
      if (char == ' '.codeUnitAt(0)) {
        _current = _text.substring(start, end);
        _index = end;
        return true;
      }

      end++;
    }

    _current = _text.substring(start, end);
    _index = end;
    return true;
  }

  bool moveNext() {
    int start = _index;
    while (
        start < _text.length && _text.codeUnitAt(start) == ' '.codeUnitAt(0)) {
      start++;
    }
    if (start == _text.length) return false;

    int end = start + 1;

    final firstChar = _text.codeUnitAt(start);
    if (firstChar == '('.codeUnitAt(0) || firstChar == ')'.codeUnitAt(0)) {
      _current = _text.substring(start, end);
      _index = end;
      return true;
    }
    if (firstChar == '=') {
      _current = _text.substring(start, end);
      _index = end;
      return true;
    }

    while (end < _text.length && _text.codeUnitAt(end) != ' '.codeUnitAt(0)) {
      final char = _text.codeUnitAt(end);
      if (char == '('.codeUnitAt(0) || char == ')'.codeUnitAt(0)) {
        _current = _text.substring(start, end);
        _index = end;
        return true;
      }
      if (char == '=') {
        _current = _text.substring(start, end);
        _index = end;
        return true;
      }
      end++;
    }

    _current = _text.substring(start, end);
    _index = end;
    return true;
  }

  void movePrev() {
    _index -= current.length;
    _current = null;
  }

  String? peek() {
    if (!moveNext()) return null;
    final peek = current;
    movePrev();
    return peek;
  }

  String get remaining => _text.substring(_index);
}

List<SetExpression>? _parseExpressions(
    _TokenIterator tokens, Output output, Set<String> namedSets) {
  final all = <SetExpression>[];

  while (true) {
    final peek = tokens.peek();
    if (peek == null || peek == ')') break;
    final e = parse(tokens, output, namedSets);
    if (e == null) return null;
    all.add(e);
  }
  return all;
}

List<String> _parsePatterns(_TokenIterator tokens, Output output) {
  final patterns = <String>[];
  while (tokens.moveNextPattern()) {
    if (tokens.current == ')') {
      tokens.movePrev();
    }
    patterns.add(tokens.current);
  }
  return patterns;
}

class NamedSets {
  final Map<String, IntSet> _namedSets = {};
  int _varIndex = 0;

  List<String> get names => _namedSets.keys.toList();

  String nameSet(IntSet oids, [String? id]) {
    id ??= _generateName();
    _namedSets[id] = oids;
    return id;
  }

  IntSet? getSet(String name) => _namedSets[name];

  bool hasSetName(String name) => _namedSets.containsKey(name);

  void clear(String name) {
    _namedSets.remove(name);
  }

  void clearWhere(bool Function(String) cond) {
    _namedSets.removeWhere((name, _) => cond(name));
  }

  void forEach(void Function(String, IntSet) fun) {
    _namedSets.forEach(fun);
  }

  String _generateName() => '\$${_varIndex++}';
}

abstract class Output {
  void print(String message) {}
  void printError(String message) {}
  void suggestCompletion(String text) {}
}

const dslDescription = '''
An `<expr>` can be

Filtering a set of objects based on class/field or data:

  filter   <expr> $dslFilter
  dfilter  <expr> [{<,<=,==,>=,>}NUM]* [content-pattern]*

Traversing to references or uses of the set of objects:

  follow   <expr> $dslFilter
  users    <expr> $dslFilter
  closure  <expr> $dslFilter
  uclosure <expr> $dslFilter

Performing a set operation on multiple sets:

  or   <expr>*
  and  <expr>*
  sub  <expr> <expr>*

Sample a random element from a set:

  sample <expr> <num>?

Name a set of objects or retrieve the objects for a given name:

  <name>
  <name> = <expr>
''';

const dslFilter = '[class-pattern]* [class-pattern:field-pattern]*';
