(defproject api "0.1.0-SNAPSHOT"
  :description "The API backing habby clients."
  :url "http://example.com/FIXME"
  :license {:name "GPL-3.0"
            :url "http://www.eclipse.org/legal/epl-v10.html"}
  :dependencies [[org.clojure/clojure "1.8.0"]
                 [com.walmartlabs/lacinia "0.21.0"]
                 [com.walmartlabs/lacinia-pedestal "0.5.0-rc-2"]
                 [io.aviso/logging "0.2.0"]
                 [com.novemberain/monger "3.1.0"]
                 [slingshot "0.12.2"]
                 [clj-time "0.14.2"]
                 [org.jasypt/jasypt "1.9.3"]
                 [proto-repl "0.3.1"]
                 [org.clojure/test.check "0.9.0"]]
  :main ^:skip-aot api.core
  :target-path "target/%s"
  :repl-options {;; If nREPL takes too long to load it may timeout,
                 ;; increase this to wait longer before timing out.
                 ;; Defaults to 30000 (30 seconds)
                 :timeout 120000}
  :profiles {:uberjar {:aot :all}})
