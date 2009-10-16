/*
 * See LICENSE file in distribution for copyright and licensing information.
 */
package org.jruby.ext.jvyaml;

import java.io.IOException;
import java.io.ByteArrayInputStream;

import java.util.Iterator;
import java.util.Map;
import java.util.HashMap;

import org.jruby.Ruby;
import org.jruby.RubyClass;
import org.jruby.RubyModule;
import org.jruby.RubyHash;
import org.jruby.RubyArray;
import org.jruby.RubyString;
import org.jruby.runtime.builtin.IRubyObject;

import org.jruby.javasupport.JavaEmbedUtils;

import org.jruby.runtime.ThreadContext;
import org.jvyamlb.SafeRepresenterImpl;
import org.jvyamlb.Serializer;
import org.jvyamlb.Representer;
import org.jvyamlb.YAMLConfig;
import org.jvyamlb.YAMLNodeCreator;
import org.jvyamlb.Representer;
import org.jvyamlb.Constructor;
import org.jvyamlb.ParserImpl;
import org.jvyamlb.Scanner;
import org.jvyamlb.ScannerImpl;
import org.jvyamlb.Composer;
import org.jvyamlb.ComposerImpl;
import org.jvyamlb.PositioningScannerImpl;
import org.jvyamlb.PositioningComposerImpl;
import org.jvyamlb.Serializer;
import org.jvyamlb.Resolver;
import org.jvyamlb.ResolverImpl;
import org.jvyamlb.EmitterImpl;
import org.jvyamlb.exceptions.YAMLException;
import org.jvyamlb.YAMLConfig;
import org.jvyamlb.YAML;
import org.jvyamlb.PositioningScanner;
import org.jvyamlb.Positionable;
import org.jvyamlb.Position;
import org.jvyamlb.nodes.Node;
import org.jvyamlb.nodes.ScalarNode;
import org.jvyamlb.nodes.MappingNode;

import org.jruby.util.ByteList;

/**
 * @author <a href="mailto:ola.bini@ki.se">Ola Bini</a>
 */
public class JRubyRepresenter extends SafeRepresenterImpl {
    public JRubyRepresenter(final Serializer serializer, final YAMLConfig opts) {
        super(serializer,opts);
    }

    @Override
    protected YAMLNodeCreator getNodeCreatorFor(final Object data) {
        if(data instanceof YAMLNodeCreator) {
            return (YAMLNodeCreator)data;
        } else if(data instanceof IRubyObject) {
            return new IRubyObjectYAMLNodeCreator(data);
        } else {
            return super.getNodeCreatorFor(data);
        }
    }

    public Node map(String tag, java.util.Map mapping, Object flowStyle) throws IOException {
        if(null == flowStyle) {
            return map(tag,mapping,false);
        } else {
            return map(tag,mapping,true);
        }
    }
    public Node seq(String tag, java.util.List sequence, Object flowStyle) throws IOException {
        if(sequence instanceof RubyArray) {
            sequence = ((RubyArray)sequence).getList();
        }

        if(null == flowStyle) {
            return seq(tag,sequence,false);
        } else {
            return seq(tag,sequence,true);
        }
    }

    public Node scalar(String tag, String val, String style) throws IOException {
        return scalar(tag, ByteList.create(val), style);
    }

    public Node scalar(String tag, ByteList val, String style) throws IOException {
        if(null == style || style.length() == 0) {
            return scalar(tag,val,(char)0);
        } else {
            return scalar(tag,val,style.charAt(0));
        }
    }

    @Override
    public Node representMapping(final String tag, final Map mapping, final boolean flowStyle) throws IOException {
        Map value = new HashMap();
        final Iterator iter = (mapping instanceof RubyHash) ? ((RubyHash)mapping).directEntrySet().iterator() : mapping.entrySet().iterator();
        while(iter.hasNext()) {
            Map.Entry entry = (Map.Entry)iter.next();
            value.put(representData(entry.getKey()),representData(entry.getValue()));
        }
        return new MappingNode(tag,value,flowStyle);
    }

