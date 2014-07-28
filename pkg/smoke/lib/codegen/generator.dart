// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Library to generate code that can initialize the `StaticConfiguration` in
/// `package:smoke/static.dart`.
///
/// This library doesn't have any specific logic to extract information from
/// Dart source code. To extract code using the analyzer, take a look at the
/// `smoke.codegen.recorder` library.
library smoke.codegen.generator;

import 'dart:collection' show SplayTreeMap, SplayTreeSet;

import 'package:smoke/src/common.dart' show compareLists, compareMaps;

/// Collects the necessary information and generates code to initialize a
/// `StaticConfiguration`. After setting up the generator by calling
/// [addGetter], [addSetter], [addSymbol], and [addDeclaration], you can
/// retrieve the generated code using the following three methods:
///
///   * [writeImports] writes a list of imports directives,
///   * [writeTopLevelDeclarations] writes additional declarations used to
///     represent mixin classes by name in the generated code.
///   * [writeStaticConfiguration] writes the actual code that allocates the
///     static configuration.
///
/// You'd need to include all three in your generated code, since the
/// initialization code refers to symbols that are only available from the
/// generated imports or the generated top-level declarations.
class SmokeCodeGenerator {
  // Note: we use SplayTreeSet/Map here and below to keep generated code sorted.
  /// Names used as getters via smoke.
  final Set<String> _getters = new SplayTreeSet();

  /// Names used as setters via smoke.
  final Set<String> _setters = new SplayTreeSet();

  /// Subclass relations needed to run smoke queries.
  final Map<TypeIdentifier, TypeIdentifier> _parents = new SplayTreeMap();

  /// Declarations requested via `smoke.getDeclaration or `smoke.query`.
  final Map<TypeIdentifier, Map<String, _DeclarationCode>> _declarations =
      new SplayTreeMap();

  /// Static methods used on each type.
  final Map<TypeIdentifier, Set<String>> _staticMethods = new SplayTreeMap();

  /// Names that are used both as strings and symbols.
  final Set<String> _names = new SplayTreeSet();

  /// Prefixes associated with imported libraries.
  final Map<String, String> _libraryPrefix = {};

  /// Register that [name] is used as a getter in the code.
  void addGetter(String name) { _getters.add(name); }

  /// Register that [name] is used as a setter in the code.
  void addSetter(String name) { _setters.add(name); }

  /// Register that [name] might be needed as a symbol.
  void addSymbol(String name) { _names.add(name); }

  /// Register that `cls.name` is used as a static method in the code.
  void addStaticMethod(TypeIdentifier cls, String name) {
    var methods = _staticMethods.putIfAbsent(cls,
        () => new SplayTreeSet<String>());
    _addLibrary(cls.importUrl);
    methods.add(name);
  }

  int _mixins = 0;

  /// Creates a new type to represent a mixin. Use [comment] to help users
  /// figure out what mixin is being represented.
  TypeIdentifier createMixinType([String comment = '']) =>
      new TypeIdentifier(null, '_M${_mixins++}', comment);

  /// Register that we care to know that [child] extends [parent].
  void addParent(TypeIdentifier child, TypeIdentifier parent) {
    var existing = _parents[child];
    if (existing != null) {
      if (existing == parent) return;
      throw new StateError('$child already has a different parent associated'
          '($existing instead of $parent)');
    }
    _addLibrary(child.importUrl);
    _addLibrary(parent.importUrl);
    _parents[child] = parent;
  }

  /// Register a declaration of a field, property, or method. Note that one and
  /// only one of [isField], [isMethod], or [isProperty] should be set at a
  /// given time.
  void addDeclaration(TypeIdentifier cls, String name, TypeIdentifier type,
      {bool isField: false, bool isProperty: false, bool isMethod: false,
      bool isFinal: false, bool isStatic: false,
      List<ConstExpression> annotations: const []}) {
    final count = (isField ? 1 : 0) + (isProperty ? 1 : 0) + (isMethod ? 1 : 0);
    if (count != 1) {
      throw new ArgumentError('Declaration must be one (and only one) of the '
          'following: a field, a property, or a method.');
    }
    var kind = isField ? 'FIELD' : isProperty ? 'PROPERTY' : 'METHOD';
    _declarations.putIfAbsent(cls,
        () => new SplayTreeMap<String, _DeclarationCode>());
    _addLibrary(cls.importUrl);
    var map = _declarations[cls];

    for (var exp in annotations) {
      for (var lib in exp.librariesUsed) {
        _addLibrary(lib);
      }
    }

    _addLibrary(type.importUrl);
    var decl = new _DeclarationCode(name, type, kind, isFinal, isStatic,
        annotations);
    if (map.containsKey(name) && map[name] != decl) {
      throw new StateError('$type.$name already has a different declaration'
          ' (${map[name]} instead of $decl).');
    }
    map[name] = decl;
  }

