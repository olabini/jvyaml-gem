/*
 * See LICENSE file in distribution for copyright and licensing information.
 */
package org.jruby.ext.jvyaml;

import java.io.IOException;

import java.util.Iterator;
import java.util.List;
import java.util.Map;

import java.util.regex.Pattern;


import org.jruby.Ruby;
import org.jruby.RubyArray;
import org.jruby.RubyFixnum;
import org.jruby.RubyHash;
import org.jruby.RubyString;
import org.jruby.RubyClass;
import org.jruby.RubyModule;

import org.jruby.anno.JRubyMethod;
import org.jruby.anno.JRubyClass;
import org.jruby.anno.JRubyModule;

import org.jruby.runtime.Block;
import org.jruby.runtime.ThreadContext;
import org.jruby.runtime.builtin.IRubyObject;

import org.jruby.javasupport.JavaEmbedUtils;

import org.jruby.javasupport.JavaUtil;
import org.jruby.javasupport.util.RuntimeHelpers;
import org.jruby.runtime.Visibility;

import org.jruby.util.IOInputStream;
import org.jruby.util.IOOutputStream;

import org.jvyamlb.Representer;
import org.jvyamlb.Constructor;
import org.jvyamlb.ParserImpl;
import org.jvyamlb.PositioningParserImpl;
import org.jvyamlb.Scanner;
import org.jvyamlb.ScannerImpl;
import org.jvyamlb.Composer;
import org.jvyamlb.ComposerImpl;
import org.jvyamlb.PositioningScannerImpl;
import org.jvyamlb.PositioningComposerImpl;
import org.jvyamlb.Serializer;
import org.jvyamlb.ResolverImpl;
import org.jvyamlb.EmitterImpl;
import org.jvyamlb.exceptions.YAMLException;
import org.jvyamlb.YAMLConfig;
import org.jvyamlb.YAML;
import org.jvyamlb.PositioningScanner;
import org.jvyamlb.Positionable;
import org.jvyamlb.Position;

/**
 * @author <a href="mailto:ola.bini@ki.se">Ola Bini</a>
 */
@JRubyModule(name="YAML")
public class RubyYAML {
    public static RubyModule createYAMLModule(Ruby runtime) {
        RubyModule result = runtime.defineModule("JvYAML");

        runtime.getKernel().callMethod(runtime.getCurrentContext(),"require", runtime.newString("stringio"));

        result.defineAnnotatedMethods(RubyYAML.class);

        RubyClass obj = runtime.getObject();
        RubyClass clazz = runtime.getClassClass();
        RubyClass hash = runtime.getHash();
        RubyClass array = runtime.getArray();
        RubyClass struct = runtime.getStructClass();
        RubyClass exception = runtime.getException();
        RubyClass string = runtime.getString();
        RubyClass symbol = runtime.getSymbol();
        RubyClass range = runtime.getRange();
        RubyClass regexp = runtime.getRegexp();
        RubyClass time = runtime.getTime();
        RubyClass date = runtime.fastGetClass("Date");
        RubyClass fixnum = runtime.getFixnum();
        RubyClass bignum = runtime.getBignum();
        RubyClass flt = runtime.getFloat();
        RubyClass trueClass = runtime.getTrueClass();
        RubyClass falseClass = runtime.getFalseClass();
        RubyClass nilClass = runtime.getNilClass();

        clazz.defineAnnotatedMethods(YAMLClassMethods.class);

        obj.defineAnnotatedMethods(YAMLObjectMethods.class);

        hash.defineAnnotatedMethods(YAMLHashMethods.class);

        array.defineAnnotatedMethods(YAMLArrayMethods.class);

        struct.defineAnnotatedMethods(YAMLStructMethods.class);

        exception.defineAnnotatedMethods(YAMLExceptionMethods.class);

        string.defineAnnotatedMethods(YAMLStringMethods.class);

        symbol.defineAnnotatedMethods(YAMLSymbolMethods.class);

        range.defineAnnotatedMethods(YAMLRangeMethods.class);

        regexp.defineAnnotatedMethods(YAMLRegexpMethods.class);

        time.defineAnnotatedMethods(YAMLTimeMethods.class);

        date.defineAnnotatedMethods(YAMLDateMethods.class);

        bignum.defineAnnotatedMethods(YAMLNumericMethods.class);

        fixnum.defineAnnotatedMethods(YAMLNumericMethods.class);

        flt.defineAnnotatedMethods(YAMLNumericMethods.class);

        trueClass.defineAnnotatedMethods(YAMLTrueMethods.class);

        falseClass.defineAnnotatedMethods(YAMLFalseMethods.class);

        nilClass.defineAnnotatedMethods(YAMLNilMethods.class);

        result.dataWrapStruct(runtime.getObject().searchMethod("to_jvyaml"));

        return result;
    }

