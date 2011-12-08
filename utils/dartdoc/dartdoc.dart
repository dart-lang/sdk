// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * To use it, from this directory, run:
 *
 *     $ dartdoc <path to .dart file>
 *
 * This will create a "docs" directory with the docs for your libraries. To
 * create these beautiful docs, dartdoc parses your library and every library
 * it imports (recursively). From each library, it parses all classes and
 * members, finds the associated doc comments and builds crosslinked docs from
 * them.
 */
#library('dartdoc');

#import('../../frog/lang.dart');
#import('../../frog/file_system.dart');
#import('../../frog/file_system_node.dart');
#import('../markdown/lib.dart', prefix: 'md');

#source('classify.dart');
#source('files.dart');
#source('utils.dart');

/** Path to corePath library. */
final corePath = 'lib';

/** Path to generate html files into. */
final outdir = 'docs';

/** Set to `false` to not include the source code in the generated docs. */
bool includeSource = true;

FileSystem files;

/** Special comment position used to store the library-level doc comment. */
final _libraryDoc = -1;

/** The library that we're currently generating docs for. */
Library _currentLibrary;

/** The type that we're currently generating docs for. */
Type _currentType;

/** The member that we're currently generating docs for. */
Member _currentMember;

/**
 * The cached lookup-table to associate doc comments with spans. The outer map
 * is from filenames to doc comments in that file. The inner map maps from the
 * token positions to doc comments. Each position is the starting offset of the
 * next non-comment token *following* the doc comment. For example, the position
 * for this comment would be the position of the "Map" token below.
 */
Map<String, Map<int, String>> _comments;

/** A callback that returns additional Markdown documentation for a type. */
typedef String TypeDocumenter(Type type);

/** A list of callbacks registered for documenting types. */
List<TypeDocumenter> _typeDocumenters;

/** A callback that returns additional Markdown documentation for a method. */
typedef String MethodDocumenter(MethodMember method);

/** A list of callbacks registered for documenting methods. */
List<MethodDocumenter> _methodDocumenters;

/** A callback that returns additional Markdown documentation for a field. */
typedef String FieldDocumenter(FieldMember field);

/** A list of callbacks registered for documenting fields. */
List<FieldDocumenter> _fieldDocumenters;

int _totalLibraries = 0;
int _totalTypes = 0;
int _totalMembers = 0;

/**
 * Run this from the `utils/dartdoc` directory.
 */
void main() {
  // The entrypoint of the library to generate docs for.
  final entrypoint = process.argv[2];

  // Parse the dartdoc options.
  for (int i = 3; i < process.argv.length; i++) {
    final arg = process.argv[i];
    switch (arg) {
      case '--no-code':
        includeSource = false;
        break;

      default:
        print('Unknown option: $arg');
    }
  }

  files = new NodeFileSystem();
  parseOptions('../../frog', [] /* args */, files);
  initializeWorld(files);

  final elapsed = time(() {
    initializeDartDoc();
    document(entrypoint);
  });

  printStats(elapsed);
}

void initializeDartDoc() {
  _comments = <Map<int, String>>{};
  _typeDocumenters = <TypeDocumenter>[];
  _methodDocumenters = <MethodDocumenter>[];
  _fieldDocumenters = <FieldDocumenter>[];

  // Patch in support for [:...:]-style code to the markdown parser.
  // TODO(rnystrom): Markdown already has syntax for this. Phase this out?
  md.InlineParser.syntaxes.insertRange(0, 1,
      new md.CodeSyntax(@'\[\:((?:.|\n)*?)\:\]'));

  md.setImplicitLinkResolver(resolveNameReference);
}

