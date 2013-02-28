require 'nokogiri'

describe "tdl-create" do
  it "should convert tdls to etdls" do
   output = `./bin/tdl-convert.rb convert data/sample.tdl`
   $?.exitstatus.should == 0

   xsd = Nokogiri::XML::RelaxNG(File.read("data/etdl.rng"))
   doc = Nokogiri::XML(output)
   xsd.validate(doc).should be_empty
  end

  it "should convert etdls to tdls" do
   output = `./bin/tdl-convert.rb convert data/sample.etdl`
   $?.exitstatus.should == 0

   xsd = Nokogiri::XML::RelaxNG(File.read("data/tdl.rng"))
   doc = Nokogiri::XML(output)
   xsd.validate(doc).should be_empty
  end
end
