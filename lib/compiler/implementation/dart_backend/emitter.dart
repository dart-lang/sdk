// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

String emitCode(
      Compiler compiler,
      Unparser unparser,
      Map<LibraryElement, String> imports,
      Collection<Element> topLevelElements,
      Map<ClassElement, Collection<Element>> classMembers) {
  final processedVariableLists = new Set<VariableListElement>();

  void outputElement(Element element) {
    if (element is SynthesizedConstructorElement) return;
    if (element.isField()) {
      assert(element is VariableElement);
      // Different VariableElement's may refer to the same VariableListElement.
      // Output this list only once.
      // TODO: only emit used variables.
      VariableElement variableElement = element;
      final variableList = variableElement.variables;
      if (!processedVariableLists.contains(variableList)) {
        processedVariableLists.add(variableList);
        unparser.unparse(variableList.parseNode(compiler));
      }
    } else {
      unparser.unparse(element.parseNode(compiler));
    }
  }

  void outputClass(ClassElement classElement, Collection<Element> members) {
    ClassNode classNode = classElement.parseNode(compiler);
    // classElement.beginToken is 'class', 'interface', or 'abstract'.
    unparser.addToken(classNode.beginToken);
    if (classNode.beginToken.stringValue == 'abstract') {
      unparser.addToken(classNode.beginToken.next);
    }
    unparser.unparse(classNode.name);
    if (classNode.typeParameters !== null) {
      unparser.unparse(classNode.typeParameters);
    }
    if (classNode.extendsKeyword !== null) {
      unparser.addString(' ');
      unparser.addToken(classNode.extendsKeyword);
      unparser.unparse(classNode.superclass);
    }
    if (!classNode.interfaces.isEmpty()) {
      unparser.addString(' ');
      unparser.unparse(classNode.interfaces);
    }
    if (classNode.defaultClause !== null) {
      unparser.addString(' default ');
      unparser.unparse(classNode.defaultClause);
    }
    unparser.addString('{');
    members.forEach((element) {
      // TODO(smok): Filter out default constructors here.
      outputElement(element);
    });
    unparser.addString('}');
  }

  imports.forEach((libraryElement, prefix) {
    unparser.addString('#import("${libraryElement.uri}",prefix:"$prefix");');
  });

  for (final element in topLevelElements) {
    if (element is ClassElement) {
      outputClass(element, classMembers[element]);
    } else {
      outputElement(element);
    }
  }
}
