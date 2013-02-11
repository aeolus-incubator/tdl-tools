require 'nokogiri'

describe "tdl-create" do
  it "should create a new tdl" do
    output = `./bin/tdl-create.rb tdl`
    $?.exitstatus.should == 0

    xsd = Nokogiri::XML::RelaxNG(File.read('data/tdl.rng'))
    doc = Nokogiri::XML(output)
    xsd.validate(doc).should be_empty
  end

  it "should take parameters to create a tdl with" do
    output = `./bin/tdl-create.rb tdl --interactive < spec/data/interactive_input`
    $?.exitstatus.should == 0

    # XXX remove prompts from output
    output.slice!(0..113)

    doc = Nokogiri::XML(output)
    doc.xpath('/template/name').first.content.should == 'custom-name'
    doc.xpath('/template/description').first.content.should == 'custom description'

    xsd = Nokogiri::XML::RelaxNG(File.read('data/tdl.rng'))
    xsd.validate(doc).should be_empty
  end
end
