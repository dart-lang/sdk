// Some examples of how the dart type system/checked mode interacts with dart type unsoundness.
// Suppose we were to "trust types" in the following sense: if the program passes the dart
// type checker, assume that all checks implied by checked mode would have passed, and 
// compile under that assumption.  What does that buy you?  These examples are intended to 
// illustrate why this is less than you might think.  This file has no static errors or 
// warnings, and runs fine in checked mode, but it demonstrates lots of ways in which 
// nonetheless we can produce no such method errors, or sideways casts, etc.

// A simple class
class A {
  int x = 0;
}

// Overriding x with an assignable type (supertype) is ok
class B extends A {
  num x = 1.0;
  int y = 1;
}

// Contain a B
class S0 {
   B field;
}

// Override to an A
class S1 extends S0 {
  A field;
  S1(A this.field);
}

// If we assume that s has type S0, can we assume that s.field has type B? No.
void nsm0(S0 s) {
  // Dynamic dispatch required.
  // With global subclass information, the compiler could potentially get rid
  // of some of the checks here when bad overrides as above don't happen.
  try {s.field.y;}
  on NoSuchMethodError catch (r) {
    print ("Oops, no field y in something of type B");
   }
}

// If we assume that f returns a B, can we assume that B.y exists? No.
void nsm1(B f()) {
  // Dynamic dispatch required.
  // Even with global subclass info, the compiler can't do anything here, since
  // this relies on screwy subtyping rather than screwy field overrides.
  try {f().y;}
  on NoSuchMethodError catch (r) {
    print ("Oops, no field y in something of type B (extra badness)");
  }
}

// If we assume that s is an S1, can we assume that s.field is an A? No.
void doubleForInt0(S1 s) {
  // Dynamic dispatch required.
  // With global subclass info we can possibly know when we need to emit careful code
  // here, but we certainly can't just generate a simple unconditional primitive operation
  // (even ignoring nulls)
  s.field.x + 1;
  if (s.field.x is double) {
    print("Oops, got double for int");
  }
}

// Can we assume that f returns an int (or a subtype of an int)? No.  
// Can we assume that f returns an int (or subtype or a supertype of an int)? No.
void doubleForInt1(int f()) {
  // Dynamic dispatch required.
  // Here, even with global subclass info we're still stuck - we can't really
  // ever trust the return types on closures.  Note that int and double aren't
  // even assignment compatible in this case.
  f() + 1;
  if (f() is double) {
    print("Oops, got double for int (extra badness)");
  }
}

class C extends A {
}

// Can we assume that f returns something on the same branch of the inheritance chain as B? No.
void sidewaysCast(B f()) {
  // Just to emphasize the point, here's a more general case where the static type
  // isn't even on the same branch of the subtype hierarchy as the dynamic type.
  if (f() is C) {
    print("Static type of expression is B, but runtime type is C (neither sub nor supertype)");
  }
  if (f() is B) {
    // Do something here.  This code doesn't get reached.... unless the compiler optimizes
    // based on trusting types and  eliminates the is check, in which case we may suddenly 
    // execute different code.
  }
}

// If we assume that x has type List<B>, what can we assume about the type of the elements?  Nothing.
void generic0(List<B> x) {
  // What can we assume about the elements of this array if we trust types?  
  // Absolutely nothing, whatsoever.
  if (x[0] is int) {
    print("Parameter type is List<B> but actually contains an int (completely unrelated type)");
  }
}

void main() {
  nsm0(new S1(new A()));
  nsm1(() => new A());
  doubleForInt0(new S1(new B()));
  doubleForInt1(() {num b = 1.0; return b;});
  sidewaysCast(() {A a = new C(); return a;});
  generic0(<dynamic>[3]);
}