    @JRubyMethod(name = "dump", module = true, visibility = Visibility.PRIVATE)
    public static IRubyObject dump(IRubyObject self, IRubyObject arg0) {
        Ruby runtime = self.getRuntime();
        IRubyObject val = runtime.newArray(arg0);
        return self.callMethod(runtime.getCurrentContext(),"dump_all", val);
    }

    @JRubyMethod(name = "dump", module = true, visibility = Visibility.PRIVATE)
    public static IRubyObject dump(IRubyObject self, IRubyObject arg0, IRubyObject arg1) {
        IRubyObject obj = arg0;
        Ruby runtime = self.getRuntime();
        IRubyObject val = runtime.newArray(obj);
        return RuntimeHelpers.invoke(runtime.getCurrentContext(), self,"dump_all", val, arg1);
    }

    @JRubyMethod(name = "dump_all", required = 1, optional = 1, module = true, visibility = Visibility.PRIVATE)
    public static IRubyObject dump_all(IRubyObject self, IRubyObject[] args) {
        ThreadContext context = self.getRuntime().getCurrentContext();
        RubyArray objs = (RubyArray)args[0];
        IRubyObject io = null;
        IRubyObject io2 = null;
        if(args.length == 2 && args[1] != null && !args[1].isNil()) {
            io = args[1];
        }
        YAMLConfig cfg = YAML.config().version("1.0");
        IOOutputStream iox = null;
        if(null == io) {
            io2 = self.getRuntime().fastGetClass("StringIO").callMethod(context, "new");
            iox = new IOOutputStream(io2);
        } else {
            iox = new IOOutputStream(io);
        }
        Serializer ser = new JRubySerializer(new EmitterImpl(iox,cfg),new ResolverImpl(),cfg);
        try {
            ser.open();
            Representer r = new JRubyRepresenter(ser, cfg);
            for(Iterator iter = objs.getList().iterator();iter.hasNext();) {
                r.represent(iter.next());
            }
            ser.close();
        } catch(IOException e) {
            throw self.getRuntime().newIOErrorFromException(e);
        }
        if(null == io) {
            io2.callMethod(context, "rewind");
            return io2.callMethod(context, "read");
        } else {
            return io;
        }
    }

    @JRubyMethod(name = "_parse_internal", required = 1, module = true, visibility = Visibility.PRIVATE)
    public static IRubyObject parse_internal(IRubyObject self, IRubyObject arg) {
        boolean debug = self.getRuntime().getDebug().isTrue();
        IRubyObject io = check_yaml_port(arg);
        Scanner scn = null;
        try {
            if(io instanceof RubyString) {
                scn = debug ? new PositioningScannerImpl(((RubyString)io).getByteList()) : new ScannerImpl(((RubyString)io).getByteList());
            } else {
                scn = debug ? new PositioningScannerImpl(new IOInputStream(io)) : new ScannerImpl(new IOInputStream(io));
            }
            Composer ctor =
                debug ?
                new PositioningComposerImpl(new PositioningParserImpl((PositioningScanner)scn,YAML.config().version("1.0")),new ResolverImpl()) :
                new ComposerImpl(new ParserImpl(scn,YAML.config().version("1.0")),new ResolverImpl())
                ;
            if(ctor.checkNode()) {
                return JavaEmbedUtils.javaToRuby(self.getRuntime(),ctor.getNode());
            }
            return self.getRuntime().getNil();
        } catch(YAMLException e) {
            if(self.getRuntime().getDebug().isTrue()) {
                Position.Range range = ((Positionable)e).getRange();
                throw self.getRuntime().newArgumentError("syntax error on " + range.start + ":" + range.end + ": " + e.getMessage());
            } else {
                throw self.getRuntime().newArgumentError("syntax error:" + e.getMessage());
            }
        }
    }

