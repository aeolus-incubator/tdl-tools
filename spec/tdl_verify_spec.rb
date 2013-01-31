describe "tdl-verify" do
  it "should validate valid tdl" do
   `./bin/tdl-verify.rb verify spec/data/valid.tdl`
   $?.exitstatus.should == 0
  end

  it "should validate invalid tdl" do
   `./bin/tdl-verify.rb verify spec/data/invalid.tdl`
   $?.exitstatus.should == 1
  end
end
