require 'spec_helper'

describe 'elasticsearch::role' do
  let(:title) { 'elastic_role' }

  let(:pre_condition) do
    <<-EOS
      class { 'elasticsearch': }
    EOS
  end

  let(:params) do
    {
      :privileges => {
        'cluster' => '*'
      },
      :mappings => [
        'cn=users,dc=example,dc=com',
        'cn=admins,dc=example,dc=com',
        'cn=John Doe,cn=other users,dc=example,dc=com'
      ]
    }
  end

  on_supported_os(
    :hardwaremodels => ['x86_64'],
    :supported_os => [
      {
        'operatingsystem' => 'CentOS',
        'operatingsystemrelease' => ['7']
      }
    ]
  ).each do |os, facts|
    context "on #{os}" do
      let(:facts) { facts.merge(
        :scenario => '',
        :common => ''
      ) }

      context 'with an invalid role name' do
        context 'too long' do
          let(:title) { 'A' * 41 }
          it { should raise_error(Puppet::Error, /expected length/i) }
        end
      end

      context 'with default parameters' do
        it { should contain_elasticsearch__role('elastic_role') }
        it { should contain_elasticsearch_role('elastic_role') }
        it do
          should contain_elasticsearch_role_mapping('elastic_role').with(
            'ensure' => 'present',
            'mappings' => [
              'cn=users,dc=example,dc=com',
              'cn=admins,dc=example,dc=com',
              'cn=John Doe,cn=other users,dc=example,dc=com'
            ]
          )
        end
      end

      describe 'collector ordering' do
        describe 'when present' do
          let(:pre_condition) do
            <<-EOS
              class { 'elasticsearch': }
              elasticsearch::template { 'foo': content => {"foo" => "bar"} }
              elasticsearch::user { 'elastic':
                password => 'foobar',
                roles => ['elastic_role'],
              }
            EOS
          end

          it { should contain_elasticsearch__role('elastic_role')
            .that_comes_before([
            'Elasticsearch::Template[foo]',
            'Elasticsearch::User[elastic]'
          ])}

          include_examples 'class', :systemd
        end

        describe 'when absent' do
          let(:pre_condition) do
            <<-EOS
              class { 'elasticsearch': }
              elasticsearch::template { 'foo': content => {"foo" => "bar"} }
              elasticsearch::user { 'elastic':
                password => 'foobar',
                roles => ['elastic_role'],
              }
            EOS
          end

          include_examples 'class', :systemd
          # TODO: Uncomment once upstream issue is fixed.
          # https://github.com/rodjek/rspec-puppet/issues/418
          # it { should contain_elasticsearch__shield__role('elastic_role')
          #   .that_comes_before([
          #   'Elasticsearch::Template[foo]',
          #   'Elasticsearch::Plugin[shield]',
          #   'Elasticsearch::Shield::User[elastic]'
          # ])}
        end
      end
    end
  end
end
