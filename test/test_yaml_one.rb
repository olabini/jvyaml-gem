
require 'test/unit'
require 'yaml'
#require 'jvyaml'

class JvYAMLUnitTests < Test::Unit::TestCase
  def test_basic_strings
    assert_equal("str", YAML.load("!str str"))
    assert_equal("str", YAML.load("--- str"))
    assert_equal("str", YAML.load("---\nstr"))
    assert_equal("str", YAML.load("--- \nstr"))
    assert_equal("str", YAML.load("--- \n str"))
    assert_equal("str", YAML.load("str"))
    assert_equal("str", YAML.load(" str"))
    assert_equal("str", YAML.load("\nstr"))
    assert_equal("str", YAML.load("\n str"))
    assert_equal("str", YAML.load('"str"'))
    assert_equal("str", YAML.load("'str'"))
    assert_equal("str", YAML.load(" --- 'str'"))
    assert_equal("1.0", YAML.load("!str 1.0"))
  end


  def test_other_basic_types
    assert_equal(:str, YAML.load(":str"))

    assert_equal(47, YAML.load("47"))
    assert_equal(0, YAML.load("0"))
    assert_equal(-1, YAML.load("-1"))

    assert_equal({'a' => 'b', 'c' => 'd' }, YAML.load("a: b\nc: d"))
    assert_equal({'a' => 'b', 'c' => 'd' }, YAML.load("c: d\na: b\n"))

    assert_equal({'a' => 'b', 'c' => 'd' }, YAML.load("{a: b, c: d}"))
    assert_equal({'a' => 'b', 'c' => 'd' }, YAML.load("{c: d,\na: b}"))

    assert_equal(%w(a b c), YAML.load("--- \n- a\n- b\n- c\n"))
    assert_equal(%w(a b c), YAML.load("--- [a, b, c]"))
    assert_equal(%w(a b c), YAML.load("[a, b, c]"))

    assert_equal("--- str\n", "str".to_yaml)
    assert_equal("--- \na: b\n", {'a'=>'b'}.to_yaml)
    assert_equal("--- \n- a\n- b\n- c\n", %w(a b c).to_yaml)

    assert_equal("--- \"1.0\"\n", "1.0".to_yaml)
  end

  class TestBean
    attr_accessor :value, :key
    def initialize(v,k)
      @value=v
      @key=k
    end

    def ==(other)
      self.class == other.class && self.value == other.value && self.key == other.key
    end
  end

  TestStruct = Struct.new(:foo,:bar)
  def test_custom_serialization
    assert(["--- !ruby/object:JvYAMLUnitTests::TestBean \nvalue: 13\nkey: 42\n",
            "--- !ruby/object:JvYAMLUnitTests::TestBean \nkey: 42\nvalue: 13\n"].include?(TestBean.new(13,42).to_yaml))
    assert_equal(TestBean.new(13,42),YAML.load("--- !ruby/object:JvYAMLUnitTests::TestBean \nvalue: 13\nkey: 42\n"))

    assert(["--- !ruby/struct:JvYAMLUnitTests::TestStruct \nfoo: 13\nbar: 42\n","--- !ruby/struct:JvYAMLUnitTests::TestStruct \nbar: 42\nfoo: 13\n"].include?(TestStruct.new(13,42).to_yaml))
    assert_equal("--- !ruby/exception:StandardError \nmessage: foobar\n", StandardError.new("foobar").to_yaml)
  end

  def test_symbols
    assert_equal("--- :foo\n", :foo.to_yaml)
  end

  def test_range
    assert_equal(["--- !ruby/range ", "begin: 1", "end: 3", "excl: false"], (1..3).to_yaml.split("\n").sort)
    assert_equal(["--- !ruby/range ", "begin: 1", "end: 3", "excl: true"], (1...3).to_yaml.split("\n").sort)
  end

  def test_regexps
    assert_equal("--- !ruby/regexp /^abc/\n", /^abc/.to_yaml)
  end

  def test_times_and_dates
    assert_equal("--- 1982-05-03 15:32:44 Z\n",Time.utc(1982,05,03,15,32,44).to_yaml)
    assert_equal("--- 2005-05-03\n",Date.new(2005,5,3).to_yaml)
  end

  def test_weird_numbers
    assert_equal("--- .NaN\n",(0.0/0.0).to_yaml)
    assert_equal("--- .Inf\n",(1.0/0.0).to_yaml)
    assert_equal("--- -.Inf\n",(-1.0/0.0).to_yaml)
    assert_equal("--- 0.0\n", (0.0).to_yaml)
    assert_equal("--- 0\n", 0.to_yaml)
  end

  def test_boolean
    assert_equal("--- true\n", true.to_yaml)
    assert_equal("--- false\n", false.to_yaml)
  end

  def test_nil
    assert_equal("--- \n", nil.to_yaml)
  end

  def test_JRUBY_718
    assert_equal("--- \"\"\n", ''.to_yaml)
    assert_equal('', YAML.load("---\n!str"))
  end

  def test_JRUBY_719
    assert_equal('---', YAML.load("--- ---\n"))
    assert_equal('---', YAML.load("---"))
  end

  def test_shared_strings
    astr = "abcde"
    shared = astr[2..-1]
    assert_equal('cde', YAML.load(shared))
    assert_equal("--- cde\n", shared.to_yaml)
  end

  def test_JRUBY_1026
    a = "one0.1"
    b = a[3..-1]
    assert_equal("--- \"0.1\"\n", YAML.dump(b))
  end

  class HashWithIndifferentAccess < Hash
  end

  def test_JRUBY_1169
    hash = HashWithIndifferentAccess.new
    hash['kind'] = 'human'
    need_to_be_serialized = {:first => 'something', :second_params => hash}
    a = {:x => need_to_be_serialized.to_yaml}
    assert_equal need_to_be_serialized, YAML.load(YAML.load(a.to_yaml)[:x])
  end

  def test_JRUBY_1220
    bad_text = " A\nR"
    dump = YAML.dump({'text' => bad_text})
    loaded = YAML.load(dump)
    assert_equal bad_text, loaded['text']

    bad_text = %{
 ActiveRecord::StatementInvalid in ProjectsController#confirm_delete
RuntimeError: ERROR	C23503	Mupdate or delete on "projects" violates foreign
    }

    dump = YAML.dump({'text' => bad_text})
    loaded = YAML.load(dump)
    assert_equal bad_text, loaded['text']

    string = <<-YAML