  /// Register that we might try to read declarations of [type], even if no
  /// declaration exists. This informs the smoke system that querying for a
  /// member in this class might be intentional and not an error.
  void addEmptyDeclaration(TypeIdentifier type) {
    _addLibrary(type.importUrl);
    _declarations.putIfAbsent(type,
        () => new SplayTreeMap<String, _DeclarationCode>());
  }

  /// Writes to [buffer] a line for each import that is needed by the generated
  /// code. The code added by [writeStaticConfiguration] depends on these
  /// imports.
  void writeImports(StringBuffer buffer) {
    DEFAULT_IMPORTS.forEach((i) => buffer.writeln(i));
    _libraryPrefix.forEach((url, prefix) {
      buffer.writeln("import '$url' as $prefix;");
    });
  }

  /// Writes to [buffer] top-level declarations that are used by the code
  /// generated in [writeStaticConfiguration]. These are typically declarations
  /// of empty classes that are then used as placeholders for mixin
  /// superclasses.
  void writeTopLevelDeclarations(StringBuffer buffer) {
    var types = new Set()
        ..addAll(_parents.keys)
        ..addAll(_parents.values)
        ..addAll(_declarations.keys)
        ..addAll(_declarations.values.expand(
              (m) => m.values.map((d) => d.type)))
        ..removeWhere((t) => t.importUrl != null);
    for (var type in types) {
      buffer.write('abstract class ${type.name} {}');
      if (type.comment != null) buffer.write(' // ${type.comment}');
      buffer.writeln();
    }
  }

  /// Appends to [buffer] code that will create smoke's static configuration.
  /// For example, the code might be of the form:
  ///
  ///    new StaticConfiguration(
  ///      getters: {
  ///         #i: (o) => o.i,
  ///         ...
  ///      names: {
  ///         #i: "i",
  ///      })
  ///
  /// Callers of this code can assign this expression to a variable, and should
  /// generate code that invokes `useGeneratedCode`.
  ///
  /// The optional [indent] argument is used for formatting purposes. All
  /// entries in each map (getters, setters, names, declarations, parents) are
  /// sorted alphabetically.
  ///
  /// **Note**: this code assumes that imports from [writeImports] and top-level
  /// declarations from [writeTopLevelDeclarations] are included in the same
  /// library where this code will live.
  void writeStaticConfiguration(StringBuffer buffer, [int indent = 2]) {
    final spaces = ' ' * (indent + 4);
    var args = {};

    if (_getters.isNotEmpty) {
      args['getters'] = _getters.map((n) => '${_symbol(n)}: (o) => o.$n');
    }
    if (_setters.isNotEmpty) {
      args['setters'] = _setters.map(
          (n) => '${_symbol(n)}: (o, v) { o.$n = v; }');
    }

    if (_parents.isNotEmpty) {
      var parentsMap = [];
      _parents.forEach((child, parent) {
        var parent = _parents[child];
        parentsMap.add('${child.asCode(_libraryPrefix)}: '
          '${parent.asCode(_libraryPrefix)}');
      });
      args['parents'] = parentsMap;
    }

    if (_declarations.isNotEmpty) {
      var declarations = [];
      _declarations.forEach((type, members) {
        final sb = new StringBuffer()
            ..write(type.asCode(_libraryPrefix))
            ..write(': ');
        if (members.isEmpty) {
          sb.write('{}');
        } else {
          sb.write('{\n');
          members.forEach((name, decl) {
            var decl = members[name].asCode(_libraryPrefix);
            sb.write('${spaces}    ${_symbol(name)}: $decl,\n');
          });
          sb.write('${spaces}  }');
        }
        declarations.add(sb.toString());
      });
      args['declarations'] = declarations;
    }

    if (_staticMethods.isNotEmpty) {
      var methods = [];
      _staticMethods.forEach((type, members) {
        var className = type.asCode(_libraryPrefix);
        final sb = new StringBuffer()
            ..write(className)
            ..write(': ');
        if (members.isEmpty) {
          sb.write('{}');
        } else {
          sb.write('{\n');
          for (var name in members) {
            sb.write('${spaces}    ${_symbol(name)}: $className.$name,\n');
          }
          sb.write('${spaces}  }');
        }
        methods.add(sb.toString());
      });
      args['staticMethods'] = methods;
    }

    if (_names.isNotEmpty) {
      args['names'] = _names.map((n) => "${_symbol(n)}: r'$n'");
    }

    buffer..writeln('new StaticConfiguration(')
        ..write('${spaces}checkedMode: false');

    args.forEach((name, mapContents) {
      buffer.writeln(',');
      // TODO(sigmund): use const map when Type can be keys (dartbug.com/17123)
      buffer.writeln('${spaces}$name: {');
      for (var entry in mapContents) {
        buffer.writeln('${spaces}  $entry,');
      }
      buffer.write('${spaces}}');
    });
    buffer.write(')');
  }

