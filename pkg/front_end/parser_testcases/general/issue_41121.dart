class ConfigurationService {
  Configuration _configuration;

  ConfigurationService(Configuration configuration)
      : assert(configuration != null),
        _configuration = configuration {
    // Above is OK in the constructor.
  }

  void set configuration(Configuration configuration)
      : assert(configuration != null),
        _configuration = configuration {
    // Above is NOT OK in a non-constructor.
  }

  Configuration get configuration
      : assert(_configuration != null),
        _configuration = _configuration.foo {
    // Above is NOT OK in a non-constructor.
    return _configuration;
  }

  void method() : _configuration = null {
    // Above is NOT OK in a non-constructor.
  }

  Foo() : _configuration = null {
    // Misnamed constructor.
    // Expect and error for that, but then initializers are OK.
  }
}

class Configuration {
  Configuration get foo => this;
}
