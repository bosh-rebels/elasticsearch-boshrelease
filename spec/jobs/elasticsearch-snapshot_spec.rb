require 'rspec'
require 'json'
require 'bosh/template/test'

describe 'elasticsearch-snapshot job' do
  let(:release) { Bosh::Template::Test::ReleaseDir.new(File.join(File.dirname(__FILE__), '../..')) }
  let(:job) { release.job('elasticsearch-snapshot') }

  describe 'run' do
    let(:template) { job.template('bin/run') }
    let(:links) { [
        Bosh::Template::Test::Link.new(
          name: 'elasticsearch',
          instances: [Bosh::Template::Test::LinkInstance.new(address: '10.0.8.2')],
          properties: {
            'elasticsearch'=> {
              'client' => {
                'username' => 'test',
                'password' => 'pass',
                'protocol' => 'http',
                'port' => '9201'
              }
            },
          }
        )
      ] }

    it 'type s3 works' do
      run = template.render({'elasticsearch' => {
        'snapshots' => {
          'repository' => 'foo',
          'type' => 's3',
          'settings' => {
            'bucket' => 'my-s3-bucket',
            'endpoint' => 'https://s3-ap-northeast-1.amazonaws.com',
            'access_key' => 'xxxxxxxxxxxxxxxxxxxxxxxxxxxxxx',
            'secret_key' => 'yyyyyyyyyyyyyyyyyyyyyyyyyyyyyy' 
          }
        }
      }}, consumes: links).strip
      expect(run).to include('curl -D /dev/stderr -k -s -X PUT "http://test:pass@10.0.8.2:9201/_snapshot/foo?pretty"')
      expect(run).to include('{"type": "s3", "settings": {"bucket":"my-s3-bucket","endpoint":"https://s3-ap-northeast-1.amazonaws.com","access_key":"xxxxxxxxxxxxxxxxxxxxxxxxxxxxxx","secret_key":"yyyyyyyyyyyyyyyyyyyyyyyyyyyyyy"}}')
    end

    it 'type gcs works' do
      run = template.render({'elasticsearch' => {
        'snapshots' => {
          'repository' => 'foo',
          'type' => 'gcs',
          'settings' => {
            'bucket' => 'my-gcs-bucket',
            'client' => 'foo',
            'base_path' => 'dev'
          }
        }
      }}, consumes: links).strip
      expect(run).to include('curl -D /dev/stderr -k -s -X PUT "http://test:pass@10.0.8.2:9201/_snapshot/foo?pretty"')
      expect(run).to include('{"type": "gcs", "settings": {"bucket":"my-gcs-bucket","client":"foo","base_path":"dev"}}')
    end
  end
end
