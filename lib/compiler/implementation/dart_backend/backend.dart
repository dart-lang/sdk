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

  DartBackend(Compiler compiler, [bool validateUnparse = false])
      : tasks = <CompilerTask>[],
      unparseValidator = new UnparseValidator(compiler, validateUnparse),
      super(compiler) {
    tasks.add(unparseValidator);
  }

  void enqueueHelpers(Enqueuer world) {
    // TODO(antonm): Implement this method, if needed.
  }

  String codegen(WorkItem work) { }

  void processNativeClasses(Enqueuer world,
                            Collection<LibraryElement> libraries) {
  }

  void assembleProgram() {
    resolvedElements.forEach((element, treeElements) {
      unparseValidator.check(element);
    });

    // TODO(antonm): Eventually bailouts will be proper errors.
    void bailout(String reason) {
      throw new BailoutException(reason);
    }

    try {
      resolvedElements.forEach((element, treeElements) {
        bailout('I can do nothing right now.');
      });
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