outer
  property1: value1
  additional:
  - property2: value2
    color: green
    data: SELECT 'xxxxxxxxxxxxxxxxxxx', COUNT(*) WHERE xyzabc = 'unk'
    combine: overlay-bottom
YAML
    assert_equal string, YAML.load(YAML.dump(string))
  end

  def test_whitespace_variations
    text = " "*80 + "\n" + " "*30
    assert_equal text, YAML.load(YAML.dump(text))

    text = <<-YAML
  - label: New
    color: green
    data: SELECT 'Iteration Scheduled', COUNT(*) WHERE Status = 'New'
    combine: overlay-bottom
  - label: Open
    color: pink
    data: SELECT 'Iteration Scheduled', COUNT(*) WHERE Status = 'Open'
    combine: overlay-bottom
  - label: Ready for Development
    color: yellow
    data: SELECT 'Iteration Scheduled', COUNT(*) WHERE Status = 'Ready for Development'
    combine: overlay-bottom
    color: blue
    data: SELECT 'Iteration Scheduled', COUNT(*) WHERE Status = 'Complete'
    combine: overlay-bottom
  - label: Other statuses
    color: red
    data: SELECT 'Iteration Scheduled', COUNT(*)
                    combine: total
YAML

    assert_equal text, YAML.load(YAML.dump(text))

    text = <<-YAML
stack-bar-chart
  conditions: 'Release' in (R1) and not 'Iteration Scheduled' = null
  labels: SELECT DISTINCT 'Iteration Scheduled' ORDER BY 'Iteration Scheduled'
  cumulative: true
  series:
  - label: New
    color: green
    data: SELECT 'Iteration Scheduled', COUNT(*) WHERE Status = 'New'
    combine: overlay-bottom
  - label: Open
    color: pink
    data: SELECT 'Iteration Scheduled', COUNT(*) WHERE Status = 'Open'
    combine: overlay-bottom
  - label: Ready for Development
    color: yellow
    data: SELECT 'Iteration Scheduled', COUNT(*) WHERE Status = 'Ready for Development'
    combine: overlay-bottom
  - label: Complete
    color: blue
    data: SELECT 'Iteration Scheduled', COUNT(*) WHERE Status = 'Complete'
    combine: overlay-bottom
  - label: Other statuses
    color: red
    data: SELECT 'Iteration Scheduled', COUNT(*)
    combine: total
