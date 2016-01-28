shared_examples 'a successful redirect request' do
  before do
    is_expected.to eq 302
  end

  it { expect(response).to redirect_to(expected_redirect_url) }
end
