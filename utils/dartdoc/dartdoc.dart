// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * To use it, from this directory, run:
 *
 *     $ dartdoc <path to .dart file>
 *
 * This will create a "docs" directory with the docs for your libraries. To do
 * so, dartdoc parses that library and every library it imports. From each
 * library, it parses all classes and members, finds the associated doc
 * comments and builds crosslinked docs from them.
 */
#library('dartdoc');

#import('../../frog/lang.dart');
#import('../../frog/file_system.dart');
#import('../../frog/file_system_node.dart');
#import('../markdown/lib.dart', prefix: 'md');

#source('classify.dart');

/** Path to corePath library. */
final corePath = 'lib';

/** Path to generate html files into. */
final outdir = 'docs';

/** Set to `true` to include the source code in the generated docs. */
bool includeSource = true;

/** Special comment position used to store the library-level doc comment. */
final _libraryDoc = -1;

/** The file currently being written to. */
StringBuffer _file;

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

int _totalLibraries = 0;
int _totalTypes = 0;
int _totalMembers = 0;

FileSystem files;

/**
 * Run this from the `utils/dartdoc` directory.
 */
void main() {
  // The entrypoint of the library to generate docs for.
  final libPath = process.argv[2];

  files = new NodeFileSystem();
  parseOptions('../../frog', [] /* args */, files);

  // Patch in support for [:...:]-style code to the markdown parser.
  // TODO(rnystrom): Markdown already has syntax for this. Phase this out?
  md.InlineParser.syntaxes.insertRange(0, 1,
      new md.CodeSyntax(@'\[\:((?:.|\n)*?)\:\]'));

  md.setImplicitLinkResolver(resolveNameReference);

  final elapsed = time(() {
    initializeDartDoc();

    initializeWorld(files);

    world.processScript(libPath);
    world.resolveAll();

    // Clean the output directory.
    if (files.fileExists(outdir)) {
      files.removeDirectory(outdir, recursive: true);
    }
    files.createDirectory(outdir, recursive: true);

    // Copy over the static files.
    for (final file in ['interact.js', 'styles.css']) {
      copyStatic(file);
    }

    // Generate the docs.
    for (final library in world.libraries.getValues()) {
      docLibrary(library);
    }

    docIndex(world.libraries.getValues());
  });

  print('Documented $_totalLibraries libraries, $_totalTypes types, and ' +
        '$_totalMembers members in ${elapsed}msec.');
}

void initializeDartDoc() {
  _comments = <String, Map<int, String>>{};
}

/** Copies the static file at 'static/file' to the output directory. */
copyStatic(String file) {
  var contents = files.readAll(joinPaths('static', file));
  files.writeString(joinPaths(outdir, file), contents);
}

num time(callback()) {
  // Unlike world.withTiming, returns the elapsed time.
  final watch = new Stopwatch();
  watch.start();
  callback();
  watch.stop();
  return watch.elapsedInMs();
}

startFile() {
  _file = new StringBuffer();
}

write(String s) {
  _file.add(s);
}

writeln(String s) {
  write(s);
  write('\n');
}

endFile(String outfile) {
  world.files.writeString(outfile, _file.toString());
  _file = null;
}

/** Turns a library name into something that's safe to use as a file name. */
sanitize(String name) => name.replaceAll(':', '_').replaceAll('/', '_');

docIndex(List<Library> libraries) {
  startFile();
  // TODO(rnystrom): Need to figure out what this should look like.
  writeln(
      '''
      <html><head>
      <title>Index</title>
      <link rel="stylesheet" type="text/css" href="styles.css" />
      </head>
      <body>
      <div class="content">
      <ul>
      ''');

  final sorted = new List<Library>.from(libraries);
  sorted.sort((a, b) => a.name.compareTo(b.name));

  for (final library in sorted) {
    writeln(
        '''
        <li><a href="${libraryUrl(library)}">Library ${library.name}</a></li>
        ''');
  }

  writeln(
      '''
      </ul>
      </div>
      </body></html>
      ''');

  endFile('$outdir/index.html');
}

