#
# JvYAML::Store
#
require 'jvyaml'
require 'pstore'

class JvYAML::Store < PStore
  def initialize( *o )
    @opt = JvYAML::DEFAULTS.dup
    if String === o.first
      super(o.shift)
    end
    if o.last.is_a? Hash
      @opt.update(o.pop)
    end
  end

  def dump(table)
    @table.to_jvyaml(@opt)
  end

  def load(content)
    JvYAML::load(content)
  end

  def load_file(file)
    JvYAML::load(file)
  end
end
