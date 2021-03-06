require File.dirname(__FILE__) + "/../spec_helper"

describe Braintree::Util do
  describe "self.symbolize_keys" do
    it "does not modify the hash" do
      original = {"a" => "b", "c" => "d"}
      new = Braintree::Util.symbolize_keys(original)

      original["a"].should == "b"
      new[:a].should == "b"
    end

    it "symbolizes nested keys" do
      hash = {"a" => {"b" => {"c" => "d" }}}
      Braintree::Util.symbolize_keys(hash).should == {:a => {:b => {:c => "d"}}}
    end

    it "symbolizes nested keys in arrays" do
      hash = {"a" => ["b" => {"c" => "d" }]}
      Braintree::Util.symbolize_keys(hash).should == {:a => [:b => {:c => "d"}]}
    end
  end

  describe "self.verify_keys" do
    it "raises an exception if the hash contains an invalid key" do
      expect do
        Braintree::Util.verify_keys([:allowed], :allowed => "ok", :disallowed => "bad")
      end.to raise_error(ArgumentError, "invalid keys: disallowed")
    end

    it "raises an exception with all keys listed if the hash contains invalid keys" do
      expect do
        Braintree::Util.verify_keys([:allowed], :allowed => "ok", :disallowed => "bad", "also_invalid" => true)
      end.to raise_error(ArgumentError, "invalid keys: also_invalid, disallowed")
    end

    it "raises an exception if a nested hash contains an invalid key" do
      expect do
        Braintree::Util.verify_keys(
          [:allowed, {:nested => [:nested_allowed, :nested_allowed2]}],
          :allowed => "ok",
          :top_level_invalid => "bad",
          :nested => {
            :nested_allowed => "ok",
            :nested_allowed2 => "also ok",
            :nested_invalid => "bad"
          }
        )
      end.to raise_error(ArgumentError, "invalid keys: nested[nested_invalid], top_level_invalid")
    end

    it "does not raise an exception for wildcards" do
      expect do
        Braintree::Util.verify_keys(
          [:allowed, {:custom_fields => :_any_key_}],
          :allowed => "ok",
          :custom_fields => {
            :custom_allowed => "ok",
            :custom_allowed2 => "also ok",
          }
        )
      end.to_not raise_error
    end

    it "raise an exception for wildcards at different nesting" do
      expect do
        Braintree::Util.verify_keys(
          [:allowed, {:custom_fields => :_any_key_}],
          :allowed => {
            :custom_fields => {
              :bad_nesting => "very bad"
            }
          }
        )
      end.to raise_error(ArgumentError, "invalid keys: allowed[custom_fields][bad_nesting]")
    end

    it "raises an exception if a deeply nested hash contains an invalid key" do
      expect do
        Braintree::Util.verify_keys(
          [:allowed, {:nested => [:nested_allowed, :nested_allowed2, {:deeply_allowed => [:super_deep_allowed]}]}],
          :allowed => "ok",
          :top_level_invalid => "bad",
          :nested => {
            :nested_allowed => "ok",
            :nested_allowed2 => "also ok",
            :nested_invalid => "bad",
            :deeply_allowed => {
              :super_deep_allowed => "yep",
              :real_deep_invalid => "nope"
            }
          }
        )
      end.to raise_error(ArgumentError, "invalid keys: nested[deeply_allowed][real_deep_invalid], nested[nested_invalid], top_level_invalid")
    end
  end

  describe "self._flatten_hash_keys" do
    it "flattens hash keys" do
      Braintree::Util._flatten_hash_keys(:nested => {
        :nested_allowed => "ok",
        :nested_allowed2 => "also ok",
        :nested_invalid => "bad"
      }).should == ["nested[nested_allowed2]", "nested[nested_allowed]", "nested[nested_invalid]"]
    end
  end

  describe "self._flatten_valid_keys" do
    it "flattens hash keys" do
      Braintree::Util._flatten_valid_keys(
        [:top_level, {:nested => [:nested_allowed, :nested_allowed2]}]
      ).should == ["nested[nested_allowed2]", "nested[nested_allowed]", "top_level"]
    end

    it "allows wildcards with the :_any_key_ symbol" do
      Braintree::Util._flatten_valid_keys(
        [:top_level, {:nested => :_any_key_}]
      ).should == ["nested[_any_key_]", "top_level"]
    end
  end

  describe "self.extract_attribute_as_array" do
    it "delets the attribute from the hash" do
      hash = {:foo => ["x"], :bar => :baz}
      Braintree::Util.extract_attribute_as_array(hash, :foo)
      hash.should == {:bar => :baz}
    end

    it "puts the attribute in an array if it's not an array" do
      hash = {:foo => "x", :bar => :baz}
      result = Braintree::Util.extract_attribute_as_array(hash, :foo)
      result.should == ["x"]
    end

    it "returns the value if it's already an array" do
      hash = {:foo => ["one", "two"], :bar => :baz}
      result = Braintree::Util.extract_attribute_as_array(hash, :foo)
      result.should == ["one", "two"]
    end
  end

  describe "self.hash_to_query_string" do
    it "generates a query string from the hash" do
      hash = {:foo => {:key_one => "value_one", :key_two => "value_two"}}
      Braintree::Util.hash_to_query_string(hash).should == "foo%5Bkey_one%5D=value_one&foo%5Bkey_two%5D=value_two"
    end

    it "works for nesting 2 levels deep" do
      hash = {:foo => {:nested => {:key_one => "value_one", :key_two => "value_two"}}}
      Braintree::Util.hash_to_query_string(hash).should == "foo%5Bnested%5D%5Bkey_one%5D=value_one&foo%5Bnested%5D%5Bkey_two%5D=value_two"
    end
  end

  describe "self.parse_query_string" do
    it "parses the query string" do
      query_string = "foo=bar%20baz&hash=a1b2c3"
      Braintree::Util.parse_query_string(query_string).should == {:foo => "bar baz", :hash => "a1b2c3"}
    end
  end

  describe "self.raise_exception_for_status_code" do
    it "raises an AuthenticationError if authentication fails" do
      expect do
        Braintree::Util.raise_exception_for_status_code(401)
      end.to raise_error(Braintree::AuthenticationError)
    end

    it "raises an AuthorizationError if authorization fails" do
      expect do
        Braintree::Util.raise_exception_for_status_code(403)
      end.to raise_error(Braintree::AuthorizationError)
    end

    it "raises a ServerError if the server 500's" do
      expect do
        Braintree::Util.raise_exception_for_status_code(500)
      end.to raise_error(Braintree::ServerError)
    end

    it "raises a DownForMaintenanceError if the server is down for maintenance" do
      expect do
        Braintree::Util.raise_exception_for_status_code(503)
      end.to raise_error(Braintree::DownForMaintenanceError)
    end

    it "raises an UnexpectedError if some other code is returned" do
      expect do
        Braintree::Util.raise_exception_for_status_code(600)
      end.to raise_error(Braintree::UnexpectedError, "Unexpected HTTP_RESPONSE 600")
    end
  end

  describe "self.to_big_decimal" do
    it "returns the BigDecimal when given a BigDecimal" do
      Braintree::Util.to_big_decimal(BigDecimal.new("12.34")).should == BigDecimal.new("12.34")
    end

    it "returns a BigDecimal when given a string" do
      Braintree::Util.to_big_decimal("12.34").should == BigDecimal.new("12.34")
    end

    it "returns nil when given nil" do
      Braintree::Util.to_big_decimal(nil).should be_nil
    end

    it "blows up when not given a String or BigDecimal" do
      expect {
        Braintree::Util.to_big_decimal(12.34)
      }.to raise_error(/Argument must be a String or BigDecimal/)
    end
  end

  describe "self.url_encode" do
    it "url encodes the given text" do
      Braintree::Util.url_encode("foo?bar").should == "foo%3Fbar"
    end
  end
end