docLibrary(Library library) {
  _totalLibraries++;
  _currentLibrary = library;

  startFile();
  writeln(
      '''
      <html>
      <head>
      <title>${library.name}</title>
      <link rel="stylesheet" type="text/css" href="styles.css" />
      <link href="http://fonts.googleapis.com/css?family=Open+Sans:400,600,700,800" rel="stylesheet" type="text/css">
      <script src="interact.js"></script>
      </head>
      <body>
      <div class="content">
      <h1>Library <strong>${library.name}</strong></h1>
      ''');

  bool needsSeparator = false;

  // Look for a comment for the entire library.
  final comment = findCommentInFile(library.baseSource, _libraryDoc);
  if (comment != null) {
    final html = md.markdownToHtml(comment);
    writeln('<div class="doc">$html</div>');
    needsSeparator = true;
  }

  for (final type in orderValuesByKeys(library.types)) {
    // Skip private types (for now at least).
    if ((type.name != null) && type.name.startsWith('_')) continue;

    if (needsSeparator) writeln('<hr/>');
    if (docType(type)) needsSeparator = true;
  }

  writeln(
      '''
      </div>
      </body></html>
      ''');

  endFile('$outdir/${sanitize(library.name)}.html');
}

/**
 * Documents [type]. Handles top-level members if given an unnamed Type.
 * Returns `true` if it wrote anything.
 */
