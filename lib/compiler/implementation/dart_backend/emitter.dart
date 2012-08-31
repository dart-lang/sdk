// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

String emitCode(
      Compiler compiler,
      Unparser unparser,
      Map<LibraryElement, String> imports,
      Collection<Element> topLevelElements,
      Map<ClassElement, Collection<Element>> classMembers) {
  final sb = new StringBuffer();
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
        sb.add(unparser.unparse(variableList.parseNode(compiler)));
      }
    } else {
      sb.add(unparser.unparse(element.parseNode(compiler)));
    }
  }

  void outputClass(ClassElement classElement, Collection<Element> members) {
    ClassNode classNode = classElement.parseNode(compiler);
    // classElement.beginToken is 'class', 'interface', or 'abstract'.
    sb.add(classNode.beginToken.slowToString());
    if (classNode.beginToken.slowToString() == 'abstract') {
      sb.add(' ');
      sb.add(classNode.beginToken.next.slowToString());  // 'class'
    }
    sb.add(' ');
    sb.add(unparser.unparse(classNode.name));
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
    members.forEach((element) {
      // TODO(smok): Filter out default constructors here.
      outputElement(element);
    });
    sb.add('}');
  }

  imports.forEach((libraryElement, prefix) {
    sb.add('#import("${libraryElement.uri}",prefix:"$prefix");');
  });

  for (final element in topLevelElements) {
    if (element is ClassElement) {
      outputClass(element, classMembers[element]);
    } else {
      outputElement(element);
    }
  }

  return sb.toString();
}
