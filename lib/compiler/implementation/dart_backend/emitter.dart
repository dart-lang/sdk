// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * Dart backend helper for converting program IR back to source code.
 */
class Emitter {

  final Compiler compiler;
  final StringBuffer sb;
  final ConflictingRenamer renamer;
  final Set<VariableListElement> processedVariableLists;

  Emitter(this.compiler, this.renamer) :
      sb = new StringBuffer(),
      processedVariableLists = new Set<VariableListElement>();

  /**
   * Outputs given class element with selected inner elements.
   */
  void outputClass(ClassElement classElement, Set<Element> innerElements) {
    Unparser unparser = new Unparser.withRenamer(renamer.rename);
    ClassNode classNode = classElement.parseNode(compiler);
    // classElement.beginToken is 'class', 'interface', or 'abstract'.
    sb.add(classNode.beginToken.slowToString());
    if (classNode.beginToken.slowToString() == 'abstract') {
      sb.add(' ');
      sb.add(classNode.beginToken.next.slowToString());  // 'class'
    }
    sb.add(' ');
    sb.add(renamer.renameElement(classElement));
    if (classNode.typeParameters !== null) {
      sb.add(unparser.unparse(classNode.typeParameters));
    }
    if (classNode.extendsKeyword !== null) {
      sb.add(' ');
      classNode.extendsKeyword.value.printOn(sb);
      sb.add(' ');
      sb.add(unparser.unparse(classNode.superclass));
    }
    if (!classNode.interfaces.isEmpty()) {
      sb.add(' ');
      sb.add(unparser.unparse(classNode.interfaces));
    }
    if (classNode.defaultClause !== null) {
      sb.add(' default ');
      sb.add(unparser.unparse(classNode.defaultClause));
    }
    sb.add('{');
    innerElements.forEach((element) {
      // TODO(smok): Filter out default constructors here.
      outputElement(element);
    });
    sb.add('}');
  }

  void outputElement(Element element) {
    Unparser unparser = new Unparser.withRenamer(renamer.rename);
    // TODO(smok): Figure out why AbstractFieldElement appears here,
    // we have used getters/setters resolved instead of it.
    if (element is SynthesizedConstructorElement
        || element is AbstractFieldElement) return;
    if (element.isField()) {
      assert(element is VariableElement);
      // Different VariableElement's may refer to the same VariableListElement.
      // Output this list only once.
      // TODO: only emit used variables.
      final variableList = (element as VariableElement).variables;
      if (!processedVariableLists.contains(variableList)) {
        processedVariableLists.add(variableList);
        sb.add(unparser.unparse(variableList.parseNode(compiler)));
      }
    } else {
      sb.add(unparser.unparse(element.parseNode(compiler)));
    }
  }

  String toString() {
    final result = new StringBuffer();
    final libraries = compiler.libraries;
    for (final uri in libraries.getKeys()) {
      // Same library element may be a value for different uris as of now
      // e.g., core libraryElement is a value for both keys 'dart:core'
      // and full file name.  Only care about uris with dart scheme.
      if (!uri.startsWith('dart:')) continue;
      final lib = libraries[uri];
      if (renamer.imports.containsKey(lib)) {
        result.add('#import("$uri", prefix: "${renamer.imports[lib]}");');
      }
    }
    result.add(sb);
    return result.toString();
  }
}
