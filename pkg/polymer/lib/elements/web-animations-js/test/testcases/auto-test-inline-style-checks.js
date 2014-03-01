timing_test(function() {
  at(0, function() {
    assert_styles("#target",{'left':'0px','backgroundColor':'rgb(176, 196, 222)'});
  });
  at(0.5, function() {
    assert_styles("#target",{'left':'50px','backgroundColor':'rgb(176, 196, 222)'});
  });
  at(1.5, function() {
    assert_styles("#target",{'left':'100px','backgroundColor':'rgb(176, 196, 222)'});
  });
  at(2, function() {
    assert_styles("#target",{'left':'50px','backgroundColor':'rgb(176, 196, 222)'});
  });
  at(3, function() {
    assert_styles("#target",{'left':'100px','backgroundColor':'rgb(0, 128, 0)'});
  });
}, "Auto generated tests");
