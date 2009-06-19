# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{pandemic}
  s.version = "0.3.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 1.2") if s.respond_to? :required_rubygems_version=
  s.authors = ["Arya Asemanfar"]
  s.date = %q{2009-06-18}
  s.description = %q{Distribute MapReduce to any of the workers and it will spread, like a pandemic.}
  s.email = %q{aryaasemanfar@gmail.com}
  s.extra_rdoc_files = ["lib/pandemic/client_side/cluster_connection.rb", "lib/pandemic/client_side/config.rb", "lib/pandemic/client_side/connection.rb", "lib/pandemic/client_side/connection_proxy.rb", "lib/pandemic/client_side/pandemize.rb", "lib/pandemic/connection_pool.rb", "lib/pandemic/mutex_counter.rb", "lib/pandemic/server_side/client.rb", "lib/pandemic/server_side/config.rb", "lib/pandemic/server_side/handler.rb", "lib/pandemic/server_side/peer.rb", "lib/pandemic/server_side/processor.rb", "lib/pandemic/server_side/request.rb", "lib/pandemic/server_side/server.rb", "lib/pandemic/util.rb", "lib/pandemic.rb", "README.markdown"]
  s.files = ["examples/client/client.rb", "examples/client/constitution.txt", "examples/client/pandemic_client.yml", "examples/server/pandemic_server.yml", "examples/server/word_count_server.rb", "lib/pandemic/client_side/cluster_connection.rb", "lib/pandemic/client_side/config.rb", "lib/pandemic/client_side/connection.rb", "lib/pandemic/client_side/connection_proxy.rb", "lib/pandemic/client_side/pandemize.rb", "lib/pandemic/connection_pool.rb", "lib/pandemic/mutex_counter.rb", "lib/pandemic/server_side/client.rb", "lib/pandemic/server_side/config.rb", "lib/pandemic/server_side/handler.rb", "lib/pandemic/server_side/peer.rb", "lib/pandemic/server_side/processor.rb", "lib/pandemic/server_side/request.rb", "lib/pandemic/server_side/server.rb", "lib/pandemic/util.rb", "lib/pandemic.rb", "Manifest", "MIT-LICENSE", "pandemic.gemspec", "Rakefile", "README.markdown", "test/client_test.rb", "test/connection_pool_test.rb", "test/functional_test.rb", "test/handler_test.rb", "test/mutex_counter_test.rb", "test/peer_test.rb", "test/processor_test.rb", "test/server_test.rb", "test/test_helper.rb", "test/util_test.rb"]
  s.homepage = %q{https://github.com/arya/pandemic/}
  s.rdoc_options = ["--line-numbers", "--inline-source", "--title", "Pandemic", "--main", "README.markdown"]
  s.require_paths = ["lib"]
  s.rubyforge_project = %q{pandemic}
  s.rubygems_version = %q{1.3.4}
  s.summary = %q{Distribute MapReduce to any of the workers and it will spread, like a pandemic.}
  s.test_files = ["test/client_test.rb", "test/connection_pool_test.rb", "test/functional_test.rb", "test/handler_test.rb", "test/mutex_counter_test.rb", "test/peer_test.rb", "test/processor_test.rb", "test/server_test.rb", "test/test_helper.rb", "test/util_test.rb"]

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
      s.add_development_dependency(%q<shoulda>, [">= 0"])
      s.add_development_dependency(%q<mocha>, [">= 0"])
    else
      s.add_dependency(%q<shoulda>, [">= 0"])
      s.add_dependency(%q<mocha>, [">= 0"])
    end
  else
    s.add_dependency(%q<shoulda>, [">= 0"])
    s.add_dependency(%q<mocha>, [">= 0"])
  end
end
