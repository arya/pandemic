# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{pandemic}
  s.version = "0.2"

  s.required_rubygems_version = Gem::Requirement.new(">= 1.2") if s.respond_to? :required_rubygems_version=
  s.authors = ["Arya Asemanfar"]
  s.date = %q{2009-03-10}
  s.description = %q{Distribute MapReduce to any of the workers and it will spread, like a pandemic.}
  s.email = %q{aryaasemanfar@gmail.com}
  s.extra_rdoc_files = ["lib/pandemic/client_side/cluster_connection.rb", "lib/pandemic/client_side/config.rb", "lib/pandemic/client_side/connection.rb", "lib/pandemic/client_side/connection_proxy.rb", "lib/pandemic/client_side/pandemize.rb", "lib/pandemic/connection_pool.rb", "lib/pandemic/mutex_counter.rb", "lib/pandemic/server_side/client.rb", "lib/pandemic/server_side/config.rb", "lib/pandemic/server_side/handler.rb", "lib/pandemic/server_side/peer.rb", "lib/pandemic/server_side/request.rb", "lib/pandemic/server_side/server.rb", "lib/pandemic/util.rb", "lib/pandemic.rb", "README.markdown"]
  s.files = ["lib/pandemic/client_side/cluster_connection.rb", "lib/pandemic/client_side/config.rb", "lib/pandemic/client_side/connection.rb", "lib/pandemic/client_side/connection_proxy.rb", "lib/pandemic/client_side/pandemize.rb", "lib/pandemic/connection_pool.rb", "lib/pandemic/mutex_counter.rb", "lib/pandemic/server_side/client.rb", "lib/pandemic/server_side/config.rb", "lib/pandemic/server_side/handler.rb", "lib/pandemic/server_side/peer.rb", "lib/pandemic/server_side/request.rb", "lib/pandemic/server_side/server.rb", "lib/pandemic/util.rb", "lib/pandemic.rb", "Rakefile", "README.markdown", "Manifest", "pandemic.gemspec"]
  s.has_rdoc = true
  s.homepage = %q{}
  s.rdoc_options = ["--line-numbers", "--inline-source", "--title", "Pandemic", "--main", "README.markdown"]
  s.require_paths = ["lib"]
  s.rubyforge_project = %q{pandemic}
  s.rubygems_version = %q{1.3.1}
  s.summary = %q{Distribute MapReduce to any of the workers and it will spread, like a pandemic.}

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 2

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
    else
    end
  else
  end
end
