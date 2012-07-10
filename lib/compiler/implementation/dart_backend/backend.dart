// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class BailoutException {
  final String reason;

  const BailoutException(this.reason);
}

class DartBackend extends Backend {
  final List<CompilerTask> tasks;
  final UnparseValidator unparseValidator;

  Map<Element, TreeElements> get resolvedElements() =>
      compiler.enqueuer.resolution.resolvedElements;
  Map<ClassElement, Set<Element>> resolvedClassMembers;

  DartBackend(Compiler compiler, [bool validateUnparse = false])
      : tasks = <CompilerTask>[],
      unparseValidator = new UnparseValidator(compiler, validateUnparse),
      resolvedClassMembers = new Map<ClassElement, Set<Element>>(),
      super(compiler) {
    tasks.add(unparseValidator);
  }

  void enqueueHelpers(Enqueuer world) {
    // TODO(antonm): Implement this method, if needed.
  }

  CodeBlock codegen(WorkItem work) { return new CodeBlock(null, null); }

  void processNativeClasses(Enqueuer world,
                            Collection<LibraryElement> libraries) {
  }

  /**
   * Adds given class element with its member element to resolved classes
   * collections.
   */
  void addMemberToClass(Element element, ClassElement classElement) {
    // ${element} should have ${classElement} as enclosing.
    assert(element.enclosingElement == classElement);
    Set<Element> resolvedElementsInClass = resolvedClassMembers.putIfAbsent(
        classElement, () => new Set<Element>());
    resolvedElementsInClass.add(element);
  }

  /**
   * Outputs given class element with given inner elements to a string buffer.
   */
  void outputClass(ClassElement classElement, Set<Element> innerElements,
      StringBuffer sb) {
    // TODO(smok): Very soon properly print out correct class declaration with
    // extends, implements, etc.
    sb.add('class ');
    sb.add(classElement.name.slowToString());
    sb.add('{');
    innerElements.forEach((element) {
      // TODO(smok): Filter out default constructors here.
      sb.add(element.parseNode(compiler).unparse());
    });
    sb.add('}');
  }

  void assembleProgram() {
    resolvedElements.forEach((element, treeElements) {
      unparseValidator.check(element);
    });

    // TODO(antonm): Eventually bailouts will be proper errors.
    void bailout(String reason) {
      throw new BailoutException(reason);
    }

    /**
     * Tells whether we should output given element. Corelib classes like
     * Object should not be in the resulting code.
     */
    bool shouldOutput(Element element) {
      return element.kind !== ElementKind.VOID
          && element.getLibrary() !== compiler.coreLibrary;
    }

    try {
      StringBuffer sb = new StringBuffer();
      resolvedElements.forEach((element, treeElements) {
        if (!shouldOutput(element)) return;
        if (element.isMember()) {
          var enclosingClass = element.enclosingElement;
          assert(enclosingClass.isClass());
          assert(enclosingClass.isTopLevel());
          addMemberToClass(element, enclosingClass);
          return;
        }
        if (!element.isTopLevel()) {
          bailout('Cannot process non top-level $element');
        }

        if (element.isField()) {
          // Add modifiers first.
          sb.add(element.modifiers.toString());
          sb.add(' ');
          // Figure out type.
          if (element is VariableElement) {
            VariableListElement variables = element.variables;
            if (variables.type !== null) {
              sb.add(variables.type);
              sb.add(' ');
            }
          }
          // TODO(smok): Maybe not rely on node unparsing,
          // but unparse initializer manually.
          sb.add(element.parseNode(compiler).unparse());
          sb.add(';');
        } else {
          sb.add(element.parseNode(compiler).unparse());
        }
      });

      // Now output resolved classes with inner elements we met before.
      resolvedClassMembers.forEach((classElement, resolvedElements) {
        outputClass(classElement, resolvedElements, sb);
      });
      compiler.assembledCode = sb.toString();
    } catch (BailoutException e) {
      compiler.assembledCode = '''
main() {
  final bailout_reason = "${e.reason}";
}
''';
    }
  }

  log(String message) => compiler.log('[DartBackend] $message');
}
