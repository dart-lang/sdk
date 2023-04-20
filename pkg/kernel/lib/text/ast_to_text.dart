// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library kernel.ast_to_text;

import 'dart:core';
import 'dart:convert' show json;

import '../ast.dart';
import '../import_table.dart';
import '../src/text_util.dart';

abstract class Namer<T> {
  int index = 0;
  final Map<T, String> map = <T, String>{};

  String getName(T key) => map.putIfAbsent(key, () => '$prefix${++index}');

  String get prefix;
}

class NormalNamer<T> extends Namer<T> {
  @override
  final String prefix;

  NormalNamer(this.prefix);
}

class ConstantNamer extends RecursiveVisitor with Namer<Constant> {
  @override
  final String prefix;

  ConstantNamer(this.prefix);

  @override
  String getName(Constant constant) {
    if (!map.containsKey(constant)) {
      // When printing a non-fully linked kernel AST (i.e. some [Reference]s
      // are not bound) to text, we need to avoid dereferencing any
      // references.
      //
      // The normal visitor API causes references to be dereferenced in order
      // to call the `visit<name>(<name>)` / `visit<name>Reference(<name>)`.
      //
      // We therefore handle any subclass of [Constant] which has [Reference]s
      // specially here.
      //
      if (constant is InstanceConstant) {
        // Avoid visiting `InstanceConstant.classReference`.
        for (final Constant value in constant.fieldValues.values) {
          // Name everything in post-order visit of DAG.
          getName(value);
        }
      } else if (constant is StaticTearOffConstant) {
        // We only care about naming the constants themselves. [TearOffConstant]
        // has no Constant children.
        // Avoid visiting `TearOffConstant.procedureReference`.
      } else {
        // Name everything in post-order visit of DAG.
        constant.visitChildren(this);
      }
    }
    return super.getName(constant);
  }

  @override
  void defaultConstantReference(Constant constant) {
    getName(constant);
  }

  @override
  void defaultDartType(DartType type) {
    // No need to recurse into dart types, we only care about naming the
    // constants themselves.
  }
}

class Disambiguator<T, U> {
  final Map<T, String> namesT = <T, String>{};
  final Map<U, String> namesU = <U, String>{};
  final Set<String> usedNames = new Set<String>();

  String disambiguate(T? key1, U? key2, String proposeName()) {
    String getNewName() {
      String proposedName = proposeName();
      if (usedNames.add(proposedName)) return proposedName;
      int i = 2;
      while (!usedNames.add('$proposedName$i')) {
        ++i;
      }
      return '$proposedName$i';
    }

    if (key1 != null) {
      String? result = namesT[key1];
      if (result != null) return result;
      return namesT[key1] = getNewName();
    }
    if (key2 != null) {
      String? result = namesU[key2];
      if (result != null) return result;
      return namesU[key2] = getNewName();
    }
    throw "Cannot disambiguate";
  }
}

NameSystem globalDebuggingNames = new NameSystem();

String debugLibraryName(Library? node) {
  return node == null
      ? 'null'
      : node.name ?? globalDebuggingNames.nameLibrary(node);
}

String debugClassName(Class? node) {
  return node == null ? 'null' : node.name;
}

String debugQualifiedClassName(Class node) {
  return debugLibraryName(node.enclosingLibrary) + '::' + debugClassName(node);
}

String debugMemberName(Member node) {
  return node.name.text;
}

