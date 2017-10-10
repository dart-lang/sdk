// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
library kernel.ast_to_text;

import '../ast.dart';
import '../import_table.dart';

class Namer<T> {
  int index = 0;
  final String prefix;
  final Map<T, String> map = <T, String>{};

  Namer(this.prefix);

  String getName(T key) => map.putIfAbsent(key, () => '$prefix${++index}');
}

class Disambiguator<T> {
  final Map<T, String> names = <T, String>{};
  final Set<String> usedNames = new Set<String>();

  String disambiguate(T key, String proposeName()) {
    return names.putIfAbsent(key, () {
      var proposedName = proposeName();
      if (usedNames.add(proposedName)) return proposedName;
      int i = 2;
      while (!usedNames.add('$proposedName$i')) {
        ++i;
      }
      return '$proposedName$i';
    });
  }
}

NameSystem globalDebuggingNames = new NameSystem();

String debugLibraryName(Library node) {
  return node == null
      ? 'null'
      : node.name ?? globalDebuggingNames.nameLibrary(node);
}

String debugClassName(Class node) {
  return node == null
      ? 'null'
      : node.name ?? globalDebuggingNames.nameClass(node);
}

String debugQualifiedClassName(Class node) {
  return debugLibraryName(node.enclosingLibrary) + '::' + debugClassName(node);
}

String debugMemberName(Member node) {
  return node.name?.name ?? globalDebuggingNames.nameMember(node);
}

String debugQualifiedMemberName(Member node) {
  if (node.enclosingClass != null) {
    return debugQualifiedClassName(node.enclosingClass) +
        '::' +
        debugMemberName(node);
  } else {
    return debugLibraryName(node.enclosingLibrary) +
        '::' +
        debugMemberName(node);
  }
}

String debugTypeParameterName(TypeParameter node) {
  return node.name ?? globalDebuggingNames.nameTypeParameter(node);
}

String debugQualifiedTypeParameterName(TypeParameter node) {
  if (node.parent is Class) {
    return debugQualifiedClassName(node.parent) +
        '::' +
        debugTypeParameterName(node);
  }
  if (node.parent is Member) {
    return debugQualifiedMemberName(node.parent) +
        '::' +
        debugTypeParameterName(node);
  }
  return debugTypeParameterName(node);
}

String debugVariableDeclarationName(VariableDeclaration node) {
  return node.name ?? globalDebuggingNames.nameVariable(node);
}

String debugNodeToString(Node node) {
  StringBuffer buffer = new StringBuffer();
  new Printer(buffer, syntheticNames: globalDebuggingNames).writeNode(node);
  return '$buffer';
}

String programToString(Program node) {
  StringBuffer buffer = new StringBuffer();
  new Printer(buffer, syntheticNames: new NameSystem()).writeProgramFile(node);
  return '$buffer';
}

class NameSystem {
  final Namer<VariableDeclaration> variables =
      new Namer<VariableDeclaration>('#t');
  final Namer<Member> members = new Namer<Member>('#m');
  final Namer<Class> classes = new Namer<Class>('#class');
  final Namer<Library> libraries = new Namer<Library>('#lib');
  final Namer<TypeParameter> typeParameters = new Namer<TypeParameter>('#T');
  final Namer<TreeNode> labels = new Namer<TreeNode>('#L');
  final Disambiguator<Library> prefixes = new Disambiguator<Library>();

  nameVariable(VariableDeclaration node) => variables.getName(node);
  nameMember(Member node) => members.getName(node);
  nameClass(Class node) => classes.getName(node);
  nameLibrary(Library node) => libraries.getName(node);
  nameTypeParameter(TypeParameter node) => typeParameters.getName(node);
  nameSwitchCase(SwitchCase node) => labels.getName(node);
  nameLabeledStatement(LabeledStatement node) => labels.getName(node);

  nameLibraryPrefix(Library node, {String proposedName}) {
    return prefixes.disambiguate(node, () {
      if (proposedName != null) return proposedName;
      if (node.name != null) return abbreviateName(node.name);
      if (node.importUri != null) {
        var path = node.importUri.hasEmptyPath
            ? '${node.importUri}'
            : node.importUri.pathSegments.last;
        if (path.endsWith('.dart')) {
          path = path.substring(0, path.length - '.dart'.length);
        }
        return abbreviateName(path);
      }
      return 'L';
    });
  }

  final RegExp punctuation = new RegExp('[.:]');

  String abbreviateName(String name) {
    int dot = name.lastIndexOf(punctuation);
    if (dot != -1) {
      name = name.substring(dot + 1);
    }
    if (name.length > 4) {
      return name.substring(0, 3);
    }
    return name;
  }
}

abstract class Annotator {
  String annotateVariable(Printer printer, VariableDeclaration node);
  String annotateReturn(Printer printer, FunctionNode node);
  String annotateField(Printer printer, Field node);
}

/// A quick and dirty ambiguous text printer.
class Printer extends Visitor<Null> {
  final NameSystem syntheticNames;
  final StringSink sink;
  final Annotator annotator;
  ImportTable importTable;
  int indentation = 0;
  int column = 0;
  bool showExternal;
  bool showOffsets;

  static int SPACE = 0;
  static int WORD = 1;
  static int SYMBOL = 2;
  int state = SPACE;

  Printer(this.sink,
      {NameSystem syntheticNames,
      this.showExternal,
      this.showOffsets: false,
      this.importTable,
      this.annotator})
      : this.syntheticNames = syntheticNames ?? new NameSystem();

  Printer._inner(Printer parent, this.importTable)
      : sink = parent.sink,
        syntheticNames = parent.syntheticNames,
        annotator = parent.annotator,
        showExternal = parent.showExternal,
        showOffsets = parent.showOffsets;

  bool shouldHighlight(Node node) {
    return false;
  }

  void startHighlight(Node node) {}
  void endHighlight(Node node) {}

  String getLibraryName(Library node) {
    return node.name ?? syntheticNames.nameLibrary(node);
  }

  String getLibraryReference(Library node) {
    if (node == null) return '<No Library>';
    if (importTable != null && importTable.getImportIndex(node) != -1) {
      return syntheticNames.nameLibraryPrefix(node);
    }
    return getLibraryName(node);
  }

  String getClassName(Class node) {
    return node.name ?? syntheticNames.nameClass(node);
  }

