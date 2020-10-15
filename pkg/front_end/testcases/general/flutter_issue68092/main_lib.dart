class DynamicDispatchRegistry<T extends Function> {
  T register(T function) => null;
}

class Registry extends DynamicDispatchRegistry<int Function({int x})> {}
