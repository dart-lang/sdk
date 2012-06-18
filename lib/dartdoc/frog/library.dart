// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class LibraryImport {
  final String prefix;
  final Library library;
  final SourceSpan span;
  LibraryImport(this.library, [this.prefix, this.span]);
}

// TODO(jimhug): Make this more useful for good error messages.
class AmbiguousMember extends Member {
  List<Member> members;
  AmbiguousMember(String name, this.members): super(name, null);
}


/** Represents a Dart library. */
class Library extends Element {
  final SourceFile baseSource;
  Map<String, DefinedType> types;
  List<LibraryImport> imports;
  String sourceDir;
  List<SourceFile> natives;
  List<SourceFile> sources;

  Map<String, Member> _topNames;
  Map<String, MemberSet> _privateMembers;

  /** The type that holds top level types in the library. */
  DefinedType topType;

  /** Set to true by [WorldGenerator] once this type has been written. */
  bool isWritten = false;

  Library(this.baseSource) : super(null, null) {
    sourceDir = dirname(baseSource.filename);
    topType = new DefinedType(null, this, null, true);
    types = { '': topType };
    imports = [];
    natives = [];
    sources = [];
    _privateMembers = {};
  }

  Element get enclosingElement() => null;
  Library get library() => this;

  bool get isNative() => topType.isNative;

  bool get isCore() => this == world.corelib;
  bool get isCoreImpl() => this == world.coreimpl;

  // TODO(jmesserly): we shouldn't be special casing DOM anywhere.
  bool get isDomOrHtml() => this == world.dom || this == world.html;

  SourceSpan get span() => new SourceSpan(baseSource, 0, 0);

  String makeFullPath(String filename) {
    if (filename.startsWith('dart:')) return filename;
    if (filename.startsWith('package:')) return filename;
    // TODO(jmesserly): replace with node.js path.resolve
    if (filename.startsWith('/')) return filename;
    if (filename.startsWith('file:///')) return filename;
    if (filename.startsWith('http://')) return filename;
    if (const RegExp('^[a-zA-Z]:/').hasMatch(filename)) return filename;
    return joinPaths(sourceDir, filename);
  }

  /** Adds an import to the library. */
  addImport(String fullname, String prefix, SourceSpan span) {
    var newLib = world.getOrAddLibrary(fullname);
    // Special exemption in spec to ensure core is only imported once
    if (newLib.isCore) return;
    imports.add(new LibraryImport(newLib, prefix, span));
    return newLib;
  }

  addNative(String fullname) {
    natives.add(world.reader.readFile(fullname));
  }

  MemberSet _findMembers(String name) {
    if (name.startsWith('_')) {
      return _privateMembers[name];
    } else {
      return world._members[name];
    }
  }

  _addMember(Member member) {
    if (member.isPrivate) {
      if (member.isStatic) {
        if (member.declaringType.isTop) {
          world._addTopName(member);
        }
      } else {
        var members = _privateMembers[member.name];
        if (members == null) {
          members = new MemberSet(member, isVar: true);
          _privateMembers[member.name] = members;
        } else {
          members.add(member);
        }
      }
    } else {
      world._addMember(member);
    }
  }

  // TODO(jimhug): Cache and share the types as interfaces!
  Type getOrAddFunctionType(Element enclosingElement, String name,
      FunctionDefinition func, MethodData data) {
    // TODO(jimhug): This is redundant now that FunctionDef has type params.
    final def = new FunctionTypeDefinition(func, null, func.span);
    final type = new DefinedType(name, this, def, false);
    type.addMethod(':call', func);
    var m = type.members[':call'];
    m.enclosingElement = enclosingElement;
    m.resolve();
    m._methodData = data;
    // Function types implement the Function interface.
    type.interfaces = [world.functionType];
    return type;
  }

  /** Adds a type to the library. */
  DefinedType addType(String name, Node definition, bool isClass) {
    if (types.containsKey(name)) {
      var existingType = types[name];
      if ((isCore || isCoreImpl) && existingType.definition == null) {
        // TODO(jimhug): Validate compatibility with natives.
        existingType.setDefinition(definition);
      } else {
        world.warning('duplicate definition of $name', definition.span,
            existingType.span);
      }
    } else {
      types[name] = new DefinedType(name, this, definition, isClass);
    }

    return types[name];
  }

  Type findType(NameTypeReference type) {
    Type result = findTypeByName(type.name.name);
    if (result == null) return null;

    if (type.names != null) {
      if (type.names.length > 1) {
        // TODO(jmesserly): can we ever get legitimate types with more than one
        // name after the library prefix?
        return null;
      }

      if (!result.isTop) {
        // No inner type support. If we get first-class types, this should
        // perform a lookup on the type.
        return null;
      }

      // The type we got back was the "top level" library type.
      // Now perform a lookup in that library for the next name.
      return result.library.findTypeByName(type.names[0].name);
    }
    return result;
  }