  String getClassReference(Class node) {
    if (node == null) return '<No Class>';
    String name = getClassName(node);
    String library = getLibraryReference(node.enclosingLibrary);
    return '$library::$name';
  }

  String getTypedefReference(Typedef node) {
    if (node == null) return '<No Typedef>';
    String library = getLibraryReference(node.enclosingLibrary);
    return '$library::${node.name}';
  }

  static final String emptyNameString = '•';
  static final Name emptyName = new Name(emptyNameString);

  Name getMemberName(Member node) {
    if (node.name?.name == '') return emptyName;
    if (node.name != null) return node.name;
    return new Name(syntheticNames.nameMember(node));
  }

  String getMemberReference(Member node) {
    if (node == null) return '<No Member>';
    String name = getMemberName(node).name;
    if (node.parent is Class) {
      String className = getClassReference(node.parent);
      return '$className::$name';
    } else {
      String library = getLibraryReference(node.enclosingLibrary);
      return '$library::$name';
    }
  }

  String getVariableName(VariableDeclaration node) {
    return node.name ?? syntheticNames.nameVariable(node);
  }

  String getVariableReference(VariableDeclaration node) {
    if (node == null) return '<No VariableDeclaration>';
    return getVariableName(node);
  }

  String getTypeParameterName(TypeParameter node) {
    return node.name ?? syntheticNames.nameTypeParameter(node);
  }

  String getTypeParameterReference(TypeParameter node) {
    if (node == null) return '<No TypeParameter>';
    String name = getTypeParameterName(node);
    if (node.parent is FunctionNode && node.parent.parent is Member) {
      String member = getMemberReference(node.parent.parent);
      return '$member::$name';
    } else if (node.parent is Class) {
      String className = getClassReference(node.parent);
      return '$className::$name';
    } else {
      return name; // Bound inside a function type.
    }
  }

  void writeLibraryFile(Library library) {
    writeAnnotationList(library.annotations);
    writeWord('library');
    if (library.name != null) {
      writeWord(library.name);
    }
    endLine(';');
    var imports = new LibraryImportTable(library);
    for (var library in imports.importedLibraries) {
      var importPath = imports.getImportPath(library);
      if (importPath == "") {
        var prefix =
            syntheticNames.nameLibraryPrefix(library, proposedName: 'self');
        endLine('import self as $prefix;');
      } else {
        var prefix = syntheticNames.nameLibraryPrefix(library);
        endLine('import "$importPath" as $prefix;');
      }
    }

    // TODO(scheglov): Do we want to print dependencies? dartbug.com/30224
    if (library.additionalExports.isNotEmpty) {
      write('additionalExports = (');
      for (var reference in library.additionalExports) {
        var node = reference.node;
        if (node is Class) {
          Library nodeLibrary = node.enclosingLibrary;
          String prefix = syntheticNames.nameLibraryPrefix(nodeLibrary);
          write(prefix + '::' + node.name);
        } else if (node is Field) {
          Library nodeLibrary = node.enclosingLibrary;
          String prefix = syntheticNames.nameLibraryPrefix(nodeLibrary);
          write(prefix + '::' + node.name.name);
        } else if (node is Procedure) {
          Library nodeLibrary = node.enclosingLibrary;
          String prefix = syntheticNames.nameLibraryPrefix(nodeLibrary);
          write(prefix + '::' + node.name.name);
        } else if (node is Typedef) {
          Library nodeLibrary = node.enclosingLibrary;
          String prefix = syntheticNames.nameLibraryPrefix(nodeLibrary);
          write(prefix + '::' + node.name);
        } else {
          throw new UnimplementedError('${node.runtimeType}');
        }
      }
      endLine(')');
    }

    endLine();
    var inner = new Printer._inner(this, imports);
    library.typedefs.forEach(inner.writeNode);
    library.classes.forEach(inner.writeNode);
    library.fields.forEach(inner.writeNode);
    library.procedures.forEach(inner.writeNode);
  }

  void writeProgramFile(Program program) {
    ImportTable imports = new ProgramImportTable(program);
    var inner = new Printer._inner(this, imports);
    writeWord('main');
    writeSpaced('=');
    inner.writeMemberReference(program.mainMethod);
    endLine(';');
    for (var library in program.libraries) {
      if (library.isExternal) {
        if (!showExternal) {
          continue;
        }
        writeWord('external');
      }
      writeAnnotationList(library.annotations);
      writeWord('library');
      if (library.name != null) {
        writeWord(library.name);
      }
      if (library.importUri != null) {
        writeSpaced('from');
        writeWord('"${library.importUri}"');
      }
      var prefix = syntheticNames.nameLibraryPrefix(library);
      writeSpaced('as');
      writeWord(prefix);
      endLine(' {');
      ++inner.indentation;
      library.dependencies.forEach(inner.writeNode);
      library.typedefs.forEach(inner.writeNode);
      library.classes.forEach(inner.writeNode);
      library.fields.forEach(inner.writeNode);
      library.procedures.forEach(inner.writeNode);
      --inner.indentation;
      endLine('}');
    }
  }

  int getPrecedence(TreeNode node) {
    return Precedence.of(node);
  }

  void write(String string) {
    sink.write(string);
    column += string.length;
  }

  void writeSpace([String string = ' ']) {
    write(string);
    state = SPACE;
  }

  void ensureSpace() {
    if (state != SPACE) writeSpace();
  }

  void writeSymbol(String string) {
    write(string);
    state = SYMBOL;
  }

  void writeSpaced(String string) {
    ensureSpace();
    write(string);
    writeSpace();
  }

  void writeComma([String string = ',']) {
    write(string);
    writeSpace();
  }

  void writeWord(String string) {
    if (string.isEmpty) return;
    ensureWordBoundary();
    write(string);
    state = WORD;
  }

  void ensureWordBoundary() {
    if (state == WORD) {
      writeSpace();
    }
  }

  void writeIndentation() {
    writeSpace('  ' * indentation);
  }

  void writeNode(Node node) {
    if (node == null) {
      writeSymbol("<Null>");
    } else {
      final highlight = shouldHighlight(node);
      if (highlight) {
        startHighlight(node);
      }

      if (showOffsets && node is TreeNode) {
        writeWord("[${node.fileOffset}]");
      }

      node.accept(this);

      if (highlight) {
        endHighlight(node);
      }
    }
  }

