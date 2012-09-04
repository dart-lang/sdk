// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

String emitCode(
      Compiler compiler,
      Unparser unparser,
      Map<LibraryElement, String> imports,
      Collection<Element> topLevelElements,
      Map<ClassElement, Collection<Element>> classMembers) {
  void outputElement(Element element) {
    unparser.unparse(element.parseNode(compiler));
  }

  void outputClass(ClassElement classElement, Collection<Element> members) {
    unparser.unparseClassWithBody(classElement.parseNode(compiler), () {
      members.forEach((element) {
        // TODO(smok): Filter out default constructors here.
        outputElement(element);
      });
    });
  }

  imports.forEach((libraryElement, prefix) {
    unparser.unparseImportTag('${libraryElement.uri}', prefix);
  });

  for (final element in topLevelElements) {
    if (element is ClassElement) {
      outputClass(element, classMembers[element]);
    } else {
      outputElement(element);
    }
  }
}
