require "rake"
require "test_helper"


class RunnerTest < Minitest::Test

  def test_runner
    script_paths = Dir[File.expand_path("../../examples/*.kal", __FILE__)]
    refute_empty script_paths

    script_paths.each do |script_path|
      assert_runner_output /^\s*-?[0-9.]+\s*$/, script_path
    end
  end

  def test_runner_missing_arg
    # error message printed to $stderr, thus $stdout is empty
    assert_runner_output /^$/, nil
  end

  private

  def assert_runner_output(output, script_path)
    Rake.application = Rake::Application.new
    Rake.application.init
    Rake.application.load_rakefile

    assert_output(output) do
      Rake.application[:run].invoke(script_path)
    end
  end

end
