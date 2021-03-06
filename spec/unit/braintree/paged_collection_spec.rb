require File.dirname(__FILE__) + "/../spec_helper"

describe "Braintree::PagedCollection" do
  it "includes enumerable" do
    collection = Braintree::PagedCollection.new(:items => ["a"])
    collection.detect { |item| item == "a" }.should == "a"
  end

  describe "[]" do
    it "returns the element at the given index" do
      collection = Braintree::PagedCollection.new(:items => ["one", "two", "three"])
      collection[0].should == "one"
      collection[2].should == "three"
      collection[3].should == nil
    end
  end

  describe "each" do
    it "iterates over the contents" do
      expected = ["apples", "bananas", "cherries"]
      collection = Braintree::PagedCollection.new(
        :items => expected
      )
      actual = []
      collection.each do |item|
        actual << item
      end
      actual.should == expected
    end
  end

  describe "first" do
    it "returns the first element" do
      collection = Braintree::PagedCollection.new(
        :items => ["apples", "bananas", "cherries"]
      )
      collection.first.should == "apples"
    end
  end

  describe "initialize" do
    it "initializes attributes as expected" do
      collection = Braintree::PagedCollection.new(
        :current_page_number => 1,
        :page_size => 2,
        :total_items => 4,
        :items => ["apples", "bananas", "cherries"]
      )
      collection.current_page_number.should == 1
      collection.page_size.should == 2
      collection.total_items.should == 4
      collection.items.should == ["apples", "bananas", "cherries"]
    end
  end

  describe "last_page?" do
    it "returns true if the page is the last page" do
      collection = Braintree::PagedCollection.new(:current_page_number => 3, :page_size => 50, :total_items => 150)
      collection.last_page?.should == true
    end

    it "returns false if the page is not the last page" do
      collection = Braintree::PagedCollection.new(:current_page_number => 3, :page_size => 50, :total_items => 151)
      collection.last_page?.should == false
    end
  end

  describe "next_page" do
    it "returns the next page of results" do
      collection = Braintree::PagedCollection.new(
          :current_page_number => 1,
          :page_size => 1,
          :total_items => 2
        ) do |page_num|
        "contents of page #{page_num}"
      end
      collection.next_page.should == "contents of page 2"
    end

    it "returns nil if on last page" do
      collection = Braintree::PagedCollection.new(
          :current_page_number => 2,
          :page_size => 2,
          :total_items => 4
        )
      collection.next_page.should == nil
    end
  end

  describe "next_page_number" do
    it "returns the next page number when not on the last page" do
      collection = Braintree::PagedCollection.new(
        :current_page_number => 2,
        :page_size => 1,
        :total_items => 50
      )
      collection.next_page_number.should == 3
    end

    it "returns nil when on the last page" do
      collection = Braintree::PagedCollection.new(
        :current_page_number => 1,
        :page_size => 1,
        :total_items => 1
      )
      collection.next_page_number.should == nil
    end
  end

  describe "total_pages" do
    it "calculates the total number of pages when total items is not evenly divisible by page size" do
      collection = Braintree::PagedCollection.new(
        :page_size => 5,
        :total_items => 13
      )
      collection.total_pages.should == 3
    end

    it "calculates the total number of pages when total items is not evenly divisible by page size" do
      collection = Braintree::PagedCollection.new(
        :page_size => 5,
        :total_items => 20
      )
      collection.total_pages.should == 4
    end
  end

end
