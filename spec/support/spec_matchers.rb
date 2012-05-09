RSpec::Matchers.define :have_predicate_methods do |expected|
  match do |model|
    model.gear_is_in_second?.should be_true
    model.gear_not_in_second?.should be_false
    model.gear_is_nil?.should be_false
    model.gear_is_not_nil?.should be_true
  end
end
