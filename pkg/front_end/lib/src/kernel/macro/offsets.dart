// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:math' as math;

import 'package:kernel/ast.dart';

// Coverage-ignore(suite): Not run.
/// Class that maps offsets from an intermediate augmentation library to the
/// merged augmentation library.
class ReOffset {
  final Uri intermediateAugmentationUri;
  final Uri augmentationFileUri;
  final List<MapEntry<int, int?>> _offsets;

  /// Creates a [ReOffset] from the intermediate augmentation library
  /// [intermediateAugmentationUri] to the merged augmentation library
  /// [augmentationFileUri] using [reOffsetMap] which maps the start of an
  /// offset range in [intermediateAugmentationUri] to the start of the
  /// corresponding offset range in [augmentationFileUri].
  ///
  /// The keys of [reOffsetMap] are assumed to be sorted.
  ReOffset(this.intermediateAugmentationUri, this.augmentationFileUri,
      Map<int, int?> reOffsetMap)
      : _offsets = reOffsetMap.entries.toList(),
        assert(() {
          Iterator<int> iterator = reOffsetMap.keys.iterator;
          if (iterator.moveNext()) {
            int previous = iterator.current;
            while (iterator.moveNext()) {
              int next = iterator.current;
              if (next < previous) {
                return false;
              }
              previous = next;
            }
          }
          return true;
        }(), "Offset key must be sorted: ${reOffsetMap}");

  /// Computes the file offset in the merged augmentation library corresponding
  /// to the [fileOffset] from the intermediate augmentation library.
  int reOffset(int fileOffset) {
    int low = 0;
    int high = _offsets.length - 1;
    while (low < high) {
      int mid = high - ((high - low) >> 1); // Get middle, rounding up.
      int midOffset = _offsets[mid].key;
      if (midOffset <= fileOffset) {
        low = mid;
      } else {
        high = mid - 1;
      }
    }
    int intermediateAugmentationRangeStart = _offsets[low].key;
    int? mergedAugmentationRangeStart = _offsets[low].value;

    /// We compute the new offset by adding the relative distance to start of
    /// the old offset range to the start of the new offset range.
    // TODO(johnniwinther): Verify that this doesn't lead to offsets that
    // escape their original range.
    if (mergedAugmentationRangeStart != null) {
      return fileOffset -
          intermediateAugmentationRangeStart +
          mergedAugmentationRangeStart;
    }
    assert(false,
        "No offset found for $fileOffset in $intermediateAugmentationUri.");
    return TreeNode.noOffset;
  }
}

// Coverage-ignore(suite): Not run.
/// Recursive visitor that tracks the current file URI.
abstract class FileUriVisitor extends RecursiveVisitor {
  /// Called before the `FileUriNode` [node] is visited.
  void enterFileUri(FileUriNode node);

  /// Called after the `FileUriNode` [node] is visited.
  void exitFileUri(FileUriNode node);

  void handleClass(Class node) {}

  @override
  void visitClass(Class node) {
    enterFileUri(node);
    handleClass(node);
    super.visitClass(node);
    exitFileUri(node);
  }

  void handleConstructor(Constructor node) {}

  @override
  void visitConstructor(Constructor node) {
    enterFileUri(node);
    handleConstructor(node);
    super.visitConstructor(node);
    exitFileUri(node);
  }

  void handleExtension(Extension node) {}

  @override
  void visitExtension(Extension node) {
    enterFileUri(node);
    handleExtension(node);
    super.visitExtension(node);
    exitFileUri(node);
  }

  void handleExtensionTypeDeclaration(ExtensionTypeDeclaration node) {}

  @override
  void visitExtensionTypeDeclaration(ExtensionTypeDeclaration node) {
    enterFileUri(node);
    handleExtensionTypeDeclaration(node);
    super.visitExtensionTypeDeclaration(node);
    exitFileUri(node);
  }

  void handleField(Field node) {}

  @override
  void visitField(Field node) {
    enterFileUri(node);
    handleField(node);
    super.visitField(node);
    exitFileUri(node);
  }

  void handleFileUriExpression(FileUriExpression node) {}

  @override
  void visitFileUriExpression(FileUriExpression node) {
    enterFileUri(node);
    handleFileUriExpression(node);
    super.visitFileUriExpression(node);
    exitFileUri(node);
  }

  void handleFileUriConstantExpression(FileUriConstantExpression node) {}

  @override
  void visitConstantExpression(ConstantExpression node) {
    if (node is FileUriConstantExpression) {
      enterFileUri(node);
      handleFileUriConstantExpression(node);
      super.visitConstantExpression(node);
      exitFileUri(node);
    } else {
      super.visitConstantExpression(node);
    }
  }