document(String entrypoint) {
  try {
    var oldDietParse = options.dietParse;
    options.dietParse = true;

    // Handle the built-in entrypoints.
    switch (entrypoint) {
      case 'corelib':
        world.getOrAddLibrary('dart:core');
        world.getOrAddLibrary('dart:coreimpl');
        world.process();
        break;

      case 'dom':
        world.getOrAddLibrary('dart:core');
        world.getOrAddLibrary('dart:coreimpl');
        world.getOrAddLibrary('dart:dom');
        world.process();
        break;

      case 'html':
        world.getOrAddLibrary('dart:core');
        world.getOrAddLibrary('dart:coreimpl');
        world.getOrAddLibrary('dart:dom');
        world.getOrAddLibrary('dart:html');
        world.process();
        break;

      default:
        // Normal entrypoint script.
        world.processDartScript(entrypoint);
    }

    world.resolveAll();

    // Generate the docs.
    docIndex();
    for (final library in world.libraries.getValues()) {
      docLibrary(library);
    }
  } finally {
    options.dietParse = oldDietParse;
  }
}

printStats(num elapsed) {
  print('Documented $_totalLibraries libraries, $_totalTypes types, and ' +
      '$_totalMembers members in ${elapsed}msec.');
}

writeHeader(String title) {
  writeln(
      '''
      <!DOCTYPE html>
      <html>
      <head>
      <meta charset="utf-8">
      <title>$title</title>
      <link rel="stylesheet" type="text/css"
          href="${relativePath('styles.css')}" />
      <link href="http://fonts.googleapis.com/css?family=Open+Sans:400,600,700,800" rel="stylesheet" type="text/css">
      <script src="${relativePath('interact.js')}"></script>
      </head>
      <body>
      <div class="page">
      ''');
  docNavigation();
  writeln('<div class="content">');
}

writeFooter() {
  writeln(
      '''
      </div>
      <div class="footer"</div>
      </body></html>
      ''');
}

docIndex() {
  startFile('index.html');

  writeHeader('Dart Documentation');

  writeln('<h1>Dart Documentation</h1>');
  writeln('<h3>Libraries</h3>');

  for (final library in orderByName(world.libraries)) {
    writeln(
        '''
        <h4>${a(libraryUrl(library), library.name)}</h4>
        ''');
  }

  writeFooter();
  endFile();
}

docNavigation() {
  writeln(
      '''
      <div class="nav">
      <h1>${a("index.html", "Dart Documentation")}</h1>
      ''');

  for (final library in orderByName(world.libraries)) {
    write('<h2><div class="icon-library"></div>');

    if ((_currentLibrary == library) && (_currentType == null)) {
      write('<strong>${library.name}</strong>');
    } else {
      write('${a(libraryUrl(library), library.name)}');
    }
    write('</h2>');

    // Only expand classes in navigation for current library.
    if (_currentLibrary == library) docLibraryNavigation(library);
  }

  writeln('</div>');
}

/** Writes the navigation for the types contained by the given library. */
docLibraryNavigation(Library library) {
  // Show the exception types separately.
  final types = <Type>[];
  final exceptions = <Type>[];

  for (final type in orderByName(library.types)) {
    if (type.isTop) continue;
    if (type.name.startsWith('_')) continue;

    if (type.name.endsWith('Exception')) {
      exceptions.add(type);
    } else {
      types.add(type);
    }
  }

  if ((types.length == 0) && (exceptions.length == 0)) return;

  writeType(String icon, Type type) {
    write('<li>');
    if (_currentType == type) {
      write(
          '<div class="icon-$icon"></div><strong>${typeName(type)}</strong>');
    } else {
      write(a(typeUrl(type),
          '<div class="icon-$icon"></div>${typeName(type)}'));
    }
    writeln('</li>');
  }

  writeln('<ul>');
  types.forEach((type) => writeType(type.isClass ? 'class' : 'interface',
      type));
  exceptions.forEach((type) => writeType('exception', type));
  writeln('</ul>');
}

String _runDocumenters(var item, List<Function> documenters) =>
  Strings.join(map(documenters, (doc) => doc(item)), '\n\n');