  void writeOptionalNode(Node node) {
    if (node != null) {
      node.accept(this);
    }
  }

  void writeAnnotatedType(DartType type, String annotation) {
    writeType(type);
    if (annotation != null) {
      write('/');
      write(annotation);
      state = WORD;
    }
  }

  void writeType(DartType type) {
    if (type == null) {
      print('<No DartType>');
    } else {
      type.accept(this);
    }
  }

  void writeOptionalType(DartType type) {
    if (type != null) {
      type.accept(this);
    }
  }

  visitSupertype(Supertype type) {
    if (type == null) {
      print('<No Supertype>');
    } else {
      writeClassReference(type.classNode);
      if (type.typeArguments.isNotEmpty) {
        writeSymbol('<');
        writeList(type.typeArguments, writeType);
        writeSymbol('>');
      }
    }
  }

  visitVectorType(VectorType type) {
    writeWord('Vector');
  }

  visitTypedefType(TypedefType type) {
    writeTypedefReference(type.typedefNode);
    if (type.typeArguments.isNotEmpty) {
      writeSymbol('<');
      writeList(type.typeArguments, writeType);
      writeSymbol('>');
    }
  }

  void writeModifier(bool isThere, String name) {
    if (isThere) {
      writeWord(name);
    }
  }

  void writeName(Name name) {
    if (name?.name == '') {
      writeWord(emptyNameString);
    } else {
      writeWord(name?.name ?? '<anon>'); // TODO: write library name
    }
  }

  void endLine([String string]) {
    if (string != null) {
      write(string);
    }
    write('\n');
    state = SPACE;
    column = 0;
  }

  void writeFunction(FunctionNode function,
      {name, List<Initializer> initializers, bool terminateLine: true}) {
    if (name is String) {
      writeWord(name);
    } else if (name is Name) {
      writeName(name);
    } else {
      assert(name == null);
    }
    writeTypeParameterList(function.typeParameters);
    writeParameterList(function.positionalParameters, function.namedParameters,
        function.requiredParameterCount);
    writeReturnType(
        function.returnType, annotator?.annotateReturn(this, function));
    if (initializers != null && initializers.isNotEmpty) {
      endLine();
      ++indentation;
      writeIndentation();
      writeComma(':');
      writeList(initializers, writeNode);
      --indentation;
    }
    if (function.asyncMarker != AsyncMarker.Sync) {
      writeSpaced(getAsyncMarkerKeyword(function.asyncMarker));
    }
    if (function.dartAsyncMarker != AsyncMarker.Sync &&
        function.dartAsyncMarker != function.asyncMarker) {
      writeSpaced("/* originally");
      writeSpaced(getAsyncMarkerKeyword(function.dartAsyncMarker));
      writeSpaced("*/");
    }
    if (function.body != null) {
      writeFunctionBody(function.body, terminateLine: terminateLine);
    } else if (terminateLine) {
      endLine(';');
    }
  }

  String getAsyncMarkerKeyword(AsyncMarker marker) {
    switch (marker) {
      case AsyncMarker.Sync:
        return 'sync';
      case AsyncMarker.SyncStar:
        return 'sync*';
      case AsyncMarker.Async:
        return 'async';
      case AsyncMarker.AsyncStar:
        return 'async*';
      case AsyncMarker.SyncYielding:
        return 'yielding';
      default:
        return '<Invalid async marker: $marker>';
    }
  }

  void writeFunctionBody(Statement body, {bool terminateLine: true}) {
    if (body is Block && body.statements.isEmpty) {
      ensureSpace();
      writeSymbol('{}');
      state = WORD;
      if (terminateLine) {
        endLine();
      }
    } else if (body is Block) {
      ensureSpace();
      endLine('{');
      ++indentation;
      body.statements.forEach(writeNode);
      --indentation;
      writeIndentation();
      writeSymbol('}');
      state = WORD;
      if (terminateLine) {
        endLine();
      }
    } else if (body is ReturnStatement && !terminateLine) {
      writeSpaced('=>');
      writeExpression(body.expression);
    } else {
      writeBody(body);
    }
  }

  void writeBody(Statement body) {
    if (body is Block) {
      endLine(' {');
      ++indentation;
      body.statements.forEach(writeNode);
      --indentation;
      writeIndentation();
      endLine('}');
    } else {
      endLine();
      ++indentation;
      writeNode(body);
      --indentation;
    }
  }

  void writeReturnType(DartType type, String annotation) {
    if (type == null) return;
    writeSpaced('→');
    writeAnnotatedType(type, annotation);
  }

  void writeTypeParameterList(List<TypeParameter> typeParameters) {
    if (typeParameters.isEmpty) return;
    writeSymbol('<');
    writeList(typeParameters, writeNode);
    writeSymbol('>');
    state = WORD; // Ensure space if not followed by another symbol.
  }

  void writeParameterList(List<VariableDeclaration> positional,
      List<VariableDeclaration> named, int requiredParameterCount) {
    writeSymbol('(');
    writeList(
        positional.take(requiredParameterCount), writeVariableDeclaration);
    if (requiredParameterCount < positional.length) {
      if (requiredParameterCount > 0) {
        writeComma();
      }
      writeSymbol('[');
      writeList(
          positional.skip(requiredParameterCount), writeVariableDeclaration);
      writeSymbol(']');
    }
    if (named.isNotEmpty) {
      if (positional.isNotEmpty) {
        writeComma();
      }
      writeSymbol('{');
      writeList(named, writeVariableDeclaration);
      writeSymbol('}');
    }
    writeSymbol(')');
  }

  void writeList<T>(Iterable<T> nodes, void callback(T x),
      {String separator: ','}) {
    bool first = true;
    for (var node in nodes) {
      if (first) {
        first = false;
      } else {
        writeComma(separator);
      }
      callback(node);
    }
  }

  void writeMemberReference(Member member) {
    writeWord(getMemberReference(member));
  }

  void writeClassReference(Class classNode) {
    writeWord(getClassReference(classNode));
  }

  void writeTypedefReference(Typedef typedefNode) {
    writeWord(getTypedefReference(typedefNode));
  }

  void writeLibraryReference(Library library) {
    writeWord(getLibraryReference(library));
  }

