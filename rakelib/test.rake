require File.dirname(__FILE__) + '/../test/helper'

Rake::TestTask.new(:test) do |t|
  t.test_files = FileList['test/**/test*.rb']
end