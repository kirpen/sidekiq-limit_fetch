require 'spec_helper'

describe Sidekiq::Queue do
  context 'singleton' do
    shared_examples :constructor do
      it 'with default name' do
        new_object = -> { described_class.send constructor }
        new_object.call.should == new_object.call
      end

      it 'with given name' do
        new_object = ->(name) { described_class.send constructor, name }
        new_object.call('name').should == new_object.call('name')
      end
    end

    context '.new' do
      let(:constructor) { :new }
      it_behaves_like :constructor
    end

    context '.[]' do
      let(:constructor) { :[] }
      it_behaves_like :constructor
    end

    context '#lock' do
      let(:name) { 'example' }
      let(:queue) { Sidekiq::Queue[name] }

      shared_examples_for :lock do
        it 'should be available' do
          queue.acquire.should be
        end

        it 'should be pausable' do
          queue.pause
          queue.acquire.should_not be
        end

        it 'should be continuable' do
          queue.pause
          queue.unpause
          queue.acquire.should be
        end

        it 'should be limitable' do
          queue.limit = 1
          queue.acquire.should be
          queue.acquire.should_not be
        end

        it 'should be resizable' do
          queue.limit = 0
          queue.acquire.should_not be
          queue.limit = nil
          queue.acquire.should be
        end

        it 'should be countable' do
          queue.limit = 3
          5.times { queue.acquire }
          queue.busy.should == 3
        end

        it 'should be releasable' do
          queue.acquire
          queue.busy.should == 1
          queue.release
          queue.busy.should == 0
        end

        it 'should tell if paused' do
          queue.should_not be_paused
          queue.pause
          queue.should be_paused
          queue.unpause
          queue.should_not be_paused
        end

        it 'should tell if blocking' do
          queue.should_not be_blocking
          queue.block
          queue.should be_blocking
          queue.unblock
          queue.should_not be_blocking
        end
      end

      context 'global' do
        before(:all) { Sidekiq.options[:local] = false }
        it_behaves_like :lock
      end

      context 'local' do
        before(:all) { Sidekiq.options[:local] = true }
        it_behaves_like :lock
      end
    end
  end
end