    @JRubyMethod(name = "load", required = 1, module = true, visibility = Visibility.PRIVATE)
    public static IRubyObject load(IRubyObject self, IRubyObject arg) {
        boolean debug = self.getRuntime().getDebug().isTrue();
        IRubyObject io = check_yaml_port(arg);
        Scanner scn = null;
        try {
            if(io instanceof RubyString) {
                scn = debug ? new PositioningScannerImpl(((RubyString)io).getByteList()) : new ScannerImpl(((RubyString)io).getByteList());
            } else {
                scn = debug ? new PositioningScannerImpl(new IOInputStream(io)) : new ScannerImpl(new IOInputStream(io));
            }
            Constructor ctor =
                debug ?
                new JRubyConstructor(self, new PositioningComposerImpl(new PositioningParserImpl((PositioningScanner)scn,YAML.config().version("1.0")),new ResolverImpl())) :
                new JRubyConstructor(self, new ComposerImpl(new ParserImpl(scn,YAML.config().version("1.0")),new ResolverImpl()))
                ;
            if(ctor.checkData()) {
                return JavaEmbedUtils.javaToRuby(self.getRuntime(),ctor.getData());
            }
            return self.getRuntime().getNil();
        } catch(YAMLException e) {
            if(self.getRuntime().getDebug().isTrue()) {
                Position.Range range = ((Positionable)e).getRange();
                throw self.getRuntime().newArgumentError("syntax error on " + range.start + ":" + range.end + ": " + e.getMessage());
            } else {
                throw self.getRuntime().newArgumentError("syntax error:" + e.getMessage());
            }
        }
    }

    @JRubyMethod(name = "load_file", required = 1, module = true, visibility = Visibility.PRIVATE)
    public static IRubyObject load_file(IRubyObject self, IRubyObject arg) {
        Ruby runtime = self.getRuntime();
        ThreadContext context = runtime.getCurrentContext();
        IRubyObject io = RuntimeHelpers.invoke(context, runtime.getFile(),"open", arg, runtime.newString("r"));
        IRubyObject val = self.callMethod(context,"load", io);
        io.callMethod(context, "close");
        return val;
    }

    @JRubyMethod(name = "each_document", required = 1, frame = true, module = true, visibility = Visibility.PRIVATE)
    public static IRubyObject each_document(IRubyObject self, IRubyObject arg, Block block) {
        boolean debug = self.getRuntime().getDebug().isTrue();
        ThreadContext context = self.getRuntime().getCurrentContext();
        IRubyObject io = arg;
        Scanner scn = null;
        try {
            if(io instanceof RubyString) {
                scn = debug ? new PositioningScannerImpl(((RubyString)io).getByteList()) : new ScannerImpl(((RubyString)io).getByteList());
            } else {
                scn = debug ? new PositioningScannerImpl(new IOInputStream(io)) : new ScannerImpl(new IOInputStream(io));
            }
            Constructor ctor =
                debug ?
                new JRubyConstructor(self, new PositioningComposerImpl(new PositioningParserImpl((PositioningScanner)scn,YAML.config().version("1.0")),new ResolverImpl())) :
                new JRubyConstructor(self, new ComposerImpl(new ParserImpl(scn,YAML.config().version("1.0")),new ResolverImpl()))
                ;
            while(ctor.checkData()) {
                block.yield(context, JavaEmbedUtils.javaToRuby(self.getRuntime(),ctor.getData()));
            }
            return self.getRuntime().getNil();
        } catch(YAMLException e) {
            if(self.getRuntime().getDebug().isTrue()) {
                Position.Range range = ((Positionable)e).getRange();
                throw self.getRuntime().newArgumentError("syntax error on " + range.start + ":" + range.end + ": " + e.getMessage());
            } else {
                throw self.getRuntime().newArgumentError("syntax error:" + e.getMessage());
            }
        }
    }

    @JRubyMethod(name = "load_documents", required = 1, frame = true, module = true, visibility = Visibility.PRIVATE)
    public static IRubyObject load_documents(IRubyObject self, IRubyObject arg, Block block) {
        boolean debug = self.getRuntime().getDebug().isTrue();
        ThreadContext context = self.getRuntime().getCurrentContext();
        IRubyObject io = check_yaml_port(arg);
        Scanner scn = null;
        try {
            if(io instanceof RubyString) {
                scn = debug ? new PositioningScannerImpl(((RubyString)io).getByteList()) : new ScannerImpl(((RubyString)io).getByteList());
            } else {
                scn = debug ? new PositioningScannerImpl(new IOInputStream(io)) : new ScannerImpl(new IOInputStream(io));
            }
            Constructor ctor =
                debug ?
                new JRubyConstructor(self, new PositioningComposerImpl(new PositioningParserImpl((PositioningScanner)scn,YAML.config().version("1.0")),new ResolverImpl())) :
                new JRubyConstructor(self, new ComposerImpl(new ParserImpl(scn,YAML.config().version("1.0")),new ResolverImpl()))
                ;
            while(ctor.checkData()) {
                block.yield(context, JavaEmbedUtils.javaToRuby(self.getRuntime(),ctor.getData()));
            }
            return self.getRuntime().getNil();
        } catch(YAMLException e) {
            if(self.getRuntime().getDebug().isTrue()) {
                Position.Range range = ((Positionable)e).getRange();
                throw self.getRuntime().newArgumentError("syntax error on " + range.start + ":" + range.end + ": " + e.getMessage());
            } else {
                throw self.getRuntime().newArgumentError("syntax error:" + e.getMessage());
            }
        }
    }

