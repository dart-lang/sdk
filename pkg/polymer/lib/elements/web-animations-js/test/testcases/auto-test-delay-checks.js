timing_test(function() {
  at(0, function() {
    assert_styles(".anim",{'left':'100px'});
  });
  at(0.1, function() {
    assert_styles(".anim",{'left':'100px'});
  });
  at(0.2, function() {
    assert_styles(".anim",{'left':'100px'});
  });
  at(0.30000000000000004, function() {
    assert_styles(".anim",{'left':'133.3px'});
  });
  at(0.4, function() {
    assert_styles(".anim",{'left':'166.7px'});
  });
  at(0.5, function() {
    assert_styles(".anim",{'left':'100px'});
  });
  at(0.6, function() {
    assert_styles(".anim",{'left':'133.3px'});
  });
  at(0.7, function() {
    assert_styles(".anim",{'left':'166.7px'});
  });
  at(0.7999999999999999, function() {
    assert_styles(".anim",{'left':'100px'});
  });
  at(0.8999999999999999, function() {
    assert_styles(".anim",{'left':'133.3px'});
  });
  at(0.9999999999999999, function() {
    assert_styles(".anim",{'left':'166.7px'});
  });
  at(1.0999999999999999, function() {
    assert_styles(".anim",{'left':'200px'});
  });
  at(1.2, function() {
    assert_styles(".anim",{'left':'200px'});
  });
  at(1.3, function() {
    assert_styles(".anim",{'left':'200px'});
  });
  at(1.4000000000000001, function() {
    assert_styles(".anim",{'left':'200px'});
  });
  at(1.5000000000000002, function() {
    assert_styles(".anim",{'left':'100px'});
  });
  at(1.6000000000000003, function() {
    assert_styles(".anim",{'left':'100px'});
  });
  at(1.7000000000000004, function() {
    assert_styles(".anim",{'left':'100px'});
  });
  at(1.8000000000000005, function() {
    assert_styles(".anim",{'left':'133.3px'});
  });
  at(1.9000000000000006, function() {
    assert_styles(".anim",{'left':'166.7px'});
  });
  at(2.0000000000000004, function() {
    assert_styles(".anim",{'left':'100px'});
  });
  at(2.1000000000000005, function() {
    assert_styles(".anim",{'left':'133.3px'});
  });
  at(2.2000000000000006, function() {
    assert_styles(".anim",{'left':'166.7px'});
  });
  at(2.3000000000000007, function() {
    assert_styles(".anim",{'left':'100px'});
  });
  at(2.400000000000001, function() {
    assert_styles(".anim",{'left':'133.3px'});
  });
  at(2.500000000000001, function() {
    assert_styles(".anim",{'left':'166.7px'});
  });
  at(2.600000000000001, function() {
    assert_styles(".anim",{'left':'200px'});
  });
  at(2.700000000000001, function() {
    assert_styles(".anim",{'left':'200px'});
  });
  at(2.800000000000001, function() {
    assert_styles(".anim",{'left':'200px'});
  });
  at(2.9000000000000012, function() {
    assert_styles(".anim",{'left':'200px'});
  });
}, "Auto generated tests");