  // TODO(jimhug): Should be merged with new lookup method's logic.
  Type findTypeByName(String name) {
    var ret = types[name];

    // Check all imports even if ret != null to detect conflicting names.
    // TODO(jimhug): Only do this on first lookup.
    for (var imported in imports) {
      var newRet = null;
      if (imported.prefix == null) {
        newRet = imported.library.types[name];
      } else if (imported.prefix == name) {
        newRet = imported.library.topType;
      }
      if (newRet != null) {
        // TODO(jimhug): Should not need ret != newRet here or below.
        if (ret != null  && ret != newRet) {
          world.error('conflicting types for "$name"', ret.span, newRet.span);
        } else {
          ret = newRet;
        }
      }
    }
    return ret;
  }


  // TODO(jimhug): Why is it okay to assume node is NameTypeReference in here?
  Type resolveType(TypeReference node, bool typeErrors, bool allowTypeParams) {
    if (node == null) return world.varType;

    var ret = findType(node);

    if (ret == null) {
      var message = 'cannot find type ${_getDottedName(node)}';
      if (typeErrors) {
        world.error(message, node.span);
        return world.objectType;
      } else {
        world.warning(message, node.span);
        return world.varType;
      }
    }
    return ret;
  }

  static String _getDottedName(NameTypeReference type) {
    if (type.names != null) {
      var names = map(type.names, (n) => n.name);
      return '${type.name.name}.${Strings.join(names, ".")}';
    } else {
      return type.name.name;
    }
  }

  Member lookup(String name, SourceSpan span) {
    return _topNames[name];
  }

  resolve() {
    if (name == null) {
      // TODO(jimhug): More fodder for io library.
      name = baseSource.filename;
      var index = name.lastIndexOf('/', name.length);
      if (index >= 0) {
        name = name.substring(index+1);
      }
      index = name.indexOf('.');
      if (index > 0) {
        name = name.substring(0, index);
      }
    }
    // TODO(jimhug): Expand to handle all illegal id characters
    _jsname =
      name.replaceAll('.', '_').replaceAll(':', '_').replaceAll(' ', '_');

    for (var type in types.getValues()) {
      type.resolve();
    }
  }

  _addTopName(String name, Member member, [SourceSpan localSpan]) {
    var existing = _topNames[name];
    if (existing === null) {
      _topNames[name] = member;
    } else {
      if (existing is AmbiguousMember) {
        existing.members.add(member);
      } else {
        var newMember = new AmbiguousMember(name, [existing, member]);
        world.error('conflicting members for "$name"',
          existing.span, member.span, localSpan);
          _topNames[name] = newMember;
      }
    }
  }

  _addTopNames(Library lib) {
    for (var member in lib.topType.members.getValues()) {
      if (member.isPrivate && lib != this) continue;
      _addTopName(member.name, member);
    }
    for (var type in lib.types.getValues()) {
      if (!type.isTop) {
        if (lib != this && type.typeMember.isPrivate) continue;
        _addTopName(type.name, type.typeMember);
      }
    }
  }

  /**
   * This method will check for any conflicts in top-level names in this
   * library.  It will also build up a map from top-level names to a single
   * member to be used for future lookups both to keep error messages clean
   * and as a minor perf optimization.
   */
  postResolveChecks() {
    _topNames = {};
    // check for conflicts between top-level names
    _addTopNames(this);
    for (var imported in imports) {
      if (imported.prefix == null) {
        _addTopNames(imported.library);
      } else {
        _addTopName(imported.prefix, imported.library.topType.typeMember,
            imported.span);
      }
    }
  }

  visitSources() {
    var visitor = new _LibraryVisitor(this);
    visitor.addSource(baseSource);
  }

  toString() => baseSource.filename;

  int hashCode() => baseSource.filename.hashCode();

  bool operator ==(other) => other is Library &&
    other.baseSource.filename == baseSource.filename;
}


class _LibraryVisitor implements TreeVisitor {
  final Library library;
  DefinedType currentType;
  List<SourceFile> sources;

  bool seenImport = false;
  bool seenSource = false;
  bool seenResource = false;
  bool isTop = true;

  _LibraryVisitor(this.library) {
    currentType = library.topType;
    sources = [];
  }

  addSourceFromName(String name, SourceSpan span) {
    var filename = library.makeFullPath(name);
    if (filename == library.baseSource.filename) {
      world.error('library cannot source itself', span);
      return;
    } else if (sources.some((s) => s.filename == filename)) {
      world.error('file "$filename" has already been sourced', span);
      return;
    }

    var source = world.readFile(library.makeFullPath(name));
    sources.add(source);
  }