    @JRubyMethod(name = "load_stream", required = 1, module = true, visibility = Visibility.PRIVATE)
    public static IRubyObject load_stream(IRubyObject self, IRubyObject arg) {
        boolean debug = self.getRuntime().getDebug().isTrue();
        ThreadContext context = self.getRuntime().getCurrentContext();
        IRubyObject d = self.getRuntime().getNil();
        IRubyObject io = arg;
        Scanner scn = null;
        try {
            if(io instanceof RubyString) {
                scn = debug ? new PositioningScannerImpl(((RubyString)io).getByteList()) : new ScannerImpl(((RubyString)io).getByteList());
            } else {
                scn = debug ? new PositioningScannerImpl(new IOInputStream(io)) : new ScannerImpl(new IOInputStream(io));
            }
            Constructor ctor =
                debug ?
                new JRubyConstructor(self, new PositioningComposerImpl(new PositioningParserImpl((PositioningScanner)scn,YAML.config().version("1.0")),new ResolverImpl())) :
                new JRubyConstructor(self, new ComposerImpl(new ParserImpl(scn,YAML.config().version("1.0")),new ResolverImpl()))
                ;
            while(ctor.checkData()) {
                if(d.isNil()) {
                    d = self.getRuntime().fastGetModule("JvYAML").fastGetClass("Stream").callMethod(context,"new", d);
                }
                d.callMethod(context,"add", JavaEmbedUtils.javaToRuby(self.getRuntime(),ctor.getData()));
            }
            return d;
        } catch(YAMLException e) {
            if(self.getRuntime().getDebug().isTrue()) {
                Position.Range range = ((Positionable)e).getRange();
                throw self.getRuntime().newArgumentError("syntax error on " + range.start + ":" + range.end + ": " + e.getMessage());
            } else {
                throw self.getRuntime().newArgumentError("syntax error:" + e.getMessage());
            }
        }
    }

    @JRubyMethod(name = "dump_stream", rest = true, module = true, visibility = Visibility.PRIVATE)
    public static IRubyObject dump_stream(IRubyObject self, IRubyObject[] args) {
        ThreadContext context = self.getRuntime().getCurrentContext();
        IRubyObject stream = self.getRuntime().fastGetModule("JvYAML").fastGetClass("Stream").callMethod(context, "new");
        for(int i=0,j=args.length;i<j;i++) {
            stream.callMethod(context,"add", args[i]);
        }
        return stream.callMethod(context, "emit");
    }

    @JRubyMethod(name = "quick_emit_node", required = 1, rest = true, frame = true, module = true, visibility = Visibility.PRIVATE)
    public static IRubyObject quick_emit_node(IRubyObject self, IRubyObject[] args, Block block) {
        return block.yield(self.getRuntime().getCurrentContext(), args[0]);
    }

//    @JRubyMethod(name = "quick_emit_node", rest = true, module = true, visibility = Visibility.PRIVATE)
    public static IRubyObject quick_emit(IRubyObject self, IRubyObject[] args) {
        return self.getRuntime().getNil();
    }

    // prepares IO port type for load (ported from ext/syck/rubyext.c)
    private static IRubyObject check_yaml_port(IRubyObject port) {
        if (port instanceof RubyString) {
            // OK
        }
        else if (port.respondsTo("read")) {
            if (port.respondsTo("binmode")) {
                ThreadContext context = port.getRuntime().getCurrentContext();
                port.callMethod(context, "binmode");
            }
        }
        else {
            throw port.getRuntime().newTypeError("instance of IO needed");
        }
        return port;
    }

