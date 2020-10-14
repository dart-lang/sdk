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
  Map<X, ScanResult<Y, TreeNode>> targets = new Map();
  Map<X, ScanError> errors;
}

class ScanError {}

abstract class ClassScanner<Y extends TreeNode> implements Scanner<Class, Y> {
  final Scanner<Y, TreeNode> next;

  ClassScanner(this.next);

  bool predicate(Class node);

  ScanResult<Class, Y> scan(TreeNode node) {
    ScanResult<Class, Y> result = new ScanResult();

    if (node is Class) {
      if (predicate(node)) {
        result.targets[node] = next?.scan(node);
        // TODO(dmitryas): set result.errors when specification is landed,
        //  same with all other places where targets is set
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

    if (node is Field) {
      _scanField(node, result);
    } else if (node is Class) {
      _scanClass(node, result);
    } else if (node is Library) {
      _scanLibrary(node, result);
    } else if (node is Component) {
      _scanComponent(node, result);
    }

    return result;
  }

  void _scanField(Field field, ScanResult<Field, Y> result) {
    if (predicate(field)) {
      result.targets[field] = next?.scan(field);
    }
  }

  void _scanClass(Class cls, ScanResult<Field, Y> result) {
    for (Field field in cls.fields) {
      _scanField(field, result);
    }
  }

  void _scanLibrary(Library library, ScanResult<Field, Y> result) {
    for (Class cls in library.classes) {
      _scanClass(cls, result);
    }
    for (Field field in library.fields) {
      _scanField(field, result);
    }
  }

  void _scanComponent(Component component, ScanResult<Field, Y> result) {
    for (Library library in component.libraries) {
      _scanLibrary(library, result);
    }
  }
}

abstract class MemberScanner<Y extends TreeNode> implements Scanner<Member, Y> {
  final Scanner<Y, TreeNode> next;

  MemberScanner(this.next);

  bool predicate(Member node);

  ScanResult<Member, Y> scan(TreeNode node) {
    ScanResult<Member, Y> result = new ScanResult();

    if (node is Member) {
      _scanMember(node, result);
    } else if (node is Class) {
      _scanClass(node, result);
    } else if (node is Library) {
      _scanLibrary(node, result);
    } else if (node is Component) {
      _scanComponent(node, result);
    }

    return result;
  }

  void _scanMember(Member member, ScanResult<Member, Y> result) {
    if (predicate(member)) {
      result.targets[member] = next?.scan(member);
    }
  }

  void _scanClass(Class cls, ScanResult<Member, Y> result) {
    for (Member member in cls.members) {
      _scanMember(member, result);
    }
  }

  void _scanLibrary(Library library, ScanResult<Member, Y> result) {
    for (Class cls in library.classes) {
      _scanClass(cls, result);
    }
    for (Member member in library.members) {
      _scanMember(member, result);
    }
  }

  void _scanComponent(Component component, ScanResult<Member, Y> result) {
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

    if (node is Procedure) {
      _scanProcedure(node, result);
    } else if (node is Class) {
      _scanClass(node, result);
    } else if (node is Library) {
      _scanLibrary(node, result);
    } else if (node is Component) {
      _scanComponent(node, result);
    }

    return result;
  }

  void _scanProcedure(Procedure procedure, ScanResult<Procedure, Y> result) {
    if (predicate(procedure)) {
      result.targets[procedure] = next?.scan(procedure);
    }
  }

  void _scanClass(Class cls, ScanResult<Procedure, Y> result) {
    for (Procedure procedure in cls.procedures) {
      _scanProcedure(procedure, result);
    }
  }

  void _scanLibrary(Library library, ScanResult<Procedure, Y> result) {
    for (Class cls in library.classes) {
      _scanClass(cls, result);
    }
    for (Procedure procedure in library.procedures) {
      _scanProcedure(procedure, result);
    }
  }

  void _scanComponent(Component component, ScanResult<Procedure, Y> result) {
    for (Library library in component.libraries) {
      _scanLibrary(library, result);
    }
  }
}

abstract class ExpressionScanner<Y extends TreeNode>
    extends RecursiveVisitor<void> implements Scanner<Expression, Y> {
  final Scanner<Y, TreeNode> next;
  ScanResult<Expression, Y> _result;

  ExpressionScanner(this.next);

  bool predicate(Expression node);

  ScanResult<Expression, Y> scan(TreeNode node) {
    ScanResult<Expression, Y> result = _result = new ScanResult();
    node.accept(this);
    _result = null;
    return result;
  }

  void visitExpression(Expression node) {
    if (predicate(node)) {
      _result.targets[node] = next?.scan(node);
      // TODO: Update result.errors.
    }
  }
}

abstract class MethodInvocationScanner<Y extends TreeNode>
    extends RecursiveVisitor<void> implements Scanner<MethodInvocation, Y> {
  final Scanner<Y, TreeNode> next;
  ScanResult<MethodInvocation, Y> _result;

  MethodInvocationScanner(this.next);

  bool predicate(MethodInvocation node);

  ScanResult<MethodInvocation, Y> scan(TreeNode node) {
    ScanResult<MethodInvocation, Y> result = _result = new ScanResult();
    node.accept(this);
    _result = null;
    return result;
  }

  void visitMethodInvocation(MethodInvocation node) {
    if (predicate(node)) {
      _result.targets[node] = next?.scan(node);
      // TODO: Update result.errors.
    }
  }
}
