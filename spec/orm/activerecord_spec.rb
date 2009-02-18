require File.dirname(__FILE__) + '/../spec_helper'

require 'merb_upload/orm/activerecord'

# change this if sqlite is unavailable
dbconfig = {
  :adapter => 'sqlite3',
  :database => ':memory:'
}

ActiveRecord::Base.establish_connection(dbconfig)
ActiveRecord::Migration.verbose = false

class TestMigration < ActiveRecord::Migration
  def self.up
    create_table :events, :force => true do |t|
      t.column :image, :string
      t.column :textfile, :string
    end
  end

  def self.down
    drop_table :events
  end
end

class Event < ActiveRecord::Base; end # setup a basic AR class for testing

describe Merb::Upload::ActiveRecord do
  
  include SanitizedFileSpecHelper
  
  describe '.mount_uploader' do
    
    before(:all) { TestMigration.up }
    after(:all) { TestMigration.down }
    after { Event.delete_all }
    
    before do
      @class = Class.new(ActiveRecord::Base)
      @class.table_name = "events"
      @uploader = Class.new(Merb::Upload::Uploader)
      @class.mount_uploader(:image, @uploader)
      @event = @class.new
    end
    
    describe '#image' do
      
      it "should return nil when nothing has been assigned" do
        @event.image.should be_nil
      end
      
      it "should return nil when an empty string has been assigned" do
        @event[:image] = ''
        @event.save
        @event.reload
        @event.image.should be_nil
      end
      
      it "should retrieve a file from the storage if a value is stored in the database" do
        @event[:image] = 'test.jpeg'
        @event.save
        @event.reload
        @event.image.should be_an_instance_of(@uploader)
      end
      
      it "should set the path to the store dir" do
        @event[:image] = 'test.jpeg'
        @event.save
        @event.reload
        @event.image.current_path.should == public_path('uploads/test.jpeg')
      end
    
    end
    
    describe '#image=' do
      
      it "should cache a file" do
        @event.image = stub_file('test.jpeg')
        @event.image.should be_an_instance_of(@uploader)
      end
      
      it "should write nothing to the database, to prevent overriden filenames to fail because of unassigned attributes" do
        @event[:image].should be_nil
      end
      
      it "should copy a file into into the cache directory" do
        @event.image = stub_file('test.jpeg')
        @event.image.current_path.should =~ /^#{public_path('uploads/tmp')}/
      end
      
      it "should do nothing when nil is assigned" do
        @event.image = nil
        @event.image.should be_nil
      end
      
      it "should do nothing when an empty string is assigned" do
        @event.image = ''
        @event.image.should be_nil
      end
      
    end
    
    describe '#save' do
      
      it "should do nothing when no file has been assigned" do
        @event.save.should be_true
        @event.image.should be_nil
      end
      
      it "should copy the file to the upload directory when a file has been assigned" do
        @event.image = stub_file('test.jpeg')
        @event.save.should be_true
        @event.image.should be_an_instance_of(@uploader)
        @event.image.current_path.should == public_path('uploads/test.jpeg')
      end
      
      it "should do nothing when a validation fails" do
        @class.validate { |r| r.errors.add :textfile, "FAIL!" }
        @event.image = stub_file('test.jpeg')
        @event.save.should be_false
        @event.image.should be_an_instance_of(@uploader)
        @event.image.current_path.should =~ /^#{public_path('uploads/tmp')}/
      end
      
      it "should assign the filename to the database" do
        @event.image = stub_file('test.jpeg')
        @event.save.should be_true
        @event.reload
        @event[:image].should == 'test.jpeg'
      end
      
      it "should assign the filename before validation" do
        @class.validate { |r| r.errors.add_to_base "FAIL!" if r[:image].nil? }
        @event.image = stub_file('test.jpeg')
        @event.save.should be_true
        @event.reload
        @event[:image].should == 'test.jpeg'
      end
      
    end
    
  end
  
end