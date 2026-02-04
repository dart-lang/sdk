augment void topLevelMethod() {
  augment super();
}

augment void topLevelMethodError() {
  augment int local;
  augment;
}


augment List<int> get topLevelProperty {
  return [... augment super, augment super[0]];
}

augment void set topLevelProperty(List<int> value) {
  augment super[0] = value[1];
  augment super = value;
}

void injectedTopLevelMethod() {
  augment super();
  augment super;
  augment int local;
  augment;
}

augment class Class {
  augment void instanceMethod() {
    augment super();
  }

  augment void instanceMethodErrors() {
    augment int local;
    augment;
  }

  augment int get instanceProperty {
    augment super++;
    --augment super;
    return -augment super;
  }

  augment void set instanceProperty(int value) {
    augment super = value;
  }

  void injectedInstanceMethod() {
    augment super();
    augment super;
    augment int local;
    augment;
  }
}