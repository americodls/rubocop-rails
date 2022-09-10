# frozen_string_literal: true

RSpec.describe RuboCop::Cop::Rails::EnumerableFindBy, :config do
  context 'when using an inline block that tests an attribute equality against a variable' do
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

  context 'when using an inline block that tests an attribute equality against a constant' do
    it 'registers and corrects an offense' do
      expect_offense(<<~RUBY)
        people.find { |p| p.id == 42 }
               ^^^^^^^^^^^^^^^^^^^^^^^ Use `find_by` instead of `find` when testing attributes equality.
      RUBY

      expect_correction(<<~RUBY)
        people.find_by(id: 42)
      RUBY
    end
  end

  context 'when using an inline block that tests multiple attributes equality' do
    it 'registers and corrects an offense' do
      expect_offense(<<~RUBY)
        people.find { |p| p.id == ID && p.code == some_code && p.type == "Typo" }
               ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Use `find_by` instead of `find` when testing attributes equality.
      RUBY

      expect_correction(<<~RUBY)
        people.find_by(id: ID, code: some_code, type: "Typo")
      RUBY
    end
  end
end
