// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * Dart backend helper for converting program IR back to source code.
 */
class Emitter {

  final Compiler compiler;
  final StringBuffer sb;

  Emitter(this.compiler) : sb = new StringBuffer();

  /**
   * Outputs given class element with selected inner elements.
   */
  void outputClass(ClassElement classElement, Set<Element> innerElements) {
    ClassNode classNode = classElement.parseNode(compiler);
    // classElement.beginToken is 'class', 'interface', or 'abstract'.
    sb.add(classElement.beginToken.slowToString());
    if (classElement.beginToken.slowToString() == 'abstract') {
      sb.add(' ');
      sb.add(classElement.beginToken.next.slowToString());  // 'class'
    }
    sb.add(' ');
    sb.add(classNode.name.unparse());
    if (classNode.typeParameters !== null) {
      sb.add(classNode.typeParameters.unparse());
    }
    if (classNode.extendsKeyword !== null) {
      sb.add(' ');
      classNode.extendsKeyword.value.printOn(sb);
      sb.add(' ');
      sb.add(classNode.superclass.unparse());
    }
    if (!classNode.interfaces.isEmpty()) {
      sb.add(classElement.isInterface() ? ' extends ' : ' implements ');
      classNode.interfaces.nodes.printOn(sb, classNode.interfaces.delimiter);
    }
    if (classNode.defaultClause !== null) {
      sb.add(' default ');
      sb.add(classNode.defaultClause.unparse());
    }
    sb.add('{');
    innerElements.forEach((element) {
      // TODO(smok): Filter out default constructors here.
      outputElement(element);
    });
    sb.add('}');
  }

  void outputElement(Element element) {
    // TODO(smok): Figure out why AbstractFieldElement appears here,
    // we have used getters/setters resolved instead of it.
    if (element is SynthesizedConstructorElement
        || element is AbstractFieldElement) return;
    if (element.isField()) {
      assert(element is VariableElement);
      sb.add(element.variables.parseNode(compiler).unparse());
    } else {
      sb.add(element.parseNode(compiler).unparse());
    }
  }

  String toString() => sb.toString();
}
