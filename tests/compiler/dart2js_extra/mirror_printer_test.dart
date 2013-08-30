// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Prints all information about all mirrors. This tests that it is possible to
/// enumerate all reflective information without crashing.

// Note: Adding imports below is fine for regression tests. For example,
// 'crash_library_metadata.dart' is imported to ensure the compiler doesn't
// crash.

// TODO(ahe): This test should be extended until we are sure all data is
// printed.

library test.mirror_printer_test;

@MirrorsUsed(targets: '*')
import 'dart:mirrors';

import 'crash_library_metadata.dart'; // This would crash dart2js.

// Importing dart:html to make things interesting.
import 'dart:html';

class MirrorPrinter {
  final StringBuffer buffer;
  final TypeMirror dynamicType = currentMirrorSystem().dynamicType;

  int indentationLevel = 0;

  MirrorPrinter(this.buffer);

  void w(object) {
    buffer.write(object);
  }

  n(Symbol symbol) => MirrorSystem.getName(symbol);

  void indented(action) {
    indentationLevel++;
    action();
    indentationLevel--;
  }

  get indent {
    for (int i = 0; i < indentationLevel; i++) {
      w('  ');
    }
  }

  String stringifyInstance(InstanceMirror mirror) {
    var reflectee = mirror.reflectee;
    if (reflectee is String) return '"${reflectee}"';
    if (reflectee is Null || reflectee is bool || reflectee is num ||
        reflectee is List || reflectee is Map) {
      return '$reflectee';
    }
    StringBuffer buffer = new StringBuffer();
    Map<Symbol, VariableMirror> variables = mirror.type.variables;
    buffer
        ..write(n(mirror.type.simpleName))
        ..write('(');
    bool first = true;
    variables.forEach((Symbol name, VariableMirror variable) {
      if (variable.isStatic) return;
      // TODO(ahe): Include superclasses.
      if (first) {
        first = false;
      } else {
        buffer.write(', ');
      }
      buffer
          ..write(n(name))
          ..write(': ')
          ..write(stringifyInstance(mirror.getField(name)));
    });
    return buffer
        ..write(')')
        ..toString();
  }

  String stringifyMetadata(InstanceMirror mirror) {
    return '@${stringifyInstance(mirror)}';
  }

  bool writeType(TypeMirror mirror) {
    if (mirror == null || mirror == dynamicType) return false;
    w('${n(mirror.simpleName)} ');
    return true;
  }

  writeVariable(VariableMirror mirror) {
    bool needsVar = true;
    if (mirror.isStatic) w('static ');
    // TODO(ahe): What about const?
    if (mirror.isFinal) {
      w('final ');
      needsVar = false;
    }

    if (writeType(mirror.type)) needsVar = false;

    if (needsVar) {
      w('var ');
    }
    w('${n(mirror.simpleName)};');
  }

  writeMethod(MethodMirror mirror) {
    writeType(mirror.returnType);
    if (mirror.isOperator) {
      w('operator ');
    }
    if (mirror.isGetter) {
      w('get ');
    }
    if (mirror.isSetter) {
      w('set ');
    }
    w('${n(mirror.simpleName)}');
    if (!mirror.isGetter) {
      w('()');
    }
    w(';');
  }

  writeClass(ClassMirror mirror) {
    // TODO(ahe): Write 'abstract' if [mirror] is abstract.
    w('class ${n(mirror.simpleName)}');
    // TODO(ahe): Write superclass and interfaces.
    w(' {');
    bool first = true;
    indented(() {
      for (DeclarationMirror declaration in mirror.members.values) {
        if (first) {
          first = false;
        } else {
          w('\n');
        }
        writeDeclaration(declaration);
      }
    });
    w('\n}\n');
  }

  writeDeclaration(DeclarationMirror declaration) {
    w('\n');
    var metadata = declaration.metadata;
    if (!metadata.isEmpty) {
      indent;
      buffer.writeAll(metadata.map(stringifyMetadata), ' ');
      w('\n');
    }
    indent;
    if (declaration is ClassMirror) {
      writeClass(declaration);
    } else if (declaration is VariableMirror) {
      writeVariable(declaration);
    } else if (declaration is MethodMirror) {
      writeMethod(declaration);
    } else {
      // TODO(ahe): Test other subclasses of DeclarationMirror.
      w('$declaration');
    }
  }

  writeLibrary(LibraryMirror library) {
    w('library ${n(library.simpleName)};\n\n');
    library.members.values.forEach(writeDeclaration);
    w('\n');
  }

  static StringBuffer stringify(Map<Uri, LibraryMirror> libraries) {
    StringBuffer buffer = new StringBuffer();
    libraries.values.forEach(new MirrorPrinter(buffer).writeLibrary);
    return buffer;
  }
}

main() {
  print(MirrorPrinter.stringify(currentMirrorSystem().libraries));
}
