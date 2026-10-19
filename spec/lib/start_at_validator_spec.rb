# frozen_string_literal: true

RSpec.describe DiscourseKuuRewards::StartAtValidator do
  subject(:validator) { described_class.new }

  it "accepts a time with a time zone" do
    expect(validator.valid_value?("2026-10-20 00:00 +09:00")).to eq(true)
    expect(validator.valid_value?("2026-10-19T15:00:00Z")).to eq(true)
  end

  it "rejects a time without a time zone" do
    expect(validator.valid_value?("2026-10-20 00:00")).to eq(false)
  end

  it "rejects garbage" do
    expect(validator.valid_value?("tomorrow +09:00")).to eq(false)
    expect(validator.valid_value?("")).to eq(false)
  end

  it "parses the default as midnight in Japan" do
    expect(DiscourseKuuRewards.start_at).to eq_time(Time.utc(2026, 10, 19, 15))
  end
end