YAML

    assert_equal text, YAML.load(YAML.dump(text))
  end

  def test_nested_stuff
    text = <<YAML
valid_key:
key1: value
invalid_key
akey: blah
YAML

    assert_raises(ArgumentError) do
      YAML.load(text)
    end
  end

  def roundtrip(text)
    assert_equal text, YAML.load(YAML.dump(text))
  end

  def test_weird_stuff
    roundtrip("C VW\205\v\321XU\346")
    roundtrip("\n8 xwKmjHG")
    roundtrip("1jq[\205qIB\ns")
    roundtrip("\rj\230fso\304\nEE")
    roundtrip("ks]qkYM\2073Un\317\nL\346Yp\204 CKMfFcRDFZ\vMNk\302fQDR<R\v \314QUa\234P\237s aLJnAu \345\262Wqm_W\241\277J\256ILKpPNsMPuok")
    roundtrip :"1"
  end

  def fuzz_roundtrip(str)
    out = YAML.load(YAML.dump(str))
    assert_equal str, out
  end

  values = (1..255).to_a
  more = ('a'..'z').to_a + ('A'..'Z').to_a
  blanks = [' ', "\t", "\n"]

  types = [more*10 + blanks*2, values + more*10 + blanks*2, values + more*10 + blanks*20]
  sizes = [10, 81, 214]

  errors = []
  num = 0
  types.each do |t|
    sizes.each do |s|
      1000.times do |vv|
        val = ""
        s.times do
          val << t[rand(t.length)]
        end
        define_method :"test_fuzz_#{num+=1}" do
          fuzz_roundtrip(val)
        end
      end
    end
  end

  class YamlTest
    def initialize
      @test = Hash.new
      @test["hello"] = "foo"
    end
  end

  def test_JRUBY_1471
    list = [YamlTest.new, YamlTest.new, YamlTest.new]
    assert_equal 3, list.map{ |ll| ll.object_id }.uniq.length
    list2 = YAML.load(YAML.dump(list))
    assert_equal 3, list2.map{ |ll| ll.object_id }.uniq.length
  end
end

__END__




# JRUBY-1659
YAML.load("{a: 2007-01-01 01:12:34}")

# JRUBY-1765
#assert_equal Date.new(-1,1,1), YAML.load(Date.new(-1,1,1).to_yaml)

# JRUBY-1766
test_ok YAML.load(Time.now.to_yaml).instance_of?(Time)
test_ok YAML.load("2007-01-01 01:12:34").instance_of?(String)
test_ok YAML.load("2007-01-01 01:12:34.0").instance_of?(String)
test_ok YAML.load("2007-01-01 01:12:34 +00:00").instance_of?(Time)
test_ok YAML.load("2007-01-01 01:12:34.0 +00:00").instance_of?(Time)
test_ok YAML.load("{a: 2007-01-01 01:12:34}")["a"].instance_of?(String)

# JRUBY-1898
val = YAML.load(<<YAML)
---
- foo
- foo
- [foo]
- [foo]
- {foo: foo}
- {foo: foo}
YAML

test_ok val[0].object_id != val[1].object_id
test_ok val[2].object_id != val[3].object_id
test_ok val[4].object_id != val[5].object_id

# JRUBY-1911
val = YAML.load(<<YAML)
---
foo: { bar }
YAML

assert_equal({"foo" => {"bar" => nil}}, val)

# JRUBY-1756
# This is almost certainly invalid YAML. but MRI handles it...
val = YAML.load(<<YAML)
---
default: –
- a
YAML

assert_equal({"default" => ['a']}, val)

# JRUBY-1978, scalars can start with , if it's not ambigous
assert_equal(",a", YAML.load("--- \n,a"))

# Make sure that overriding to_yaml always throws an exception unless it returns the correct thing

class TestYamlFoo
  def to_yaml(*args)
    "foo"
  end
end

test_exception(TypeError) do
  { :foo => TestYamlFoo.new }.to_yaml
end

# JRUBY-2019, handle tagged_classes, yaml_as and so on a bit better