String debugQualifiedMemberName(Member node) {
  if (node.enclosingClass != null) {
    return debugQualifiedClassName(node.enclosingClass!) +
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
  TreeNode? parent = node.parent;
  if (parent is Class) {
    return debugQualifiedClassName(parent) +
        '::' +
        debugTypeParameterName(node);
  }
  if (parent is Member) {
    return debugQualifiedMemberName(parent) +
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

String debugLibraryToString(Library library) {
  StringBuffer buffer = new StringBuffer();
  new Printer(buffer, syntheticNames: globalDebuggingNames)
      .writeLibraryFile(library);
  return '$buffer';
}

String debugComponentToString(Component component) {
  StringBuffer buffer = new StringBuffer();
  new Printer(buffer, syntheticNames: new NameSystem())
      .writeComponentFile(component);
  return '$buffer';
}

String componentToString(Component node) {
  StringBuffer buffer = new StringBuffer();
  new Printer(buffer, syntheticNames: new NameSystem())
      .writeComponentFile(node);
  return '$buffer';
}

class NameSystem {
  final Namer<VariableDeclaration> variables =
      new NormalNamer<VariableDeclaration>('#t');
  final Namer<Member> members = new NormalNamer<Member>('#m');
  final Namer<Class> classes = new NormalNamer<Class>('#class');
  final Namer<Extension> extensions = new NormalNamer<Extension>('#extension');
  final Namer<Library> libraries = new NormalNamer<Library>('#lib');
  final Namer<TypeParameter> typeParameters =
      new NormalNamer<TypeParameter>('#T');
  final Namer<TreeNode> labels = new NormalNamer<TreeNode>('#L');
  final Namer<Constant> constants = new ConstantNamer('#C');
  final Disambiguator<Reference, CanonicalName> prefixes =
      new Disambiguator<Reference, CanonicalName>();

  String nameVariable(VariableDeclaration node) => variables.getName(node);
  String nameMember(Member node) => members.getName(node);
  String nameClass(Class node) => classes.getName(node);
  String nameExtension(Extension node) => extensions.getName(node);
  String nameLibrary(Library node) => libraries.getName(node);
  String nameTypeParameter(TypeParameter node) => typeParameters.getName(node);
  String nameSwitchCase(SwitchCase node) => labels.getName(node);
  String nameLabeledStatement(LabeledStatement node) => labels.getName(node);
  String nameConstant(Constant node) => constants.getName(node);

  final RegExp pathSeparator = new RegExp('[\\/]');

  String nameLibraryPrefix(Library node, {String? proposedName}) {
    return prefixes.disambiguate(node.reference, node.reference.canonicalName,
        () {
      if (proposedName != null) {
        return proposedName;
      }
      String? name = node.name;
      if (name != null) {
        return abbreviateName(name);
      }
      // ignore: unnecessary_null_comparison
      if (node.importUri != null) {
        String path = node.importUri.hasEmptyPath
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

  String nameCanonicalNameAsLibraryPrefix(Reference? node, CanonicalName? name,
      {String? proposedName}) {
    return prefixes.disambiguate(node, name, () {
      if (proposedName != null) return proposedName;
      CanonicalName? canonicalName = name ?? node?.canonicalName;
      if (canonicalName?.name != null) {
        String path = canonicalName!.name;
        int slash = path.lastIndexOf(pathSeparator);
        if (slash >= 0) {
          path = path.substring(slash + 1);
        }
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
class Printer extends Visitor<void> with VisitorVoidMixin {
  final NameSystem syntheticNames;
  final StringSink sink;
  final Annotator? annotator;
  final Map<String, MetadataRepository<dynamic>>? metadata;
  ImportTable? importTable;
  int indentation = 0;
  int column = 0;
  bool showOffsets;
  bool showMetadata;

  static int SPACE = 0;
  static int WORD = 1;
  static int SYMBOL = 2;
  int state = SPACE;

  Printer(this.sink,
      {NameSystem? syntheticNames,
      this.showOffsets = false,
      this.showMetadata = false,
      this.importTable,
      this.annotator,
      this.metadata})
      : this.syntheticNames = syntheticNames ?? new NameSystem();

  Printer createInner(ImportTable importTable,
      Map<String, MetadataRepository<dynamic>>? metadata) {
    return new Printer(sink,
        importTable: importTable,
        metadata: metadata,
        syntheticNames: syntheticNames,
        annotator: annotator,
        showOffsets: showOffsets,
        showMetadata: showMetadata);
  }

  bool shouldHighlight(Node node) {
    return false;
  }

  void startHighlight(Node node) {}
  void endHighlight(Node node) {}

  String getLibraryName(Library node) {
    return node.name ?? syntheticNames.nameLibrary(node);
  }

  String getLibraryReference(Library node) {
    // ignore: unnecessary_null_comparison
    if (node == null) return '<No Library>';
    if (importTable != null && importTable?.getImportIndex(node) != -1) {
      return syntheticNames.nameLibraryPrefix(node);
    }
    return getLibraryName(node);
  }

  String getClassName(Class node) {
    return node.name;
  }

  String getExtensionName(Extension node) {
    return node.name;
  }

  String getInlineClassName(InlineClass node) {
    return node.name;
  }

  String getClassReference(Class node) {
    // ignore: unnecessary_null_comparison
    if (node == null) return '<No Class>';
    String name = getClassName(node);
    String library = getLibraryReference(node.enclosingLibrary);
    return '$library::$name';
  }

  String getExtensionReference(Extension node) {
    // ignore: unnecessary_null_comparison
    if (node == null) return '<No Extension>';
    String name = getExtensionName(node);
    String library = getLibraryReference(node.enclosingLibrary);
    return '$library::$name';
  }

  String getInlineClassReference(InlineClass node) {
    // ignore: unnecessary_null_comparison
    if (node == null) return '<No InlineClass>';
    String name = getInlineClassName(node);
    String library = getLibraryReference(node.enclosingLibrary);
    return '$library::$name';
  }

  String getTypedefReference(Typedef node) {
    // ignore: unnecessary_null_comparison
    if (node == null) return '<No Typedef>';
    String library = getLibraryReference(node.enclosingLibrary);
    return '$library::${node.name}';
  }

  static final String emptyNameString = '•';
  static final Name emptyName = new Name(emptyNameString);

  Name getMemberName(Member node) {
    if (node.name.text == '') return emptyName;
    // ignore: unnecessary_null_comparison
    if (node.name != null) return node.name;
    return new Name(syntheticNames.nameMember(node));
  }

  String getMemberReference(Member node) {
    // ignore: unnecessary_null_comparison
    if (node == null) return '<No Member>';
    String name = getMemberName(node).text;
    Class? enclosingClass = node.enclosingClass;
    if (enclosingClass != null) {
      String className = getClassReference(enclosingClass);
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
    // ignore: unnecessary_null_comparison
    if (node == null) return '<No VariableDeclaration>';
    return getVariableName(node);
  }

  String getTypeParameterName(TypeParameter node) {
    return node.name ?? syntheticNames.nameTypeParameter(node);
  }

  String getTypeParameterReference(TypeParameter node) {
    // ignore: unnecessary_null_comparison
    if (node == null) return '<No TypeParameter>';
    String name = getTypeParameterName(node);
    TreeNode? parent = node.parent;
    if (parent is FunctionNode && parent.parent is Member) {
      String member = getMemberReference(parent.parent as Member);
      return '$member::$name';
    } else if (parent is Class) {
      String className = getClassReference(parent);
      return '$className::$name';
    } else {
      return name; // Bound inside a function type.
    }
  }

  void writeComponentProblems(Component component) {
    writeProblemsAsJson("Problems in component", component.problemsAsJson);
  }

  void writeProblemsAsJson(String header, List<String>? problemsAsJson) {
    if (problemsAsJson != null && problemsAsJson.isNotEmpty) {
      endLine("//");
      write("// ");
      write(header);
      endLine(":");
      endLine("//");
      for (String s in problemsAsJson) {
        Map<String, dynamic> decoded = json.decode(s);
        List<dynamic> plainTextFormatted =
            decoded["plainTextFormatted"] as List<dynamic>;
        List<String> lines = plainTextFormatted.join("\n").split("\n");
        for (int i = 0; i < lines.length; i++) {
          write("//");
          String trimmed = lines[i].trimRight();
          if (trimmed.isNotEmpty) write(" ");
          endLine(trimmed);
        }
        if (lines.isNotEmpty) endLine("//");
      }
    }
  }

  void writeLibraryFile(Library library) {
    writeAnnotationList(library.annotations);
    writeWord('library');
    String? name = library.name;
    if (name != null) {
      writeWord(name);
    }
    List<String> flags = [];
    if (library.isUnsupported) {
      flags.add('isUnsupported');
    }
    if (library.isNonNullableByDefault) {
      flags.add('isNonNullableByDefault');
    }
    if (flags.isNotEmpty) {
      writeWord('/*${flags.join(',')}*/');
    }
    endLine(';');

    LibraryImportTable imports = new LibraryImportTable(library);
    Printer inner = createInner(imports, library.enclosingComponent?.metadata);
    inner.writeStandardLibraryContent(library,
        outerPrinter: this, importsToPrint: imports);
  }

  void printLibraryImportTable(LibraryImportTable imports) {
    for (Library library in imports.importedLibraries) {
      String importPath = imports.getImportPath(library);
      if (importPath == "") {
        String prefix =
            syntheticNames.nameLibraryPrefix(library, proposedName: 'self');
        endLine('import self as $prefix;');
      } else {
        String prefix = syntheticNames.nameLibraryPrefix(library);
        endLine('import "$importPath" as $prefix;');
      }
    }
  }

  void writeStandardLibraryContent(Library library,
      {Printer? outerPrinter, LibraryImportTable? importsToPrint}) {
    outerPrinter ??= this;
    outerPrinter.writeProblemsAsJson(
        "Problems in library", library.problemsAsJson);

    if (importsToPrint != null) {
      outerPrinter.printLibraryImportTable(importsToPrint);
    }

    writeAdditionalExports(library.additionalExports);
    endLine();
    library.dependencies.forEach(writeNode);
    if (library.dependencies.isNotEmpty) endLine();
    library.parts.forEach(writeNode);
    library.typedefs.forEach(writeNode);
    library.classes.forEach(writeNode);
    library.extensions.forEach(writeNode);
    library.inlineClasses.forEach(writeNode);
    library.fields.forEach(writeNode);
    library.procedures.forEach(writeNode);
  }

  void writeAdditionalExports(List<Reference> additionalExports) {
    if (additionalExports.isEmpty) return;
    write('additionalExports = (');
    for (int i = 0; i < additionalExports.length; i++) {
      Reference reference = additionalExports[i];
      NamedNode? node = reference.node;
      if (node is Class) {
        Library nodeLibrary = node.enclosingLibrary;
        String prefix = syntheticNames.nameLibraryPrefix(nodeLibrary);
        write(prefix + '::' + node.name);
      } else if (node is Extension) {
        Library nodeLibrary = node.enclosingLibrary;
        String prefix = syntheticNames.nameLibraryPrefix(nodeLibrary);
        write(prefix + '::' + node.name);
      } else if (node is Field) {
        Library nodeLibrary = node.enclosingLibrary;
        String prefix = syntheticNames.nameLibraryPrefix(nodeLibrary);
        write(prefix + '::' + node.name.text);
      } else if (node is InlineClass) {
        Library nodeLibrary = node.enclosingLibrary;
        String prefix = syntheticNames.nameLibraryPrefix(nodeLibrary);
        write(prefix + '::' + node.name);
      } else if (node is Procedure) {
        Library nodeLibrary = node.enclosingLibrary;
        String prefix = syntheticNames.nameLibraryPrefix(nodeLibrary);
        write(prefix + '::' + node.name.text);
      } else if (node is Typedef) {
        Library nodeLibrary = node.enclosingLibrary;
        String prefix = syntheticNames.nameLibraryPrefix(nodeLibrary);
        write(prefix + '::' + node.name);
      } else if (reference.canonicalName != null) {
        write(reference.canonicalName.toString());
      } else {
        throw new UnimplementedError('${node.runtimeType}');
      }

      if (i + 1 == additionalExports.length) {
        endLine(")");
      } else {
        endLine(",");
        write("  ");
      }
    }
  }

  void writeComponentFile(Component component) {
    ImportTable imports = new ComponentImportTable(component);
    Printer inner = createInner(imports, component.metadata);
    writeWord('main');
    writeSpaced('=');
    inner.writeMemberReferenceFromReference(component.mainMethodName);
    endLine(';');
    if (showMetadata) {
      inner.writeMetadata(component);
    }
    writeComponentProblems(component);
    for (Library library in component.libraries) {
      if (showMetadata) {
        inner.writeMetadata(library);
      }
      writeAnnotationList(library.annotations);
      writeWord('library');
      String? name = library.name;
      if (name != null) {
        writeWord(name);
      }
      // ignore: unnecessary_null_comparison
      if (library.importUri != null) {
        writeSpaced('from');
        writeWord('"${library.importUri}"');
      }
      String prefix = syntheticNames.nameLibraryPrefix(library);
      writeSpaced('as');
      writeWord(prefix);
      endLine(' {');
      ++inner.indentation;

      inner.writeStandardLibraryContent(library);
      --inner.indentation;
      endLine('}');
    }
    writeConstantTable(component);
  }

  void writeConstantTable(Component component) {
    if (syntheticNames.constants.map.isEmpty) return;
    ImportTable imports = new ComponentImportTable(component);
    Printer inner = createInner(imports, component.metadata);
    writeWord('constants ');
    endLine(' {');
    ++inner.indentation;
    for (final Constant constant
        in syntheticNames.constants.map.keys.toList()) {
      inner.writeNode(constant);
    }
    --inner.indentation;
    endLine('}');
  }

  int getPrecedence(Expression node) {
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

  void writeNode(Node? node) {
    if (node == null) {
      writeSymbol("<Null>");
    } else {
      final bool highlight = shouldHighlight(node);
      if (highlight) {
        startHighlight(node);
      }

      if (showOffsets && node is TreeNode) {
        writeWord("[${node.fileOffset}]");
      }
      if (showMetadata && node is TreeNode) {
        writeMetadata(node);
      }

      node.accept(this);

      if (highlight) {
        endHighlight(node);
      }
    }
  }

  void writeMetadata(TreeNode node) {
    if (metadata != null) {
      for (MetadataRepository<dynamic> md in metadata!.values) {
        final dynamic nodeMetadata = md.mapping[node];
        if (nodeMetadata != null) {
          writeWord("[@${md.tag}=${nodeMetadata}]");
        }
      }
    }
  }

  void writeAnnotatedType(DartType type, String? annotation) {
    writeType(type);
    if (annotation != null) {
      write('/');
      write(annotation);
      state = WORD;
    }
  }

  void writeType(DartType type) {
    // ignore: unnecessary_null_comparison
    if (type == null) {
      write('<No DartType>');
    } else {
      type.accept(this);
    }
  }

  void writeOptionalType(DartType type) {
    // ignore: unnecessary_null_comparison
    if (type != null) {
      type.accept(this);
    }
  }

  @override
  void visitSupertype(Supertype type) {
    // ignore: unnecessary_null_comparison
    if (type == null) {
      write('<No Supertype>');
    } else {
      writeClassReferenceFromReference(type.className);
      if (type.typeArguments.isNotEmpty) {
        writeSymbol('<');
        writeList(type.typeArguments, writeType);
        writeSymbol('>');
      }
    }
  }

  @override
  void visitTypedefType(TypedefType type) {
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
    if (name.text == '') {
      writeWord(emptyNameString);
    } else {
      writeWord(name.text); // TODO: write library name
    }
  }

  void endLine([String? string]) {
    if (string != null) {
      write(string);
    }
    write('\n');
    state = SPACE;
    column = 0;
  }

  void writeFunction(FunctionNode function,
      {name, List<Initializer>? initializers, bool terminateLine = true}) {
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
    if (function.futureValueType != null) {
      writeSpaced("/* futureValueType=");
      writeNode(function.futureValueType);
      writeSpaced("*/");
    }
    if (function.dartAsyncMarker != AsyncMarker.Sync &&
        function.dartAsyncMarker != function.asyncMarker) {
      writeSpaced("/* originally");
      writeSpaced(getAsyncMarkerKeyword(function.dartAsyncMarker));
      writeSpaced("*/");
    }
    Statement? body = function.body;
    if (body != null) {
      writeFunctionBody(body, terminateLine: terminateLine);
    } else if (terminateLine) {
      endLine(';');
    } else {
      writeSymbol(';');
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
      default:
        return '<Invalid async marker: $marker>';
    }
  }

  void writeFunctionBody(Statement body, {bool terminateLine = true}) {
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
      writeExpression(body.expression!);
    } else {
      writeBody(body);
    }
  }

  void writeFunctionType(FunctionType node) {
    if (state == WORD) {
      ensureSpace();
    }
    writeTypeParameterList(node.typeParameters);
    writeSymbol('(');
    List<DartType> positional = node.positionalParameters;

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
    ensureSpace();
    write('→');
    writeNullability(node.nullability);
    writeSpace();
    writeType(node.returnType);
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

  void writeReturnType(DartType type, String? annotation) {
    // ignore: unnecessary_null_comparison
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
      {String separator = ','}) {
    bool first = true;
    for (T node in nodes) {
      if (first) {
        first = false;
      } else {
        writeComma(separator);
      }
      callback(node);
    }
  }

  void writeClassReferenceFromReference(Reference reference) {
    writeWord(getClassReferenceFromReference(reference));
  }

  String getClassReferenceFromReference(Reference reference) {
    // ignore: unnecessary_null_comparison
    if (reference == null) return '<No Class>';
    if (reference.node != null) return getClassReference(reference.asClass);
    if (reference.canonicalName != null) {
      return getCanonicalNameString(reference.canonicalName!);
    }
    throw "Neither node nor canonical name found";
  }

  void writeExtensionReferenceFromReference(Reference reference) {
    writeWord(getExtensionReferenceFromReference(reference));
  }

  String getExtensionReferenceFromReference(Reference reference) {
    // ignore: unnecessary_null_comparison
    if (reference == null) return '<No Extension>';
    if (reference.node != null) {
      return getExtensionReference(reference.asExtension);
    }
    if (reference.canonicalName != null) {
      return getCanonicalNameString(reference.canonicalName!);
    }
    throw "Neither node nor canonical name found";
  }

  void writeInlineClassReferenceFromReference(Reference reference) {
    writeWord(getInlineClassReferenceFromReference(reference));
  }

  String getInlineClassReferenceFromReference(Reference reference) {
    // ignore: unnecessary_null_comparison
    if (reference == null) return '<No Extension>';
    if (reference.node != null) {
      return getInlineClassReference(reference.asInlineClass);
    }
    if (reference.canonicalName != null) {
      return getCanonicalNameString(reference.canonicalName!);
    }
    throw "Neither node nor canonical name found";
  }

  void writeMemberReferenceFromReference(Reference? reference) {
    writeWord(getMemberReferenceFromReference(reference));
  }

  String getMemberReferenceFromReference(Reference? reference) {
    if (reference == null) return '<No Member>';
    if (reference.node != null) return getMemberReference(reference.asMember);
    if (reference.canonicalName != null) {
      return getCanonicalNameString(reference.canonicalName!);
    }
    throw "Neither node nor canonical name found";
  }

  String getCanonicalNameString(CanonicalName name) {
    if (name.isRoot) throw 'unexpected root';
    if (name.name.startsWith('@')) throw 'unexpected @';

    String libraryString(CanonicalName lib) {
      if (lib.reference.node != null) {
        return getLibraryReference(lib.reference.asLibrary);
      }
      return syntheticNames.nameCanonicalNameAsLibraryPrefix(
          lib.reference, lib);
    }

    String classString(CanonicalName cls) =>
        libraryString(cls.parent!) + '::' + cls.name;

    if (name.parent!.isRoot) return libraryString(name);
    if (name.parent!.parent!.isRoot) return classString(name);

    CanonicalName atNode = name.parent!;
    while (!atNode.name.startsWith('@')) {
      atNode = atNode.parent!;
    }

    String parent = "";
    if (atNode.parent!.parent!.isRoot) {
      parent = libraryString(atNode.parent!);
    } else {
      parent = classString(atNode.parent!);
    }

    if (name.name == '') return "$parent::$emptyNameString";
    return "$parent::${name.name}";
  }

  void writeTypedefReference(Typedef typedefNode) {
    writeWord(getTypedefReference(typedefNode));
  }

  void writeVariableReference(VariableDeclaration variable) {
    final bool highlight = shouldHighlight(variable);
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

  void writeExpression(Expression node, [int? minimumPrecedence]) {
    final bool highlight = shouldHighlight(node);
    if (highlight) {
      startHighlight(node);
    }
    if (showOffsets) writeWord("[${node.fileOffset}]");
    bool needsParentheses = false;
    if (minimumPrecedence != null && getPrecedence(node) < minimumPrecedence) {
      needsParentheses = true;
      writeSymbol('(');
    }
    writeNode(node);
    if (needsParentheses) {
      writeSymbol(')');
    }
    if (highlight) {
      endHighlight(node);
    }
  }

  void writeAnnotation(Expression node) {
    writeSymbol('@');
    if (node is ConstructorInvocation) {
      writeMemberReferenceFromReference(node.targetReference);
      visitArguments(node.arguments);
    } else {
      writeExpression(node);
    }
  }

  void writeAnnotationList(List<Expression> nodes,
      {bool separateLines = true}) {
    for (Expression node in nodes) {
      if (separateLines) {
        writeIndentation();
      }
      writeAnnotation(node);
      if (separateLines) {
        endLine();
      } else {
        writeSpace();
      }
    }
  }

  @override
  void visitLibrary(Library node) {}

  @override
  void visitField(Field node) {
    writeAnnotationList(node.annotations);
    writeIndentation();
    writeModifier(node.isEnumElement, 'enum-element');
    writeModifier(node.isLate, 'late');
    writeModifier(node.isStatic, 'static');
    writeModifier(node.isCovariantByDeclaration, 'covariant-by-declaration');
    writeModifier(node.isCovariantByClass, 'covariant-by-class');
    writeModifier(node.isFinal, 'final');
    writeModifier(node.isConst, 'const');
    // Only show implicit getter/setter modifiers in cases where they are
    // out of the ordinary.
    if (node.isFinal) {
      writeModifier(node.hasSetter, '[setter]');
    }
    writeWord('field');
    writeSpace();
    writeAnnotatedType(node.type, annotator?.annotateField(this, node));
    writeName(getMemberName(node));
    Expression? initializer = node.initializer;
    if (initializer != null) {
      writeSpaced('=');
      writeExpression(initializer);
    }
    List<String> features = <String>[];
    if (node.enclosingLibrary.isNonNullableByDefault !=
        node.isNonNullableByDefault) {
      if (node.isNonNullableByDefault) {
        features.add("isNonNullableByDefault");
      } else {
        features.add("isLegacy");
      }
    }
    Class? enclosingClass = node.enclosingClass;
    if ((enclosingClass == null &&
            node.enclosingLibrary.fileUri != node.fileUri) ||
        (enclosingClass != null && enclosingClass.fileUri != node.fileUri)) {
      features.add(" from ${node.fileUri} ");
    }
    if (features.isNotEmpty) {
      writeWord("/*${features.join(',')}*/");
    }
    endLine(';');
  }

  @override
  void visitProcedure(Procedure node) {
    writeAnnotationList(node.annotations);
    writeIndentation();
    writeModifier(node.isExternal, 'external');
    writeModifier(node.isStatic, 'static');
    writeModifier(node.isAbstract, 'abstract');
    writeModifier(node.isForwardingStub, 'forwarding-stub');
    writeModifier(node.isForwardingSemiStub, 'forwarding-semi-stub');
    switch (node.stubKind) {
      case ProcedureStubKind.Regular:
      case ProcedureStubKind.AbstractForwardingStub:
      case ProcedureStubKind.ConcreteForwardingStub:
        break;
      case ProcedureStubKind.NoSuchMethodForwarder:
        writeWord('no-such-method-forwarder');
        break;
      case ProcedureStubKind.MemberSignature:
        writeWord('member-signature');
        break;
      case ProcedureStubKind.AbstractMixinStub:
        writeWord('mixin-stub');
        break;
      case ProcedureStubKind.ConcreteMixinStub:
        writeWord('mixin-super-stub');
        break;
    }
    writeWord(procedureKindToString(node.kind));
    List<String> features = <String>[];
    if (node.enclosingLibrary.isNonNullableByDefault !=
        node.isNonNullableByDefault) {
      if (node.isNonNullableByDefault) {
        features.add("isNonNullableByDefault");
      } else {
        features.add("isLegacy");
      }
    }
    Class? enclosingClass = node.enclosingClass;
    if ((enclosingClass == null &&
            node.enclosingLibrary.fileUri != node.fileUri) ||
        (enclosingClass != null && enclosingClass.fileUri != node.fileUri)) {
      features.add(" from ${node.fileUri} ");
    }
    if (features.isNotEmpty) {
      writeWord("/*${features.join(',')}*/");
    }
    if (node.signatureType != null) {
      writeWord('/* signature-type:');
      writeType(node.signatureType!);
      writeWord('*/');
    }
    switch (node.stubKind) {
      case ProcedureStubKind.Regular:
      case ProcedureStubKind.AbstractForwardingStub:
      case ProcedureStubKind.ConcreteForwardingStub:
      case ProcedureStubKind.NoSuchMethodForwarder:
      case ProcedureStubKind.ConcreteMixinStub:
        writeFunction(node.function, name: getMemberName(node));
        break;
      case ProcedureStubKind.MemberSignature:
      case ProcedureStubKind.AbstractMixinStub:
        writeFunction(node.function,
            name: getMemberName(node), terminateLine: false);
        if (node.function.body is ReturnStatement) {
          writeSymbol(';');
        }
        writeSymbol(' -> ');
        writeMemberReferenceFromReference(node.stubTargetReference!);
        endLine();
        break;
    }
  }

  @override
  void visitConstructor(Constructor node) {
    writeAnnotationList(node.annotations);
    writeIndentation();
    writeModifier(node.isExternal, 'external');
    writeModifier(node.isConst, 'const');
    writeModifier(node.isSynthetic, 'synthetic');
    writeWord('constructor');
    List<String> features = <String>[];
    if (node.enclosingLibrary.isNonNullableByDefault !=
        node.isNonNullableByDefault) {
      if (node.isNonNullableByDefault) {
        features.add("isNonNullableByDefault");
      } else {
        features.add("isLegacy");
      }
    }
    if (features.isNotEmpty) {
      writeWord("/*${features.join(',')}*/");
    }
    writeFunction(node.function,
        name: node.name, initializers: node.initializers);
  }

  @override
  void visitRedirectingFactory(RedirectingFactory node) {
    writeAnnotationList(node.annotations);
    writeIndentation();
    writeModifier(node.isExternal, 'external');
    writeModifier(node.isConst, 'const');
    writeWord('redirecting_factory');
    writeFunction(node.function, name: node.name);
    writeSpaced('=');
    writeMemberReferenceFromReference(node.targetReference!);
    if (node.typeArguments.isNotEmpty) {
      writeSymbol('<');
      writeList(node.typeArguments, writeType);
      writeSymbol('>');
    }
    List<String> features = <String>[];
    if (node.enclosingLibrary.isNonNullableByDefault !=
        node.isNonNullableByDefault) {
      if (node.isNonNullableByDefault) {
        features.add("isNonNullableByDefault");
      } else {
        features.add("isLegacy");
      }
    }
    if (features.isNotEmpty) {
      writeWord("/*${features.join(',')}*/");
    }
    endLine(';');
  }

  @override
  void visitClass(Class node) {
    writeAnnotationList(node.annotations);
    writeIndentation();
    writeModifier(node.isAbstract, 'abstract');
    writeModifier(node.isMacro, 'macro');
    writeModifier(node.isSealed, 'sealed');
    writeModifier(node.isBase, 'base');
    writeModifier(node.isInterface, 'interface');
    writeModifier(node.isFinal, 'final');
    writeModifier(node.isMixinClass, 'mixin');
    writeWord('class');
    writeWord(getClassName(node));
    writeTypeParameterList(node.typeParameters);
    if (node.isMixinApplication) {
      writeSpaced('=');
      visitSupertype(node.supertype!);
      writeSpaced('with');
      visitSupertype(node.mixedInType!);
    } else if (node.supertype != null) {
      writeSpaced('extends');
      visitSupertype(node.supertype!);
    }
    if (node.implementedTypes.isNotEmpty) {
      writeSpaced('implements');
      writeList(node.implementedTypes, visitSupertype);
    }
    List<String> features = <String>[];
    if (node.isEnum) {
      features.add('isEnum');
    }
    if (node.isAnonymousMixin) {
      features.add('isAnonymousMixin');
    }
    if (node.isEliminatedMixin) {
      features.add('isEliminatedMixin');
    }
    if (node.isMixinDeclaration) {
      features.add('isMixinDeclaration');
    }
    if (node.hasConstConstructor) {
      features.add('hasConstConstructor');
    }
    if (features.isNotEmpty) {
      writeSpaced('/*${features.join(',')}*/');
    }
    String endLineString = ' {';
    if (node.enclosingLibrary.fileUri != node.fileUri) {
      endLineString += ' // from ${node.fileUri}';
    }
    endLine(endLineString);
    ++indentation;
    node.fields.forEach(writeNode);
    node.constructors.forEach(writeNode);
    node.procedures.forEach(writeNode);
    node.redirectingFactories.forEach(writeNode);
    --indentation;
    writeIndentation();
    endLine('}');
  }

  @override
  void visitExtension(Extension node) {
    writeAnnotationList(node.annotations);
    writeIndentation();
    writeWord('extension');
    if (node.isExtensionTypeDeclaration) {
      writeWord('type');
    }
    if (node.isUnnamedExtension) {
      writeWord('/* unnamed */');
    }
    writeWord(getExtensionName(node));
    writeTypeParameterList(node.typeParameters);
    writeSpaced('on');
    writeType(node.onType);

    ExtensionTypeShowHideClause? showHideClause = node.showHideClause;
    if (showHideClause != null) {
      // 'Show' clause elements.
      if (showHideClause.shownSupertypes.isNotEmpty) {
        writeSpaced('show-types');
        writeList(showHideClause.shownSupertypes, visitSupertype);
      }
      if (showHideClause.shownMethods.isNotEmpty) {
        writeSpaced('show-methods');
        writeList(
            showHideClause.shownMethods, writeMemberReferenceFromReference);
      }
      if (showHideClause.shownGetters.isNotEmpty) {
        writeSpaced('show-getters');
        writeList(
            showHideClause.shownGetters, writeMemberReferenceFromReference);
      }
      if (showHideClause.shownSetters.isNotEmpty) {
        writeSpaced('show-setters');
        writeList(
            showHideClause.shownSetters, writeMemberReferenceFromReference);
      }
      if (showHideClause.shownOperators.isNotEmpty) {
        writeSpaced('show-operators');
        writeList(
            showHideClause.shownOperators, writeMemberReferenceFromReference);
      }

      // 'Hide' clause elements.
      if (showHideClause.hiddenSupertypes.isNotEmpty) {
        writeSpaced('hide-types');
        writeList(showHideClause.hiddenSupertypes, visitSupertype);
      }
      if (showHideClause.hiddenMethods.isNotEmpty) {
        writeSpaced('hide-methods');
        writeList(
            showHideClause.hiddenMethods, writeMemberReferenceFromReference);
      }
      if (showHideClause.hiddenGetters.isNotEmpty) {
        writeSpaced('hide-getters');
        writeList(
            showHideClause.hiddenGetters, writeMemberReferenceFromReference);
      }
      if (showHideClause.hiddenSetters.isNotEmpty) {
        writeSpaced('hide-setters');
        writeList(
            showHideClause.hiddenSetters, writeMemberReferenceFromReference);
      }
      if (showHideClause.hiddenOperators.isNotEmpty) {
        writeSpaced('hide-operators');
        writeList(
            showHideClause.hiddenOperators, writeMemberReferenceFromReference);
      }
    }

    String endLineString = ' {';
    if (node.enclosingLibrary.fileUri != node.fileUri) {
      endLineString += ' // from ${node.fileUri}';
    }

    endLine(endLineString);
    ++indentation;
    node.members.forEach((ExtensionMemberDescriptor descriptor) {
      writeIndentation();
      writeModifier(descriptor.isStatic, 'static');
      switch (descriptor.kind) {
        case ExtensionMemberKind.Method:
          writeWord('method');
          break;
        case ExtensionMemberKind.Getter:
          writeWord('get');
          break;
        case ExtensionMemberKind.Setter:
          writeWord('set');
          break;
        case ExtensionMemberKind.Operator:
          writeWord('operator');
          break;
        case ExtensionMemberKind.Field:
          writeWord('field');
          break;
        case ExtensionMemberKind.TearOff:
          writeWord('tearoff');
          break;
      }
      writeName(descriptor.name);
      writeSpaced('=');
      Member member = descriptor.member.asMember;
      if (member is Procedure) {
        if (member.isGetter) {
          writeWord('get');
        } else if (member.isSetter) {
          writeWord('set');
        }
      }
      writeMemberReferenceFromReference(descriptor.member);
      endLine(';');
    });
    --indentation;
    writeIndentation();
    endLine('}');
  }

  @override
  void visitInlineClass(InlineClass node) {
    writeAnnotationList(node.annotations);
    writeIndentation();
    writeWord('inline class');
    writeWord(getInlineClassName(node));
    writeTypeParameterList(node.typeParameters);
    writeWord('/* declaredRepresentationType =');
    writeType(node.declaredRepresentationType);
    writeWord('*/');
    if (node.implements.isNotEmpty) {
      writeSpaced('implements');
      writeList(node.implements, writeType);
    }
    String endLineString = ' {';
    if (node.enclosingLibrary.fileUri != node.fileUri) {
      endLineString += ' // from ${node.fileUri}';
    }

    endLine(endLineString);
    ++indentation;
    node.members.forEach((InlineClassMemberDescriptor descriptor) {
      writeIndentation();
      writeModifier(descriptor.isStatic, 'static');
      switch (descriptor.kind) {
        case InlineClassMemberKind.Constructor:
          writeWord('constructor');
          break;
        case InlineClassMemberKind.Factory:
          writeWord('factory');
          break;
        case InlineClassMemberKind.Method:
          writeWord('method');
          break;
        case InlineClassMemberKind.Getter:
          writeWord('get');
          break;
        case InlineClassMemberKind.Setter:
          writeWord('set');
          break;
        case InlineClassMemberKind.Operator:
          writeWord('operator');
          break;
        case InlineClassMemberKind.Field:
          writeWord('field');
          break;
        case InlineClassMemberKind.TearOff:
          writeWord('tearoff');
          break;
      }
      writeName(descriptor.name);
      writeSpaced('=');
      Member member = descriptor.member.asMember;
      if (member is Procedure) {
        if (member.isGetter) {
          writeWord('get');
        } else if (member.isSetter) {
          writeWord('set');
        }
      }
      writeMemberReferenceFromReference(descriptor.member);
      endLine(';');
    });
    --indentation;
    writeIndentation();
    endLine('}');
  }

  @override
  void visitTypedef(Typedef node) {
    writeAnnotationList(node.annotations);
    writeIndentation();
    writeWord('typedef');
    writeWord(node.name);
    writeTypeParameterList(node.typeParameters);
    writeSpaced('=');
    DartType? type = node.type;
    if (type is FunctionType) {
      writeFunctionType(type);
    } else {
      writeNode(type);
    }
    endLine(';');
  }

  @override
  void visitInvalidExpression(InvalidExpression node) {
    writeWord('invalid-expression');
    if (node.message != null) {
      writeWord('"${escapeString(node.message!)}"');
    }
    if (node.expression != null) {
      writeSpaced('in');
      writeNode(node.expression!);
    }
  }

  void _writeDynamicAccessKind(DynamicAccessKind kind) {
    switch (kind) {
      case DynamicAccessKind.Dynamic:
        writeSymbol('{dynamic}.');
        break;
      case DynamicAccessKind.Never:
        writeSymbol('{Never}.');
        break;
      case DynamicAccessKind.Invalid:
        writeSymbol('{<invalid>}.');
        break;
      case DynamicAccessKind.Unresolved:
        writeSymbol('{<unresolved>}.');
        break;
    }
  }

  @override
  void visitDynamicInvocation(DynamicInvocation node) {
    writeExpression(node.receiver, Precedence.PRIMARY);
    _writeDynamicAccessKind(node.kind);
    writeName(
      node.name,
    );
    writeNode(node.arguments);
  }

  void _writeFunctionAccessKind(FunctionAccessKind kind) {
    switch (kind) {
      case FunctionAccessKind.Function:
      case FunctionAccessKind.FunctionType:
        break;
      case FunctionAccessKind.Inapplicable:
        writeSymbol('{<inapplicable>}.');
        break;
      case FunctionAccessKind.Nullable:
        writeSymbol('{<nullable>}.');
        break;
    }
  }

  @override
  void visitFunctionInvocation(FunctionInvocation node) {
    writeExpression(node.receiver, Precedence.PRIMARY);
    _writeFunctionAccessKind(node.kind);
    writeNode(node.arguments);
    if (node.functionType != null) {
      writeSymbol('{');
      writeType(node.functionType!);
      writeSymbol('}');
    }
  }

  @override
  void visitLocalFunctionInvocation(LocalFunctionInvocation node) {
    writeVariableReference(node.variable);
    writeNode(node.arguments);
    writeSymbol('{');
    writeType(node.functionType);
    writeSymbol('}');
  }

  void _writeInstanceAccessKind(InstanceAccessKind kind) {
    switch (kind) {
      case InstanceAccessKind.Instance:
      case InstanceAccessKind.Object:
        break;
      case InstanceAccessKind.Inapplicable:
        writeSymbol('{<inapplicable>}.');
        break;
      case InstanceAccessKind.Nullable:
        writeSymbol('{<nullable>}.');
        break;
    }
  }

  @override
  void visitInstanceInvocation(InstanceInvocation node) {
    writeExpression(node.receiver, Precedence.PRIMARY);
    writeSymbol('.');
    writeInterfaceTarget(node.name, node.interfaceTargetReference);
    _writeInstanceAccessKind(node.kind);
    List<String> flags = <String>[];
    if (node.isInvariant) {
      flags.add('Invariant');
    }
    if (node.isBoundsSafe) {
      flags.add('BoundsSafe');
    }
    if (flags.isNotEmpty) {
      write('{${flags.join(',')}}');
    }
    writeNode(node.arguments);
    writeSymbol('{');
    writeType(node.functionType);
    writeSymbol('}');
  }

  @override
  void visitInstanceGetterInvocation(InstanceGetterInvocation node) {
    writeExpression(node.receiver, Precedence.PRIMARY);
    writeSymbol('.');
    writeInterfaceTarget(node.name, node.interfaceTargetReference);
    _writeInstanceAccessKind(node.kind);
    writeNode(node.arguments);
    if (node.functionType != null) {
      writeSymbol('{');
      writeType(node.functionType!);
      writeSymbol('}');
    }
  }

  @override
  void visitEqualsCall(EqualsCall node) {
    int precedence = Precedence.EQUALITY;
    writeExpression(node.left, precedence);
    writeSpace();
    writeSymbol('==');
    writeInterfaceTarget(Name.equalsName, node.interfaceTargetReference);
    writeSymbol('{');
    writeType(node.functionType);
    writeSymbol('}');
    writeSpace();
    writeExpression(node.right, precedence + 1);
  }

  @override
  void visitEqualsNull(EqualsNull node) {
    writeExpression(node.expression, Precedence.EQUALITY);
    writeSpace();
    writeSymbol('==');
    writeSpace();
    writeSymbol('null');
  }

  @override
  void visitSuperMethodInvocation(SuperMethodInvocation node) {
    writeWord('super');
    writeSymbol('.');
    writeInterfaceTarget(node.name, node.interfaceTargetReference);
    writeNode(node.arguments);
  }

  @override
  void visitStaticInvocation(StaticInvocation node) {
    writeModifier(node.isConst, 'const');
    writeMemberReferenceFromReference(node.targetReference);
    writeNode(node.arguments);
  }

  @override
  void visitConstructorInvocation(ConstructorInvocation node) {
    writeWord(node.isConst ? 'const' : 'new');
    writeMemberReferenceFromReference(node.targetReference);
    writeNode(node.arguments);
  }

  @override
  void visitNot(Not node) {
    writeSymbol('!');
    writeExpression(node.operand, Precedence.PREFIX);
  }

  @override
  void visitNullCheck(NullCheck node) {
    writeExpression(node.operand, Precedence.POSTFIX);
    writeSymbol('!');
  }

  @override
  void visitLogicalExpression(LogicalExpression node) {
    int precedence = Precedence.binaryPrecedence[
        logicalExpressionOperatorToString(node.operatorEnum)]!;
    writeExpression(node.left, precedence);
    writeSpaced(logicalExpressionOperatorToString(node.operatorEnum));
    writeExpression(node.right, precedence + 1);
  }

  @override
  void visitConditionalExpression(ConditionalExpression node) {
    writeExpression(node.condition, Precedence.LOGICAL_OR);
    ensureSpace();
    write('?');
    writeStaticType(node.staticType);
    writeSpace();
    writeExpression(node.then);
    writeSpaced(':');
    writeExpression(node.otherwise);
  }

  @override
  void visitStringConcatenation(StringConcatenation node) {
    if (state == WORD) {
      writeSpace();
    }
    write('"');
    for (Expression part in node.expressions) {
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

  @override
  void visitListConcatenation(ListConcatenation node) {
    bool first = true;
    for (Expression part in node.lists) {
      if (!first) writeSpaced('+');
      writeExpression(part);
      first = false;
    }
  }

  @override
  void visitSetConcatenation(SetConcatenation node) {
    bool first = true;
    for (Expression part in node.sets) {
      if (!first) writeSpaced('+');
      writeExpression(part);
      first = false;
    }
  }

  @override
  void visitMapConcatenation(MapConcatenation node) {
    bool first = true;
    for (Expression part in node.maps) {
      if (!first) writeSpaced('+');
      writeExpression(part);
      first = false;
    }
  }

  @override
  void visitInstanceCreation(InstanceCreation node) {
    writeClassReferenceFromReference(node.classReference);
    if (node.typeArguments.isNotEmpty) {
      writeSymbol('<');
      writeList(node.typeArguments, writeType);
      writeSymbol('>');
    }
    writeSymbol('{');
    bool first = true;
    node.fieldValues.forEach((Reference fieldRef, Expression value) {
      if (!first) {
        writeComma();
      }
      writeWord('${fieldRef.asField.name.text}');
      writeSymbol(':');
      writeExpression(value);
      first = false;
    });
    for (AssertStatement assert_ in node.asserts) {
      if (!first) {
        writeComma();
      }
      write('assert(');
      writeExpression(assert_.condition);
      Expression? message = assert_.message;
      if (message != null) {
        writeComma();
        writeExpression(message);
      }
      write(')');
      first = false;
    }
    for (Expression unusedArgument in node.unusedArguments) {
      if (!first) {
        writeComma();
      }
      writeExpression(unusedArgument);
      first = false;
    }
    writeSymbol('}');
  }

  @override
  void visitFileUriExpression(FileUriExpression node) {
    writeExpression(node.expression);
  }

  @override
  void visitIsExpression(IsExpression node) {
    writeExpression(node.operand, Precedence.BITWISE_OR);
    writeSpaced(
        node.isForNonNullableByDefault ? 'is{ForNonNullableByDefault}' : 'is');
    writeType(node.type);
  }

  @override
  void visitAsExpression(AsExpression node) {
    writeExpression(node.operand, Precedence.BITWISE_OR);
    List<String> flags = <String>[];
    if (node.isTypeError) {
      flags.add('TypeError');
    }
    if (node.isCovarianceCheck) {
      flags.add('CovarianceCheck');
    }
    if (node.isForDynamic) {
      flags.add('ForDynamic');
    }
    if (node.isForNonNullableByDefault) {
      flags.add('ForNonNullableByDefault');
    }
    writeSpaced(flags.isNotEmpty ? 'as{${flags.join(',')}}' : 'as');
    writeType(node.type);
  }

  @override
  void visitSymbolLiteral(SymbolLiteral node) {
    writeSymbol('#');
    writeWord(node.value);
  }

  @override
  void visitTypeLiteral(TypeLiteral node) {
    writeType(node.type);
  }

  @override
  void visitThisExpression(ThisExpression node) {
    writeWord('this');
  }

  @override
  void visitRethrow(Rethrow node) {
    writeWord('rethrow');
  }

  @override
  void visitThrow(Throw node) {
    writeWord('throw');
    writeSpace();
    writeExpression(node.expression);
  }

  @override
  void visitListLiteral(ListLiteral node) {
    if (node.isConst) {
      writeWord('const');
      writeSpace();
    }
    // ignore: unnecessary_null_comparison
    if (node.typeArgument != null) {
      writeSymbol('<');
      writeType(node.typeArgument);
      writeSymbol('>');
    }
    writeSymbol('[');
    writeList(node.expressions, writeNode);
    writeSymbol(']');
  }

  @override
  void visitSetLiteral(SetLiteral node) {
    if (node.isConst) {
      writeWord('const');
      writeSpace();
    }
    // ignore: unnecessary_null_comparison
    if (node.typeArgument != null) {
      writeSymbol('<');
      writeType(node.typeArgument);
      writeSymbol('>');
    }
    writeSymbol('{');
    writeList(node.expressions, writeNode);
    writeSymbol('}');
  }

  @override
  void visitMapLiteral(MapLiteral node) {
    if (node.isConst) {
      writeWord('const');
      writeSpace();
    }
    // ignore: unnecessary_null_comparison
    if (node.keyType != null) {
      writeSymbol('<');
      writeList([node.keyType, node.valueType], writeType);
      writeSymbol('>');
    }
    writeSymbol('{');
    writeList(node.entries, writeNode);
    writeSymbol('}');
  }

  @override
  void visitMapLiteralEntry(MapLiteralEntry node) {
    writeExpression(node.key);
    writeComma(':');
    writeExpression(node.value);
  }

  @override
  void visitRecordLiteral(RecordLiteral node) {
    if (node.isConst) {
      writeWord('const');
      writeSpace();
    }
    writeSymbol('(');
    writeList(node.positional, writeNode);
    if (node.named.isNotEmpty) {
      if (node.positional.isNotEmpty) writeComma();
      writeSymbol('{');
      writeList(node.named, writeNode);
      writeSymbol('}');
    }
    writeSymbol(')');
  }

  @override
  void visitAwaitExpression(AwaitExpression node) {
    writeWord('await');
    writeExpression(node.operand);
    if (node.runtimeCheckType != null) {
      writeSpaced("/* runtimeCheckType=");
      writeNode(node.runtimeCheckType);
      writeSpaced("*/");
    }
  }

  @override
  void visitFunctionExpression(FunctionExpression node) {
    writeFunction(node.function, terminateLine: false);
  }

  @override
  void visitStringLiteral(StringLiteral node) {
    writeWord('"${escapeString(node.value)}"');
  }

  @override
  void visitIntLiteral(IntLiteral node) {
    writeWord('${node.value}');
  }

  @override
  void visitDoubleLiteral(DoubleLiteral node) {
    writeWord('${node.value}');
  }

  @override
  void visitBoolLiteral(BoolLiteral node) {
    writeWord('${node.value}');
  }

  @override
  void visitNullLiteral(NullLiteral node) {
    writeWord('null');
  }

  @override
  void visitLet(Let node) {
    writeWord('let');
    writeVariableDeclaration(node.variable);
    writeSpaced('in');
    writeExpression(node.body);
  }

  @override
  void visitBlockExpression(BlockExpression node) {
    writeSpaced('block');
    writeBlockBody(node.body.statements, asExpression: true);
    writeSymbol(' =>');
    writeExpression(node.value);
  }

  @override
  void visitInstantiation(Instantiation node) {
    writeExpression(node.expression, Precedence.TYPE_LITERAL);
    writeSymbol('<');
    writeList(node.typeArguments, writeType);
    writeSymbol('>');
  }

  @override
  void visitLoadLibrary(LoadLibrary node) {
    writeWord('LoadLibrary');
    writeSymbol('(');
    writeWord(node.import.name!);
    writeSymbol(')');
    state = WORD;
  }

  @override
  void visitCheckLibraryIsLoaded(CheckLibraryIsLoaded node) {
    writeWord('CheckLibraryIsLoaded');
    writeSymbol('(');
    writeWord(node.import.name!);
    writeSymbol(')');
    state = WORD;
  }

  @override
  void visitLibraryPart(LibraryPart node) {
    writeAnnotationList(node.annotations);
    writeIndentation();
    writeWord('part');
    writeWord(node.partUri);
    endLine(";");
  }

  @override
  void visitLibraryDependency(LibraryDependency node) {
    writeAnnotationList(node.annotations);
    writeIndentation();
    writeWord(node.isImport ? 'import' : 'export');
    String uriString;
    if (node.importedLibraryReference.node != null) {
      uriString = '${node.targetLibrary.importUri}';
    } else {
      uriString = '${node.importedLibraryReference.canonicalName?.name}';
    }
    writeWord('"$uriString"');
    if (node.isDeferred) {
      writeWord('deferred');
    }
    String? name = node.name;
    if (name != null) {
      writeWord('as');
      writeWord(name);
    }
    String? last;
    final String show = 'show';
    final String hide = 'hide';
    if (node.combinators.isNotEmpty) {
      for (Combinator combinator in node.combinators) {
        if (combinator.isShow && last != show) {
          last = show;
          writeWord(show);
        } else if (combinator.isHide && last != hide) {
          last = hide;
          writeWord(hide);
        }

        bool first = true;
        for (String name in combinator.names) {
          if (!first) writeComma();
          writeWord(name);
          first = false;
        }
      }
    }
    endLine(';');
  }

  @override
  void defaultExpression(Expression node) {
    writeWord('${node.runtimeType}');
  }

  @override
  void visitVariableGet(VariableGet node) {
    writeVariableReference(node.variable);
    DartType? promotedType = node.promotedType;
    if (promotedType != null) {
      writeSymbol('{');
      writeNode(promotedType);
      writeSymbol('}');
      state = WORD;
    }
  }

  @override
  void visitVariableSet(VariableSet node) {
    writeVariableReference(node.variable);
    writeSpaced('=');
    writeExpression(node.value);
  }

  void writeInterfaceTarget(Name name, Reference? target) {
    if (target != null) {
      writeSymbol('{');
      writeMemberReferenceFromReference(target);
      writeSymbol('}');
    } else {
      writeName(name);
    }
  }

  void writeStaticType(DartType type) {
    // ignore: unnecessary_null_comparison
    if (type != null) {
      writeSymbol('{');
      writeType(type);
      writeSymbol('}');
    }
  }

  @override
  void visitDynamicGet(DynamicGet node) {
    writeExpression(node.receiver, Precedence.PRIMARY);
    _writeDynamicAccessKind(node.kind);
    writeName(node.name);
  }

  @override
  void visitFunctionTearOff(FunctionTearOff node) {
    writeExpression(node.receiver, Precedence.PRIMARY);
    writeSymbol('.');
    writeSymbol('call');
  }

  @override
  void visitInstanceGet(InstanceGet node) {
    writeExpression(node.receiver, Precedence.PRIMARY);
    writeSymbol('.');
    writeInterfaceTarget(node.name, node.interfaceTargetReference);
    _writeInstanceAccessKind(node.kind);
    writeSymbol('{');
    writeType(node.resultType);
    writeSymbol('}');
  }

  @override
  void visitInstanceTearOff(InstanceTearOff node) {
    writeExpression(node.receiver, Precedence.PRIMARY);
    writeSymbol('.');
    writeInterfaceTarget(node.name, node.interfaceTargetReference);
    _writeInstanceAccessKind(node.kind);
    writeSymbol('{');
    writeType(node.resultType);
    writeSymbol('}');
  }

  @override
  void visitDynamicSet(DynamicSet node) {
    writeExpression(node.receiver, Precedence.PRIMARY);
    _writeDynamicAccessKind(node.kind);
    writeName(node.name);
    writeSpaced('=');
    writeExpression(node.value);
  }

  @override
  void visitInstanceSet(InstanceSet node) {
    writeExpression(node.receiver, Precedence.PRIMARY);
    writeSymbol('.');
    writeInterfaceTarget(node.name, node.interfaceTargetReference);
    _writeInstanceAccessKind(node.kind);
    writeSpaced('=');
    writeExpression(node.value);
  }

  @override
  void visitSuperPropertyGet(SuperPropertyGet node) {
    writeWord('super');
    writeSymbol('.');
    writeInterfaceTarget(node.name, node.interfaceTargetReference);
  }

  @override
  void visitSuperPropertySet(SuperPropertySet node) {
    writeWord('super');
    writeSymbol('.');
    writeInterfaceTarget(node.name, node.interfaceTargetReference);
    writeSpaced('=');
    writeExpression(node.value);
  }

  @override
  void visitStaticTearOff(StaticTearOff node) {
    writeMemberReferenceFromReference(node.targetReference);
  }

  @override
  void visitStaticGet(StaticGet node) {
    writeMemberReferenceFromReference(node.targetReference);
  }

  @override
  void visitStaticSet(StaticSet node) {
    writeMemberReferenceFromReference(node.targetReference);
    writeSpaced('=');
    writeExpression(node.value);
  }

  @override
  void visitConstructorTearOff(ConstructorTearOff node) {
    writeMemberReferenceFromReference(node.targetReference);
  }

  @override
  void visitRedirectingFactoryTearOff(RedirectingFactoryTearOff node) {
    writeMemberReferenceFromReference(node.targetReference);
  }

  @override
  void visitTypedefTearOff(TypedefTearOff node) {
    writeTypeParameterList(node.typeParameters);
    state = SYMBOL;
    writeSymbol('.(');
    writeNode(node.expression);
    if (node.typeArguments.isNotEmpty) {
      writeSymbol('<');
      writeList(node.typeArguments, writeType);
      writeSymbol('>');
    }
    writeSymbol(')');
    state = WORD;
  }

  @override
  void visitRecordIndexGet(RecordIndexGet node) {
    writeExpression(node.receiver, Precedence.PRIMARY);
    writeSymbol('.\$${node.index + 1}');
    writeSymbol('{');
    writeType(node.receiverType.positional[node.index]);
    writeSymbol('}');
  }

  @override
  void visitRecordNameGet(RecordNameGet node) {
    writeExpression(node.receiver, Precedence.PRIMARY);
    writeSymbol('.${node.name}');
    writeSymbol('{');
    // TODO(johnniwinther): Should we store the result type in the node?
    writeType(node.receiverType.named
        .singleWhere((element) => element.name == node.name)
        .type);
    writeSymbol('}');
  }

  @override
  void visitExpressionStatement(ExpressionStatement node) {
    writeIndentation();
    writeExpression(node.expression);
    endLine(';');
  }

  void writeBlockBody(List<Statement> statements, {bool asExpression = false}) {
    if (statements.isEmpty) {
      asExpression ? writeSymbol('{}') : endLine('{}');
      return;
    }
    endLine('{');
    ++indentation;
    statements.forEach(writeNode);
    --indentation;
    writeIndentation();
    asExpression ? writeSymbol('}') : endLine('}');
  }

  @override
  void visitBlock(Block node) {
    writeIndentation();
    writeBlockBody(node.statements);
  }

  @override
  void visitAssertBlock(AssertBlock node) {
    writeIndentation();
    writeSpaced('assert');
    writeBlockBody(node.statements);
  }

  @override
  void visitEmptyStatement(EmptyStatement node) {
    writeIndentation();
    endLine(';');
  }

  @override
  void visitAssertStatement(AssertStatement node, {bool asExpression = false}) {
    if (!asExpression) {
      writeIndentation();
    }
    writeWord('assert');
    writeSymbol('(');
    writeExpression(node.condition);
    Expression? message = node.message;
    if (message != null) {
      writeComma();
      writeExpression(message);
    }
    if (!asExpression) {
      endLine(');');
    } else {
      writeSymbol(')');
    }
  }

  @override
  void visitLabeledStatement(LabeledStatement node) {
    writeIndentation();
    writeWord(syntheticNames.nameLabeledStatement(node));
    endLine(':');
    writeNode(node.body);
  }

  @override
  void visitBreakStatement(BreakStatement node) {
    writeIndentation();
    writeWord('break');
    writeWord(syntheticNames.nameLabeledStatement(node.target));
    endLine(';');
  }

  @override
  void visitWhileStatement(WhileStatement node) {
    writeIndentation();
    writeSpaced('while');
    writeSymbol('(');
    writeExpression(node.condition);
    writeSymbol(')');
    writeBody(node.body);
  }

  @override
  void visitDoStatement(DoStatement node) {
    writeIndentation();
    writeWord('do');
    writeBody(node.body);
    writeIndentation();
    writeSpaced('while');
    writeSymbol('(');
    writeExpression(node.condition);
    endLine(')');
  }

  @override
  void visitForStatement(ForStatement node) {
    writeIndentation();
    writeSpaced('for');
    writeSymbol('(');
    writeList(node.variables, writeVariableDeclaration);
    writeComma(';');
    Expression? condition = node.condition;
    if (condition != null) {
      writeExpression(condition);
    }
    writeComma(';');
    writeList(node.updates, writeExpression);
    writeSymbol(')');
    writeBody(node.body);
  }

  @override
  void visitForInStatement(ForInStatement node) {
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

  @override
  void visitSwitchStatement(SwitchStatement node) {
    writeIndentation();
    writeWord('switch');
    writeSymbol('(');
    writeExpression(node.expression);
    writeSymbol(')');
    if (node.isExplicitlyExhaustive) {
      writeWord(" /*isExplicitlyExhaustive*/");
    }
    endLine(' {');
    ++indentation;
    node.cases.forEach(writeNode);
    --indentation;
    writeIndentation();
    endLine('}');
  }

  @override
  void visitSwitchCase(SwitchCase node) {
    String label = syntheticNames.nameSwitchCase(node);
    writeIndentation();
    writeWord(label);
    endLine(':');
    for (Expression expression in node.expressions) {
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

  @override
  void visitContinueSwitchStatement(ContinueSwitchStatement node) {
    writeIndentation();
    writeWord('continue');
    writeWord(syntheticNames.nameSwitchCase(node.target));
    endLine(';');
  }

  @override
  void visitIfStatement(IfStatement node) {
    writeIndentation();
    writeWord('if');
    writeSymbol('(');
    writeExpression(node.condition);
    writeSymbol(')');
    writeBody(node.then);
    Statement? otherwise = node.otherwise;
    if (otherwise != null) {
      writeIndentation();
      writeWord('else');
      writeBody(otherwise);
    }
  }

  @override
  void visitReturnStatement(ReturnStatement node) {
    writeIndentation();
    writeWord('return');
    Expression? expression = node.expression;
    if (expression != null) {
      writeSpace();
      writeExpression(expression);
    }
    endLine(';');
  }

  @override
  void visitTryCatch(TryCatch node) {
    writeIndentation();
    writeWord('try');
    writeBody(node.body);
    node.catches.forEach(writeNode);
  }

  @override
  void visitCatch(Catch node) {
    writeIndentation();
    // ignore: unnecessary_null_comparison
    if (node.guard != null) {
      writeWord('on');
      writeType(node.guard);
      writeSpace();
    }
    writeWord('catch');
    writeSymbol('(');
    VariableDeclaration? exception = node.exception;
    if (exception != null) {
      writeVariableDeclaration(exception);
    } else {
      writeWord('no-exception-var');
    }
    VariableDeclaration? stackTrace = node.stackTrace;
    if (stackTrace != null) {
      writeComma();
      writeVariableDeclaration(stackTrace);
    }
    writeSymbol(')');
    writeBody(node.body);
  }

  @override
  void visitTryFinally(TryFinally node) {
    writeIndentation();
    writeWord('try');
    writeBody(node.body);
    writeIndentation();
    writeWord('finally');
    writeBody(node.finalizer);
  }

  @override
  void visitYieldStatement(YieldStatement node) {
    writeIndentation();
    if (node.isYieldStar) {
      writeWord('yield*');
    } else {
      writeWord('yield');
    }
    writeExpression(node.expression);
    endLine(';');
  }

  @override
  void visitVariableDeclaration(VariableDeclaration node) {
    writeIndentation();
    writeVariableDeclaration(node, useVarKeyword: true);
    endLine(';');
  }

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {
    writeAnnotationList(node.variable.annotations);
    writeIndentation();
    writeWord('function');
    // ignore: unnecessary_null_comparison
    if (node.function != null) {
      writeFunction(node.function, name: getVariableName(node.variable));
    } else {
      writeWord(getVariableName(node.variable));
      endLine('...;');
    }
  }

  void writeVariableDeclaration(VariableDeclaration node,
      {bool useVarKeyword = false}) {
    if (showOffsets) writeWord("[${node.fileOffset}]");
    if (showMetadata) writeMetadata(node);
    writeAnnotationList(node.annotations, separateLines: false);
    writeModifier(node.isLowered, 'lowered');
    writeModifier(node.isLate, 'late');
    writeModifier(node.isRequired, 'required');
    writeModifier(node.isCovariantByDeclaration, 'covariant-by-declaration');
    writeModifier(node.isCovariantByClass, 'covariant-by-class');
    writeModifier(node.isFinal, 'final');
    writeModifier(node.isConst, 'const');
    writeModifier(node.isSynthesized && node.name != null, 'synthesized');
    writeModifier(node.isHoisted, 'hoisted');
    bool hasImplicitInitializer = node.initializer is NullLiteral ||
        (node.initializer is ConstantExpression &&
            (node.initializer as ConstantExpression).constant is NullConstant);
    if ((node.initializer == null || hasImplicitInitializer) &&
        node.hasDeclaredInitializer) {
      writeModifier(node.hasDeclaredInitializer, 'has-declared-initializer');
    } else if (node.initializer != null &&
        !hasImplicitInitializer &&
        !node.hasDeclaredInitializer) {
      writeModifier(node.hasDeclaredInitializer, 'has-no-declared-initializer');
    }
    // ignore: unnecessary_null_comparison
    if (node.type != null) {
      writeAnnotatedType(node.type, annotator?.annotateVariable(this, node));
    }
    // ignore: unnecessary_null_comparison
    if (useVarKeyword && !node.isFinal && !node.isConst && node.type == null) {
      writeWord('var');
    }
    writeWord(getVariableName(node));
    Expression? initializer = node.initializer;
    if (initializer != null) {
      writeSpaced('=');
      writeExpression(initializer);
    }
  }

  @override
  void visitArguments(Arguments node) {
    if (node.types.isNotEmpty) {
      writeSymbol('<');
      writeList(node.types, writeType);
      writeSymbol('>');
    }
    writeSymbol('(');
    Iterable<TreeNode> allArgs =
        <List<TreeNode>>[node.positional, node.named].expand((x) => x);
    writeList(allArgs, writeNode);
    writeSymbol(')');
  }

  @override
  void visitNamedExpression(NamedExpression node) {
    writeWord(node.name);
    writeComma(':');
    writeExpression(node.value);
  }

  @override
  void defaultStatement(Statement node) {
    writeIndentation();
    endLine('${node.runtimeType}');
  }

  @override
  void visitInvalidInitializer(InvalidInitializer node) {
    writeWord('invalid-initializer');
  }

  @override
  void visitFieldInitializer(FieldInitializer node) {
    writeMemberReferenceFromReference(node.fieldReference);
    writeSpaced('=');
    writeExpression(node.value);
  }

  @override
  void visitSuperInitializer(SuperInitializer node) {
    writeWord('super');
    writeMemberReferenceFromReference(node.targetReference);
    writeNode(node.arguments);
  }

  @override
  void visitRedirectingInitializer(RedirectingInitializer node) {
    writeWord('this');
    writeMemberReferenceFromReference(node.targetReference);
    writeNode(node.arguments);
  }

  @override
  void visitLocalInitializer(LocalInitializer node) {
    writeVariableDeclaration(node.variable);
  }

  @override
  void visitAssertInitializer(AssertInitializer node) {
    visitAssertStatement(node.statement, asExpression: true);
  }

  @override
  void defaultInitializer(Initializer node) {
    writeIndentation();
    endLine(': ${node.runtimeType}');
  }

  void writeNullability(Nullability nullability, {bool inComment = false}) {
    switch (nullability) {
      case Nullability.legacy:
        writeSymbol('*');
        if (!inComment) {
          state = WORD; // Disallow a word immediately after the '*'.
        }
        break;
      case Nullability.nullable:
        writeSymbol('?');
        if (!inComment) {
          state = WORD; // Disallow a word immediately after the '?'.
        }
        break;
      case Nullability.undetermined:
        writeSymbol('%');
        if (!inComment) {
          state = WORD; // Disallow a word immediately after the '%'.
        }
        break;
      case Nullability.nonNullable:
        if (inComment) {
          writeSymbol("!");
        }
        break;
    }
  }

  void writeDartTypeNullability(DartType type, {bool inComment = false}) {
    if (type is InvalidType) {
      writeNullability(Nullability.undetermined);
    } else {
      writeNullability(type.nullability, inComment: inComment);
    }
  }

  @override
  void visitInvalidType(InvalidType node) {
    writeWord('invalid-type');
  }

  @override
  void visitDynamicType(DynamicType node) {
    writeWord('dynamic');
  }

  @override
  void visitVoidType(VoidType node) {
    writeWord('void');
  }

  @override
  void visitNeverType(NeverType node) {
    writeWord('Never');
    writeNullability(node.nullability);
  }

  @override
  void visitNullType(NullType node) {
    writeWord('Null');
  }

  @override
  void visitInterfaceType(InterfaceType node) {
    writeClassReferenceFromReference(node.className);
    if (node.typeArguments.isNotEmpty) {
      writeSymbol('<');
      writeList(node.typeArguments, writeType);
      writeSymbol('>');
      state = WORD; // Disallow a word immediately after the '>'.
    }
    writeNullability(node.nullability);
  }

  @override
  void visitExtensionType(ExtensionType node) {
    writeExtensionReferenceFromReference(node.extensionReference);
    if (node.typeArguments.isNotEmpty) {
      writeSymbol('<');
      writeList(node.typeArguments, writeType);
      writeSymbol('>');
      state = Printer.WORD;
    }
    writeNullability(node.declaredNullability);
  }

  @override
  void visitInlineType(InlineType node) {
    writeInlineClassReferenceFromReference(node.inlineClassReference);
    if (node.typeArguments.isNotEmpty) {
      writeSymbol('<');
      writeList(node.typeArguments, writeType);
      writeSymbol('>');
      state = Printer.WORD;
    }
    writeNullability(node.declaredNullability);
  }

  @override
  void visitFutureOrType(FutureOrType node) {
    writeWord('FutureOr');
    writeSymbol('<');
    writeNode(node.typeArgument);
    writeSymbol('>');
    writeNullability(node.declaredNullability);
  }

  @override
  void visitFunctionType(FunctionType node) {
    writeFunctionType(node);
  }

  @override
  void visitRecordType(RecordType node) {
    writeSymbol('(');
    writeList(node.positional, writeType);
    if (node.positional.isNotEmpty && node.named.isNotEmpty) {
      writeComma(',');
    }
    if (node.named.isNotEmpty) {
      writeSymbol('{');
      writeList(node.named, writeNode);
      writeSymbol('}');
    }
    writeSymbol(')');
    writeNullability(node.declaredNullability);
    // Disallow a word immediately after the record type.
    state = WORD;
  }

  @override
  void visitNamedType(NamedType node) {
    writeModifier(node.isRequired, 'required');
    writeWord(node.name);
    writeSymbol(':');
    writeSpace();
    writeType(node.type);
  }

  @override
  void visitTypeParameterType(TypeParameterType node) {
    writeTypeParameterReference(node.parameter);
    writeNullability(node.declaredNullability);
  }

  @override
  void visitIntersectionType(IntersectionType node) {
    writeType(node.left);
    writeSpaced('&');
    writeType(node.right);
    writeWord("/* '");

    writeDartTypeNullability(node.left, inComment: true);
    writeWord("' & '");
    writeDartTypeNullability(node.right, inComment: true);
    writeWord("' = '");
    writeNullability(node.nullability, inComment: true);
    writeWord("' */");
  }

  @override
  void visitTypeParameter(TypeParameter node) {
    writeModifier(node.isCovariantByClass, 'covariant-by-class');
    writeAnnotationList(node.annotations, separateLines: false);
    if (node.variance != Variance.covariant) {
      writeWord(const <String>[
        "unrelated",
        "covariant",
        "contravariant",
        "invariant"
      ][node.variance]);
    }
    writeWord(getTypeParameterName(node));
    writeSpaced('extends');
    writeType(node.bound);
    if (node.defaultType != node.bound) {
      writeSpaced('=');
      writeType(node.defaultType);
    }
  }

  void writeConstantReference(Constant node) {
    writeWord(syntheticNames.nameConstant(node));
  }

  @override
  void visitConstantExpression(ConstantExpression node) {
    writeConstantReference(node.constant);
  }

  @override
  void defaultConstant(Constant node) {
    writeIndentation();
    writeConstantReference(node);
    writeSpaced('=');
    endLine('${node.runtimeType}');
  }

  @override
  void visitNullConstant(NullConstant node) {
    writeIndentation();
    writeConstantReference(node);
    writeSpaced('=');
    endLine('${node.value}');
  }

  @override
  void visitBoolConstant(BoolConstant node) {
    writeIndentation();
    writeConstantReference(node);
    writeSpaced('=');
    endLine('${node.value}');
  }

  @override
  void visitIntConstant(IntConstant node) {
    writeIndentation();
    writeConstantReference(node);
    writeSpaced('=');
    endLine('${node.value}');
  }

  @override
  void visitDoubleConstant(DoubleConstant node) {
    writeIndentation();
    writeConstantReference(node);
    writeSpaced('=');
    endLine('${node.value}');
  }

  @override
  void visitSymbolConstant(SymbolConstant node) {
    writeIndentation();
    writeConstantReference(node);
    writeSpaced('=');
    Reference? libraryReference = node.libraryReference;
    String text = libraryReference != null
        ? '#${libraryReference.asLibrary.importUri}::${node.name}'
        : '#${node.name}';
    endLine('${text}');
  }

  @override
  void visitListConstant(ListConstant node) {
    writeIndentation();
    writeConstantReference(node);
    writeSpaced('=');
    writeSymbol('<');
    writeType(node.typeArgument);
    writeSymbol('>[');
    writeList(node.entries, writeConstantReference);
    endLine(']');
  }

  @override
  void visitSetConstant(SetConstant node) {
    writeIndentation();
    writeConstantReference(node);
    writeSpaced('=');
    writeSymbol('<');
    writeType(node.typeArgument);
    writeSymbol('>{');
    writeList(node.entries, writeConstantReference);
    endLine('}');
  }

  @override
  void visitMapConstant(MapConstant node) {
    writeIndentation();
    writeConstantReference(node);
    writeSpaced('=');
    writeSymbol('<');
    writeList([node.keyType, node.valueType], writeType);
    writeSymbol('>{');
    writeList(node.entries, (ConstantMapEntry entry) {
      writeConstantReference(entry.key);
      writeSymbol(':');
      writeConstantReference(entry.value);
    });
    endLine('}');
  }

  @override
  void visitTypeLiteralConstant(TypeLiteralConstant node) {
    writeIndentation();
    writeConstantReference(node);
    writeSpaced('=');
    writeWord('${node.runtimeType}');
    writeSymbol('(');
    writeNode(node.type);
    endLine(')');
  }

  @override
  void visitInstanceConstant(InstanceConstant node) {
    writeIndentation();
    writeConstantReference(node);
    writeSpaced('=');
    writeClassReferenceFromReference(node.classReference);
    if (!node.typeArguments.isEmpty) {
      writeSymbol('<');
      writeList(node.typeArguments, writeType);
      writeSymbol('>');
    }

    writeSymbol(' {');
    writeList(node.fieldValues.entries, (MapEntry<Reference, Constant> entry) {
      if (entry.key.node != null) {
        writeWord('${entry.key.asField.name.text}');
      } else {
        writeWord('${entry.key.canonicalName!.name}');
      }
      writeSymbol(':');
      writeConstantReference(entry.value);
    });
    endLine('}');
  }

  @override
  void visitRecordConstant(RecordConstant node) {
    writeIndentation();
    writeConstantReference(node);
    writeSpaced('=');
    writeSymbol('(');
    writeList(node.positional, writeConstantReference);
    if (node.named.isNotEmpty) {
      if (node.positional.isNotEmpty) writeComma();
      writeSymbol('{');
      writeList(node.named.entries, (MapEntry<String, Constant> entry) {
        writeWord(entry.key);
        writeSymbol(':');
        writeConstantReference(entry.value);
      });
      writeSymbol('}');
    }
    writeSymbol(')');
    endLine();
  }

  @override
  void visitInstantiationConstant(InstantiationConstant node) {
    writeIndentation();
    writeConstantReference(node);
    writeSpaced('=');
    writeWord('instantiation');
    writeSpace();
    writeConstantReference(node.tearOffConstant);
    writeSpace();
    writeSymbol('<');
    writeList(node.types, writeType);
    writeSymbol('>');
    endLine();
  }

  @override
  void visitStringConstant(StringConstant node) {
    writeIndentation();
    writeConstantReference(node);
    writeSpaced('=');
    endLine('"${escapeString(node.value)}"');
  }

  @override
  void visitStaticTearOffConstant(StaticTearOffConstant node) {
    writeIndentation();
    writeConstantReference(node);
    writeSpaced('=');
    writeWord('static-tearoff');
    writeSpace();
    writeMemberReferenceFromReference(node.targetReference);
    endLine();
  }

  @override
  void visitTypedefTearOffConstant(TypedefTearOffConstant node) {
    writeIndentation();
    writeConstantReference(node);
    writeSpaced('=');
    writeWord('typedef-tearoff');
    writeSpace();
    writeTypeParameterList(node.parameters);
    state = SYMBOL;
    writeSymbol('.(');
    writeConstantReference(node.tearOffConstant);
    if (node.types.isNotEmpty) {
      writeSymbol('<');
      writeList(node.types, writeType);
      writeSymbol('>');
    }
    writeSymbol(')');
    state = WORD;
    endLine();
  }

  @override
  void visitUnevaluatedConstant(UnevaluatedConstant node) {
    writeIndentation();
    writeConstantReference(node);
    writeSpaced('=');
    writeSymbol('eval');
    writeSpace();
    writeExpression(node.expression);
    endLine();
  }

  @override
  void visitConstructorTearOffConstant(ConstructorTearOffConstant node) {
    writeIndentation();
    writeConstantReference(node);
    writeSpaced('=');
    writeWord('constructor-tearoff');
    writeSpace();
    writeMemberReferenceFromReference(node.targetReference);
    endLine();
  }

  @override
  void visitRedirectingFactoryTearOffConstant(
      RedirectingFactoryTearOffConstant node) {
    writeIndentation();
    writeConstantReference(node);
    writeSpaced('=');
    writeWord('redirecting-factory-tearoff');
    writeSpace();
    writeMemberReferenceFromReference(node.targetReference);
    endLine();
  }

  @override
  void defaultNode(Node node) {
    write('<${node.runtimeType}>');
  }
}

class Precedence implements ExpressionVisitor<int> {
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

  static const Map<String?, int> binaryPrecedence = const {
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

  @override
  int defaultExpression(Expression node) => EXPRESSION;

  @override
  int visitInvalidExpression(InvalidExpression node) => CALLEE;

  @override
  int visitInstanceInvocation(InstanceInvocation node) => CALLEE;

  @override
  int visitInstanceGetterInvocation(InstanceGetterInvocation node) => CALLEE;

  @override
  int visitDynamicInvocation(DynamicInvocation node) => CALLEE;

  @override
  int visitFunctionInvocation(FunctionInvocation node) => CALLEE;

  @override
  int visitLocalFunctionInvocation(LocalFunctionInvocation node) => CALLEE;

  @override
  int visitEqualsCall(EqualsCall node) => EQUALITY;

  @override
  int visitEqualsNull(EqualsNull node) => EQUALITY;

  @override
  int visitAbstractSuperMethodInvocation(AbstractSuperMethodInvocation node) =>
      CALLEE;

  @override
  int visitSuperMethodInvocation(SuperMethodInvocation node) => CALLEE;

  @override
  int visitStaticInvocation(StaticInvocation node) => CALLEE;

  @override
  int visitConstructorInvocation(ConstructorInvocation node) => CALLEE;

  @override
  int visitNot(Not node) => PREFIX;

  @override
  int visitNullCheck(NullCheck node) => PRIMARY;

  @override
  int visitLogicalExpression(LogicalExpression node) =>
      binaryPrecedence[logicalExpressionOperatorToString(node.operatorEnum)]!;

  @override
  int visitConditionalExpression(ConditionalExpression node) => CONDITIONAL;

  @override
  int visitStringConcatenation(StringConcatenation node) => PRIMARY;

  @override
  int visitIsExpression(IsExpression node) => RELATIONAL;

  @override
  int visitAsExpression(AsExpression node) => RELATIONAL;

  @override
  int visitSymbolLiteral(SymbolLiteral node) => PRIMARY;

  @override
  int visitTypeLiteral(TypeLiteral node) => PRIMARY;

  @override
  int visitThisExpression(ThisExpression node) => CALLEE;

  @override
  int visitRethrow(Rethrow node) => PRIMARY;

  @override
  int visitThrow(Throw node) => EXPRESSION;

  @override
  int visitListLiteral(ListLiteral node) => PRIMARY;

  @override
  int visitSetLiteral(SetLiteral node) => PRIMARY;

  @override
  int visitMapLiteral(MapLiteral node) => PRIMARY;

  @override
  int visitRecordLiteral(RecordLiteral node) => PRIMARY;

  @override
  int visitAwaitExpression(AwaitExpression node) => PREFIX;

  @override
  int visitFunctionExpression(FunctionExpression node) => EXPRESSION;

  @override
  int visitStringLiteral(StringLiteral node) => CALLEE;

  @override
  int visitIntLiteral(IntLiteral node) => CALLEE;

  @override
  int visitDoubleLiteral(DoubleLiteral node) => CALLEE;

  @override
  int visitBoolLiteral(BoolLiteral node) => CALLEE;

  @override
  int visitNullLiteral(NullLiteral node) => CALLEE;

  @override
  int visitVariableGet(VariableGet node) => PRIMARY;

  @override
  int visitVariableSet(VariableSet node) => EXPRESSION;

  @override
  int visitInstanceGet(InstanceGet node) => PRIMARY;

  @override
  int visitDynamicGet(DynamicGet node) => PRIMARY;

  @override
  int visitInstanceTearOff(InstanceTearOff node) => PRIMARY;

  @override
  int visitFunctionTearOff(FunctionTearOff node) => PRIMARY;

  @override
  int visitAbstractSuperPropertyGet(AbstractSuperPropertyGet node) => PRIMARY;

  @override
  int visitRecordIndexGet(RecordIndexGet node) => PRIMARY;

  @override
  int visitRecordNameGet(RecordNameGet node) => PRIMARY;

  @override
  int visitAbstractSuperPropertySet(AbstractSuperPropertySet node) =>
      EXPRESSION;

  @override
  int visitSuperPropertyGet(SuperPropertyGet node) => PRIMARY;

  @override
  int visitSuperPropertySet(SuperPropertySet node) => EXPRESSION;

  @override
  int visitStaticGet(StaticGet node) => PRIMARY;

  @override
  int visitStaticTearOff(StaticTearOff node) => PRIMARY;

  @override
  int visitStaticSet(StaticSet node) => EXPRESSION;

  @override
  int visitConstructorTearOff(ConstructorTearOff node) => PRIMARY;

  @override
  int visitRedirectingFactoryTearOff(RedirectingFactoryTearOff node) => PRIMARY;

  @override
  int visitTypedefTearOff(TypedefTearOff node) => EXPRESSION;

  @override
  int visitLet(Let node) => EXPRESSION;

  @override
  int defaultBasicLiteral(BasicLiteral node) => CALLEE;

  @override
  int visitBlockExpression(BlockExpression node) => EXPRESSION;

  @override
  int visitCheckLibraryIsLoaded(CheckLibraryIsLoaded node) => EXPRESSION;

  @override
  int visitConstantExpression(ConstantExpression node) => PRIMARY;

  @override
  int visitDynamicSet(DynamicSet node) => EXPRESSION;

  @override
  int visitFileUriExpression(FileUriExpression node) => EXPRESSION;

  @override
  int visitInstanceCreation(InstanceCreation node) => EXPRESSION;

  @override
  int visitInstanceSet(InstanceSet node) => EXPRESSION;

  @override
  int visitInstantiation(Instantiation node) => EXPRESSION;

  @override
  int visitListConcatenation(ListConcatenation node) => EXPRESSION;

  @override
  int visitLoadLibrary(LoadLibrary node) => EXPRESSION;

  @override
  int visitMapConcatenation(MapConcatenation node) => EXPRESSION;

  @override
  int visitSetConcatenation(SetConcatenation node) => EXPRESSION;

  @override
  int visitSwitchExpression(SwitchExpression node) => PRIMARY;

  @override
  int visitPatternAssignment(PatternAssignment node) => EXPRESSION;
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
}