  /// Adds a library that needs to be imported.
  void _addLibrary(String url) {
    if (url == null || url == 'dart:core') return;
    _libraryPrefix.putIfAbsent(url, () => 'smoke_${_libraryPrefix.length}');
  }
}

/// Information used to generate code that allocates a `Declaration` object.
class _DeclarationCode extends ConstExpression {
  final String name;
  final TypeIdentifier type;
  final String kind;
  final bool isFinal;
  final bool isStatic;
  final List<ConstExpression> annotations;

  _DeclarationCode(this.name, this.type, this.kind, this.isFinal, this.isStatic,
      this.annotations);

  List<String> get librariesUsed => []
      ..addAll(type.librariesUsed)
      ..addAll(annotations.expand((a) => a.librariesUsed));

  String asCode(Map<String, String> libraryPrefixes) {
    var sb = new StringBuffer();
    sb.write('const Declaration(${_symbol(name)}, '
        '${type.asCode(libraryPrefixes)}');
    if (kind != 'FIELD') sb.write(', kind: $kind');
    if (isFinal) sb.write(', isFinal: true');
    if (isStatic) sb.write(', isStatic: true');
    if (annotations != null && annotations.isNotEmpty) {
      sb.write(', annotations: const [');
      bool first = true;
      for (var e in annotations) {
        if (!first) sb.write(', ');
        first = false;
        sb.write(e.asCode(libraryPrefixes));
      }
      sb.write(']');
    }
    sb.write(')');
    return sb.toString();
  }

  String toString() =>
      '(decl: $type.$name - $kind, $isFinal, $isStatic, $annotations)';
  operator== (other) => other is _DeclarationCode && name == other.name && 
      type == other.type && kind == other.kind && isFinal == other.isFinal &&
      isStatic == other.isStatic &&
      compareLists(annotations, other.annotations);
  int get hashCode => name.hashCode + (31 * type.hashCode);
}

/// A constant expression that can be used as an annotation.
abstract class ConstExpression {

  /// Returns the library URLs that needs to be imported for this
  /// [ConstExpression] to be a valid annotation.
  List<String> get librariesUsed;

  /// Return a string representation of the code in this expression.
  /// [libraryPrefixes] describes what prefix has been associated with each
  /// import url mentioned in [libraryUsed].
  String asCode(Map<String, String> libraryPrefixes);

  ConstExpression();

  /// Create a string expression of the form `'string'`, where [string] is
  /// normalized so we can correctly wrap it in single quotes.
  factory ConstExpression.string(String string) {
    var value = string.replaceAll(r'\', r'\\').replaceAll(r"'", r"\'");
    return new CodeAsConstExpression("'$value'");
  }

  /// Create an expression of the form `prefix.variable_name`.
  factory ConstExpression.identifier(String importUrl, String name) =>
      new TopLevelIdentifier(importUrl, name);

  /// Create an expression of the form `prefix.Constructor(v1, v2, p3: v3)`.
  factory ConstExpression.constructor(String importUrl, String name,
      List<ConstExpression> positionalArgs,
      Map<String, ConstExpression> namedArgs) =>
      new ConstructorExpression(importUrl, name, positionalArgs, namedArgs);
}

/// A constant expression written as a String. Used when the code is self
/// contained and it doesn't depend on any imported libraries.
class CodeAsConstExpression extends ConstExpression {
  String code;
  List<String> get librariesUsed => const [];

  CodeAsConstExpression(this.code);

  String asCode(Map<String, String> libraryPrefixes) => code;

  String toString() => '(code: $code)';
  operator== (other) => other is CodeAsConstExpression && code == other.code;
  int get hashCode => code.hashCode;
}

/// Describes a reference to some symbol that is exported from a library. This
/// is typically used to refer to a type or a top-level variable from that
/// library.
class TopLevelIdentifier extends ConstExpression {
  final String importUrl;
  final String name;
  TopLevelIdentifier(this.importUrl, this.name);

  List<String> get librariesUsed => [importUrl];
  String asCode(Map<String, String> libraryPrefixes) {
    if (importUrl == 'dart:core' || importUrl == null) return name;
    return '${libraryPrefixes[importUrl]}.$name';
  }

  String toString() => '(identifier: $importUrl, $name)';
  operator== (other) => other is TopLevelIdentifier && name == other.name
      && importUrl == other.importUrl;
  int get hashCode => 31 * importUrl.hashCode + name.hashCode;
}

/// Represents an expression that invokes a const constructor.
class ConstructorExpression extends ConstExpression {
  final String importUrl;
  final String name;
  final List<ConstExpression> positionalArgs;
  final Map<String, ConstExpression> namedArgs;
  ConstructorExpression(this.importUrl, this.name, this.positionalArgs,
      this.namedArgs);