docLibrary(Library library) {
  _totalLibraries++;
  _currentLibrary = library;
  _currentType = null;

  startFile(libraryUrl(library));
  writeHeader(library.name);
  writeln('<h1>Library <strong>${library.name}</strong></h1>');

  // Look for a comment for the entire library.
  final comment = findCommentInFile(library.baseSource, _libraryDoc);
  if (comment != null) {
    final html = md.markdownToHtml(comment);
    writeln('<div class="doc">$html</div>');
  }

  // Document the top-level members.
  docMembers(library.topType);

  // Document the types.
  final classes = <Type>[];
  final interfaces = <Type>[];
  final exceptions = <Type>[];

  for (final type in orderByName(library.types)) {
    if (type.isTop) continue;
    if (type.name.startsWith('_')) continue;

    if (type.name.endsWith('Exception')) {
      exceptions.add(type);
    } else if (type.isClass) {
      classes.add(type);
    } else {
      interfaces.add(type);
    }
  }

  docTypes(classes, 'Classes');
  docTypes(interfaces, 'Interfaces');
  docTypes(exceptions, 'Exceptions');

  writeFooter();
  endFile();

  for (final type in library.types.getValues()) {
    if (!type.isTop) docType(type);
  }
}

docTypes(List<Type> types, String header) {
  if (types.length == 0) return;

  writeln('<h3>$header</h3>');

  for (final type in types) {
    writeln(
        '''
        <div class="type">
        <h4>
          ${a(typeUrl(type), "<strong>${typeName(type)}</strong>")}
        </h4>
        </div>
        ''');
  }
}

docType(Type type) {
  _totalTypes++;
  _currentType = type;

  startFile(typeUrl(type));

  final typeTitle = '${type.isClass ? "Class" : "Interface"} ${typeName(type)}';
  writeHeader('Library ${type.library.name} / $typeTitle');
  writeln(
      '''
      <h1>${a(libraryUrl(type.library),
            "Library <strong>${type.library.name}</strong>")}</h1>
      <h2>${type.isClass ? "Class" : "Interface"}
          <strong>${typeName(type, showBounds: true)}</strong></h2>
      ''');

  docInheritance(type);
  docCode(type.span, _runDocumenters(type, _typeDocumenters));
  docConstructors(type);
  docMembers(type);

  writeFooter();
  endFile();
}

void docMembers(Type type) {
  // Collect the different kinds of members.
  final methods = [];
  final fields = [];

  for (final member in orderByName(type.members)) {
    if (member.name.startsWith('_')) continue;

    if (member.isProperty) {
      if (member.canGet) methods.add(member.getter);
      if (member.canSet) methods.add(member.setter);
    } else if (member.isMethod) {
      methods.add(member);
    } else if (member.isField) {
      fields.add(member);
    }
  }

  if (methods.length > 0) {
    writeln('<h3>Methods</h3>');
    for (final method in methods) docMethod(type, method);
  }

  if (fields.length > 0) {
    writeln('<h3>Fields</h3>');
    for (final field in fields) docField(type, field);
  }
}

/** Document the superclass, superinterfaces and factory of [Type]. */
docInheritance(Type type) {
  final isSubclass = (type.parent != null) && !type.parent.isObject;

  Type factory;
  if (type.definition is TypeDefinition) {
    TypeDefinition definition = type.definition;
    if (definition.factoryType != null) {
      factory = definition.factoryType.type;
    }
  }

  if (isSubclass ||
      (type.interfaces != null && type.interfaces.length > 0) ||
      (factory != null)) {
    writeln('<p>');

    if (isSubclass) {
      write('Extends ${typeReference(type.parent)}. ');
    }

    if (type.interfaces != null && type.interfaces.length > 0) {
      var interfaceStr = joinWithCommas(map(type.interfaces, typeReference));
      write('Implements ${interfaceStr}. ');
    }

    if (factory != null) {
      write('Has factory class ${typeReference(factory)}.');
    }
  }
}

/** Document the constructors for [Type], if any. */
docConstructors(Type type) {
  final names = type.constructors.getKeys().filter(
    (name) => !name.startsWith('_'));

  if (names.length > 0) {
    writeln('<h3>Constructors</h3>');
    names.sort((x, y) => x.toUpperCase().compareTo(y.toUpperCase()));

    for (final name in names) {
      docMethod(type, type.constructors[name], constructorName: name);
    }
  }
}

/**
 * Documents the [method] in type [type]. Handles all kinds of methods
 * including getters, setters, and constructors.
 */