    @JRubyClass(name="Hash")
    public static class YAMLHashMethods {
        @JRubyMethod(name = "to_jvyaml_node", required = 1)
        public static IRubyObject hash_to_yaml_node(IRubyObject self, IRubyObject arg) {
            Ruby runtime = self.getRuntime();
            ThreadContext context = runtime.getCurrentContext();
            return RuntimeHelpers.invoke(context, arg, "map", self.callMethod(context, "jv_taguri"), self, self.callMethod(context, "to_jvyaml_style"));
        }
    }

    @JRubyClass(name="Object")
    public static class YAMLObjectMethods {
        @JRubyMethod(name = "to_jvyaml_properties")
        public static IRubyObject obj_to_yaml_properties(IRubyObject self) {
            ThreadContext context = self.getRuntime().getCurrentContext();
            return self.callMethod(context, "instance_variables").callMethod(context, "sort");
        }
        @JRubyMethod(name = "to_jvyaml_style")
        public static IRubyObject obj_to_yaml_style(IRubyObject self) {
            return self.getRuntime().getNil();
        }
        @JRubyMethod(name = "to_jvyaml_node", required = 1)
        public static IRubyObject obj_to_yaml_node(IRubyObject self, IRubyObject arg) {
            ThreadContext context = self.getRuntime().getCurrentContext();
            Map mep = (Map)(new RubyHash(self.getRuntime()));
            RubyArray props = (RubyArray)self.callMethod(context, "to_jvyaml_properties");
            for(Iterator iter = props.getList().iterator(); iter.hasNext();) {
                String m = iter.next().toString();
                mep.put(self.getRuntime().newString(m.substring(1)), self.callMethod(context,"instance_variable_get", self.getRuntime().newString(m)));
            }
            return RuntimeHelpers.invoke(context, arg, "map", self.callMethod(context, "jv_taguri"), (IRubyObject)mep, self.callMethod(context, "to_jvyaml_style"));
        }
        @JRubyMethod(name = "to_jvyaml")
        public static IRubyObject obj_to_yaml(IRubyObject self) {
            return dump(self.getRuntime().fastGetModule("JvYAML"), self);
        }
        @JRubyMethod(name = "to_jvyaml")
        public static IRubyObject obj_to_yaml(IRubyObject self, IRubyObject opts) {
            return dump(self.getRuntime().fastGetModule("JvYAML"), self);
        }
        @JRubyMethod(name = "jv_taguri")
        public static IRubyObject obj_taguri(IRubyObject self) {
            return self.getRuntime().newString("!ruby/object:" + self.getType().getName());
        }
    }

    @JRubyClass(name="Class")
    public static class YAMLClassMethods {
        @JRubyMethod(name = "to_jvyaml", rest = true)
        public static IRubyObject class_to_yaml(IRubyObject self, IRubyObject[] args) {
            throw self.getRuntime().newTypeError("can't dump anonymous class " + self.getType().getName());
        }
    }

    @JRubyClass(name="Array")
    public static class YAMLArrayMethods {
        @JRubyMethod(name = "to_jvyaml_node", required = 1)
        public static IRubyObject array_to_yaml_node(IRubyObject self, IRubyObject arg) {
            ThreadContext context = self.getRuntime().getCurrentContext();
            return RuntimeHelpers.invoke(context, arg, "seq", self.callMethod(context, "jv_taguri"), self, self.callMethod(context, "to_jvyaml_style"));
        }
    }

    @JRubyClass(name="Struct")
    public static class YAMLStructMethods {
        @JRubyMethod(name = "to_jvyaml_node", required = 1)
        public static IRubyObject struct_to_yaml_node(IRubyObject self, IRubyObject arg) {
            ThreadContext context = self.getRuntime().getCurrentContext();
            Map mep = (Map)(new RubyHash(self.getRuntime()));
            for(Iterator iter = ((RubyArray)self.callMethod(context, "members")).getList().iterator();iter.hasNext();) {
                IRubyObject key = self.getRuntime().newString(iter.next().toString());
                mep.put(key,self.callMethod(context, "[]", key));
            }
            for(Iterator iter = ((RubyArray)self.callMethod(context, "to_jvyaml_properties")).getList().iterator(); iter.hasNext();) {
                String m = iter.next().toString();
                mep.put(self.getRuntime().newString(m.substring(1)), self.callMethod(context,"instance_variable_get", self.getRuntime().newString(m)));
            }
            return RuntimeHelpers.invoke(context, arg, "map", self.callMethod(context, "jv_taguri"), (IRubyObject)mep, self.callMethod(context, "to_jvyaml_style"));
        }
        @JRubyMethod(name = "jv_taguri")
        public static IRubyObject struct_taguri(IRubyObject self) {
            return self.getRuntime().newString("!ruby/struct:" + self.getType().getName());
        }
    }

