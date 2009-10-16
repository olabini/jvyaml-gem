
require 'test/unit'
require 'jvyaml'

class JvYAMLUnitTests < Test::Unit::TestCase
  def test_basic_strings
    assert_equal("str", JvYAML.load("!str str"))
    assert_equal("str", JvYAML.load("--- str"))
    assert_equal("str", JvYAML.load("---\nstr"))
    assert_equal("str", JvYAML.load("--- \nstr"))
    assert_equal("str", JvYAML.load("--- \n str"))
    assert_equal("str", JvYAML.load("str"))
    assert_equal("str", JvYAML.load(" str"))
    assert_equal("str", JvYAML.load("\nstr"))
    assert_equal("str", JvYAML.load("\n str"))
    assert_equal("str", JvYAML.load('"str"'))
    assert_equal("str", JvYAML.load("'str'"))
    assert_equal("str", JvYAML.load(" --- 'str'"))
    assert_equal("1.0", JvYAML.load("!str 1.0"))
  end


  def test_other_basic_types
    assert_equal(:str, JvYAML.load(":str"))

    assert_equal(47, JvYAML.load("47"))
    assert_equal(0, JvYAML.load("0"))
    assert_equal(-1, JvYAML.load("-1"))

    assert_equal({'a' => 'b', 'c' => 'd' }, JvYAML.load("a: b\nc: d"))
    assert_equal({'a' => 'b', 'c' => 'd' }, JvYAML.load("c: d\na: b\n"))

    assert_equal({'a' => 'b', 'c' => 'd' }, JvYAML.load("{a: b, c: d}"))
    assert_equal({'a' => 'b', 'c' => 'd' }, JvYAML.load("{c: d,\na: b}"))

    assert_equal(%w(a b c), JvYAML.load("--- \n- a\n- b\n- c\n"))
    assert_equal(%w(a b c), JvYAML.load("--- [a, b, c]"))
    assert_equal(%w(a b c), JvYAML.load("[a, b, c]"))

    assert_equal("--- str\n", "str".to_jvyaml)
    assert_equal("--- \na: b\n", {'a'=>'b'}.to_jvyaml)
    assert_equal("--- \n- a\n- b\n- c\n", %w(a b c).to_jvyaml)

    assert_equal("--- \"1.0\"\n", "1.0".to_jvyaml)
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
            "--- !ruby/object:JvYAMLUnitTests::TestBean \nkey: 42\nvalue: 13\n"].include?(TestBean.new(13,42).to_jvyaml))
    assert_equal(TestBean.new(13,42),JvYAML.load("--- !ruby/object:JvYAMLUnitTests::TestBean \nvalue: 13\nkey: 42\n"))

    assert(["--- !ruby/struct:JvYAMLUnitTests::TestStruct \nfoo: 13\nbar: 42\n","--- !ruby/struct:JvYAMLUnitTests::TestStruct \nbar: 42\nfoo: 13\n"].include?(TestStruct.new(13,42).to_jvyaml))
    assert_equal("--- !ruby/exception:StandardError \nmessage: foobar\n", StandardError.new("foobar").to_jvyaml)
  end

  def test_symbols
    assert_equal("--- :foo\n", :foo.to_jvyaml)
  end

  def test_range
    assert_equal(["--- !ruby/range ", "begin: 1", "end: 3", "excl: false"], (1..3).to_jvyaml.split("\n").sort)
    assert_equal(["--- !ruby/range ", "begin: 1", "end: 3", "excl: true"], (1...3).to_jvyaml.split("\n").sort)
  end

  def test_regexps
    assert_equal("--- !ruby/regexp /^abc/\n", /^abc/.to_jvyaml)
  end

  def test_times_and_dates
    assert_equal("--- 1982-05-03 15:32:44 Z\n",Time.utc(1982,05,03,15,32,44).to_jvyaml)
    assert_equal("--- 2005-05-03\n",Date.new(2005,5,3).to_jvyaml)
  end

  def test_weird_numbers
    assert_equal("--- .NaN\n",(0.0/0.0).to_jvyaml)
    assert_equal("--- .Inf\n",(1.0/0.0).to_jvyaml)
    assert_equal("--- -.Inf\n",(-1.0/0.0).to_jvyaml)
    assert_equal("--- 0.0\n", (0.0).to_jvyaml)
    assert_equal("--- 0\n", 0.to_jvyaml)
  end

  def test_boolean
    assert_equal("--- true\n", true.to_jvyaml)
    assert_equal("--- false\n", false.to_jvyaml)
  end

  def test_nil
    assert_equal("--- \n", nil.to_jvyaml)
  end

  def test_JRUBY_718
    assert_equal("--- \"\"\n", ''.to_jvyaml)
    assert_equal('', JvYAML.load("---\n!str"))
  end

  def test_JRUBY_719
    assert_equal('---', JvYAML.load("--- ---\n"))
    assert_equal('---', JvYAML.load("---"))
  end

  def test_shared_strings
    astr = "abcde"
    shared = astr[2..-1]
    assert_equal('cde', JvYAML.load(shared))
    assert_equal("--- cde\n", shared.to_jvyaml)
  end

  def test_JRUBY_1026
    a = "one0.1"
    b = a[3..-1]
    assert_equal("--- \"0.1\"\n", JvYAML.dump(b))
  end

  class HashWithIndifferentAccess < Hash
  end

  def test_JRUBY_1169
    hash = HashWithIndifferentAccess.new
    hash['kind'] = 'human'
    need_to_be_serialized = {:first => 'something', :second_params => hash}
    a = {:x => need_to_be_serialized.to_jvyaml}
    assert_equal need_to_be_serialized, JvYAML.load(JvYAML.load(a.to_jvyaml)[:x])
  end

  def test_JRUBY_1220
    bad_text = " A\nR"
    dump = JvYAML.dump({'text' => bad_text})
    loaded = JvYAML.load(dump)
    assert_equal bad_text, loaded['text']

    bad_text = %{
 ActiveRecord::StatementInvalid in ProjectsController#confirm_delete
RuntimeError: ERROR	C23503	Mupdate or delete on "projects" violates foreign
    }

    dump = JvYAML.dump({'text' => bad_text})
    loaded = JvYAML.load(dump)
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
    assert_equal string, JvYAML.load(JvYAML.dump(string))
  end

  def test_whitespace_variations
    text = " "*80 + "\n" + " "*30
    assert_equal text, JvYAML.load(JvYAML.dump(text))

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

    assert_equal text, JvYAML.load(JvYAML.dump(text))

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

    assert_equal text, JvYAML.load(JvYAML.dump(text))
  end

  def test_nested_stuff
    text = <<YAML
