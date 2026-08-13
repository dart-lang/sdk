# Adding Semantic Highlighting

This document describes what semantic highlighting is and how to enhance it.

## Overview

Syntactic highlighting is the support that styles tokens in the source code
based on where those tokens are located in the grammar. For example, syntactic
highlighting is used to apply a color to all of the keywords and
pseudo-keywords.

Semantic highlighting includes syntactic highlighting, but additionally styles
tokens based on their semantics. For example, semantic highlighting is used to
apply a color to type names or a strikethrough to deprecated elements.

Note that the analysis server isn't the only implementation of syntactic
highlighting that the Dart team controls, and all of the implementations should
be kept reasonably consistent with each other.

## Enhancing semantic highlighting

If we have decided to change semantic highlighting, you can add that support by
modifying the class `_DartUnitHighlightsComputerVisitor`. That class is a
`RecursiveAstVisitor`, so the first task is to figure out which kind of node
contains the text to be styled. You can then either add a new `visit` method for
the node or edit an existing method.

If you're adding a new `visit` method, you'll need to invoke the overridden
method to ensure that children are still visited.

Within the `visit` method, use one of the private methods on the `computer` to
associate a highlight region with a `HighlightRegionType`. The mapping from a
highlight type to actual text styling is handled by the client (and is in some
cases user controlled).

## Testing semantic highlighting

The tests for semantic highlighting are in the class
`AnalysisNotificationHighlightsTest`.

The tests generally follow the following pattern:

1. Use `addTestFile` to add a file containing code that should be highlighted.
2. Use `await prepareHighlights();` to compute and cache the semantic
   highlighting results.
3. Use `assertHasRegion` to test that the expected highlight type is associated
   with the region that matches the search string. If the search string needs to
   be longer than the highlight region in order to be unique, then the optional
   length argument can be provided so specify the expected length of the region.
