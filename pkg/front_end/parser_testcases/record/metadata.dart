// These are parsed as argument lists to the annotation:
@metadata(x, y) a;

@metadata<T>(x, y) a;

@metadata <T>(x, y) a;

// These are parsed as record variable types:
@metadata (x, y) a;

@metadata
(x, y) a;

@metadata/* comment */(x, y) a;

@metadata // Comment.
(x,) a;

// Note that the NO_SPACE rule is applied unconditionally,
// even when the metadata annotation appears in a context where no ambiguity
// with record types is possible, as in:
@metadata (x, y)
class C {}

// This example has a syntax error because the (x, y) is not parsed as arguments
// to the metadata and can't be parsed as anything else either.

// Another interesting case is:

@metadata<T> (x, y) a;

// This is a syntax error because the <T> means there must be an argument list
// after it, but the NO_SPACE in metadatum prevents it from being parsed as such
// and the result is an error.

// (though apparently not a parser issued error)