valid_key:
key1: value
invalid_key
akey: blah
YAML

    assert_raises(ArgumentError) do
      JvYAML.load(text)
    end
  end

  def roundtrip(text)
    assert_equal text, JvYAML.load(JvYAML.dump(text))
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
    out = JvYAML.load(JvYAML.dump(str))
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
    list2 = JvYAML.load(JvYAML.dump(list))
    assert_equal 3, list2.map{ |ll| ll.object_id }.uniq.length
  end

  def test_JRUBY_1659
    JvYAML.load("{a: 2007-01-01 01:12:34}")
  end

  def test_JRUBY_1765
    assert_equal Date.new(-1,1,1), JvYAML.load(Date.new(-1,1,1).to_jvyaml)
  end

  def test_JRBY_1766
    assert JvYAML.load(Time.now.to_jvyaml).instance_of?(Time)
    assert JvYAML.load("2007-01-01 01:12:34").instance_of?(String)
    assert JvYAML.load("2007-01-01 01:12:34.0").instance_of?(String)
    assert JvYAML.load("2007-01-01 01:12:34 +00:00").instance_of?(Time)
    assert JvYAML.load("2007-01-01 01:12:34.0 +00:00").instance_of?(Time)
    assert JvYAML.load("{a: 2007-01-01 01:12:34}")["a"].instance_of?(String)
  end

  def test_JRUBY_1898
    val = JvYAML.load(<<YAML)
