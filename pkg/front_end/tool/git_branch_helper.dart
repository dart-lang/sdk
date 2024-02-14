// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

void main(List<String> args) {
  // Use `runZonedGuarded` instead of try/catch, and do it here before anything
  // else has been printed --- both because of
  // https://github.com/dart-lang/sdk/issues/54911.
  runZonedGuarded(() {
    mainImpl(args);
  }, (e, _) {
    stderr.writeln("Error: $e");
  });
}

const String CSI = "\x1b[";

Map<String, GitBranch> branches = {};

GitBranch getBranch(String name) {
  GitBranch? result = branches[name];
  if (result == null) {
    result = branches[name] = new GitBranch(name);
  }
  return result;
}

void mainImpl(List<String> args) {
  ProcessResult result = Process.runSync("git",
      ["branch", "--list", "--format=%(refname:short)%09%(upstream:short)"],
      runInShell: true);
  result.stdout.split("\n").forEach(processGitBranchLine);

  result =
      Process.runSync("git", ["branch", "--show-current"], runInShell: true);
  String currentBranchName = result.stdout;
  currentBranchName = currentBranchName.trim();
  GitBranch currentBranch = branches[currentBranchName]!;
  Set<String> involvedBranchNames = {};
  currentBranch.collectSelfAndParentNames(involvedBranchNames);
  currentBranch.collectSelfAndChildrenNames(involvedBranchNames);

  result = Process.runSync(
      "git",
      [
        "branch",
        "--list",
        "--format=%(refname:short)%09%(upstream:track)",
        ...involvedBranchNames
      ],
      runInShell: true);
  result.stdout.split("\n").forEach(processGitBranchTrackLine);

  int indentation = currentBranch.parent?.printSelfAndParentChain() ?? 0;

  currentBranch.printSelfAndChildren(indentation, color: true);
}

void processGitBranchLine(String gitLine) {
  if (gitLine.isEmpty) return;
  int pos = gitLine.indexOf("\t");
  String thisName = gitLine.substring(0, pos);
  String parentName = gitLine.substring(pos + 1).trim();
  GitBranch thisBranch = getBranch(thisName);
  GitBranch parentBranch = getBranch(parentName);
  parentBranch.registerChild(thisBranch);
}

void processGitBranchTrackLine(String gitLine) {
  if (gitLine.isEmpty) return;
  int pos = gitLine.indexOf("\t");
  String thisName = gitLine.substring(0, pos);
  String tracking = gitLine.substring(pos + 1).trim();
  GitBranch thisBranch = getBranch(thisName);
  thisBranch.tracking = tracking;
}

class GitBranch {
  final String name;
  GitBranch? parent;
  final List<GitBranch> children = [];
  String? tracking;

  GitBranch(this.name);

  void collectSelfAndChildrenNames(Set<String> names) {
    names.add(name);
    for (GitBranch child in children) {
      child.collectSelfAndChildrenNames(names);
    }
  }

  void collectSelfAndParentNames(Set<String> names) {
    parent?.collectSelfAndParentNames(names);
    names.add(name);
  }

  void printSelfAndChildren(int indention, {bool color = false}) {
    _printLineWithIndention(indention, color: color);
    for (GitBranch child in children) {
      child.printSelfAndChildren(indention + 1);
    }
  }

  int printSelfAndParentChain() {
    int indention = 0;
    GitBranch? parent = this.parent;
    if (parent != null) {
      indention = parent.printSelfAndParentChain();
    }
    _printLineWithIndention(indention);

    return indention + 1;
  }

  void registerChild(GitBranch child) {
    children.add(child);
    child.parent = this;
  }

  @override
  String toString() {
    return "GitBranch[$name, children = $children]";
  }

  void _printLineWithIndention(int indention, {bool color = false}) {
    stdout.write("│   " * (indention));
    stdout.write("├── ");
    if (color) {
      stdout.write("${CSI}31m");
    }
    stdout.write("$name");
    if (color) {
      stdout.write("${CSI}0m");
    }
    if (tracking != null) {
      stdout.write(" $tracking");
    }
    stdout.write("\n");
  }
}
