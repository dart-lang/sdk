Apidoc is a specialization of Dartdoc.
Dartdoc generates static HTML documentation from Dart code.
Apidoc wraps the dartdoc output with official dartlang.org skin, comments, etc.

To use it, from this directory, run:

    $ dart apidoc.dart [--out=<output directory>]

This will create a "docs" directory with the docs for your libraries.


How docs are generated
----------------------

To make beautiful docs from your library, dartdoc parses it and every library it
imports (recursively). From each library, it parses all classes and members,
finds the associated doc comments and builds crosslinked docs from them.

"Doc comments" can be in one of a few forms:

    /**
     * JavaDoc style block comments.
     */

    /** Which can also be single line. */

    /// Triple-slash line comments.
    /// Which can be multiple lines.

The body of a doc comment will be parsed as markdown which means you can apply
most of the formatting and structuring you want while still having docs that
look nice in plain text. For example:

    /// This is a doc comment. This is the first paragraph in the comment. It
    /// can span multiple lines.
    ///
    /// A blank line starts a new paragraph like this one.
    ///
    /// *   Unordered lists start with `*` or `-` or `+`.
    /// *   And can have multiple items.
    ///     1. You can nest lists.
    ///     2. Like this numbered one.
    ///
    /// ---
    ///
    /// Three dashes, underscores, or tildes on a line by themselves create a
    /// horizontal rule.
    ///
    ///     to.get(a.block + of.code) {
    ///       indent(it, 4.lines);
    ///       like(this);
    ///     }
    ///
    /// There are a few inline styles you can apply: *emphasis*, **strong**,
    /// and `inline code`. You can also use underscores for _emphasis_ and
    /// __strong__.
    ///
    /// An H1 header using equals on the next line
    /// ==========================================
    ///
    /// And an H2 in that style using hyphens
    /// -------------------------------------
    ///
    /// # Or an H1 - H6 using leading hashes
    /// ## H2
    /// ### H3
    /// #### H4 you can also have hashes at then end: ###
    /// ##### H5
    /// ###### H6

There is also an extension to markdown specific to dartdoc: A name inside
square brackets that is not a markdown link (i.e. doesn't have square brackets
or parentheses following it) like:

    Calls [someMethod], passing in [arg].

is understood to be the name of some member or type that's in the scope of the
member where that comment appears. Dartdoc will automatically figure out what
the name refers to and generate an approriate link to that member or type.


Attribution
-----------

dartdoc uses the delightful Silk icon set by Mark James.
http://www.famfamfam.com/lab/icons/silk/
