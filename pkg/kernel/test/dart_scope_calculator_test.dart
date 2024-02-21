// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:kernel/ast.dart';
import 'package:kernel/binary/ast_from_binary.dart';
import 'package:kernel/binary/ast_to_binary.dart';
import 'package:kernel/dart_scope_calculator.dart';
import 'package:kernel/src/printer.dart';

import 'binary/find_sdk_dills.dart';

void main() {
  List<File> dills = findSdkDills().where((dill) {
    // Patching is bad on outlines, see
    // https://github.com/dart-lang/sdk/issues/54117.
    if (dill.path.endsWith("_outline.dill")) return false;
    if (dill.path.endsWith("_outline_unsound.dill")) return false;
    if (dill.path.contains("/vm_outline_")) return false;
    return true;
  }).toList();

  print("Found ${dills.length} dill files.");

  for (int i = 0; i < dills.length; i++) {
    print("");
    testDill(dills[i]);
    print("Finished dill ${i + 1} out of ${dills.length}");
  }

  {
    List<MapEntry<String, int>> unfilteredCountsList =
        afterFilterCounts.entries.toList();
    unfilteredCountsList.sort((a, b) => b.value - a.value);
    print("");
    print("Small counts came from here:");
    for (MapEntry<String, int> entry in unfilteredCountsList) {
      if (needleCount(entry.key, "|") <= 2) {
        print(" => ${entry.value}: ${entry.key}");
      }
    }
    print("");
    print("Big filtered counts came from here:");
    for (MapEntry<String, int> entry in unfilteredCountsList) {
      if (needleCount(entry.key, "|") > 2) {
        print(" => ${entry.value}: ${entry.key}");
      }
    }
  }

  print("");
  print("Valid block offsets: ${DillBlockChecker.validBlockOffset}");
  print("Empty block offsets: ${DillBlockChecker.emptyBlockOffset}");
  print("No block offsets: ${DillBlockChecker.noBlockOffset}");
  print("");

  if (errors.isNotEmpty) {
    print("");
    print("GOT ERRORS!");
    for (String e in errors) {
      print(" - $e");
    }
    throw "Errors detected.";
  } else {
    print("No direct errors found.");
  }
}

int needleCount(String s, String needle) {
  int result = 0;
  int indexOf = s.indexOf(needle);
  while (indexOf >= 0) {
    result++;
    indexOf = s.indexOf(needle, indexOf + 1);
  }
  return result;
}

List<String> errors = [];

void testDill(File dill) {
  print("Looking at $dill");
  Component component = new Component();
  try {
    new BinaryBuilder(dill.readAsBytesSync()).readComponent(component);
  } catch (e) {
    if (e is InvalidKernelVersionError) {
      print("$dill has a wrong kernel version. Skipping.");
      return;
    }
    rethrow;
  }
  DillBlockChecker dillBlockChecker = new DillBlockChecker();
  component.accept(dillBlockChecker);

  ScopeTestingBinaryPrinter binaryPrinter = new ScopeTestingBinaryPrinter();
  binaryPrinter.writeComponentFile(component);

  print("${binaryPrinter.exact} out of ${binaryPrinter.total} "
      "(${binaryPrinter.moreButAgree}/${binaryPrinter.total - binaryPrinter.exact})");
  int totalAgree = binaryPrinter.exact + binaryPrinter.moreButAgree;
  print(" => ${totalAgree * 100 / binaryPrinter.total}%");
  print(" =====> Also notice more than 1: "
      "${binaryPrinter.countMoreThanOneAfterFilter}; "
      "== 1: ${binaryPrinter.countExactlyOneAfterFilter}");
}

class DevNullSink<T> implements Sink<T> {
  const DevNullSink();

  @override
  void add(T data) {}

  @override
  void close() {}
}

/// Checks that each block (except for a few known bad cases) contains all
/// offsets inside it, thus verifying that we can use the blocks offsets to
/// skip/prune parts of the tree while searching for node(s) with a specific
/// offset.
class DillBlockChecker extends VisitorDefault<void> with VisitorVoidMixin {
  Uri _currentUri = Uri.parse("dummy:uri");
  int start = -1;
  int end = -1;
  bool insideType = false;

  static int validBlockOffset = 0;
  static int emptyBlockOffset = 0;
  static int noBlockOffset = 0;

  @override
  void defaultDartType(DartType node) {
    bool oldInsideType = insideType;
    insideType = true;
    super.defaultDartType(node);
    insideType = oldInsideType;
  }

