/*
 * See LICENSE file in distribution for copyright and licensing information.
 */
package org.jruby.ext.jvyaml;

import org.jvyamlb.SerializerImpl;
import org.jvyamlb.Emitter;
import org.jvyamlb.Resolver;
import org.jvyamlb.YAMLConfig;

import org.jvyamlb.nodes.Node;
import org.jvyamlb.nodes.CollectionNode;

/**
 * @author <a href="mailto:ola.bini@ki.se">Ola Bini</a>
 */
public class JRubySerializer extends SerializerImpl {
    public JRubySerializer(Emitter emitter, Resolver resolver, YAMLConfig opts) {
        super(emitter,resolver,opts);
    }

    protected boolean ignoreAnchor(Node node) {
        return !(node instanceof CollectionNode);
    }
}// JRubySerializer
