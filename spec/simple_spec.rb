# frozen_string_literal: true

require 'scrapod/redis/base'

require 'redis'

class Foo < Scrapod::Redis::Base
  self.model_name = 'foo'

  datetime :created_at, null: false
end

RSpec.describe Scrapod::Redis::Base do
  subject { Foo.new conn: conn, created_at: created_at }

  let(:conn) { Redis.new }

  let(:created_at) { Time.now }

  it { is_expected.to be_valid }

  context 'when required field is set to nil' do
    let(:created_at) { nil }

    it { is_expected.not_to be_valid }
  end

  describe '.find' do
    before do
      subject.save
    end

    it 'finds by ID' do
      expect(Foo.find(conn, subject.id).as_json).to eq subject.as_json
    end
  end

  describe '#persisted?' do
    context 'new record' do
      it 'returns false' do
        expect(subject).not_to be_persisted
      end
    end

    context 'persisted record' do
      before do
        subject.save
      end

      it 'returns true' do
        expect(subject).to be_persisted
      end
    end

    context 'deleted record' do
      before do
        subject.save
        subject.destroy
      end

      it 'returns false' do
        expect(subject).not_to be_persisted
      end
    end
  end

  describe '#id' do
    context 'new record' do
      it 'returns nil' do
        expect(subject.id).to eq nil
      end
    end

    context 'persisted record' do
      before do
        subject.save
      end

      it 'returns a String' do
        expect(subject.id).to be_a String
      end

      it 'is not blank' do
        expect(subject.id.strip).not_to be_empty
      end
    end

    context 'deleted record' do
      before do
        subject.save
        subject.destroy
      end

      it 'returns nil' do
        expect(subject.id).to eq nil
      end
    end
  end

  describe '#require_id' do
    context 'new record' do
      it 'raises error' do
        expect { subject.require_id }.to raise_error described_class::RecordNotPersistedError
      end
    end

    context 'persisted record' do
      before do
        subject.save
      end

      it 'equals to #id' do
        expect(subject.require_id).to eq subject.id
      end
    end

    context 'deleted record' do
      before do
        subject.save
        subject.destroy
      end

      it 'raises error' do
        expect { subject.require_id }.to raise_error described_class::RecordNotPersistedError
      end
    end
  end

  describe '#as_json' do
    it 'serializes record' do
      expect(subject.as_json).to eq(
        'created_at' => created_at.to_i,
      )
    end
  end
end