  @override
  void defaultTreeNode(TreeNode node) {
    if (insideType) {
      throw "Got to a treenode from inside a type.";
    }
    Uri prevUri = _currentUri;
    if (node is FileUriNode) {
      _currentUri = node.fileUri;
    }
    if (prevUri == _currentUri && start >= 0 && end >= 0) {
      // This node should be contained.
      for (int offset in [node.fileOffset, ...?node.fileOffsetsIfMultiple]) {
        if (offset >= 0) {
          if (offset < start || offset > end) {
            // Not contained.
            throw "Error on $node; $offset not in [$start, $end] "
                "(${node.parent.runtimeType} "
                "${node.parent?.parent.runtimeType}) "
                "${node.parent?.parent?.parent.runtimeType})";
          }
        }
      }
    }

    bool hasVisited = false;
    if (node is Block) {
      if (node.fileOffset == node.fileEndOffset) {
        emptyBlockOffset++;
      } else if (node.fileOffset < 0 || node.fileEndOffset < 0) {
        noBlockOffset++;
      } else {
        validBlockOffset++;
      }

      if (node.parent is ForInStatement) {
        // E.g. dart2js implicit cast in for-in loop
      } else if (node.parent?.parent is ForStatement) {
        // A vm transformation turns
        // `for (var foo in bar) {}`
        // into
        // `for(;iterator.moveNext; ) { var foo = iterator.current; {} }`
        // where the block directly containing `foo` has the original blocks
        // offset, i.e. after the variable declaration, but it still contain
        // it. So we pretend it has no offsets.
      } else if (node.fileOffset >= 0 &&
          node.fileEndOffset >= 0 &&
          node.fileOffset != node.fileEndOffset) {
        int prevStart = start;
        int prevEnd = end;
        start = node.fileOffset;
        end = node.fileEndOffset;
        node.visitChildren(this);
        hasVisited = true;
        end = prevEnd;
        start = prevStart;
      }
    }

    if (!hasVisited) {
      node.visitChildren(this);
    }

    _currentUri = prevUri;
  }
}

class ScopeTestingBinaryPrinter extends BinaryPrinter {
  Library? currentLibrary;
  Class? currentClass;
  Member? currentMember;
  Uri? currentUri;
  Set<int> askedOffsets = {};
  bool checkOffset = false;
  Set<Member> skipMembers = {};

  int exact = 0;
  int total = 0;
  int moreButAgree = 0;
  int countMoreThanOneAfterFilter = 0;
  int countExactlyOneAfterFilter = 0;

  ScopeTestingBinaryPrinter()
      : super(const DevNullSink(),
            newVariableIndexerForTesting: VariableIndexer2.new);

  @override
  void visitClass(Class node) {
    currentClass = node;
    Uri? prevUri = currentUri;
    currentUri = node.fileUri;
    askedOffsets.clear();
    super.visitClass(node);
    currentUri = prevUri;
    currentClass = null;
  }

  @override
  void visitConstructor(Constructor node) {
    currentMember = node;
    Uri? prevUri = currentUri;
    currentUri = node.fileUri;
    askedOffsets.clear();
    super.visitConstructor(node);
    currentUri = prevUri;
    currentMember = null;
  }

  @override
  void visitExtension(Extension node) {
    for (ExtensionMemberDescriptor memberDescriptor in node.memberDescriptors) {
      // The tear off procedures have two enclosing function nodes with the same
      // offsets, but with (possibly) different type parameters. Skip them.
      Member? skip = memberDescriptor.tearOffReference?.asMember;
      if (skip != null) {
        skipMembers.add(skip);
      }
    }
    Uri? prevUri = currentUri;
    currentUri = node.fileUri;
    askedOffsets.clear();
    super.visitExtension(node);
    currentUri = prevUri;
  }

  Set<VariableDeclaration> setVariables = {};

  @override
  void visitVariableSet(VariableSet node) {
    super.visitVariableSet(node);
    setVariables.add(node.variable);
  }

  @override
  void visitExtensionTypeDeclaration(ExtensionTypeDeclaration node) {
    Uri? prevUri = currentUri;
    currentUri = node.fileUri;
    askedOffsets.clear();
    super.visitExtensionTypeDeclaration(node);
    currentUri = prevUri;
  }

  @override
  void visitField(Field node) {
    currentMember = node;
    Uri? prevUri = currentUri;
    currentUri = node.fileUri;
    askedOffsets.clear();
    super.visitField(node);
    currentUri = prevUri;
    currentMember = null;
  }

  @override
  void visitFileUriExpression(FileUriExpression node) {
    Uri? prevUri = currentUri;
    currentUri = node.fileUri;
    askedOffsets.clear();
    super.visitFileUriExpression(node);
    currentUri = prevUri;
  }

