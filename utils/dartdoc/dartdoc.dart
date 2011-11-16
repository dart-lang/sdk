// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/** An awesome documentation generator. */
#library('dartdoc');

#import('../../frog/lang.dart');
#import('../../frog/file_system_node.dart');

#source('classify.dart');

/** Path to corePath library. */
final corePath = 'lib';

/** Path to generate html files into. */
final outdir = 'docs';

/** Special comment position used to store the library-level doc comment. */
final _libraryDoc = -1;

/** The file currently being written to. */
StringBuffer _file;

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

/**
 * Run this from the frog/samples directory.  Before running, you need
 * to create a docs dir with 'mkdir docs' - since Dart currently doesn't
 * support creating new directories.
 */
void main() {
  // The entrypoint of the library to generate docs for.
  final libPath = process.argv[2];

  // TODO(rnystrom): Get options and homedir like frog.dart does.
  final files = new NodeFileSystem();
  parseOptions('../../frog', [] /* args */, files);

  final elapsed = time(() {
    initializeWorld(files);

    world.processScript(libPath);
    world.resolveAll();

    _comments = <String, Map<int, String>>{};

    for (var library in world.libraries.getValues()) {
      docLibrary(library);
    }

    docIndex(world.libraries.getValues());
  });

  print('Documented $_totalLibraries libraries, $_totalTypes types, and ' +
        '$_totalMembers members in ${elapsed}msec.');
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

  var sorted = new List<Library>.from(libraries);
  sorted.sort((a, b) => a.name.compareTo(b.name));

  for (var library in sorted) {
    writeln(
        '''
        <li><a href="${sanitize(library.name)}.html">
            Library ${library.name}</a>
        </li>
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
    writeln('<div class="doc"><p>$comment</p></div>');
    needsSeparator = true;
  }

  for (var type in library.types.getValues()) {
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
 * Documents [Type]. Handles top-level members if given an unnamed Type.
 * Returns [:true:] if it wrote anything.
 */
bool docType(Type type) {
  _totalTypes++;

  bool wroteSomething = false;

  if (type.name != null) {
    write(
        '''
        <h2 id="${type.name}">
          ${type.isClass ? "Class" : "Interface"} <strong>${type.name}</strong>
          <a class="anchor-link" href="#${type.name}"
              title="Permalink to ${type.name}">#</a>
        </h2>
        ''');

    docInheritance(type);
    docCode(type.span);
    docConstructors(type);

    wroteSomething = true;
  }

  // Collect the different kinds of members.
  var methods = [];
  var fields = [];

  for (var member in orderValuesByKeys(type.members)) {
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
    for (var method in methods) docMethod(type.name, method);
  }

  if (fields.length > 0) {
    writeln('<h3>Fields</h3>');
    for (var field in fields) docField(type.name, field);
  }

  return wroteSomething || methods.length > 0 || fields.length > 0;
}

/** Document the superclass and superinterfaces of [Type]. */
docInheritance(Type type) {
  // Show the superclass and superinterface(s).
  if ((type.parent != null) && (type.parent.isObject) ||
      (type.interfaces != null && type.interfaces.length > 0)) {
    writeln('<p>');

    if (type.parent != null) {
      write('Extends ${typeRef(type.parent)}. ');
    }

    if (type.interfaces != null) {
      var interfaces = [];
      switch (type.interfaces.length) {
        case 0:
          // Do nothing.
          break;

        case 1:
          write('Implements ${typeRef(type.interfaces[0])}.');
          break;

        case 2:
          write('''Implements ${typeRef(type.interfaces[0])} and
              ${typeRef(type.interfaces[1])}.''');
          break;

        default:
          write('Implements ');
          for (var i = 0; i < type.interfaces.length; i++) {
            write('${typeRef(type.interfaces[i])}');
            if (i < type.interfaces.length - 1) {
              write(', ');
            } else {
              write(' and ');
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
    for (var name in type.constructors.getKeys()) {
      var constructor = type.constructors[name];
      docMethod(type.name, constructor, namedConstructor: name);
    }
  }
}

/**
 * Documents the [method] in a type named [typeName]. Handles all kinds of
 * methods including getters, setters, and constructors.
 */
docMethod(String typeName, MethodMember method,
    [String namedConstructor = null]) {
  _totalMembers++;

  writeln(
      '''
      <div class="method"><h4 id="$typeName.${method.name}">
        <span class="show-code">Code</span>
      ''');

  // A null typeName means it's a top-level definition which is implicitly
  // static so doesn't need to annotate it.
  if (method.isStatic && (typeName != null)) {
    write('static ');
  }

  if (method.isConstructor) {
    write(method.isConst ? 'const ' : 'new ');
  }

  if (namedConstructor == null) {
    write(optionalTypeRef(method.returnType));
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
  if (namedConstructor != null && namedConstructor != '') {
    write('.');
    write(namedConstructor);
  }

  write('(');
  var paramList = [];
  if (method.parameters == null) print(method.name);
  for (var p in method.parameters) {
    paramList.add('${optionalTypeRef(p.type)}${p.name}');
  }
  write(Strings.join(paramList, ", "));
  write(')');

  write(''' <a class="anchor-link" href="#$typeName.${method.name}"
            title="Permalink to $typeName.$name">#</a>''');
  writeln('</h4>');

  docCode(method.span, showCode: true);

  writeln('</div>');
}

/** Documents the field [field] in a type named [typeName]. */
docField(String typeName, FieldMember field) {
  _totalMembers++;

  writeln(
      '''
      <div class="field"><h4 id="$typeName.${field.name}">
        <span class="show-code">Code</span>
      ''');

  // A null typeName means it's a top-level definition which is implicitly
  // static so doesn't need to annotate it.
  if (field.isStatic && (typeName != null)) {
    write('static ');
  }

  if (field.isFinal) {
    write('final ');
  } else if (field.type.name == 'Dynamic') {
    write('var ');
  }

  write(optionalTypeRef(field.type));
  write(
      '''
      <strong>${field.name}</strong> <a class="anchor-link"
          href="#$typeName.${field.name}"
          title="Permalink to $typeName.${field.name}">#</a>
      </h4>
      ''');

  docCode(field.span, showCode: true);
  writeln('</div>');
}

/**
 * Writes a type annotation for [type]. Will hyperlink it to that type's
 * documentation if possible.
 */
typeRef(Type type) {
  if (type.library != null) {
    var library = sanitize(type.library.name);
    return '<a href="${library}.html#${type.name}">${type.name}</a>';
  } else {
    return type.name;
  }
}

/**
 * Creates a linked string for an optional type annotation. Returns an empty
 * string if the type is Dynamic.
 */
optionalTypeRef(Type type) {
  if (type.name == 'Dynamic') {
    return '';
  } else {
    return typeRef(type) + ' ';
  }
}

/**
 * Documents the code contained within [span]. Will include the previous
 * Dartdoc associated with that span if found, and will include the syntax
 * highlighted code itself if desired.
 */
docCode(SourceSpan span, [bool showCode = false]) {
  if (span == null) return;

  writeln('<div class="doc">');
  var comment = findComment(span);
  if (comment != null) {
    writeln('<p>$comment</p>');
  }

  if (showCode) {
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
  var fileComments = _comments.putIfAbsent(file.filename,
    () => parseDocComments(file));

  return fileComments[position];
}

parseDocComments(SourceFile file) {
  var comments = <int, String>{};

  var tokenizer = new Tokenizer(file, false);
  var lastComment = null;

  while (true) {
    var token = tokenizer.next();
    if (token.kind == TokenKind.END_OF_FILE) break;

    if (token.kind == TokenKind.COMMENT) {
      var text = token.text;
      if (text.startsWith('/**')) {
        // Remember that we've encountered a doc comment.
        lastComment = stripComment(token.text);
      }
    } else if (token.kind == TokenKind.WHITESPACE) {
      // Ignore whitespace tokens.
    } else if (token.kind == TokenKind.HASH) {
      // Look for #library() to find the library comment.
      var next = tokenizer.next();
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
  var column = getSpanColumn(span);
  var lines = span.text.split('\n');
  // TODO(rnystrom): Dirty hack.
  for (int i = 1; i < lines.length; i++) {
    lines[i] = unindent(lines[i], column);
  }

  var code = Strings.join(lines, '\n');

  // Syntax highlight.
  return classifySource(new SourceFile('', code));
}

// TODO(rnystrom): Move into SourceSpan?
int getSpanColumn(SourceSpan span) {
  var line = span.file.getLine(span.start);
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
 * characters.
 */
// TODO(rnystrom): Should handle [name] and [:code:] in comments. Should also
// break empty lines into multiple paragraphs. Other formatting?
// See dart/compiler/java/com/google/dart/compiler/backend/doc for ideas.
// (/DartDocumentationVisitor.java#180)
stripComment(comment) {
  StringBuffer buf = new StringBuffer();

  for (var line in comment.split('\n')) {
    line = line.trim();
    if (line.startsWith('/**')) line = line.substring(3, line.length);
    if (line.endsWith('*/')) line = line.substring(0, line.length-2);
    line = line.trim();
    while (line.startsWith('*')) line = line.substring(1, line.length);
    line = line.trim();
    buf.add(line);
    buf.add(' ');
  }

  return buf.toString();
}