  void writeVariableReference(VariableDeclaration variable) {
    final highlight = shouldHighlight(variable);
    if (highlight) {
      startHighlight(variable);
    }
    writeWord(getVariableReference(variable));
    if (highlight) {
      endHighlight(variable);
    }
  }

  void writeTypeParameterReference(TypeParameter node) {
    writeWord(getTypeParameterReference(node));
  }

  void writeExpression(Expression node, [int minimumPrecedence]) {
    final highlight = shouldHighlight(node);
    if (highlight) {
      startHighlight(node);
    }
    if (showOffsets) writeWord("[${node.fileOffset}]");
    bool needsParenteses = false;
    if (minimumPrecedence != null && getPrecedence(node) < minimumPrecedence) {
      needsParenteses = true;
      writeSymbol('(');
    }
    writeNode(node);
    if (needsParenteses) {
      writeSymbol(')');
    }
    if (highlight) {
      endHighlight(node);
    }
  }

  void writeAnnotation(Expression node) {
    writeSymbol('@');
    if (node is ConstructorInvocation) {
      writeMemberReference(node.target);
      visitArguments(node.arguments);
    } else {
      writeExpression(node);
    }
  }

  void writeAnnotationList(List<Expression> nodes) {
    for (Expression node in nodes) {
      writeIndentation();
      writeAnnotation(node);
      endLine();
    }
  }

  visitLibrary(Library node) {}

  visitField(Field node) {
    writeAnnotationList(node.annotations);
    writeIndentation();
    writeModifier(node.isStatic, 'static');
    writeModifier(node.isCovariant, 'covariant');
    writeModifier(node.isGenericCovariantImpl, 'generic-covariant-impl');
    writeModifier(
        node.isGenericCovariantInterface, 'generic-covariant-interface');
    writeModifier(node.isFinal, 'final');
    writeModifier(node.isConst, 'const');
    // Only show implicit getter/setter modifiers in cases where they are
    // out of the ordinary.
    if (node.isStatic) {
      writeModifier(node.hasImplicitGetter, '[getter]');
      writeModifier(node.hasImplicitSetter, '[setter]');
    } else {
      writeModifier(!node.hasImplicitGetter, '[no-getter]');
      if (node.isFinal) {
        writeModifier(node.hasImplicitSetter, '[setter]');
      } else {
        writeModifier(!node.hasImplicitSetter, '[no-setter]');
      }
    }
    writeWord('field');
    writeSpace();
    writeAnnotatedType(node.type, annotator?.annotateField(this, node));
    writeName(getMemberName(node));
    if (node.initializer != null) {
      writeSpaced('=');
      writeExpression(node.initializer);
    }
    if ((node.enclosingClass == null &&
            node.enclosingLibrary.fileUri != node.fileUri) ||
        (node.enclosingClass != null &&
            node.enclosingClass.fileUri != node.fileUri)) {
      writeWord("/* from ${node.fileUri} */");
    }
    endLine(';');
  }

  visitProcedure(Procedure node) {
    writeAnnotationList(node.annotations);
    writeIndentation();
    writeModifier(node.isExternal, 'external');
    writeModifier(node.isStatic, 'static');
    writeModifier(node.isAbstract, 'abstract');
    writeModifier(node.isForwardingStub, 'forwarding-stub');
    writeWord(procedureKindToString(node.kind));
    if ((node.enclosingClass == null &&
            node.enclosingLibrary.fileUri != node.fileUri) ||
        (node.enclosingClass != null &&
            node.enclosingClass.fileUri != node.fileUri)) {
      writeWord("/* from ${node.fileUri} */");
    }
    writeFunction(node.function, name: getMemberName(node));
  }

  visitConstructor(Constructor node) {
    writeAnnotationList(node.annotations);
    writeIndentation();
    writeModifier(node.isExternal, 'external');
    writeModifier(node.isConst, 'const');
    writeModifier(node.isSyntheticDefault, 'default');
    writeWord('constructor');
    writeFunction(node.function,
        name: node.name, initializers: node.initializers);
  }

  visitClass(Class node) {
    writeAnnotationList(node.annotations);
    writeIndentation();
    writeModifier(node.isAbstract, 'abstract');
    writeWord('class');
    writeWord(getClassName(node));
    writeTypeParameterList(node.typeParameters);
    if (node.isMixinApplication) {
      writeSpaced('=');
      visitSupertype(node.supertype);
      writeSpaced('with');
      visitSupertype(node.mixedInType);
    } else if (node.supertype != null) {
      writeSpaced('extends');
      visitSupertype(node.supertype);
    }
    if (node.implementedTypes.isNotEmpty) {
      writeSpaced('implements');
      writeList(node.implementedTypes, visitSupertype);
    }
    var endLineString = ' {';
    if (node.enclosingLibrary.fileUri != node.fileUri) {
      endLineString += ' // from ${node.fileUri}';
    }
    endLine(endLineString);
    ++indentation;
    node.fields.forEach(writeNode);
    node.constructors.forEach(writeNode);
    node.procedures.forEach(writeNode);
    --indentation;
    writeIndentation();
    endLine('}');
  }

  visitTypedef(Typedef node) {
    writeAnnotationList(node.annotations);
    writeIndentation();
    writeWord('typedef');
    writeWord(node.name);
    writeTypeParameterList(node.typeParameters);
    writeSpaced('=');
    writeNode(node.type);
    endLine(';');
  }

  visitInvalidExpression(InvalidExpression node) {
    writeWord('invalid-expression');
  }

  visitMethodInvocation(MethodInvocation node) {
    writeExpression(node.receiver, Precedence.PRIMARY);
    writeSymbol('.');
    writeInterfaceTarget(node.name, node.interfaceTarget);
    writeNode(node.arguments);
  }

  visitDirectMethodInvocation(DirectMethodInvocation node) {
    writeExpression(node.receiver, Precedence.PRIMARY);
    writeSymbol('.{=');
    writeMemberReference(node.target);
    writeSymbol('}');
    writeNode(node.arguments);
  }

  visitSuperMethodInvocation(SuperMethodInvocation node) {
    writeWord('super');
    writeSymbol('.');
    writeInterfaceTarget(node.name, node.interfaceTarget);
    writeNode(node.arguments);
  }

