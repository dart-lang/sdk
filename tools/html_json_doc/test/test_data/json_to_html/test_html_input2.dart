/**
 * This is a library level dartdoc comment.
 * This should be ignored.
 */
library testInput2;

/// @docsEditable
class InputTestCase1 {

}

/// @docsEditable
class InputTestCase2 extends InputTestCase1 {

}

/// @docsEditable
class InputTestCase3 extends InputTestCase2 {

}

/*
 * This is not a dartdoc comment and should not be picked up.
 * The output of this comment should be nothing.
 */
/// @docsEditable
class InputTestCase4 {

}

/**
 * This multi-line dartdoc comment doesn't have the /// @docsEditable stuff.
 * This comment should not show up in the JSON.
 * Note that the /// @docsEditable in this line and the one above are ignored.
 */
class InputTestCase5 {

}

/// This is a single line dartdoc comment that is ignored.
class InputTestCase6 {

}

/// This is a multi-line dartdoc comment that is ignored.
/// It is made of multiple single line dartdoc comments.
class InputTestCase7 {

  /// @docsEditable
  var InputTestCase8;

  /// @docsEditable
  var InputTestCase9;

  /// @docsEditable
  var InputTestCase10;

  /**
   * This multi-line comment on a member is ignored.
   */
  var InputTestCase11;

  /// This single line dartdoc comment on a member is ignored.
  var InputTestCase12;
}