    @JRubyClass(name="Exception")
    public static class YAMLExceptionMethods {
        @JRubyMethod(name = "to_jvyaml_node", required = 1)
        public static IRubyObject exception_to_yaml_node(IRubyObject self, IRubyObject arg) {
            ThreadContext context = self.getRuntime().getCurrentContext();
            Map mep = (Map)(new RubyHash(self.getRuntime()));
            mep.put(self.getRuntime().newString("message"),self.callMethod(context, "message"));
            for(Iterator iter = ((RubyArray)self.callMethod(context, "to_jvyaml_properties")).getList().iterator(); iter.hasNext();) {
                String m = iter.next().toString();
                mep.put(self.getRuntime().newString(m.substring(1)), self.callMethod(context,"instance_variable_get", self.getRuntime().newString(m)));
            }
            return RuntimeHelpers.invoke(context, arg,"map", self.callMethod(context, "jv_taguri"), (IRubyObject)mep, self.callMethod(context, "to_jvyaml_style"));
        }
        @JRubyMethod(name = "jv_taguri")
        public static IRubyObject exception_taguri(IRubyObject self) {
            return self.getRuntime().newString("!ruby/exception:" + self.getType().getName());
        }
    }

    private static final Pattern AFTER_NEWLINE = Pattern.compile("\n.+", Pattern.DOTALL);
    @JRubyClass(name="String")
    public static class YAMLStringMethods {
        @JRubyMethod(name = "is_complex_jvyaml?")
        public static IRubyObject string_is_complex(IRubyObject self) {
            ThreadContext context = self.getRuntime().getCurrentContext();
            return (self.callMethod(context, "to_jvyaml_style").isTrue() ||
                    ((List)self.callMethod(context, "to_jvyaml_properties")).isEmpty() ||
                    AFTER_NEWLINE.matcher(self.toString()).find()) ? self.getRuntime().getTrue() : self.getRuntime().getFalse();
        }
        @JRubyMethod(name = "is_jv_binary_data?")
        public static IRubyObject string_is_binary(IRubyObject self) {
            ThreadContext context = self.getRuntime().getCurrentContext();
            if(self.callMethod(context, "empty?").isTrue()) {
                return self.getRuntime().getNil();
            }
            return self.toString().indexOf('\0') != -1 ? self.getRuntime().getTrue() : self.getRuntime().getFalse();
        }
        private static JRubyRepresenter into(IRubyObject arg) {
            Object jobj = arg.dataGetStruct();
            if(jobj != null) {
                return (JRubyRepresenter)(((org.jruby.javasupport.JavaObject)jobj).getValue());
            }
            return null;
        }
        @JRubyMethod(name = "to_jvyaml_node", required = 1)
        public static IRubyObject string_to_yaml_node(IRubyObject self, IRubyObject arg) {
            ThreadContext context = self.getRuntime().getCurrentContext();
            Ruby rt = self.getRuntime();
            if(self.callMethod(context, "is_jv_binary_data?").isTrue()) {
                return RuntimeHelpers.invoke(context, arg, "scalar", rt.newString("tag:yaml.org,2002:binary"), rt.newArray(self).callMethod(context, "pack", rt.newString("m")), rt.newString("|"));
            }
            if(((List)self.callMethod(context, "to_jvyaml_properties")).isEmpty()) {
                JRubyRepresenter rep = into(arg);
                if(rep != null) {
                    try {
                        return JavaUtil.convertJavaToRuby(rt,rep.scalar(self.callMethod(context, "jv_taguri").toString(),self.convertToString().getByteList(),self.toString().startsWith(":") ? "\"" : self.callMethod(context, "to_jvyaml_style").toString()));
                    } catch(IOException e) {
                        throw rt.newIOErrorFromException(e);
                    }
                } else {
                    return RuntimeHelpers.invoke(context, arg, "scalar", self.callMethod(context, "jv_taguri"), self, self.toString().startsWith(":") ? rt.newString("\"") : self.callMethod(context, "to_jvyaml_style"));
                }
            }

            Map mep = (Map)(new RubyHash(self.getRuntime()));
            mep.put(self.getRuntime().newString("str"),rt.newString(self.toString()));
            for(Iterator iter = ((RubyArray)self.callMethod(context, "to_jvyaml_properties")).getList().iterator(); iter.hasNext();) {
                String m = iter.next().toString();
                mep.put(self.getRuntime().newString(m), self.callMethod(context,"instance_variable_get", self.getRuntime().newString(m)));
            }
            return RuntimeHelpers.invoke(context, arg, "map", self.callMethod(context, "jv_taguri"), (IRubyObject)mep, self.callMethod(context, "to_jvyaml_style"));
        }
    }

