shared_context 'authenticate request' do
  let(:json_headers) { { 'Accept' => 'application/json', 'Content-Type' => 'application/json'} }
  let(:fragment_access_token) { Hash[URI.decode_www_form(URI(response.location).fragment)]["access_token"] }
  let(:authenticate_request) { get authenticate_url, request_params }
  let(:token_info_request) { get token_info_url, {access_token: fragment_access_token}, json_headers }
  let(:token_info_hash) { JSON.parse(response.body) }
end

shared_examples 'a valid authenticate request' do
  include_context 'with consumer redirect url'
  include_context 'authenticate request'
  before do
    expect(request_params).to have_key :client_id
    expect(request_params).to have_key :response_type
    expect(request_params).to have_key :state
    expect(authenticate_request).to be < 400
  end
  after do
    expect(response).to redirect_to(tokenized_consumer_url)
    expect(response.location).not_to be_nil
    expect(response.location).to be_a String
    expect(URI(response.location).fragment).to eq token_fragment
    expect(Hash[URI.decode_www_form(URI(response.location).fragment)]).to have_key "access_token"
    expect(Hash[URI.decode_www_form(URI(response.location).fragment)]).to have_key "access_token"
    expect(token_info_request).to eq 200
    expect(response.body).not_to be_nil
    expect(token_info_hash).to be_a Hash
    expect(token_info_hash).to have_key 'audience'
    expect(token_info_hash).to have_key 'uid'
    expect(token_info_hash).to have_key 'scope'
    expect(token_info_hash).to have_key 'signed_info'
    expect(token_info_hash).to have_key 'expires_in'
    expect(token_info_hash['audience']).to eq request_params[:client_id]
    expect(token_info_hash['uid']).to eq user.uid
    expect(token_info_hash['scope']).to eq request_params[:scope]
    expect(token_info_hash['signed_info']).to eq signed_info
  end
end

shared_context 'valid authenticate request' do
  include_context 'authenticate request'
  before do
    expect(authenticate_request).to eq 302
    expect(response).to redirect_to(login_url)
    expect(follow_redirect!).to eq 302
  end
end

shared_context 'invalid authenticate request' do
  include_context 'authenticate request'
  let(:request_params) { {} }
  before { expect(authenticate_request).to eq 401 }
end

shared_context 'failed authentication' do
  include_context 'valid authenticate request'
  let(:shib_mock) { OmniAuth.config.mock_auth[:shibboleth] = :invalid }
end

shared_examples 'an invalid request' do
  it { expect(response.status).to eq(401) }
  it { expect(response.body).to eq('invalid_request') }
end