  @override
  void visitFunctionNode(FunctionNode node) {
    bool oldCheckOffset = checkOffset;
    checkOffset = true;
    super.visitFunctionNode(node);
    checkOffset = oldCheckOffset;
  }

  @override
  void visitLibrary(Library node) {
    currentLibrary = node;
    Uri? prevUri = currentUri;
    currentUri = node.fileUri;
    askedOffsets.clear();
    super.visitLibrary(node);
    currentUri = prevUri;
    currentLibrary = null;
  }

  @override
  void visitProcedure(Procedure node) {
    currentMember = node;
    Uri? prevUri = currentUri;
    currentUri = node.fileUri;
    askedOffsets.clear();
    super.visitProcedure(node);
    currentUri = prevUri;
    currentMember = null;
  }

  @override
  void visitTypedef(Typedef node) {
    Uri? prevUri = currentUri;
    currentUri = node.fileUri;
    askedOffsets.clear();
    super.visitTypedef(node);
    currentUri = prevUri;
  }

  @override
  void writeOffset(int offset) {
    if (checkOffset &&
        offset >= 0 &&
        !skipMembers.contains(currentMember) &&
        askedOffsets.add(offset)) {
      List<DartScope2> nodesAtPoint =
          DartScopeBuilder2.findScopeFromOffsetAndClassRawForTesting(
              currentLibrary!, currentUri!, currentClass, offset);

      List<Object> expectedTypeParameters =
          getTypeParameterIndexerForTesting().index.keys.toList();

      VariableIndexer2? varIndexer =
          getVariableIndexerForTesting() as VariableIndexer2?;
      Map<String, DartType> expectedVariablesMap = {};
      for (VariableDeclaration variable in varIndexer?.declsOrder ?? const []) {
        String? name = variable.name;
        if (name != null && name != "" && !variable.isSynthesized) {
          if (variable.isHoisted && !setVariables.contains(variable)) {
            // A hoisted variable that isn't set (yet) --- pretend it isn't
            // there.
          } else {
            expectedVariablesMap[name] = variable.type;
          }
        }
      }

      total++;
      if (nodesAtPoint.length == 0) {
        String msg = "Didn't find any scope for "
            "${currentLibrary!.fileUri} $currentUri and $offset";
        errors.add(msg);
        print(msg);
      } else if (nodesAtPoint.length == 1) {
        exact++;
        if (!compareScopes(expectedTypeParameters, expectedVariablesMap,
            nodesAtPoint.single, offset,
            doPrint: true)) {
          errors.add("Found 1 scope, but it didn't match for "
              "${currentLibrary!.fileUri} $currentUri and $offset");
        }
      } else {
        // Does one that agree exist?
        bool foundMatch = false;
        bool allMatch = true;
        for (DartScope2 compareMe in nodesAtPoint) {
          if (compareScopes(
              expectedTypeParameters, expectedVariablesMap, compareMe, offset,
              doPrint: false)) {
            foundMatch = true;
          } else {
            allMatch = false;
          }
        }
        if (!foundMatch) {
          String msg =
              "Found ${nodesAtPoint.length} scopes, but didn't one matching "
              "${currentLibrary!.fileUri} $currentUri and $offset";
          print(msg);
          errors.add(msg);
        }
        if (allMatch) {
          moreButAgree++;
        }

        List<DartScope2> filteredScopes = DartScopeBuilder2.filterAllForTesting(
            nodesAtPoint, currentLibrary!, offset);

        if (filteredScopes.length == 1) {
          countExactlyOneAfterFilter++;
          return;
        } else {
          if (filteredScopes.isEmpty) throw "Now empty :/";
          countMoreThanOneAfterFilter++;
          {
            String key = filteredScopes
                .map((e) => e.node.runtimeType.toString())
                .join("|");
            afterFilterCounts[key] = (afterFilterCounts[key] ?? 0) + 1;
            WrappedBool wrappedBoolForDebugging = new WrappedBool();

            {
              for (int i = 0; i < filteredScopes.length; i++) {
                DartScope2 scope = filteredScopes[i];
                TreeNode node = scope.node;
                if (node is Member) {
                  print("$i ${scope.node.runtimeType} name = ${node.name}");
                }
              }
            }

            {
              TreeNode node = filteredScopes[0].node;
              if (node is Procedure) {
                if (node.function.body != null) node = node.function.body!;
              } else if (node is FunctionNode) {
                if (node.body != null) node = node.body!;
              } else if (node is! Block) {
                if (node.parent != null) node = node.parent!;
                for (int i = 0; i < 3; i++) {
                  if (node is! Block &&
                      node.parent != null &&
                      node.parent is! Member &&
                      node.parent is! FunctionNode) {
                    node = node.parent!;
                  }
                }
              }
              print("-----------");
              print("$key via ${filteredScopes[0].node.location}:");
              print(node.debugPrint(filteredScopes));
              print("-----------");
            }

            if (wrappedBoolForDebugging.value) {
              // Go in here to debug by setting
              // wrappedBoolForDebugging.value = true in the debugger.
              print(DartScopeBuilder2.filterAllForTesting(
                  nodesAtPoint, currentLibrary!, offset));
            }
          }
        }
      }
    }
    super.writeOffset(offset);
  }

