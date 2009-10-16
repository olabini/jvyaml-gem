(load (expand-file-name "../prj-ant" (file-name-directory (car current-load-list))))
(let* ((project-base "/Users/olabini/workspace/jvyaml-gem")
       (project-src (with-project-base "src/java"))
       (project-jars (with-project-base (directory-files (with-project-base "lib") t "\\.jar$" t)))
       (project-build-dirs (with-project-base '("pkg/classes"))))
  (jde-ant-set-variables "jvyaml-gem")
  (jde-set-variables
   '(jde-gen-buffer-boilerplate (quote ("/*"
                                        " * See LICENSE file in distribution for copyright and licensing information."
                                        " */")))))