  List<String> get librariesUsed => [importUrl]
      ..addAll(positionalArgs.expand((e) => e.librariesUsed))
      ..addAll(namedArgs.values.expand((e) => e.librariesUsed));

  String asCode(Map<String, String> libraryPrefixes) {
    var sb = new StringBuffer();
    sb.write('const ');
    if (importUrl != 'dart:core' && importUrl != null) {
      sb.write('${libraryPrefixes[importUrl]}.');
    }
    sb.write('$name(');
    bool first = true;
    for (var e in positionalArgs) {
      if (!first) sb.write(', ');
      first = false;
      sb.write(e.asCode(libraryPrefixes));
    }
    namedArgs.forEach((name, value) {
      if (!first) sb.write(', ');
      first = false;
      sb.write('$name: ');
      sb.write(value.asCode(libraryPrefixes));
    });
    sb.write(')');
    return sb.toString();
  }

  String toString() => '(ctor: $importUrl, $name, $positionalArgs, $namedArgs)';
  operator== (other) => other is ConstructorExpression && name == other.name
      && importUrl == other.importUrl &&
      compareLists(positionalArgs, other.positionalArgs) &&
      compareMaps(namedArgs, other.namedArgs);
  int get hashCode => 31 * importUrl.hashCode + name.hashCode;
}


/// Describes a type identifier, with the library URL where the type is defined.
// TODO(sigmund): consider adding support for imprecise TypeIdentifiers, which
// may be used by tools that want to generate code without using the analyzer
// (they can syntactically tell the type comes from one of N imports).
class TypeIdentifier extends TopLevelIdentifier
    implements Comparable<TypeIdentifier> {
  final String comment;
  TypeIdentifier(importUrl, typeName, [this.comment])
      : super(importUrl, typeName);

  // We implement [Comparable] to sort out entries in the generated code.
  int compareTo(TypeIdentifier other) {
    if (importUrl == null && other.importUrl != null) return 1;
    if (importUrl != null && other.importUrl == null) return -1;
    var c1 = importUrl == null ? 0 : importUrl.compareTo(other.importUrl);
    return c1 != 0 ? c1 : name.compareTo(other.name);
  }

  String toString() => '(type-identifier: $importUrl, $name, $comment)';
  bool operator ==(other) => other is TypeIdentifier &&
      importUrl == other.importUrl && name == other.name &&
      comment == other.comment;
  int get hashCode => super.hashCode;
}

/// Default set of imports added by [SmokeCodeGenerator].
const DEFAULT_IMPORTS = const [
    "import 'package:smoke/smoke.dart' show Declaration, PROPERTY, METHOD;",
    "import 'package:smoke/static.dart' show "
        "useGeneratedCode, StaticConfiguration;",
  ];

_symbol(String name) {
  if (!_publicSymbolPattern.hasMatch(name)) {
    throw new StateError('invalid symbol name: "$name"');
  }
  return _literalSymbolPattern.hasMatch(name)
      ? '#$name' : "const Symbol('$name')";
}

// TODO(sigmund): is this included in some library we can import? I derived the
// definitions below from sdk/lib/internal/symbol.dart.

/// Reserved words in Dart.
const String _reservedWordRE =
    r'(?:assert|break|c(?:a(?:se|tch)|lass|on(?:st|tinue))|d(?:efault|o)|'
    r'e(?:lse|num|xtends)|f(?:alse|inal(?:ly)?|or)|i[fns]|n(?:ew|ull)|'
    r'ret(?:hrow|urn)|s(?:uper|witch)|t(?:h(?:is|row)|r(?:ue|y))|'
    r'v(?:ar|oid)|w(?:hile|ith))';

/// Public identifier: a valid identifier (not a reserved word) that doesn't
/// start with '_'.
const String _publicIdentifierRE =
    r'(?!' '$_reservedWordRE' r'\b(?!\$))[a-zA-Z$][\w$]*';

/// Pattern that matches operators only.
final RegExp _literalSymbolPattern = new RegExp(
    '^(?:$_publicIdentifierRE(?:\$|[.](?!\$)))+?\$');

/// Operator names allowed as symbols. The name of the oeprators is the same as
/// the operator itself except for unary minus, where the name is "unary-".
const String _operatorRE =
    r'(?:[\-+*/%&|^]|\[\]=?|==|~/?|<[<=]?|>[>=]?|unary-)';

/// Pattern that matches public symbols.
final RegExp _publicSymbolPattern = new RegExp(
    '^(?:$_operatorRE\$|$_publicIdentifierRE(?:=?\$|[.](?!\$)))+?\$');
