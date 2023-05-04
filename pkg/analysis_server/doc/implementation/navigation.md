# Adding Navigation

This document describes what navigation is and how to enhance it.

## Overview

Navigation is the ability to move from one piece of text to a related location.
This includes such things as jumping to the declaration of an identifier or
opening a file based on a URI or file path.

## Enhancing navigation

If we have decided to provide navigation from a given kind of text that was
previously not supported, you can add that support by modifying the class
`_DartNavigationComputerVisitor`. That class is a `RecursiveAstVisitor`, so the
first task is to figure out which kind of node contains the text at the origin.
You can then either add a new `visit` method for the node or edit an existing
method.

If you're adding a new `visit` method, you'll need to invoke the overridden
method to ensure that children are still visited.

Within the `visit` method, compute the region from which the user can navigate
and the location to which they should be navigated. There are some utility
methods in `_DartNavigationCollector`, to make common cases easier, or you can
use `computer.collector.addRegion` to add an arbitrary region.

## Testing the navigation

The tests for navigation are in the class `AnalysisNotificationNavigationTest`.

The tests generally follow the following pattern:

1. Use `addTestFile` to add a file containing both the origin and target of the
   navigation.
2. Use `await prepareNavigation();` to compute and cache navigation results.
3. Use `assertHasRegion` to test that the offset of the string in the test file
   is a navigation origin, and `assertHasTarget` to ensure the target to which
   the user will be navigated.