  visitStaticInvocation(StaticInvocation node) {
    writeModifier(node.isConst, 'const');
    writeMemberReference(node.target);
    writeNode(node.arguments);
  }

  visitConstructorInvocation(ConstructorInvocation node) {
    writeWord(node.isConst ? 'const' : 'new');
    writeMemberReference(node.target);
    writeNode(node.arguments);
  }

  visitNot(Not node) {
    writeSymbol('!');
    writeExpression(node.operand, Precedence.PREFIX);
  }

  visitLogicalExpression(LogicalExpression node) {
    int precedence = Precedence.binaryPrecedence[node.operator];
    writeExpression(node.left, precedence);
    writeSpaced(node.operator);
    writeExpression(node.right, precedence + 1);
  }

  visitConditionalExpression(ConditionalExpression node) {
    writeExpression(node.condition, Precedence.LOGICAL_OR);
    ensureSpace();
    write('?');
    writeStaticType(node.staticType);
    writeSpace();
    writeExpression(node.then);
    writeSpaced(':');
    writeExpression(node.otherwise);
  }

  String getEscapedCharacter(int codeUnit) {
    switch (codeUnit) {
      case 9:
        return r'\t';
      case 10:
        return r'\n';
      case 11:
        return r'\v';
      case 12:
        return r'\f';
      case 13:
        return r'\r';
      case 34:
        return r'\"';
      case 36:
        return r'\$';
      case 92:
        return r'\\';
      default:
        if (codeUnit < 32 || codeUnit > 126) {
          return r'\u' + '$codeUnit'.padLeft(4, '0');
        } else {
          return null;
        }
    }
  }

  String escapeString(String string) {
    StringBuffer buffer;
    for (int i = 0; i < string.length; ++i) {
      String character = getEscapedCharacter(string.codeUnitAt(i));
      if (character != null) {
        buffer ??= new StringBuffer(string.substring(0, i));
        buffer.write(character);
      } else {
        buffer?.write(string[i]);
      }
    }
    return buffer == null ? string : buffer.toString();
  }

  visitStringConcatenation(StringConcatenation node) {
    if (state == WORD) {
      writeSpace();
    }
    write('"');
    for (var part in node.expressions) {
      if (part is StringLiteral) {
        writeSymbol(escapeString(part.value));
      } else {
        writeSymbol(r'${');
        writeExpression(part);
        writeSymbol('}');
      }
    }
    write('"');
    state = WORD;
  }

  visitIsExpression(IsExpression node) {
    writeExpression(node.operand, Precedence.BITWISE_OR);
    writeSpaced('is');
    writeType(node.type);
  }

  visitAsExpression(AsExpression node) {
    writeExpression(node.operand, Precedence.BITWISE_OR);
    writeSpaced('as');
    writeType(node.type);
  }

  visitSymbolLiteral(SymbolLiteral node) {
    writeSymbol('#');
    writeWord(node.value);
  }

  visitTypeLiteral(TypeLiteral node) {
    writeType(node.type);
  }

  visitThisExpression(ThisExpression node) {
    writeWord('this');
  }

  visitRethrow(Rethrow node) {
    writeWord('rethrow');
  }

  visitThrow(Throw node) {
    writeWord('throw');
    writeSpace();
    writeExpression(node.expression);
  }

  visitListLiteral(ListLiteral node) {
    if (node.isConst) {
      writeWord('const');
      writeSpace();
    }
    if (node.typeArgument != null) {
      writeSymbol('<');
      writeType(node.typeArgument);
      writeSymbol('>');
    }
    writeSymbol('[');
    writeList(node.expressions, writeNode);
    writeSymbol(']');
  }

  visitMapLiteral(MapLiteral node) {
    if (node.isConst) {
      writeWord('const');
      writeSpace();
    }
    if (node.keyType != null) {
      writeSymbol('<');
      writeList([node.keyType, node.valueType], writeType);
      writeSymbol('>');
    }
    writeSymbol('{');
    writeList(node.entries, writeNode);
    writeSymbol('}');
  }

  visitMapEntry(MapEntry node) {
    writeExpression(node.key);
    writeComma(':');
    writeExpression(node.value);
  }

  visitAwaitExpression(AwaitExpression node) {
    writeWord('await');
    writeExpression(node.operand);
  }

  visitFunctionExpression(FunctionExpression node) {
    writeFunction(node.function, terminateLine: false);
  }

  visitStringLiteral(StringLiteral node) {
    writeWord('"${escapeString(node.value)}"');
  }

  visitIntLiteral(IntLiteral node) {
    writeWord('${node.value}');
  }

  visitDoubleLiteral(DoubleLiteral node) {
    writeWord('${node.value}');
  }

  visitBoolLiteral(BoolLiteral node) {
    writeWord('${node.value}');
  }

  visitNullLiteral(NullLiteral node) {
    writeWord('null');
  }

  visitLet(Let node) {
    writeWord('let');
    writeVariableDeclaration(node.variable);
    writeSpaced('in');
    writeExpression(node.body);
  }

  visitLoadLibrary(LoadLibrary node) {
    writeWord('LoadLibrary');
    writeSymbol('(');
    writeWord(node.import.name);
    writeSymbol(')');
    state = WORD;
  }

  visitCheckLibraryIsLoaded(CheckLibraryIsLoaded node) {
    writeWord('CheckLibraryIsLoaded');
    writeSymbol('(');
    writeWord(node.import.name);
    writeSymbol(')');
    state = WORD;
  }

  visitVectorCreation(VectorCreation node) {
    writeWord('MakeVector');
    writeSymbol('(');
    writeWord(node.length.toString());
    writeSymbol(')');
  }

  visitVectorGet(VectorGet node) {
    writeExpression(node.vectorExpression);
    writeSymbol('[');
    writeWord(node.index.toString());
    writeSymbol(']');
  }

  visitVectorSet(VectorSet node) {
    writeExpression(node.vectorExpression);
    writeSymbol('[');
    writeWord(node.index.toString());
    writeSymbol(']');
    writeSpaced('=');
    writeExpression(node.value);
  }

  visitVectorCopy(VectorCopy node) {
    writeWord('CopyVector');
    writeSymbol('(');
    writeExpression(node.vectorExpression);
    writeSymbol(')');
  }

