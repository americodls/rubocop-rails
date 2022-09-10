# frozen_string_literal: true

RSpec.describe RuboCop::Cop::Rails::EnumerableFindBy, :config do
  context 'when using a block that tests an attribute equality' do
    it 'registers and corrects an offense' do
      expect_offense(<<~RUBY)
        people.find { |p| p.id == some_id }
               ^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Use `find_by` instead of `find` when testing attributes equality.
      RUBY

      expect_correction(<<~RUBY)
        people.find_by(id: some_id)
      RUBY
    end
  end

  context 'when using a block that tests an attribute equality' do
    it 'registers and corrects an offense' do
      expect_offense(<<~RUBY)
        people.find { |p| p.id == some_id && p.code == some_code && p.type == some_type }
               ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Use `find_by` instead of `find` when testing attributes equality.
      RUBY

      expect_correction(<<~RUBY)
        people.find_by(id: some_id, code: some_code, type: some_type)
      RUBY
    end
  end
end
