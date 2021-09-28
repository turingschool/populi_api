require "populi_api/middleware/indifferent_hashify"

RSpec.describe Faraday::Response::IndifferentHashify do
  describe "#parse" do
    it "converts hashes to HashWithIndifferentAccess" do
      expect(subject.parse({ a: "b" })).to be_instance_of(HashWithIndifferentAccess)
    end

    it "recursively converts hashes within arrays" do
      expect(subject.parse([1, { a: "b" }, 2])).to eq([
        1,
        HashWithIndifferentAccess.new({ a: "b" }),
        2,
      ])
    end

    it "leaves other objects as-is" do
      expect(subject.parse("string")).to eq("string")
      expect(subject.parse(123)).to eq(123)
      expect(subject.parse([0, true, "abc"])).to eq([0, true, "abc"])
    end
  end
end
