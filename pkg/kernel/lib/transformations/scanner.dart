library kernel.transformations.scanner;

import '../ast.dart';
import '../kernel.dart';

abstract class Scanner<X extends TreeNode, Y extends TreeNode> {
  final Scanner<Y, TreeNode> next;
  Scanner(this.next);
  bool predicate(X x);
  ScanResult<X, Y> scan(TreeNode node);
}

class ScanResult<X extends TreeNode, Y extends TreeNode> {
  Map<X, ScanResult<Y, TreeNode>> targets;
  Map<X, ScanError> errors;
}

class ScanError {}

abstract class ClassScanner<Y extends TreeNode> implements Scanner<Class, Y> {
  final Scanner<Y, TreeNode> next;

  ClassScanner(this.next);

  bool predicate(Class node);

  ScanResult<Class, Y> scan(TreeNode node) {
    ScanResult<Class, Y> result = new ScanResult();
    result.targets = new Map();

    if (node is Class) {
      if (predicate(node)) {
        result.targets[node] = next?.scan(node);
      }
    } else if (node is Library) {
      _scanLibrary(node, result);
    } else if (node is Component) {
      _scanComponent(node, result);
    }

    return result;
  }

  void _scanLibrary(Library library, ScanResult<Class, Y> result) {
    for (Class cls in library.classes) {
      if (predicate(cls)) {
        result.targets[cls] = next?.scan(cls);
      }
    }
  }

  void _scanComponent(Component component, ScanResult<Class, Y> result) {
    for (Library library in component.libraries) {
      _scanLibrary(library, result);
    }
  }
}

abstract class FieldScanner<Y extends TreeNode> implements Scanner<Field, Y> {
  final Scanner<Y, TreeNode> next;

  FieldScanner(this.next);

  bool predicate(Field node);

  ScanResult<Field, Y> scan(TreeNode node) {
    ScanResult<Field, Y> result = new ScanResult();
    result.targets = new Map();

    if (node is Field) {
      if (predicate(node)) {
        result.targets[node] = next?.scan(node);
      }
    } else if (node is Class) {
      _scanClass(node, result);
    } else if (node is Library) {
      _scanLibrary(node, result);
    } else if (node is Component) {
      _scanComponent(node, result);
    }

    return result;
  }

  void _scanClass(Class cls, ScanResult<Field, Y> result) {
    for (Field field in cls.fields) {
      if (predicate(field)) {
        result.targets[field] = next?.scan(field);
      }
    }
  }

  void _scanLibrary(Library library, ScanResult<Field, Y> result) {
    for (Class cls in library.classes) {
      _scanClass(cls, result);
    }
    for (Field field in library.fields) {
      if (predicate(field)) {
        result.targets[field] = next?.scan(field);
      }
    }
  }

  void _scanComponent(Component component, ScanResult<Field, Y> result) {
    for (Library library in component.libraries) {
      _scanLibrary(library, result);
    }
  }
}

abstract class ProcedureScanner<Y extends TreeNode>
    implements Scanner<Procedure, Y> {
  final Scanner<Y, TreeNode> next;

  ProcedureScanner(this.next);

  bool predicate(Procedure node);

  ScanResult<Procedure, Y> scan(TreeNode node) {
    ScanResult<Procedure, Y> result = new ScanResult();
    result.targets = new Map();

    if (node is Procedure) {
      if (predicate(node)) {
        result.targets[node] = next?.scan(node);
      }
    } else if (node is Class) {
      _scanClass(node, result);
    } else if (node is Library) {
      _scanLibrary(node, result);
    } else if (node is Component) {
      _scanComponent(node, result);
    }

    return result;
  }

  void _scanClass(Class cls, ScanResult<Procedure, Y> result) {
    for (Procedure procedure in cls.procedures) {
      if (predicate(procedure)) {
        result.targets[procedure] = next?.scan(procedure);
      }
    }
  }

  void _scanLibrary(Library library, ScanResult<Procedure, Y> result) {
    for (Class cls in library.classes) {
      _scanClass(cls, result);
    }
    for (Procedure procedure in library.procedures) {
      if (predicate(procedure)) {
        result.targets[procedure] = next?.scan(procedure);
      }
    }
  }

  void _scanComponent(Component component, ScanResult<Procedure, Y> result) {
    for (Library library in component.libraries) {
      _scanLibrary(library, result);
    }
  }
}