  visitClosureCreation(ClosureCreation node) {
    writeWord('MakeClosure');
    writeSymbol('<');
    writeNode(node.functionType);
    if (node.typeArguments.length > 0) writeSymbol(', ');
    writeList(node.typeArguments, writeType);
    writeSymbol('>');
    writeSymbol('(');
    writeMemberReference(node.topLevelFunction);
    writeComma();
    writeExpression(node.contextVector);
    writeSymbol(')');
  }

  visitLibraryDependency(LibraryDependency node) {
    writeIndentation();
    writeWord(node.isImport ? 'import' : 'export');
    var uriString = '${node.targetLibrary.importUri}';
    writeWord('"$uriString"');
    if (node.isDeferred) {
      writeWord('deferred');
    }
    if (node.name != null) {
      writeWord('as');
      writeWord(node.name);
    }
    endLine(';');
  }

  defaultExpression(Expression node) {
    writeWord('${node.runtimeType}');
  }

  visitVariableGet(VariableGet node) {
    writeVariableReference(node.variable);
    if (node.promotedType != null) {
      writeSymbol('{');
      writeNode(node.promotedType);
      writeSymbol('}');
      state = WORD;
    }
  }

  visitVariableSet(VariableSet node) {
    writeVariableReference(node.variable);
    writeSpaced('=');
    writeExpression(node.value);
  }

  void writeInterfaceTarget(Name name, Member target) {
    if (target != null) {
      writeSymbol('{');
      writeMemberReference(target);
      writeSymbol('}');
    } else {
      writeName(name);
    }
  }

  void writeStaticType(DartType type) {
    if (type != null) {
      writeSymbol('{');
      writeType(type);
      writeSymbol('}');
    }
  }

  visitPropertyGet(PropertyGet node) {
    writeExpression(node.receiver, Precedence.PRIMARY);
    writeSymbol('.');
    writeInterfaceTarget(node.name, node.interfaceTarget);
  }

  visitPropertySet(PropertySet node) {
    writeExpression(node.receiver, Precedence.PRIMARY);
    writeSymbol('.');
    writeInterfaceTarget(node.name, node.interfaceTarget);
    writeSpaced('=');
    writeExpression(node.value);
  }

  visitSuperPropertyGet(SuperPropertyGet node) {
    writeWord('super');
    writeSymbol('.');
    writeInterfaceTarget(node.name, node.interfaceTarget);
  }

  visitSuperPropertySet(SuperPropertySet node) {
    writeWord('super');
    writeSymbol('.');
    writeInterfaceTarget(node.name, node.interfaceTarget);
    writeSpaced('=');
    writeExpression(node.value);
  }

  visitDirectPropertyGet(DirectPropertyGet node) {
    writeExpression(node.receiver, Precedence.PRIMARY);
    writeSymbol('.{=');
    writeMemberReference(node.target);
    writeSymbol('}');
  }

  visitDirectPropertySet(DirectPropertySet node) {
    writeExpression(node.receiver, Precedence.PRIMARY);
    writeSymbol('.{=');
    writeMemberReference(node.target);
    writeSymbol('}');
    writeSpaced('=');
    writeExpression(node.value);
  }

  visitStaticGet(StaticGet node) {
    writeMemberReference(node.target);
  }

  visitStaticSet(StaticSet node) {
    writeMemberReference(node.target);
    writeSpaced('=');
    writeExpression(node.value);
  }

  visitInvalidStatement(InvalidStatement node) {
    writeIndentation();
    endLine('invalid-statement;');
  }

  visitExpressionStatement(ExpressionStatement node) {
    writeIndentation();
    writeExpression(node.expression);
    endLine(';');
  }

  visitBlock(Block node) {
    writeIndentation();
    if (node.statements.isEmpty) {
      endLine('{}');
      return null;
    }
    endLine('{');
    ++indentation;
    node.statements.forEach(writeNode);
    --indentation;
    writeIndentation();
    endLine('}');
  }

  visitEmptyStatement(EmptyStatement node) {
    writeIndentation();
    endLine(';');
  }

  visitAssertStatement(AssertStatement node) {
    writeIndentation();
    writeWord('assert');
    writeSymbol('(');
    writeExpression(node.condition);
    if (node.message != null) {
      writeComma();
      writeExpression(node.message);
    }
    endLine(');');
  }

  visitLabeledStatement(LabeledStatement node) {
    writeIndentation();
    writeWord(syntheticNames.nameLabeledStatement(node));
    endLine(':');
    writeNode(node.body);
  }

  visitBreakStatement(BreakStatement node) {
    writeIndentation();
    writeWord('break');
    writeWord(syntheticNames.nameLabeledStatement(node.target));
    endLine(';');
  }

  visitWhileStatement(WhileStatement node) {
    writeIndentation();
    writeSpaced('while');
    writeSymbol('(');
    writeExpression(node.condition);
    writeSymbol(')');
    writeBody(node.body);
  }

  visitDoStatement(DoStatement node) {
    writeIndentation();
    writeWord('do');
    writeBody(node.body);
    writeIndentation();
    writeSpaced('while');
    writeSymbol('(');
    writeExpression(node.condition);
    endLine(')');
  }

  visitForStatement(ForStatement node) {
    writeIndentation();
    writeSpaced('for');
    writeSymbol('(');
    writeList(node.variables, writeVariableDeclaration);
    writeComma(';');
    if (node.condition != null) {
      writeExpression(node.condition);
    }
    writeComma(';');
    writeList(node.updates, writeExpression);
    writeSymbol(')');
    writeBody(node.body);
  }

  visitForInStatement(ForInStatement node) {
    writeIndentation();
    if (node.isAsync) {
      writeSpaced('await');
    }
    writeSpaced('for');
    writeSymbol('(');
    writeVariableDeclaration(node.variable, useVarKeyword: true);
    writeSpaced('in');
    writeExpression(node.iterable);
    writeSymbol(')');
    writeBody(node.body);
  }

  visitSwitchStatement(SwitchStatement node) {
    writeIndentation();
    writeWord('switch');
    writeSymbol('(');
    writeExpression(node.expression);
    endLine(') {');
    ++indentation;
    node.cases.forEach(writeNode);
    --indentation;
    writeIndentation();
    endLine('}');
  }

