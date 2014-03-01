timing_test(function() {
  at(0, function() {
    assert_styles(".anim",{'width':'50px'});
  });
  at(0.5, function() {
    assert_styles(".anim", [
      {'width':'81.25px'},
      {'width':'81.25px'},
      {'width':'137.5px'},
      {'width':'81.25px'},
      {'width':'95.3125px'},
      {'width':'95.3125px'},
      {'width':'95.3125px'},
    ]);
  });
  at(1, function() {
    assert_styles(".anim", [
      {'width':'150px'},
      {'width':'150px'},
      {'width':'225px'},
      {'width':'150px'},
      {'width':'168.75px'},
      {'width':'168.75px'},
      {'width':'168.75px'},
    ]);
  });
  at(1.5, function() {
    assert_styles(".anim", [
      {'width':'256.25px'},
      {'width':'256.25px'},
      {'width':'312.5px'},
      {'width':'256.25px'},
      {'width':'270.3125px'},
      {'width':'270.3125px'},
      {'width':'270.3125px'},
    ]);
  });
  at(2, function() {
    assert_styles(".anim",{'width':'400px'});
  });
}, "Auto generated tests");
