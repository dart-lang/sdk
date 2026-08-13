typedef a = foo Function(int x); // OK.
typedef b = Function(int x); // OK.
typedef c = foo(int x); // error.
typedef d = (int x); // error.
typedef e = foo<F>(int x); // error.
typedef f = <F>(int x); // error.
typedef g = foo<F, G, H, I, J>(int x); // error.
typedef h = <F, G, H, I, J>(int x); // error.
typedef i = <F, G, H, I, J>; // error.

// These should be error cases according to the spec, but are valid with the
// experimental generalized typedef.
typedef j = foo;
typedef k = List<int>;