  addSource(SourceFile source) {
    if (library.sources.some((s) => s.filename == source.filename)) {
      // TODO(jimhug): good error location.
      world.error('duplicate source file "${source.filename}"', null);
      return;
    }
    library.sources.add(source);
    final parser = new Parser(source, diet: options.dietParse);
    final unit = parser.compilationUnit();

    unit.forEach((def) => def.visit(this));

    assert(sources.length == 0 || isTop);
    isTop = false;
    var newSources = sources;
    sources = [];
    for (var newSource in newSources) {
      addSource(newSource);
    }
  }

  void visitDirectiveDefinition(DirectiveDefinition node) {
    if (!isTop) {
      world.error('directives not allowed in sourced file', node.span);
      return;
    }

    var name;
    switch (node.name.name) {
      case "library":
        name = getSingleStringArg(node);
        if (library.name == null) {
          library.name = name;
          if (seenImport || seenSource || seenResource) {
            world.error('#library must be first directive in file', node.span);
          }
        } else {
          world.error('already specified library name', node.span);
        }
        break;

      case "import":
        seenImport = true;
        name = getFirstStringArg(node);
        var prefix = tryGetNamedStringArg(node, 'prefix');
        if (node.arguments.length > 2 ||
            node.arguments.length == 2 && prefix == null) {
          world.error(
              'expected at most one "name" argument and one optional "prefix"'
              ' but found ${node.arguments.length}', node.span);
        } else if (prefix != null && prefix.indexOf('.') >= 0) {
          world.error('library prefix canot contain "."', node.span);
        } else if (seenSource || seenResource) {
          world.error('#imports must come before any #source or #resource',
            node.span);
        }

        // Empty prefix and no prefix are equivalent
        if (prefix == '') prefix = null;

        var filename = library.makeFullPath(name);

        if (library.imports.some((li) => li.library.baseSource == filename)) {
          // TODO(jimhug): Can you import a lib twice with different prefixes?
          world.error('duplicate import of "$name"', node.span);
          return;
        }

        var newLib = library.addImport(filename, prefix, node.span);
        // TODO(jimhug): Add check that imported library has a #library
        break;

      case "source":
        seenSource = true;
        name = getSingleStringArg(node);
        addSourceFromName(name, node.span);
        if (seenResource) {
          world.error('#sources must come before any #resource', node.span);
        }
        break;

      case "native":
        // TODO(jimhug): Fit this into spec?
        name = getSingleStringArg(node);
        library.addNative(library.makeFullPath(name));
        break;

      case "resource":
        // TODO(jmesserly): should we do anything else here?
        seenResource = true;
        getFirstStringArg(node);
        break;

      default:
        world.error('unknown directive: ${node.name.name}', node.span);
    }
  }

  String getSingleStringArg(DirectiveDefinition node) {
    if (node.arguments.length != 1) {
      world.error(
          'expected exactly one argument but found ${node.arguments.length}',
          node.span);
    }
    return getFirstStringArg(node);
  }

  String getFirstStringArg(DirectiveDefinition node) {
    if (node.arguments.length < 1) {
      world.error(
          'expected at least one argument but found ${node.arguments.length}',
          node.span);
    }
    var arg = node.arguments[0];
    if (arg.label != null) {
      world.error('label not allowed for directive', node.span);
    }
    return _parseStringArgument(arg);
  }

  String tryGetNamedStringArg(DirectiveDefinition node, String argName) {
    var args = node.arguments.filter(
        (a) => a.label != null && a.label.name == argName);

    if (args.length == 0) {
      return null;
    }
    if (args.length > 1) {
      world.error('expected at most one "${argName}" argument but found '
                  '${node.arguments.length}', node.span);
    }
    // Even though the collection has one arg, this is the easiest way to get
    // the first item.
    for (var arg in args) {
      return _parseStringArgument(arg);
    }
  }

  String _parseStringArgument(ArgumentNode arg) {
    var expr = arg.value;
    if (expr is! LiteralExpression || !expr.value.type.isString) {
      world.error('expected string literal', expr.span);
    }
    return expr.value.actualValue;
  }

  void visitTypeDefinition(TypeDefinition node) {
    var oldType = currentType;
    currentType = library.addType(node.name.name, node, node.isClass);
    for (var member in node.body) {
      member.visit(this);
    }
    currentType = oldType;
  }

  void visitVariableDefinition(VariableDefinition node) {
    currentType.addField(node);
  }

  void visitFunctionDefinition(FunctionDefinition node) {
    currentType.addMethod(node.name.name, node);
  }

  void visitFunctionTypeDefinition(FunctionTypeDefinition node) {
    var type = library.addType(node.func.name.name, node, false);
    type.addMethod(':call', node.func);
  }
}