  bool compareScopes(
      List<Object> expectedTypeParameters,
      Map<String, DartType> expectedVariablesMap,
      DartScope2 compareWith,
      int offsetForErrorMessage,
      {required bool doPrint}) {
    bool compareOk = true;
    if (expectedTypeParameters.length != compareWith.typeParameters.length) {
      compareOk = false;
      if (doPrint) {
        print("Failure on type parameters for "
            "${currentLibrary!.fileUri} $currentUri and "
            "$offsetForErrorMessage -- "
            "${compareWith.typeParameters} vs $expectedTypeParameters");
      }
    } else {
      // Do they agree?
      for (int i = 0; i < expectedTypeParameters.length; i++) {
        TypeParameter a = expectedTypeParameters[i] as TypeParameter;
        TypeParameter b = compareWith.typeParameters[i];
        if (!identical(a, b)) {
          compareOk = false;
          if (doPrint) {
            print("$a != $b");
          }
        }
      }
    }
    if (compareWith.cls != currentClass) {
      compareOk = false;
      if (doPrint) {
        print("Failure on class for "
            "${currentLibrary!.fileUri} $currentUri and "
            "$offsetForErrorMessage -- "
            "${compareWith.cls} vs $currentClass");
      }
    }

    if (expectedVariablesMap.length != compareWith.definitions.length) {
      compareOk = false;
      if (doPrint) {
        print("Failure on definitions for "
            "${currentLibrary!.fileUri} $currentUri and "
            "$offsetForErrorMessage -- "
            "${compareWith.definitions} vs $expectedVariablesMap");
      }
    } else {
      // Do they agree?
      for (String variableName in expectedVariablesMap.keys) {
        DartType? a = expectedVariablesMap[variableName];
        DartType? b = compareWith.definitions[variableName]?.type;
        if (a != b) {
          compareOk = false;
          if (doPrint) {
            print("$a != $b");
          }
        }
      }
    }
    return compareOk;
  }

  @override
  void writeVariableDeclaration(VariableDeclaration node) {
    bool oldCheckOffset = checkOffset;
    checkOffset = true;
    super.writeVariableDeclaration(node);
    checkOffset = oldCheckOffset;
  }
}

class VariableIndexer2 implements VariableIndexer {
  List<VariableDeclaration> declsOrder = [];
  List<VariableDeclaration> declsOrderPopped = [];
  @override
  Map<VariableDeclaration, int>? index;
  @override
  List<int>? scopes;
  @override
  int stackHeight = 0;

  @override
  int? operator [](VariableDeclaration node) {
    return index == null ? null : index![node];
  }

  @override
  void declare(VariableDeclaration node) {
    (index ??= <VariableDeclaration, int>{})[node] = stackHeight++;
    declsOrder.add(node);
  }

  @override
  void popScope() {
    stackHeight = scopes!.removeLast();
    while (declsOrder.length > stackHeight) {
      declsOrderPopped.add(declsOrder.removeLast());
    }
  }

  @override
  void pushScope() {
    (scopes ??= <int>[]).add(stackHeight);
  }

  @override
  void restoreScope(int numberOfVariables) {
    stackHeight += numberOfVariables;

    while (declsOrder.length < stackHeight) {
      declsOrder.add(declsOrderPopped.removeLast());
    }
  }
}

Map<String, int> afterFilterCounts = {};

extension on TreeNode {
  String debugPrint(List<DartScope2> scopes) {
    Set<TreeNode> mark = {};
    for (DartScope2 scope in scopes) {
      mark.add(scope.node);
    }
    MarkingAstPrinter markingAstPrinter =
        new MarkingAstPrinter(defaultAstTextStrategy, mark);
    this.toTextInternal(markingAstPrinter);
    return markingAstPrinter.getText();
  }
}

class WrappedBool {
  bool value = false;
}