  visitSwitchCase(SwitchCase node) {
    String label = syntheticNames.nameSwitchCase(node);
    writeIndentation();
    writeWord(label);
    endLine(':');
    for (var expression in node.expressions) {
      writeIndentation();
      writeWord('case');
      writeExpression(expression);
      endLine(':');
    }
    if (node.isDefault) {
      writeIndentation();
      writeWord('default');
      endLine(':');
    }
    ++indentation;
    writeNode(node.body);
    --indentation;
  }

  visitContinueSwitchStatement(ContinueSwitchStatement node) {
    writeIndentation();
    writeWord('continue');
    writeWord(syntheticNames.nameSwitchCase(node.target));
    endLine(';');
  }

  visitIfStatement(IfStatement node) {
    writeIndentation();
    writeWord('if');
    writeSymbol('(');
    writeExpression(node.condition);
    writeSymbol(')');
    writeBody(node.then);
    if (node.otherwise != null) {
      writeIndentation();
      writeWord('else');
      writeBody(node.otherwise);
    }
  }

  visitReturnStatement(ReturnStatement node) {
    writeIndentation();
    writeWord('return');
    if (node.expression != null) {
      writeSpace();
      writeExpression(node.expression);
    }
    endLine(';');
  }

  visitTryCatch(TryCatch node) {
    writeIndentation();
    writeWord('try');
    writeBody(node.body);
    node.catches.forEach(writeNode);
  }

  visitCatch(Catch node) {
    writeIndentation();
    if (node.guard != null) {
      writeWord('on');
      writeType(node.guard);
      writeSpace();
    }
    writeWord('catch');
    writeSymbol('(');
    if (node.exception != null) {
      writeVariableDeclaration(node.exception);
    } else {
      writeWord('no-exception-var');
    }
    if (node.stackTrace != null) {
      writeComma();
      writeVariableDeclaration(node.stackTrace);
    }
    writeSymbol(')');
    writeBody(node.body);
  }

  visitTryFinally(TryFinally node) {
    writeIndentation();
    writeWord('try');
    writeBody(node.body);
    writeIndentation();
    writeWord('finally');
    writeBody(node.finalizer);
  }

  visitYieldStatement(YieldStatement node) {
    writeIndentation();
    if (node.isYieldStar) {
      writeWord('yield*');
    } else if (node.isNative) {
      writeWord('[yield]');
    } else {
      writeWord('yield');
    }
    writeExpression(node.expression);
    endLine(';');
  }

  visitVariableDeclaration(VariableDeclaration node) {
    writeIndentation();
    writeVariableDeclaration(node, useVarKeyword: true);
    endLine(';');
  }

  visitFunctionDeclaration(FunctionDeclaration node) {
    writeIndentation();
    writeWord('function');
    if (node.function != null) {
      writeFunction(node.function, name: getVariableName(node.variable));
    } else {
      writeWord(getVariableName(node.variable));
      endLine('...;');
    }
  }

  void writeVariableDeclaration(VariableDeclaration node,
      {bool useVarKeyword: false}) {
    if (showOffsets) writeWord("[${node.fileOffset}]");
    writeAnnotationList(node.annotations);
    writeModifier(node.isCovariant, 'covariant');
    writeModifier(node.isGenericCovariantImpl, 'generic-covariant-impl');
    writeModifier(
        node.isGenericCovariantInterface, 'generic-covariant-interface');
    writeModifier(node.isFinal, 'final');
    writeModifier(node.isConst, 'const');
    if (node.type != null) {
      writeAnnotatedType(node.type, annotator?.annotateVariable(this, node));
    }
    if (useVarKeyword && !node.isFinal && !node.isConst && node.type == null) {
      writeWord('var');
    }
    writeWord(getVariableName(node));
    if (node.initializer != null) {
      writeSpaced('=');
      writeExpression(node.initializer);
    }
  }

  visitArguments(Arguments node) {
    if (node.types.isNotEmpty) {
      writeSymbol('<');
      writeList(node.types, writeType);
      writeSymbol('>');
    }
    writeSymbol('(');
    var allArgs =
        <List<TreeNode>>[node.positional, node.named].expand((x) => x);
    writeList(allArgs, writeNode);
    writeSymbol(')');
  }

  visitNamedExpression(NamedExpression node) {
    writeWord(node.name);
    writeComma(':');
    writeExpression(node.value);
  }

  defaultStatement(Statement node) {
    writeIndentation();
    endLine('${node.runtimeType}');
  }

  visitInvalidInitializer(InvalidInitializer node) {
    writeWord('invalid-initializer');
  }

  visitFieldInitializer(FieldInitializer node) {
    writeMemberReference(node.field);
    writeSpaced('=');
    writeExpression(node.value);
  }

  visitSuperInitializer(SuperInitializer node) {
    writeWord('super');
    writeMemberReference(node.target);
    writeNode(node.arguments);
  }

  visitRedirectingInitializer(RedirectingInitializer node) {
    writeWord('this');
    writeMemberReference(node.target);
    writeNode(node.arguments);
  }

  visitLocalInitializer(LocalInitializer node) {
    writeVariableDeclaration(node.variable);
  }

  defaultInitializer(Initializer node) {
    writeIndentation();
    endLine(': ${node.runtimeType}');
  }

  visitInvalidType(InvalidType node) {
    writeWord('invalid-type');
  }

  visitDynamicType(DynamicType node) {
    writeWord('dynamic');
  }

  visitVoidType(VoidType node) {
    writeWord('void');
  }

  visitInterfaceType(InterfaceType node) {
    writeClassReference(node.classNode);
    if (node.typeArguments.isNotEmpty) {
      writeSymbol('<');
      writeList(node.typeArguments, writeType);
      writeSymbol('>');
      state = WORD; // Disallow a word immediately after the '>'.
    }
  }

  visitFunctionType(FunctionType node) {
    if (state == WORD) {
      ensureSpace();
    }
    writeTypeParameterList(node.typeParameters);
    writeSymbol('(');
    var positional = node.positionalParameters;
    writeList(positional.take(node.requiredParameterCount), writeType);
    if (node.requiredParameterCount < positional.length) {
      if (node.requiredParameterCount > 0) {
        writeComma();
      }
      writeSymbol('[');
      writeList(positional.skip(node.requiredParameterCount), writeType);
      writeSymbol(']');
    }
    if (node.namedParameters.isNotEmpty) {
      if (node.positionalParameters.isNotEmpty) {
        writeComma();
      }
      writeSymbol('{');
      writeList(node.namedParameters, visitNamedType);
      writeSymbol('}');
    }
    writeSymbol(')');
    writeSpaced('→');
    writeType(node.returnType);
  }

