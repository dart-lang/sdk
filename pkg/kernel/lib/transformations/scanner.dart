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
      for (Class cls in node.classes) {
        if (predicate(cls)) {
          result.targets[cls] = next?.scan(cls);
        }
      }
    } else if (node is Component) {
      for (Library library in node.libraries) {
        for (Class cls in library.classes) {
          if (predicate(cls)) {
            result.targets[cls] = next?.scan(cls);
          }
        }
      }
    }
    return result;
  }
}