docMethod(Type type, MethodMember method, [String constructorName = null]) {
  _totalMembers++;
  _currentMember = method;

  writeln('<div class="method"><h4 id="${memberAnchor(method)}">');

  if (includeSource) {
    writeln('<span class="show-code">Code</span>');
  }

  if (method.isStatic && !type.isTop) {
    write('static ');
  }

  if (method.isConstructor) {
    write(method.isConst ? 'const ' : 'new ');
  }

  if (constructorName == null) {
    annotateType(type, method.returnType);
  }

  // Translate specially-named methods: getters, setters, operators.
  var name = method.name;
  if (name.startsWith('get:')) {
    // Getter.
    name = 'get ${name.substring(4)}';
  } else if (name.startsWith('set:')) {
    // Setter.
    name = 'set ${name.substring(4)}';
  } else {
    // See if it's an operator.
    name = TokenKind.rawOperatorFromMethod(name);
    if (name == null) {
      name = method.name;
    } else {
      name = 'operator $name';
    }
  }

  write('<strong>$name</strong>');

  // Named constructors.
  if (constructorName != null && constructorName != '') {
    write('.');
    write(constructorName);
  }

  docParamList(type, method);

  write(''' <a class="anchor-link" href="#${memberAnchor(method)}"
            title="Permalink to ${typeName(type)}.$name">#</a>''');
  writeln('</h4>');

  docCode(method.span, _runDocumenters(method, _methodDocumenters),
      showCode: true);

  writeln('</div>');
}

docParamList(Type enclosingType, MethodMember member) {
  write('(');
  bool first = true;
  bool inOptionals = false;
  for (final parameter in member.parameters) {
    if (!first) write(', ');

    if (!inOptionals && parameter.isOptional) {
      write('[');
      inOptionals = true;
    }

    annotateType(enclosingType, parameter.type, parameter.name);

    // Show the default value for named optional parameters.
    if (parameter.isOptional && parameter.hasDefaultValue) {
      write(' = ');
      // TODO(rnystrom): Using the definition text here is a bit cheap.
      // We really should be pretty-printing the AST so that if you have:
      //   foo([arg = 1 + /* comment */ 2])
      // the docs should just show:
      //   foo([arg = 1 + 2])
      // For now, we'll assume you don't do that.
      write(parameter.definition.value.span.text);
    }

    first = false;
  }

  if (inOptionals) write(']');
  write(')');
}

/** Documents the field [field] of type [type]. */
docField(Type type, FieldMember field) {
  _totalMembers++;
  _currentMember = field;

  writeln('<div class="field"><h4 id="${memberAnchor(field)}">');

  if (includeSource) {
    writeln('<span class="show-code">Code</span>');
  }

  if (field.isStatic && !type.isTop) {
    write('static ');
  }

  if (field.isFinal) {
    write('final ');
  } else if (field.type.name == 'Dynamic') {
    write('var ');
  }

  annotateType(type, field.type);
  write(
      '''
      <strong>${field.name}</strong> <a class="anchor-link"
          href="#${memberAnchor(field)}"
          title="Permalink to ${typeName(type)}.${field.name}">#</a>
      </h4>
      ''');

  docCode(field.span, _runDocumenters(field, _fieldDocumenters),
      showCode: true);
  writeln('</div>');
}

/**
 * Creates a hyperlink. Handles turning the [href] into an appropriate relative
 * path from the current file.
 */
String a(String href, String contents, [String class]) {
  final css = class == null ? '' : ' class="$class"';
  return '<a href="${relativePath(href)}"$css>$contents</a>';
}

/** Generates a human-friendly string representation for a type. */
typeName(Type type, [bool showBounds = false]) {
  // See if it's a generic type.
  if (type.isGeneric) {
    final typeParams = [];
    for (final typeParam in type.genericType.typeParameters) {
      if (showBounds &&
          (typeParam.extendsType != null) &&
          !typeParam.extendsType.isObject) {
        final bound = typeName(typeParam.extendsType, showBounds: true);
        typeParams.add('${typeParam.name} extends $bound');
      } else {
        typeParams.add(typeParam.name);
      }
    }

    final params = Strings.join(typeParams, ', ');
    return '${type.name}&lt;$params&gt;';
  }

  // See if it's an instantiation of a generic type.
  final typeArgs = type.typeArgsInOrder;
  if (typeArgs != null) {
    final args = Strings.join(map(typeArgs, typeName), ', ');
    return '${type.genericType.name}&lt;$args&gt;';
  }

  // Regular type.
  return type.name;
}

