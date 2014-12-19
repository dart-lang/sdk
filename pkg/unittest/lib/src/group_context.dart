part of unittest;

/// Setup and teardown functions for a group and its parents, the latter
/// for chaining.
class _GroupContext {
  final _GroupContext parent;

  /// Description text of the current test group.
  final String _name;

  /// Setup function called before each test in a group.
  Function _testSetup;

  get testSetup => _testSetup;

  get parentSetup => (parent == null) ? null : parent.testSetup;

  set testSetup(Function setup) {
    var preSetup = parentSetup;
    if (preSetup == null) {
      _testSetup = setup;
    } else {
      _testSetup = () {
        var f = preSetup();
        if (f is Future) {
          return f.then((_) => setup());
        } else {
          return setup();
        }
      };
    }
  }

  /// Teardown function called after each test in a group.
  Function _testTeardown;

  get testTeardown => _testTeardown;

  get parentTeardown => (parent == null) ? null : parent.testTeardown;

  set testTeardown(Function teardown) {
    var postTeardown = parentTeardown;
    if (postTeardown == null) {
      _testTeardown = teardown;
    } else {
      _testTeardown = () {
        var f = teardown();
        if (f is Future) {
          return f.then((_) => postTeardown());
        } else {
          return postTeardown();
        }
      };
    }
  }

  String get fullName => (parent == null || parent == _environment.rootContext)
      ? _name
      : "${parent.fullName}$groupSep$_name";

  _GroupContext([this.parent, this._name = '']) {
    _testSetup = parentSetup;
    _testTeardown = parentTeardown;
  }
}
