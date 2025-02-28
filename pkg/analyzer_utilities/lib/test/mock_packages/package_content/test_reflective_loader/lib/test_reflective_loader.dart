library test_reflective_loader;

const Object reflectiveTest = _ReflectiveTest();
const Object skippedTest = SkippedTest();
const Object soloTest = _SoloTest();

class SkippedTest {
  const SkippedTest({String? issue, String? reason});
}

class _ReflectiveTest {
  const _ReflectiveTest();
}

class _SoloTest {
  const _SoloTest();
}