bool docType(Type type) {
  _totalTypes++;
  _currentType = type;

  bool wroteSomething = false;

  if (type.name != null) {
    final name = typeName(type);

    write(
        '''
        <h2 id="${typeAnchor(type)}">
          ${type.isClass ? "Class" : "Interface"} <strong>$name</strong>
          <a class="anchor-link" href="${typeUrl(type)}"
              title="Permalink to $name">#</a>
        </h2>
        ''');

    docInheritance(type);
    docCode(type.span);
    docConstructors(type);

    wroteSomething = true;
  }

  // Collect the different kinds of members.
  final methods = [];
  final fields = [];

  for (final member in orderValuesByKeys(type.members)) {
    if (member.isMethod &&
        (member.definition != null) &&
        !member.name.startsWith('_')) {
      methods.add(member);
    } else if (member.isProperty) {
      if (member.canGet) methods.add(member.getter);
      if (member.canSet) methods.add(member.setter);
    } else if (member.isField && !member.name.startsWith('_')) {
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

  return wroteSomething || methods.length > 0 || fields.length > 0;
}

/** Document the superclass and superinterfaces of [Type]. */
docInheritance(Type type) {
  // Show the superclass and superinterface(s).
  final isSubclass = (type.parent != null) && !type.parent.isObject;

  if (isSubclass || (type.interfaces != null && type.interfaces.length > 0)) {
    writeln('<p>');

    if (isSubclass) {
      write('Extends ${typeReference(type.parent)}. ');
    }

    if (type.interfaces != null) {
      switch (type.interfaces.length) {
        case 0:
          // Do nothing.
          break;

        case 1:
          write('Implements ${typeReference(type.interfaces[0])}.');
          break;

        case 2:
          write('''Implements ${typeReference(type.interfaces[0])} and
              ${typeReference(type.interfaces[1])}.''');
          break;

        default:
          write('Implements ');
          for (final i = 0; i < type.interfaces.length; i++) {
            write('${typeReference(type.interfaces[i])}');
            if (i < type.interfaces.length - 2) {
              write(', ');
            } else if (i < type.interfaces.length - 1) {
              write(', and ');
            }
          }
          write('.');
          break;
      }
    }
  }
}

/** Document the constructors for [Type], if any. */
docConstructors(Type type) {
  if (type.constructors.length > 0) {
    writeln('<h3>Constructors</h3>');
    for (final name in type.constructors.getKeys()) {
      final constructor = type.constructors[name];
      docMethod(type, constructor, constructorName: name);
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
    write(annotation(type, method.returnType));
  }

  // Translate specially-named methods: getters, setters, operators.
  var name = method.name;
  if (name.startsWith('get\$')) {
    // Getter.
    name = 'get ${name.substring(4)}';
  } else if (name.startsWith('set\$')) {
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

  write('(');
  final parameters = map(method.parameters,
      (p) => '${annotation(type, p.type)}${p.name}');
  write(Strings.join(parameters, ', '));
  write(')');

  write(''' <a class="anchor-link" href="#${memberAnchor(method)}"
            title="Permalink to ${type.name}.$name">#</a>''');
  writeln('</h4>');

  docCode(method.span, showCode: true);

  writeln('</div>');
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

  write(annotation(type, field.type));
  write(
      '''
      <strong>${field.name}</strong> <a class="anchor-link"
          href="#${memberUrl(field)}"
          title="Permalink to ${type.name}.${field.name}">#</a>
      </h4>
      ''');

  docCode(field.span, showCode: true);
  writeln('</div>');
}

/** Generates a human-friendly string representation for a type. */
typeName(Type type) {
  // See if it's a generic type.
  if (type.isGeneric) {
    final typeParams = type.genericType.typeParameters;
    final params = Strings.join(map(typeParams, (p) => p.name), ', ');
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

/** Gets the URL to the documentation for [library]. */
libraryUrl(Library library) => '${sanitize(library.name)}.html';

/** Gets the URL for the documentation for [type]. */
typeUrl(Type type) => '${libraryUrl(type.library)}#${typeAnchor(type)}';

/** Gets the URL for the documentation for [member]. */
memberUrl(Member member) => '${typeUrl(member.declaringType)}-${member.name}';

/** Gets the anchor id for the document for [type]. */
typeAnchor(Type type) {
  var name = type.name;

  // No name for the special type that contains top-level members.
  if (type.isTop) return '';

  // Remove any type args or params that have been mangled into the name.
  var dollar = name.indexOf('\$', 0);
  if (dollar != -1) name = name.substring(0, dollar);

  return name;
}

/** Gets the anchor id for the document for [member]. */
memberAnchor(Member member) {
  return '${typeAnchor(member.declaringType)}-${member.name}';
}

/** Writes a linked cross reference to [type]. */
typeReference(Type type) {
  // TODO(rnystrom): Do we need to handle ParameterTypes here like
  // annotation() does?
  return '<a href="${typeUrl(type)}" class="crossref">${typeName(type)}</a>';
}

/**
 * Creates a linked string for an optional type annotation. Returns an empty
 * string if the type is Dynamic.
 */
annotation(Type enclosingType, Type type) {
  if (type.name == 'Dynamic') return '';

  // If we're using a type parameter within the body of a generic class then
  // just link back up to the class.
  if (type is ParameterType) {
    final library = sanitize(enclosingType.library.name);
    return '<a href="${typeUrl(enclosingType)}">${type.name}</a> ';
  }

  // Link to the type.
  return '<a href="${typeUrl(type)}">${typeName(type)}</a> ';
}

/**
 * This will be called whenever a doc comment hits a `[name]` in square
 * brackets. It will try to figure out what the name refers to and link or
 * style it appropriately.
 */
md.Node resolveNameReference(String name) {
  if (_currentMember != null) {
    // See if it's a parameter of the current method.
    for (final parameter in _currentMember.parameters) {
      if (parameter.name == name) {
        final element = new md.Element.text('span', name);
        element.attributes['class'] = 'param';
        return element;
      }
    }
  }

  makeLink(String href) {
    final anchor = new md.Element.text('a', name);
    anchor.attributes['href'] = href;
    anchor.attributes['class'] = 'crossref';
    return anchor;
  }

  // See if it's another member of the current type.
  if (_currentType != null) {
    var member = _currentType.members[name];
    if (member != null) {
      // Special case: if the member we've resolved is a property (i.e. it wraps
      // a getter and/or setter then *that* member itself won't be on the docs,
      // just the getter or setter will be. So pick one of those to link to.
      if (member.isProperty) {
        if (member.canGet) {
          member = member.getter;
        } else {
          member = member.setter;
        }
      }

      return makeLink(memberUrl(member));
    }
  }

  // See if it's another type in the current library.
  if (_currentLibrary != null) {
    final type = _currentLibrary.types[name];
    if (type != null) {
      return makeLink(typeUrl(type));
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
docCode(SourceSpan span, [bool showCode = false]) {
  if (span == null) return;

  writeln('<div class="doc">');
  final comment = findComment(span);
  if (comment != null) {
    writeln(md.markdownToHtml(comment));
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
  final comments = <int, String>{};

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

/** Removes up to [indentation] leading whitespace characters from [text]. */
unindent(String text, int indentation) {
  var start;
  for (start = 0; start < Math.min(indentation, text.length); start++) {
    // Stop if we hit a non-whitespace character.
    if (text[start] != ' ') break;
  }

  return text.substring(start);
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