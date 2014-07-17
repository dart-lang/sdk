// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This code was auto-generated, is not intended to be edited, and is subject to
// significant change. Please see the README file for more information.

library services.correction.change;

import 'package:analyzer/src/generated/source.dart';


/**
 * A description of a single change to one or more files. 
 */
class Change {
  /**
   * A textual description of the change to be applied. 
   */
  final String message;

  /**
   * A list of the [FileEdit]s used to effect the change. 
   */
  final List<FileEdit> edits = <FileEdit>[];

  Change(this.message);

  /**
   * Adds the given [FileEdit] to the list.
   */
  void add(FileEdit edit) {
    edits.add(edit);
  }

  @override
  String toString() => "Change(message=$message, edits=${edits.join(' ')})";
}


/**
 * A description of a single change to a single file. 
 */
class Edit {
  /**
   * The offset of the region to be modified. 
   */
  final int offset;

  /**
   * The length of the region to be modified.
   */
  final int length;

  /**
   * The text that is to replace the specified region in the original text. 
   */
  final String replacement;

  Edit(this.offset, this.length, this.replacement);

  Edit.range(SourceRange range, String replacement) : this(
      range.offset,
      range.length,
      replacement);

  /**
   * The offset of a character immediately after the region to be modified. 
   */
  int get end => offset + length;

  @override
  String toString() =>
      "(offset=$offset, length=$length, replacement=:>$replacement<:)";
}


/**
 * A description of a set of changes to a single file. 
 */
class FileEdit {
  /**
   * The file to be modified.
   */
  final String file;

  /**
   * A list of the [Edit]s used to effect the change. 
   */
  final List<Edit> edits = <Edit>[];

  FileEdit(this.file);

  /**
   * Adds the given [Edit] to the list.
   */
  void add(Edit edit) {
    edits.add(edit);
  }

  @override
  String toString() => "FileEdit(file=$file, edits=${edits.join(' ')})";
}
