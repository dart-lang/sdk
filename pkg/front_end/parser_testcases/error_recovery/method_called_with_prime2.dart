// This doesn't actually have any method called 'with', but could (wrongly) be
// seen as a method called 'class' returning type "foo" (or at least give
// errors at a wrong place.

class B {}foo
class M1 {foo
  class M2 {
  }
}