assert_equal({
             "tag:yaml.org,2002:omap"=>YAML::Omap,
             "tag:yaml.org,2002:pairs"=>YAML::Pairs,
             "tag:yaml.org,2002:set"=>YAML::Set,
             "tag:yaml.org,2002:timestamp#ymd"=>Date,
             "tag:yaml.org,2002:bool#yes"=>TrueClass,
             "tag:yaml.org,2002:int"=>Integer,
             "tag:yaml.org,2002:timestamp"=>Time,
             "tag:yaml.org,2002:binary"=>String,
             "tag:yaml.org,2002:str"=>String,
             "tag:yaml.org,2002:map"=>Hash,
             "tag:yaml.org,2002:null"=>NilClass,
             "tag:yaml.org,2002:bool#no"=>FalseClass,
             "tag:yaml.org,2002:seq"=>Array,
             "tag:yaml.org,2002:float"=>Float,
             "tag:ruby.yaml.org,2002:sym"=>Symbol,
             "tag:ruby.yaml.org,2002:object"=>Object,
             "tag:ruby.yaml.org,2002:hash"=>Hash,
             "tag:ruby.yaml.org,2002:time"=>Time,
             "tag:ruby.yaml.org,2002:symbol"=>Symbol,
             "tag:ruby.yaml.org,2002:string"=>String,
             "tag:ruby.yaml.org,2002:regexp"=>Regexp,
             "tag:ruby.yaml.org,2002:range"=>Range,
             "tag:ruby.yaml.org,2002:array"=>Array,
             "tag:ruby.yaml.org,2002:exception"=>Exception,
             "tag:ruby.yaml.org,2002:struct"=>Struct,
           },
           YAML::tagged_classes)


# JRUBY-2083

assert_equal({'foobar' => '>= 123'}, YAML.load("foobar: >= 123"))

# JRUBY-2135
assert_equal({'foo' => 'bar'}, YAML.load("---\nfoo: \tbar"))

# JRUBY-1911
assert_equal({'foo' => {'bar' => nil, 'qux' => nil}}, YAML.load("---\nfoo: {bar, qux}"))

# JRUBY-2323
class YAMLTestException < Exception;end
class YAMLTestString < String; end
assert_equal('--- !str:YAMLTestString', YAMLTestString.new.to_yaml.strip)
assert_equal(YAMLTestString.new, YAML::load('--- !str:YAMLTestString'))

assert_equal(<<EXCEPTION_OUT, YAMLTestException.new.to_yaml)
--- !ruby/exception:YAMLTestException
message: YAMLTestException
EXCEPTION_OUT

assert_equal(YAMLTestException.new.inspect, YAML::load(YAMLTestException.new.to_yaml).inspect)

# JRUBY-2409
assert_equal("*.rb", YAML::load("---\n*.rb"))
assert_equal("&.rb", YAML::load("---\n&.rb"))

# JRUBY-2443
a_str = "foo"
a_str.instance_variable_set :@bar, "baz"

test_ok(["--- !str \nstr: foo\n\"@bar\": baz\n", "--- !str \n\"@bar\": baz\nstr: foo\n"].include?(a_str.to_yaml))
assert_equal "baz", YAML.load(a_str.to_yaml).instance_variable_get(:@bar)

assert_equal :"abc\"flo", YAML.load("---\n:\"abc\\\"flo\"")

# JRUBY-2579
assert_equal [:year], YAML.load("---\n[:year]")

assert_equal({
             'date_select' => { 'order' => [:year, :month, :day] },
             'some' => {
               'id' => 1,
               'name' => 'some',
               'age' => 16}}, YAML.load(<<YAML))
date_select:
  order: [:year, :month, :day]
some:
    id: 1
    name: some
    age: 16
YAML


# JRUBY-2754
obj = Object.new
objects1 = [obj, obj]
test_ok objects1[0].object_id == objects1[1].object_id

objects2 = YAML::load objects1.to_yaml
test_ok objects2[0].object_id == objects2[1].object_id

# JRUBY-2192

class FooYSmith < Array; end

obj = YAML.load(<<YAMLSTR)
--- !ruby/array:FooYSmith
- val
- val2
YAMLSTR

assert_equal FooYSmith, obj.class


class FooXSmith < Hash; end

obj = YAML.load(<<YAMLSTR)
--- !ruby/hash:FooXSmith
key: value
otherkey: othervalue
YAMLSTR

assert_equal FooXSmith, obj.class

# JRUBY-2976
class PersonTestOne
  yaml_as 'tag:data.allman.ms,2008:Person'
end

assert_equal "--- !data.allman.ms,2008/Person {}\n\n", PersonTestOne.new.to_yaml
assert_equal PersonTestOne, YAML.load(PersonTestOne.new.to_yaml).class



