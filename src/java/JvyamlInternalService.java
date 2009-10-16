/*
 * See LICENSE file in distribution for copyright and licensing information.
 */
import java.io.IOException;

import org.jruby.Ruby;
import org.jruby.runtime.load.BasicLibraryService;

public class JvyamlInternalService implements BasicLibraryService {
    public boolean basicLoad(final Ruby runtime) throws IOException {
        org.jruby.ext.jvyaml.RubyYAML.createYAMLModule(runtime);
        return true;
    }
}
