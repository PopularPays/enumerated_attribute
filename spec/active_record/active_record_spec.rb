require 'spec_helper'
require 'active_record/test_in_memory'
require 'active_record'
require 'enumerated_attribute'
require 'active_record/race_car'

describe "RaceCar" do

  let (:red_car) { RaceCar.new }

  describe 'labels' do
    let(:labels) { ['Reverse', 'Neutral', 'First', 'Second', 'Over drive'] }
    let(:labels_hash) { { :reverse => "Reverse",
                          :neutral => "Neutral",
                          :first => "First",
                          :second => "Second",
                          :over_drive => "Over drive" }}

    it "sets default labels for :gear attribute" do
      select_options = [['Reverse', 'reverse'],
                        ['Neutral', 'neutral'],
                        ['First', 'first'],
                        ['Second', 'second'],
                        ['Over drive', 'over_drive']]

      red_car.gears.labels.should == labels
      labels_hash.each { |k,v| red_car.gears.label(k).should == v }
      red_car.gears.hash.should == labels_hash
      red_car.gears.select_options.should == select_options
    end
  end

  it "#enums(:gear) retrieves all the gears" do
    red_car.gear.should be_a_kind_of Symbol
    red_car.enums(:gear).should == red_car.gears
  end

  it "should increment and decrement :gear attribute correctly" do
    red_car.gear = :neutral
    [:first, :second, :over_drive, :reverse, :neutral].each do |gear|
      red_car.gear_next.should == gear
    end
    red_car.gear.should == :neutral
    [ :reverse, :over_drive, :second].each do |gear|
      red_car.gear_previous.should == gear
    end
    red_car.gear_previous
    red_car.gear.should == :first
  end

  it "has dynamic predicate methods for the :gear attribute" do
    red_car.gear = :second

    red_car.should have_predicate_methods
  end

  it "can access dynamic predicate methods on retrieved objects" do
    red_car.gear = :second
    red_car.save!

    blue_car = RaceCar.find red_car.id
    blue_car.should have_predicate_methods
  end

  context 'dynamic finders' do
    it "#find_or_create_by_name_and_gear" do
      blue_car = RaceCar.find_or_create_by_name_and_gear('specialty', :second)
      blue_car.should_not be_nil
      blue_car.gear.should == :second
      blue_car.name.should == 'specialty'

      yellow_car = RaceCar.find_or_create_by_name_and_gear('specialty', :second)
      yellow_car.gear.should == :second
      yellow_car.id.should == blue_car.id
    end

    it "#find_or_initialize_by_name_and_gear" do
      blue_car = RaceCar.find_or_initialize_by_name_and_gear('myspecialty', :second)
      blue_car.should_not be_nil
      blue_car.gear.should == :second
      blue_car.name.should == 'myspecialty'
      lambda { blue_car.save! }.should_not raise_exception

      yellow_car = RaceCar.find_or_initialize_by_name_and_gear('myspecialty', :second)
      yellow_car.gear.should == :second
      yellow_car.id.should == blue_car.id
    end

    it "#find_by_gear_and_name" do
      red_car.gear = :second
      red_car.name = 'special'
      red_car.save!

      blue_car = RaceCar.find_by_gear_and_name(:second, 'special')
      blue_car.should_not be_nil
      blue_car.id.should == red_car.id
    end
  end

  it "should initialize according to enumerated attribute definitions" do
    red_car.gear.should == :neutral
    red_car.choke.should == :none
  end

  it "should create new instance using block" do
    red_car = RaceCar.new do |red_car|
      red_car.gear = :first
      red_car.choke = :medium
      red_car.lights = 'on'
    end
    red_car.gear.should == :first
    red_car.lights.should == 'on'
    red_car.choke.should == :medium
  end

  it "should initialize using parameter hash with symbol keys" do
    yellow_car = RaceCar.new(:name=>'FastFurious',
                             :gear=>:second,
                             :lights => 'on',
                             :choke=>:medium)
    yellow_car.gear.should == :second
    yellow_car.lights.should == 'on'
    yellow_car.choke.should == :medium
  end

  it "should initialize using parameter hash with string keys" do
    yellow_car = RaceCar.new({'name'=>'FastFurious',
                              'gear'=>'second',
                              'lights'=>'on',
                              'choke'=>'medium'})
    yellow_car.gear.should == :second
    yellow_car.lights.should == 'on'
    yellow_car.choke.should == :medium
  end

  it "should convert non-column enumerated attributes from string to symbols" do
    red_car.choke = 'medium'
    red_car.choke.should == :medium
    red_car.save!
  end

  it "should convert enumerated column attributes from string to symbols" do
    red_car.gear = 'second'
    red_car.gear.should == :second
    red_car.save!

    blue_car = RaceCar.find red_car.id
    blue_car.gear.should == :second
  end

  it "should not convert non-enumerated column attributes from string to symbols" do
    red_car.lights = 'off'
    red_car.lights.should == 'off'
    red_car.save!

    blue_car = RaceCar.find red_car.id
    blue_car.lights.should == 'off'
  end

  it "should not raise InvalidEnumeration when parametrically initialized with invalid column attribute value" do
    expect{ red_car.gear = :drive}.should_not raise_error(EnumeratedAttribute::InvalidEnumeration)
  end

  it "should raise RecordInvalid on create! when parametrically initialized with invalid column attribute value" do
    expect{ RaceCar.create!(:gear => :drive)}.should raise_error(ActiveRecord::RecordInvalid)
  end


  it "should not raise InvalidEnumeration when parametrically initialized with invalid non-column attribute" do
    lambda{ red_car.choke= :all}.should_not raise_error(EnumeratedAttribute::InvalidEnumeration)
  end

  it "should not be valid on non-column attribute with parametrically initialized bad value" do
    red_car.choke = :all
    red_car.should_not be_valid
  end


  it "should return non-column enumerated attributes from [] method" do
    red_car[:choke].should == :none
  end

  it "should return enumerated column attributes from [] method" do
    red_car.gear = :neutral
    red_car[:gear].should == :neutral
  end

  it "should set non-column enumerated attributes with []= method" do
    red_car[:choke] = :medium
    red_car.choke.should == :medium
  end

  it "should set enumerated column attriubtes with []= method" do
    red_car[:gear] = :second
    red_car.gear.should == :second
  end

  it "should not raise InvalidEnumeration when setting enumerated column attribute with []= method" do
    lambda{ red_car[:gear]= :drive }.should_not raise_error(EnumeratedAttribute::InvalidEnumeration)
  end

  it "should raise RecordInvalid on save! after setting enumerated column attribute with []= method" do
    red_car[:gear] = :drive
    lambda{ red_car.save! }.should raise_error(ActiveRecord::RecordInvalid)
  end

  it "should set and retrieve string for non-enumerated column attributes with []=" do
    red_car[:lights] = 'on'
    red_car.lights.should == 'on'
    red_car[:lights].should == 'on'
  end

  it "should set and retrieve symbol for non-enumerated column attributes with []=" do
    red_car[:lights] = :on
    red_car.lights.should == :on
    red_car[:lights].should == :on
  end

  it "should not raise InvalidEnumeration for invalid enum passed to attributeblue_car = " do
    lambda { red_car.attributes = {:lights => 'off', :gear =>:drive} }.should_not raise_error(EnumeratedAttribute::InvalidEnumeration)
  end

  it "should raise RecordInvalid on save! for invalid enum passed to attributeblue_car = " do
    red_car.attributes = {:lights => 'off', :gear =>:drive}
    lambda { red_car.save! }.should raise_error(ActiveRecord::RecordInvalid)
  end

  it "should retrieve symbols for enumerations from ActiveRecord :attributes method" do
    red_car.gear = :second
    red_car.choke = :medium
    red_car.lights = 'on'
    red_car.save!

    blue_car = RaceCar.find(red_car.id)
    blue_car.attributes['gear'].should == :second
    blue_car.attributes['lights'].should == 'on'
  end

  it "should update_attribute for enumerated column attribute" do
    red_car.gear = :first
    red_car.save!
    red_car.update_attribute(:gear, :second)
    red_car.gear.should == :second

    blue_car = RaceCar.find red_car.id
    blue_car.gear.should == :second
  end

  it "should update_attribute for non-enumerated column attribute" do
    red_car.lights = 'on'
    red_car.save!
    red_car.update_attribute(:lights, 'off')
    red_car.lights.should == 'off'

    blue_car = RaceCar.find red_car.id
    blue_car.lights.should == 'off'
  end

  it "should update_attributes for both non- and enumerated column attributes" do
    red_car.gear = :first
    red_car.lights = 'off'
    red_car.save!
    red_car.update_attributes({:gear=>:second, :lights => 'on'})
    blue_car = RaceCar.find red_car.id
    blue_car.gear.should == :second
    blue_car.lights.should == 'on'
    blue_car.update_attributes({:gear=>'over_drive', :lights => 'off'})
    yellow_car = RaceCar.find blue_car.id
    yellow_car.gear.should == :over_drive
    yellow_car.lights.should == 'off'
  end

  it "should provide symbol values for enumerated column attributes from the :attributes method" do
    red_car.lights = 'on'
    red_car.save!

    blue_car = RaceCar.find red_car.id
    blue_car.attributes['gear'].should == :neutral
  end

  it "should provide normal values for non-enumerated column attributes from the :attributes method"  do
    red_car.lights = 'on'
    red_car.save!

    blue_car = RaceCar.find red_car.id
    blue_car.attributes['lights'].should == 'on'
  end

  it "should not raise InvalidEnumeration when setting invalid enumeration value with :attributeblue_car =  method" do
    expect { red_car.attributes = {:gear=>:yo, :lights => 'on'} }.should_not raise_error(EnumeratedAttribute::InvalidEnumeration)
  end

  it "should raise RecordInvalid on save! after setting invalid enumeration value with :attributeblue_car =  method" do
    red_car.attributes = {:gear=>:yo, :lights => 'on'}
    expect { red_car.save! }.should raise_error(ActiveRecord::RecordInvalid)
  end

  it "should not set init value for enumerated column attribute saved as nil" do
    red_car.gear = nil
    red_car.lights = 'on'
    red_car.save!

    blue_car = RaceCar.find red_car.id
    blue_car.gear.should == nil
    blue_car.lights.should == 'on'
  end

  it "should not set init value for enumerated column attributes saved as value" do
    red_car.gear = :second
    red_car.lights = 'all'
    red_car.save!

    blue_car = RaceCar.find red_car.id
    blue_car.gear.should == :second
    blue_car.lights.should == 'all'
  end

  it "should save and retrieve its name" do
    red_car.name = 'Green Meanie'
    red_car.save!

    blue_car = RaceCar.find red_car.id
    blue_car.should_not be_nil
    blue_car.name.should == 'Green Meanie'
  end

  it "should save and retrieve symbols for enumerated column attribute" do
    red_car.gear = :over_drive
    red_car.save!

    blue_car = RaceCar.find red_car.id
    blue_car.gear.should == :over_drive
  end

  it "should not save values for non-column enumerated attributes" do
    red_car.choke = :medium
    red_car.save!

    blue_car = RaceCar.find red_car.id
    blue_car.choke.should == :none
  end

  it "should save string and retrieve string for non-enumerated column attributes" do
    red_car.lights = 'on'
    red_car.save!

    blue_car = RaceCar.find red_car.id
    blue_car.lights.should == 'on'
    blue_car[:lights].should == 'on'
  end

  it "should save symbol and retrieve string for non-enumerated column attributes" do
    red_car.lights = :off
    red_car.save!

    blue_car = RaceCar.find red_car.id
    blue_car.lights.should == "--- :off\n"
    blue_car[:lights].should == "--- :off\n"
  end

end