Hash.class_eval do
  def to_yaml( opts = {} )
    YAML::quick_emit( self, opts ) do |out|
      out.map( taguri, to_yaml_style ) do |map|
        each do |k, v|
          map.add( k, v )
        end
      end
    end
  end

end

roundtrip({ "element" => "value", "array" => [ { "nested_element" => "nested_value" } ] })

jruby3639 = <<Y
--- !ruby/object:MySoap::InterfaceOne::DiscountServiceRequestType
orderRequest: !ruby/object:MySoap::InterfaceOne::OrderType
  brand: !str
    str: ""
Y

test_no_exception { YAML.load(jruby3639) }

# JRUBY-3773
class Badger
  attr_accessor :name, :age

  def initialize(name, age)
    @name = name
    @age = age
  end

  def to_s
    "#{name}:#{age}"
  end

  def self.from_s (s)
    ss = s.split(":")
    Badger.new ss[0], ss[1]
  end
end

#
# opening Badger to add custom YAML serialization
#
class Badger
  yaml_as "tag:ruby.yaml.org,2002:#{self}"

  def to_yaml (opts={})
    YAML::quick_emit(self.object_id, opts) do |out|
      out.map(taguri) do |map|
        map.add("s", to_s)
      end
    end
  end

  def Badger.yaml_new (klass, tag, val)
    s = val["s"]
    begin
      Badger.from_s s
    rescue => e
      raise "failed to decode Badger from '#{s}'"
    end
  end
end

b = Badger.new("Axel", 35)

assert_equal YAML::dump(b), <<OUT
--- !ruby/Badger
s: Axel:35
OUT


# JRUBY-3751

class ControlStruct < Struct.new(:arg1)
end

class BadStruct < Struct.new(:arg1)
  def initialize(a1)
    self.arg1 = a1
  end
end

class ControlObject
  attr_accessor :arg1

  def initialize(a1)
    self.arg1 = a1
  end

  def ==(o)
    self.arg1 == o.arg1
  end
end

class_obj1  = ControlObject.new('class_value')
struct_obj1 = ControlStruct.new
struct_obj1.arg1 = 'control_value'
struct_obj2 = BadStruct.new('struct_value')

assert_equal YAML.load(class_obj1.to_yaml), class_obj1
assert_equal YAML.load(struct_obj1.to_yaml), struct_obj1
assert_equal YAML.load(struct_obj2.to_yaml), struct_obj2


# JRUBY-3518
class Sample
  attr_reader :key
  def yaml_initialize( tag, val )
    @key = 'yaml initialize'
  end
end

class SampleHash < Hash
  attr_reader :key
  def yaml_initialize( tag, val )
    @key = 'yaml initialize'
  end
end

class SampleArray < Array
  attr_reader :key
  def yaml_initialize( tag, val )
    @key = 'yaml initialize'
  end
end

s = YAML.load(YAML.dump(Sample.new))
assert_equal 'yaml initialize', s.key

s = YAML.load(YAML.dump(SampleHash.new))
assert_equal 'yaml initialize', s.key

s = YAML.load(YAML.dump(SampleArray.new))
assert_equal 'yaml initialize', s.key


# JRUBY-3327

assert_equal YAML.load("- foo\n  bar: bazz"), [{"foo bar" => "bazz"}]

# JRUBY-3263
y = <<YAML
production:
 ABQIAAAAinq15RDnRyoOaQwM_PoC4RTJQa0g3IQ9GZqIMmInSLzwtGDKaBTPoBdSu0WQaPTIv1sXhVRK0Kolfg
 example.com: ABQIAAAAzMUFFnT9uH0Sfg98Y4kbhGFJQa0g3IQ9GZqIMmInSLrthJKGDmlRT98f4j135zat56yjRKQlWnkmod3TB
YAML

assert_equal YAML.load(y)['production'], {"ABQIAAAAinq15RDnRyoOaQwM_PoC4RTJQa0g3IQ9GZqIMmInSLzwtGDKaBTPoBdSu0WQaPTIv1sXhVRK0Kolfg example.com" => "ABQIAAAAzMUFFnT9uH0Sfg98Y4kbhGFJQa0g3IQ9GZqIMmInSLrthJKGDmlRT98f4j135zat56yjRKQlWnkmod3TB"}


# JRUBY-3412
y = "--- 2009-02-16 22::40:26.574754 -05:00\n"
assert_equal YAML.load(y).to_yaml, y
