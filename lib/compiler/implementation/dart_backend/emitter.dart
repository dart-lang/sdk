// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * Dart backend helper for converting program IR back to source code.
 */
class Emitter {

  final Compiler compiler;
  final StringBuffer sb;
  final Renamer renamer;

  Emitter(Compiler compiler) :
      this.compiler = compiler,
      sb = new StringBuffer(),
      renamer = new ConflictingRenamer(compiler);

  /**
   * Outputs given class element with selected inner elements.
   */
  void outputClass(ClassElement classElement, Set<Element> innerElements) {
    Unparser unparser = new Unparser(renamer);
    renamer.setContext(classElement.getCompilationUnit());
    ClassNode classNode = classElement.parseNode(compiler);
    // classElement.beginToken is 'class', 'interface', or 'abstract'.
    sb.add(classElement.beginToken.slowToString());
    if (classElement.beginToken.slowToString() == 'abstract') {
      sb.add(' ');
      sb.add(classElement.beginToken.next.slowToString());  // 'class'
    }
    sb.add(' ');
    sb.add(renamer.renameType(classElement.type));
    if (classNode.typeParameters !== null) {
      sb.add(unparser.unparse(classNode.typeParameters));
    }
    renamer.setContext(classElement);
    if (classNode.extendsKeyword !== null) {
      sb.add(' ');
      classNode.extendsKeyword.value.printOn(sb);
      sb.add(' ');
      sb.add(renamer.renameType(classElement.supertype));
    }
    if (!classNode.interfaces.isEmpty()) {
      sb.add(classElement.isInterface() ? ' extends ' : ' implements ');
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
    Unparser unparser = new Unparser(renamer);
    renamer.setContext(element);
    // TODO(smok): Figure out why AbstractFieldElement appears here,
    // we have used getters/setters resolved instead of it.
    if (element is SynthesizedConstructorElement
        || element is AbstractFieldElement) return;
    if (element.isField()) {
      assert(element is VariableElement);
      sb.add(unparser.unparse(element.variables.parseNode(compiler)));
    } else {
      sb.add(unparser.unparse(element.parseNode(compiler)));
    }
  }

  String toString() => sb.toString();
}