/** Writes a link to a human-friendly string representation for a type. */
linkToType(Type enclosingType, Type type) {
  if (type is ParameterType) {
    // If we're using a type parameter within the body of a generic class then
    // just link back up to the class.
    write(a(typeUrl(enclosingType), type.name));
    return;
  }

  // Link to the type.
  // Use .genericType to avoid writing the <...> here.
  write(a(typeUrl(type), type.genericType.name));

  // See if it's a generic type.
  if (type.isGeneric) {
    // TODO(rnystrom): This relies on a weird corner case of frog. Currently,
    // the only time we get into this case is when we have a "raw" generic
    // that's been instantiated with Dynamic for all type arguments. It's kind
    // of strange that frog works that way, but we take advantage of it to
    // show raw types without any type arguments.
    return;
  }

  // See if it's an instantiation of a generic type.
  final typeArgs = type.typeArgsInOrder;
  if (typeArgs != null) {
    write('&lt;');
    bool first = true;
    for (final arg in typeArgs) {
      if (!first) write(', ');
      first = false;
      linkToType(enclosingType, arg);
    }
    write('&gt;');
  }
}

/** Creates a linked cross reference to [type]. */
typeReference(Type type) {
  // TODO(rnystrom): Do we need to handle ParameterTypes here like
  // annotation() does?
  return a(typeUrl(type), typeName(type), class: 'crossref');
}

/**
 * Writes a type annotation for the given type and (optional) parameter name.
 */
annotateType(Type enclosingType, Type type, [String paramName = null]) {
  // Don't bother explicitly displaying Dynamic.
  if (type.isVar) {
    if (paramName !== null) write(paramName);
    return;
  }

  // For parameters, handle non-typedefed function types.
  if (paramName !== null) {
    final call = type.getCallMethod();
    if (call != null) {
      annotateType(enclosingType, call.returnType);
      write(paramName);

      docParamList(enclosingType, call);
      return;
    }
  }

  linkToType(enclosingType, type);

  write(' ');
  if (paramName !== null) write(paramName);
}


/**
 * This will be called whenever a doc comment hits a `[name]` in square
 * brackets. It will try to figure out what the name refers to and link or
 * style it appropriately.
 */
md.Node resolveNameReference(String name) {
  makeLink(String href) {
    final anchor = new md.Element.text('a', name);
    anchor.attributes['href'] = relativePath(href);
    anchor.attributes['class'] = 'crossref';
    return anchor;
  }

  findMember(Type type) {
    final member = type.members[name];
    if (member == null) return null;

    // Special case: if the member we've resolved is a property (i.e. it wraps
    // a getter and/or setter then *that* member itself won't be on the docs,
    // just the getter or setter will be. So pick one of those to link to.
    if (member.isProperty) {
      return member.canGet ? member.getter : member.setter;
    }

    return member;
  }

  // See if it's a parameter of the current method.
  if (_currentMember != null) {
    for (final parameter in _currentMember.parameters) {
      if (parameter.name == name) {
        final element = new md.Element.text('span', name);
        element.attributes['class'] = 'param';
        return element;
      }
    }
  }

  // See if it's another member of the current type.
  if (_currentType != null) {
    final member = findMember(_currentType);
    if (member != null) {
      return makeLink(memberUrl(member));
    }
  }

  // See if it's another type in the current library.
  if (_currentLibrary != null) {
    final type = _currentLibrary.types[name];
    if (type != null) {
      return makeLink(typeUrl(type));
    }

    // See if it's a top-level member in the current library.
    final member = findMember(_currentLibrary.topType);
    if (member != null) {
      return makeLink(memberUrl(member));
    }
  }

  // TODO(rnystrom): Should also consider:
  // * Names imported by libraries this library imports.
  // * Type parameters of the enclosing type.

  return new md.Element.text('code', name);
}

/**
 * Documents the code contained within [span]. Will include the previous
 * Dartdoc associated with that span if found, and will include the syntax
 * highlighted code itself if desired.
 */
