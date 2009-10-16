require 'test/unit'
require 'jvyaml'

class JvYAMLMoreUnitTests < Test::Unit::TestCase
  def test_one
    bad_text = %{
 A
R}
    dump = ::JvYAML.dump({'text' => bad_text})
    loaded = ::JvYAML.load(dump)
    assert_equal bad_text, loaded['text']
  end

  def test_two
    # JRUBY-1903
    assert_equal(<<YAML_OUT, ::JvYAML::JvYAMLi::Scalar.new("tag:yaml.org,2002:str","foobar",'').to_str)
--- foobar
YAML_OUT

    assert_equal(<<YAML_OUT, ::JvYAML::JvYAMLi::Scalar.new("tag:yaml.org,2002:str","foobar",'').to_s)
--- foobar
YAML_OUT

    assert_equal(<<YAML_OUT, ::JvYAML::JvYAMLi::Seq.new("tag:yaml.org,2002:seq",[::JvYAML::JvYAMLi::Scalar.new("tag:yaml.org,2002:str","foobar",'')],'').to_str)
--- [foobar]

YAML_OUT

    assert_equal(<<YAML_OUT, ::JvYAML::JvYAMLi::Seq.new("tag:yaml.org,2002:seq",[::JvYAML::JvYAMLi::Scalar.new("tag:yaml.org,2002:str","foobar",'')],'').to_s)
--- [foobar]

YAML_OUT

    assert_equal(<<YAML_OUT, ::JvYAML::JvYAMLi::Map.new("tag:yaml.org,2002:map",{::JvYAML::JvYAMLi::Scalar.new("tag:yaml.org,2002:str","a",'') => ::JvYAML::JvYAMLi::Scalar.new("tag:yaml.org,2002:str","b",'')},'').to_str)
--- {a: b}

YAML_OUT

    assert_equal(<<YAML_OUT, ::JvYAML::JvYAMLi::Map.new("tag:yaml.org,2002:map",{::JvYAML::JvYAMLi::Scalar.new("tag:yaml.org,2002:str","a",'') => ::JvYAML::JvYAMLi::Scalar.new("tag:yaml.org,2002:str","b",'')},'').to_s)
--- {a: b}

YAML_OUT
  end

  def test_four
    # Test Scanner exception
    old_debug, $DEBUG = $DEBUG, true
    begin
      JvYAML.load("!<abc")
      assert false
    rescue Exception => e
      assert e.to_s =~ /0:5\(5\)/
    ensure
      $DEBUG = old_debug
    end

    # Test Parser exception
    old_debug, $DEBUG = $DEBUG, true
    begin
      JvYAML.load("%YAML 2.0")
      assert false
    rescue Exception => e
      assert e.to_s =~ /0:0\(0\)/ && e.to_s =~ /0:9\(9\)/
    ensure
      $DEBUG = old_debug
    end

    # Test Composer exception
    old_debug, $DEBUG = $DEBUG, true
    begin
      JvYAML.load("*foobar")
      assert false
    rescue Exception => e
      assert e.to_s =~ /0:0\(0\)/ && e.to_s =~ /0:7\(7\)/
    ensure
      $DEBUG = old_debug
    end
  end

  def test_five
    hash = { "element" => "value", "array" => [ { "nested_element" => "nested_value" } ] }
    ex1 = <<EXPECTED
--- 
array: 
- nested_element: nested_value
element: value
EXPECTED

    ex2 = <<EXPECTED
--- 
element: value
array: 
- nested_element: nested_value
EXPECTED

    assert [ex1, ex2].include?(hash.to_jvyaml), "was: #{hash.to_jvyaml.inspect}"
  end
end