    @Override
    protected boolean ignoreAliases(final Object data) {
        return (data instanceof IRubyObject && ((IRubyObject)data).isNil()) || super.ignoreAliases(data);
    }

    public static class IRubyObjectYAMLNodeCreator implements YAMLNodeCreator {
        private final IRubyObject data;
        private final RubyClass outClass;
        private final RubyModule YAMLModule;

        public IRubyObjectYAMLNodeCreator(final Object data) {
            this.data = (IRubyObject)data;
            this.YAMLModule = (RubyModule)this.data.getRuntime().getModule("JvYAML");
            this.outClass = ((RubyClass)((RubyModule)(YAMLModule.getConstant("JvYAMLi"))).getConstant("Node"));
        }

        public String taguri() {
            return data.callMethod(data.getRuntime().getCurrentContext(), "taguri").toString();
        }

        public Node toYamlNode(final Representer representer) throws IOException {
            Ruby runtime = data.getRuntime();
            ThreadContext context = runtime.getCurrentContext();

            if(data.getMetaClass().searchMethod("to_jvyaml") == YAMLModule.dataGetStruct() ||
               data.getMetaClass().searchMethod("to_jvyaml").isUndefined() // In this case, hope that it works out correctly when calling to_yaml_node. Rails does this.
               ) {
                // to_yaml have not been overridden
                Object val = data.callMethod(context, "to_jvyaml_node", JavaEmbedUtils.javaToRuby(runtime, representer));
                if(val instanceof Node) {
                    return (Node)val;
                } else if(val instanceof IRubyObject) {
                    return (Node)JavaEmbedUtils.rubyToJava((IRubyObject) val);
                }
            } else {
                IRubyObject val = data.callMethod(context, "to_jvyaml", JavaEmbedUtils.javaToRuby(runtime, representer));

                if(!outClass.isInstance(val)) {
                    if(val instanceof RubyString && ((RubyString)val).getByteList().length() > 4) {
                        IRubyObject newObj = RubyYAML.load(data, val);
                        if(newObj instanceof RubyHash) {
                            return ((JRubyRepresenter)representer).map(YAML.DEFAULT_MAPPING_TAG, (RubyHash)newObj, null);
                        } else if(newObj instanceof RubyArray) {
                            return ((JRubyRepresenter)representer).seq(YAML.DEFAULT_SEQUENCE_TAG, (RubyArray)newObj, null);
                        } else {
                            ByteList bl = ((RubyString)val).getByteList();
                            int subst = 4;
                            if(bl.get(4) == '\n') subst++;
                            int len = (bl.length()-subst)-1;
                            Resolver res = new ResolverImpl();
                            res.descendResolver(null, null);
                            String detectedTag = res.resolve(ScalarNode.class,bl.makeShared(subst, len),new boolean[]{true,false});
                            return ((JRubyRepresenter)representer).scalar(detectedTag, bl.makeShared(subst, len), null);
                        }
                    }

                    throw runtime.newTypeError("wrong argument type " + val.getMetaClass().getRealClass() + " (expected JvYAML::JvYAMLi::Node)");
                } else {
                    IRubyObject value = val.callMethod(context, "value");
                    IRubyObject style = val.callMethod(context, "style");
                    IRubyObject type_id = val.callMethod(context, "type_id");
                    String s = null;
                    if(!style.isNil()) {
                        s = style.toString();
                    }
                    String t = type_id.toString();
                    if(value instanceof RubyHash) {
                        return ((JRubyRepresenter)representer).map(t, (RubyHash)value, s);
                    } else if(value instanceof RubyArray) {
                        return ((JRubyRepresenter)representer).seq(t, (RubyArray)value, s);
                    } else {
                        return ((JRubyRepresenter)representer).scalar(t, ((RubyString)value).getByteList(), s);
                    }
                }
            }

            return null;
        }
    }
}// JRubyRepresenter