docCode(SourceSpan span, String extraMarkdown, [bool showCode = false]) {
  if (span == null) return;

  writeln('<div class="doc">');
  final comment = findComment(span);
  if (comment != null) {
    writeln(md.markdownToHtml('${comment}\n\n${extraMarkdown}'));
  } else {
    writeln(md.markdownToHtml(extraMarkdown));
  }

  if (includeSource && showCode) {
    writeln('<pre class="source">');
    write(formatCode(span));
    writeln('</pre>');
  }

  writeln('</div>');
}

/** Finds the doc comment preceding the given source span, if there is one. */
findComment(SourceSpan span) => findCommentInFile(span.file, span.start);

/** Finds the doc comment preceding the given source span, if there is one. */
findCommentInFile(SourceFile file, int position) {
  // Get the doc comments for this file.
  final fileComments = _comments.putIfAbsent(file.filename,
    () => parseDocComments(file));

  return fileComments[position];
}

parseDocComments(SourceFile file) {
  final comments = new Map<int, String>();

  final tokenizer = new Tokenizer(file, false);
  var lastComment = null;

  while (true) {
    final token = tokenizer.next();
    if (token.kind == TokenKind.END_OF_FILE) break;

    if (token.kind == TokenKind.COMMENT) {
      final text = token.text;
      if (text.startsWith('/**')) {
        // Remember that we've encountered a doc comment.
        lastComment = stripComment(token.text);
      } else if (text.startsWith('///')) {
        var line = text.substring(3, text.length);
        // Allow a leading space.
        if (line.startsWith(' ')) line = line.substring(1, text.length);
        if (lastComment == null) {
          lastComment = line;
        } else {
          lastComment = '$lastComment$line';
        }
      }
    } else if (token.kind == TokenKind.WHITESPACE) {
      // Ignore whitespace tokens.
    } else if (token.kind == TokenKind.HASH) {
      // Look for #library() to find the library comment.
      final next = tokenizer.next();
      if ((lastComment != null) && (next.kind == TokenKind.LIBRARY)) {
        comments[_libraryDoc] = lastComment;
        lastComment = null;
      }
    } else {
      if (lastComment != null) {
        // We haven't attached the last doc comment to something yet, so stick
        // it to this token.
        comments[token.start] = lastComment;
        lastComment = null;
      }
    }
  }

  return comments;
}

/**
 * Takes a string of Dart code and turns it into sanitized HTML.
 */
formatCode(SourceSpan span) {
  // Remove leading indentation to line up with first line.
  final column = getSpanColumn(span);
  final lines = span.text.split('\n');
  // TODO(rnystrom): Dirty hack.
  for (final i = 1; i < lines.length; i++) {
    lines[i] = unindent(lines[i], column);
  }

  final code = Strings.join(lines, '\n');

  // Syntax highlight.
  return classifySource(new SourceFile('', code));
}

// TODO(rnystrom): Move into SourceSpan?
int getSpanColumn(SourceSpan span) {
  final line = span.file.getLine(span.start);
  return span.file.getColumn(line, span.start);
}

/**
 * Pulls the raw text out of a doc comment (i.e. removes the comment
 * characters).
 */
stripComment(comment) {
  StringBuffer buf = new StringBuffer();

  for (final line in comment.split('\n')) {
    line = line.trim();
    if (line.startsWith('/**')) line = line.substring(3, line.length);
    if (line.endsWith('*/')) line = line.substring(0, line.length - 2);
    line = line.trim();
    if (line.startsWith('* ')) {
      line = line.substring(2, line.length);
    } else if (line.startsWith('*')) {
      line = line.substring(1, line.length);
    }

    buf.add(line);
    buf.add('\n');
  }

  return buf.toString();
}

/** Register a callback to add additional documentation to a type. */
addTypeDocumenter(TypeDocumenter fn) => _typeDocumenters.add(fn);

/** Register a callback to add additional documentation to a method. */
addMethodDocumenter(MethodDocumenter fn) => _methodDocumenters.add(fn);

/** Register a callback to add additional documentation to a field. */
addFieldDocumenter(FieldDocumenter fn) => _fieldDocumenters.add(fn);