  visitNamedType(NamedType node) {
    writeWord(node.name);
    writeSymbol(':');
    writeSpace();
    writeType(node.type);
  }

  visitTypeParameterType(TypeParameterType node) {
    writeTypeParameterReference(node.parameter);
    if (node.promotedBound != null) {
      writeSpace();
      writeWord('extends');
      writeSpace();
      writeType(node.promotedBound);
    }
  }

  visitTypeParameter(TypeParameter node) {
    writeModifier(node.isGenericCovariantImpl, 'generic-covariant-impl');
    writeModifier(
        node.isGenericCovariantInterface, 'generic-covariant-interface');
    writeAnnotationList(node.annotations);
    writeWord(getTypeParameterName(node));
    writeSpaced('extends');
    writeType(node.bound);
  }

  defaultNode(Node node) {
    write('<${node.runtimeType}>');
  }
}

class Precedence extends ExpressionVisitor<int> {
  static final Precedence instance = new Precedence();

  static int of(Expression node) => node.accept(instance);

  static const int EXPRESSION = 1;
  static const int CONDITIONAL = 2;
  static const int LOGICAL_NULL_AWARE = 3;
  static const int LOGICAL_OR = 4;
  static const int LOGICAL_AND = 5;
  static const int EQUALITY = 6;
  static const int RELATIONAL = 7;
  static const int BITWISE_OR = 8;
  static const int BITWISE_XOR = 9;
  static const int BITWISE_AND = 10;
  static const int SHIFT = 11;
  static const int ADDITIVE = 12;
  static const int MULTIPLICATIVE = 13;
  static const int PREFIX = 14;
  static const int POSTFIX = 15;
  static const int TYPE_LITERAL = 19;
  static const int PRIMARY = 20;
  static const int CALLEE = 21;

  static const Map<String, int> binaryPrecedence = const {
    '&&': LOGICAL_AND,
    '||': LOGICAL_OR,
    '??': LOGICAL_NULL_AWARE,
    '==': EQUALITY,
    '!=': EQUALITY,
    '>': RELATIONAL,
    '>=': RELATIONAL,
    '<': RELATIONAL,
    '<=': RELATIONAL,
    '|': BITWISE_OR,
    '^': BITWISE_XOR,
    '&': BITWISE_AND,
    '>>': SHIFT,
    '<<': SHIFT,
    '+': ADDITIVE,
    '-': ADDITIVE,
    '*': MULTIPLICATIVE,
    '%': MULTIPLICATIVE,
    '/': MULTIPLICATIVE,
    '~/': MULTIPLICATIVE,
    null: EXPRESSION,
  };

  static bool isAssociativeBinaryOperator(int precedence) {
    return precedence != EQUALITY && precedence != RELATIONAL;
  }

  int defaultExpression(Expression node) => EXPRESSION;
  int visitInvalidExpression(InvalidExpression node) => CALLEE;
  int visitMethodInvocation(MethodInvocation node) => CALLEE;
  int visitSuperMethodInvocation(SuperMethodInvocation node) => CALLEE;
  int visitDirectMethodInvocation(DirectMethodInvocation node) => CALLEE;
  int visitStaticInvocation(StaticInvocation node) => CALLEE;
  int visitConstructorInvocation(ConstructorInvocation node) => CALLEE;
  int visitNot(Not node) => PREFIX;
  int visitLogicalExpression(LogicalExpression node) =>
      binaryPrecedence[node.operator];
  int visitConditionalExpression(ConditionalExpression node) => CONDITIONAL;
  int visitStringConcatenation(StringConcatenation node) => PRIMARY;
  int visitIsExpression(IsExpression node) => RELATIONAL;
  int visitAsExpression(AsExpression node) => RELATIONAL;
  int visitSymbolLiteral(SymbolLiteral node) => PRIMARY;
  int visitTypeLiteral(TypeLiteral node) => PRIMARY;
  int visitThisExpression(ThisExpression node) => CALLEE;
  int visitRethrow(Rethrow node) => PRIMARY;
  int visitThrow(Throw node) => EXPRESSION;
  int visitListLiteral(ListLiteral node) => PRIMARY;
  int visitMapLiteral(MapLiteral node) => PRIMARY;
  int visitAwaitExpression(AwaitExpression node) => PREFIX;
  int visitFunctionExpression(FunctionExpression node) => PRIMARY;
  int visitStringLiteral(StringLiteral node) => CALLEE;
  int visitIntLiteral(IntLiteral node) => CALLEE;
  int visitDoubleLiteral(DoubleLiteral node) => CALLEE;
  int visitBoolLiteral(BoolLiteral node) => CALLEE;
  int visitNullLiteral(NullLiteral node) => CALLEE;
  int visitVariableGet(VariableGet node) => PRIMARY;
  int visitVariableSet(VariableSet node) => EXPRESSION;
  int visitPropertyGet(PropertyGet node) => PRIMARY;
  int visitPropertySet(PropertySet node) => EXPRESSION;
  int visitSuperPropertyGet(SuperPropertyGet node) => PRIMARY;
  int visitSuperPropertySet(SuperPropertySet node) => EXPRESSION;
  int visitDirectPropertyGet(DirectPropertyGet node) => PRIMARY;
  int visitDirectPropertySet(DirectPropertySet node) => EXPRESSION;
  int visitStaticGet(StaticGet node) => PRIMARY;
  int visitStaticSet(StaticSet node) => EXPRESSION;
  int visitLet(Let node) => EXPRESSION;
}

String procedureKindToString(ProcedureKind kind) {
  switch (kind) {
    case ProcedureKind.Method:
      return 'method';
    case ProcedureKind.Getter:
      return 'get';
    case ProcedureKind.Setter:
      return 'set';
    case ProcedureKind.Operator:
      return 'operator';
    case ProcedureKind.Factory:
      return 'factory';
  }
  throw 'illegal ProcedureKind: $kind';
}

class ExpressionPrinter {
  final Printer writeer;
  final int minimumPrecedence;

  ExpressionPrinter(this.writeer, this.minimumPrecedence);
}