    @JRubyClass(name="Symbol")
    public static class YAMLSymbolMethods {
        @JRubyMethod(name = "to_jvyaml_node", required = 1)
        public static IRubyObject symbol_to_yaml_node(IRubyObject self, IRubyObject arg) {
            ThreadContext context = self.getRuntime().getCurrentContext();
            return RuntimeHelpers.invoke(context, arg, "scalar", self.callMethod(context, "jv_taguri"), self.callMethod(context, "inspect"), self.callMethod(context, "to_jvyaml_style"));
        }
        @JRubyMethod(name = "jv_taguri")
        public static IRubyObject symbol_taguri(IRubyObject self) {
            return self.getRuntime().newString("tag:yaml.org,2002:str");
        }
    }

    @JRubyClass(name="Numeric")
    public static class YAMLNumericMethods {
        @JRubyMethod(name = "to_jvyaml_node", required = 1)
        public static IRubyObject numeric_to_yaml_node(IRubyObject self, IRubyObject arg) {
            ThreadContext context = self.getRuntime().getCurrentContext();
            String val = self.toString();
            if("Infinity".equals(val)) {
                val = ".Inf";
            } else if("-Infinity".equals(val)) {
                val = "-.Inf";
            } else if("NaN".equals(val)) {
                val = ".NaN";
            }
            return RuntimeHelpers.invoke(context, arg,"scalar", self.callMethod(context, "jv_taguri"), self.getRuntime().newString(val), self.callMethod(context, "to_jvyaml_style"));
        }
    }

    @JRubyClass(name="Range")
    public static class YAMLRangeMethods {
        @JRubyMethod(name = "to_jvyaml_node", required = 1)
        public static IRubyObject range_to_yaml_node(IRubyObject self, IRubyObject arg) {
            ThreadContext context = self.getRuntime().getCurrentContext();
            Map mep = (Map)(new RubyHash(self.getRuntime()));
            mep.put(self.getRuntime().newString("begin"),self.callMethod(context, "begin"));
            mep.put(self.getRuntime().newString("end"),self.callMethod(context, "end"));
            mep.put(self.getRuntime().newString("excl"),self.callMethod(context, "exclude_end?"));
            for(Iterator iter = ((RubyArray)self.callMethod(context, "to_jvyaml_properties")).getList().iterator(); iter.hasNext();) {
                String m = iter.next().toString();
                mep.put(self.getRuntime().newString(m.substring(1)), self.callMethod(context,"instance_variable_get", self.getRuntime().newString(m)));
            }
            return RuntimeHelpers.invoke(context, arg, "map", self.callMethod(context, "jv_taguri"), (IRubyObject)mep, self.callMethod(context, "to_jvyaml_style"));
        }
    }

    @JRubyClass(name="Regexp")
    public static class YAMLRegexpMethods {
        @JRubyMethod(name = "to_jvyaml_node", required = 1)
        public static IRubyObject regexp_to_yaml_node(IRubyObject self, IRubyObject arg) {
            ThreadContext context = self.getRuntime().getCurrentContext();
            return RuntimeHelpers.invoke(context, arg, "scalar", self.callMethod(context, "jv_taguri"), self.callMethod(context, "inspect"), self.callMethod(context, "to_jvyaml_style"));
        }
    }

