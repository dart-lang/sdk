class ParentWithMixin extends Parent with Mixin<Parent> {}

class Parent {
  method() {}
}

mixin Mixin<T extends Parent> on Parent {
  @override
  method() {}
}
