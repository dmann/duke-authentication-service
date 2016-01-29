shared_context 'authenticate request' do
  let(:authenticate_request) { get authenticate_url, request_params }
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