    @JRubyClass(name="Time")
    public static class YAMLTimeMethods {
        @JRubyMethod(name = "to_jvyaml_node", required = 1)
        public static IRubyObject time_to_yaml_node(IRubyObject self, IRubyObject arg) {
            ThreadContext context = self.getRuntime().getCurrentContext();
            IRubyObject tz = self.getRuntime().newString("Z");
            IRubyObject difference_sign = self.getRuntime().newString("-");
            self = self.dup();
            if(!self.callMethod(context, "utc?").isTrue()) {
                IRubyObject utc_same_instant = self.callMethod(context, "utc");
                IRubyObject utc_same_writing = RuntimeHelpers.invoke(context, self.getRuntime().getTime(), "utc", new IRubyObject[]{
                        self.callMethod(context, "year"),self.callMethod(context, "month"),self.callMethod(context, "day"),self.callMethod(context, "hour"),
                        self.callMethod(context, "min"),self.callMethod(context, "sec"),self.callMethod(context, "usec")});
                IRubyObject difference_to_utc = utc_same_writing.callMethod(context, "-", utc_same_instant);
                IRubyObject absolute_difference;
                if(difference_to_utc.callMethod(context, "<", RubyFixnum.zero(self.getRuntime())).isTrue()) {
                    difference_sign = self.getRuntime().newString("-");
                    absolute_difference = RubyFixnum.zero(self.getRuntime()).callMethod(context, "-", difference_to_utc);
                } else {
                    difference_sign = self.getRuntime().newString("+");
                    absolute_difference = difference_to_utc;
                }
                IRubyObject difference_minutes = absolute_difference.callMethod(context,"/", self.getRuntime().newFixnum(60)).callMethod(context, "round");
                tz = self.getRuntime().newString("%s%02d:%02d").callMethod(context,"%", self.getRuntime().newArrayNoCopy(new IRubyObject[]{difference_sign,difference_minutes.callMethod(context,"/", self.getRuntime().newFixnum(60)),difference_minutes.callMethod(context,"%", self.getRuntime().newFixnum(60))}));
            }
            IRubyObject standard = self.callMethod(context,"strftime", self.getRuntime().newString("%Y-%m-%d %H:%M:%S"));
            if(self.callMethod(context, "usec").callMethod(context, "nonzero?").isTrue()) {
                standard = standard.callMethod(context, "+", self.getRuntime().newString(".%06d").callMethod(context,"%", self.getRuntime().newArray(self.callMethod(context, "usec"))));
            }
            standard = standard.callMethod(context, "+", self.getRuntime().newString(" %s").callMethod(context,"%", self.getRuntime().newArray(tz)));
            return RuntimeHelpers.invoke(context, arg, "scalar", self.callMethod(context, "jv_taguri"), standard, self.callMethod(context, "to_jvyaml_style"));
        }
    }

    @JRubyClass(name="Date")
    public static class YAMLDateMethods {
        @JRubyMethod(name = "to_jvyaml_node", required = 1)
        public static IRubyObject date_to_yaml_node(IRubyObject self, IRubyObject arg) {
            ThreadContext context = self.getRuntime().getCurrentContext();
            return RuntimeHelpers.invoke(context, arg, "scalar", self.callMethod(context, "jv_taguri"), self.callMethod(context, "to_s"), self.callMethod(context, "to_jvyaml_style"));
        }
    }

    @JRubyClass(name="TrueClass")
    public static class YAMLTrueMethods {
        @JRubyMethod(name = "to_jvyaml_node", required = 1)
        public static IRubyObject true_to_yaml_node(IRubyObject self, IRubyObject arg) {
            ThreadContext context = self.getRuntime().getCurrentContext();
            return RuntimeHelpers.invoke(context, arg, "scalar", self.callMethod(context, "jv_taguri"), self.callMethod(context, "to_s"), self.callMethod(context, "to_jvyaml_style"));
        }
        @JRubyMethod(name = "jv_taguri")
        public static IRubyObject true_taguri(IRubyObject self) {
            return self.getRuntime().newString("tag:yaml.org,2002:bool");
        }
    }

    @JRubyClass(name="FalseClass")
    public static class YAMLFalseMethods {
        @JRubyMethod(name = "to_jvyaml_node", required = 1)
        public static IRubyObject false_to_yaml_node(IRubyObject self, IRubyObject arg) {
            ThreadContext context = self.getRuntime().getCurrentContext();
            return RuntimeHelpers.invoke(context, arg, "scalar", self.callMethod(context, "jv_taguri"), self.callMethod(context, "to_s"), self.callMethod(context, "to_jvyaml_style"));
        }
        @JRubyMethod(name = "jv_taguri")
        public static IRubyObject false_taguri(IRubyObject self) {
            return self.getRuntime().newString("tag:yaml.org,2002:bool");
        }
    }

    @JRubyClass(name="NilClass")
    public static class YAMLNilMethods {
        @JRubyMethod(name = "to_jvyaml_node", required = 1)
        public static IRubyObject nil_to_yaml_node(IRubyObject self, IRubyObject arg) {
            ThreadContext context = self.getRuntime().getCurrentContext();
            return RuntimeHelpers.invoke(context, arg,"scalar", self.callMethod(context, "jv_taguri"), self.getRuntime().newString(""), self.callMethod(context, "to_jvyaml_style"));
        }
    }
}// RubyYAML