  void handleLibrary(Library node) {}

  @override
  void visitLibrary(Library node) {
    enterFileUri(node);
    handleLibrary(node);
    super.visitLibrary(node);
    exitFileUri(node);
  }

  void handleProcedure(Procedure node) {}

  @override
  void visitProcedure(Procedure node) {
    enterFileUri(node);
    handleProcedure(node);
    super.visitProcedure(node);
    exitFileUri(node);
  }

  void handleTypedef(Typedef node) {}

  @override
  void visitTypedef(Typedef node) {
    enterFileUri(node);
    handleTypedef(node);
    super.visitTypedef(node);
    exitFileUri(node);
  }
}

// Coverage-ignore(suite): Not run.
/// Visitor that replaces offsets in intermediate augmentation libraries with
/// the offsets for the merged augmentation libraries.
class ReOffsetVisitor extends FileUriVisitor {
  final Map<Uri, ReOffset> _reOffsetMaps;

  final List<ReOffset> _currentReOffsets = [];

  ReOffsetVisitor(this._reOffsetMaps);

  int _reOffset(int offset) {
    if (_currentReOffsets.isNotEmpty) {
      if (offset != TreeNode.noOffset) {
        return _currentReOffsets.last.reOffset(offset);
      }
    }
    return offset;
  }

  @override
  void enterFileUri(FileUriNode node) {
    ReOffset? reOffset = _reOffsetMaps[node.fileUri];
    if (reOffset != null) {
      _currentReOffsets.add(reOffset);
    }
  }

  @override
  void exitFileUri(FileUriNode node) {
    ReOffset? reOffset = _reOffsetMaps[node.fileUri];
    if (reOffset != null) {
      node.fileUri = reOffset.augmentationFileUri;
      _currentReOffsets.removeLast();
    }
  }

  @override
  void defaultTreeNode(TreeNode node) {
    node.fileOffset = _reOffset(node.fileOffset);
    super.defaultTreeNode(node);
  }

  @override
  void visitAssertStatement(AssertStatement node) {
    node.conditionStartOffset = _reOffset(node.conditionStartOffset);
    node.conditionEndOffset = _reOffset(node.conditionEndOffset);
    super.visitAssertStatement(node);
  }

  @override
  void visitBlock(Block node) {
    node.fileEndOffset = _reOffset(node.fileEndOffset);
    super.visitBlock(node);
  }

  @override
  void handleClass(Class node) {
    node.startFileOffset = _reOffset(node.startFileOffset);
    node.fileEndOffset = _reOffset(node.fileEndOffset);
  }

  @override
  void handleConstructor(Constructor node) {
    node.startFileOffset = _reOffset(node.startFileOffset);
    node.fileEndOffset = _reOffset(node.fileEndOffset);
  }

  @override
  void visitForInStatement(ForInStatement node) {
    node.bodyOffset = _reOffset(node.bodyOffset);
    super.visitForInStatement(node);
  }

  @override
  void visitFunctionNode(FunctionNode node) {
    node.fileEndOffset = _reOffset(node.fileEndOffset);
    super.visitFunctionNode(node);
  }

  @override
  void handleField(Field node) {
    node.fileEndOffset = _reOffset(node.fileEndOffset);
  }

  @override
  void handleProcedure(Procedure node) {
    node.fileStartOffset = _reOffset(node.fileStartOffset);
    node.fileEndOffset = _reOffset(node.fileEndOffset);
  }

  @override
  void visitSwitchCase(SwitchCase node) {
    for (int i = 0; i < node.expressionOffsets.length; i++) {
      node.expressionOffsets[i] = _reOffset(node.expressionOffsets[i]);
    }
    super.visitSwitchCase(node);
  }

  @override
  void visitVariableDeclaration(VariableDeclaration node) {
    node.fileEqualsOffset = _reOffset(node.fileEqualsOffset);
    super.visitVariableDeclaration(node);
  }
}

// Coverage-ignore(suite): Not run.
/// A range of file offset.
///
/// Used to computed the file offsets of nested ranges.
class OffsetRange {
  final int start;
  final int end;

  OffsetRange(this.start, this.end);

  OffsetRange include(OffsetRange range) {
    return new OffsetRange(
        math.min(start, range.start), math.max(end, range.end));
  }
}

// Coverage-ignore(suite): Not run.
extension OffsetRangeExtension on OffsetRange? {
  OffsetRange include(OffsetRange range) {
    OffsetRange? self = this;
    return self == null ? range : self.include(range);
  }
}