---
- foo
- foo
- [foo]
- [foo]
- {foo: foo}
- {foo: foo}
YAML

    assert val[0].object_id != val[1].object_id
    assert val[2].object_id != val[3].object_id
    assert val[4].object_id != val[5].object_id
  end

  def test_JRUBY_1911
    val = JvYAML.load(<<YAML)
---
foo: { bar }
YAML

    assert_equal({"foo" => {"bar" => nil}}, val)
  end

  def test_JRUBY_1756
    # This is almost certainly invalid JvYAML. but MRI handles it...
    val = JvYAML.load(<<YAML)
---
default: –
- a
YAML
    assert_equal({"default" => ['a']}, val)
  end

  def test_JRUBY_1978
    # JRUBY-1978, scalars can start with , if it's not ambigous
    assert_equal(",a", JvYAML.load("--- \n,a"))
  end

  # Make sure that overriding to_jvyaml always throws an exception unless it returns the correct thing

  class TestYamlFoo
    def to_jvyaml(*args)
      "foo"
    end
  end

  def test_returning_type_of_to_jvyaml
    test_exception(TypeError) do
      { :foo => TestYamlFoo.new }.to_jvyaml
    end
  end

  def test_JRUBY_2019
    assert_equal({
                   "tag:yaml.org,2002:omap"=>JvYAML::Omap,
                   "tag:yaml.org,2002:pairs"=>JvYAML::Pairs,
                   "tag:yaml.org,2002:set"=>JvYAML::Set,
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
                 JvYAML::tagged_classes)
  end

  def test_JRUBY_2083
    assert_equal({'foobar' => '>= 123'}, JvYAML.load("foobar: >= 123"))
  end

  def test_JRUBY_2135
    assert_equal({'foo' => 'bar'}, JvYAML.load("---\nfoo: \tbar"))
  end

  def test_JRUBY_1911
    assert_equal({'foo' => {'bar' => nil, 'qux' => nil}}, JvYAML.load("---\nfoo: {bar, qux}"))
  end

  class YAMLTestException < Exception;end
  class YAMLTestString < String; end

  def test_JRUBY_2323
    assert_equal('--- !str:YAMLTestString', YAMLTestString.new.to_jvyaml.strip)
    assert_equal(YAMLTestString.new, JvYAML::load('--- !str:YAMLTestString'))
    assert_equal(<<EXCEPTION_OUT, YAMLTestException.new.to_jvyaml)
--- !ruby/exception:YAMLTestException
message: YAMLTestException
EXCEPTION_OUT

    assert_equal(YAMLTestException.new.inspect, JvYAML::load(YAMLTestException.new.to_jvyaml).inspect)
  end

  def test_JRUBY_2409
    assert_equal("*.rb", JvYAML::load("---\n*.rb"))
    assert_equal("&.rb", JvYAML::load("---\n&.rb"))
  end

  def test_JRUBY_2443
    a_str = "foo"
    a_str.instance_variable_set :@bar, "baz"

    assert(["--- !str \nstr: foo\n\"@bar\": baz\n", "--- !str \n\"@bar\": baz\nstr: foo\n"].include?(a_str.to_jvyaml))
    assert_equal "baz", JvYAML.load(a_str.to_jvyaml).instance_variable_get(:@bar)

    assert_equal :"abc\"flo", JvYAML.load("---\n:\"abc\\\"flo\"")
  end

  def test_JRUBY_2579
    assert_equal [:year], JvYAML.load("---\n[:year]")

    assert_equal({
                   'date_select' => { 'order' => [:year, :month, :day] },
                   'some' => {
                     'id' => 1,
                     'name' => 'some',
                     'age' => 16}}, JvYAML.load(<<YAML))
date_select:
  order: [:year, :month, :day]
some:
    id: 1
    name: some
    age: 16
YAML
  end

  def test_JRUBY_2754
    obj = Object.new
    objects1 = [obj, obj]
    assert objects1[0].object_id == objects1[1].object_id

    objects2 = JvYAML::load objects1.to_jvyaml
    assert objects2[0].object_id == objects2[1].object_id
  end

  class FooYSmith < Array; end
  class FooXSmith < Hash; end

  def test_JRUBY_2192
    obj = JvYAML.load(<<YAMLSTR)
--- !ruby/array:FooYSmith
- val
- val2
YAMLSTR

    assert_equal FooYSmith, obj.class

    obj = JvYAML.load(<<YAMLSTR)
--- !ruby/hash:FooXSmith
key: value
otherkey: othervalue
YAMLSTR

    assert_equal FooXSmith, obj.class
  end

  class PersonTestOne
    jvyaml_as 'tag:data.allman.ms,2008:Person'
  end

  def test_JRUBY_2976
    assert_equal "--- !data.allman.ms,2008/Person {}\n\n", PersonTestOne.new.to_jvyaml
    assert_equal PersonTestOne, JvYAML.load(PersonTestOne.new.to_jvyaml).class

    Hash.class_eval do
      def to_jvyaml( opts = {} )
        YAML::quick_emit( self, opts ) do |out|
          out.map( jv_taguri, to_jvyaml_style ) do |map|
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

    assert_nothing_raised { JvYAML.load(jruby3639) }
  end


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
  jvyaml_as "tag:ruby.yaml.org,2002:#{self}"

    def to_jvyaml (opts={})
      YAML::quick_emit(self.object_id, opts) do |out|
        out.map(jv_taguri) do |map|
          map.add("s", to_s)
        end
      end
    end

    def Badger.jvyaml_new (klass, tag, val)
      s = val["s"]
      begin
        Badger.from_s s
      rescue => e
        raise "failed to decode Badger from '#{s}'"
      end
    end
  end

  def test_JRUBY_3773
    b = Badger.new("Axel", 35)

    assert_equal JvYAML::dump(b), <<OUT
--- !ruby/Badger
s: Axel:35
OUT
  end

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

  def test_JRUBY_3751
    class_obj1  = ControlObject.new('class_value')
    struct_obj1 = ControlStruct.new
    struct_obj1.arg1 = 'control_value'
    struct_obj2 = BadStruct.new('struct_value')

    assert_equal JvYAML.load(class_obj1.to_jvyaml), class_obj1
    assert_equal JvYAML.load(struct_obj1.to_jvyaml), struct_obj1
    assert_equal JvYAML.load(struct_obj2.to_jvyaml), struct_obj2
  end

  class Sample
    attr_reader :key
    def jvyaml_initialize( tag, val )
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
    def jvyaml_initialize( tag, val )
      @key = 'yaml initialize'
    end
  end

  def test_JRUBY_3518
    s = JvYAML.load(JvYAML.dump(Sample.new))
    assert_equal 'yaml initialize', s.key

    s = JvYAML.load(JvYAML.dump(SampleHash.new))
    assert_equal 'yaml initialize', s.key

    s = JvYAML.load(JvYAML.dump(SampleArray.new))
    assert_equal 'yaml initialize', s.key
  end

  def test_JRUBY_3327
    assert_equal JvYAML.load("- foo\n  bar: bazz"), [{"foo bar" => "bazz"}]
  end

  def test_JRUBY_3263
    y = <<YAML
production:
 ABQIAAAAinq15RDnRyoOaQwM_PoC4RTJQa0g3IQ9GZqIMmInSLzwtGDKaBTPoBdSu0WQaPTIv1sXhVRK0Kolfg
 example.com: ABQIAAAAzMUFFnT9uH0Sfg98Y4kbhGFJQa0g3IQ9GZqIMmInSLrthJKGDmlRT98f4j135zat56yjRKQlWnkmod3TB
YAML

    assert_equal JvYAML.load(y)['production'], {"ABQIAAAAinq15RDnRyoOaQwM_PoC4RTJQa0g3IQ9GZqIMmInSLzwtGDKaBTPoBdSu0WQaPTIv1sXhVRK0Kolfg example.com" => "ABQIAAAAzMUFFnT9uH0Sfg98Y4kbhGFJQa0g3IQ9GZqIMmInSLrthJKGDmlRT98f4j135zat56yjRKQlWnkmod3TB"}
  end

  def test_JRUBY_3412
    y = "--- 2009-02-16 22::40:26.574754 -05:00\n"
    assert_equal JvYAML.load(y).to_jvyaml, y
  end
end
