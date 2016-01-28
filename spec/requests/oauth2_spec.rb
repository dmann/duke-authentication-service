require 'rails_helper'

OmniAuth.config.test_mode = true

describe 'Duke OAuth2' do
  let(:user) { FactoryGirl.create(:user) }
  let(:first_name) { Faker::Name.first_name }
  let(:last_name) { Faker::Name.last_name }
  let(:display_name) { Faker::Name.name }
  let(:email) { Faker::Internet.email }
  let(:consumer) { FactoryGirl.create(:consumer) }
  let(:response_type) { 'token' }
  let(:scope) { Rails.application.config.default_scope }
  let(:state) { Faker::Lorem.characters(20) }

  #let(:consumer_redirect_url) { shibboleth_login_url(protocol: 'https://', params: request_params) }
  let(:login_url) { shibboleth_login_url(protocol: 'https://') }
  let(:authorize_url) { '/authorize' }
  let(:auth_failure_url) { '/auth/failure?message=invalid&strategy=shibboleth' }
  let(:process_authorization_url) { '/process_authorization' }
  let(:token_info_url) { '/api/v1/token_info/' }
  let(:shib_mock) { 
    OmniAuth.config.mock_auth[:shibboleth] = OmniAuth::AuthHash.new({
      :provider => 'shibboleth',
      uid: user.uid,
      info: {
        givenname: first_name,
        sn: last_name,
        name: display_name,
        mail: email
      }
    })
  }
  
  let(:request_params) { {
      client_id: consumer.uuid,
      response_type: response_type,
      scope: scope,
      state: state
  } }

  describe '#authenticate' do
    subject { get url, request_params }
    let(:url) { authenticate_url }

    before do
      Rails.application.env_config["omniauth.auth"] = shib_mock
    end

    context 'without parameters' do
      let(:request_params) { {} }
      before { is_expected.to eq 401 }

      it { expect(response.body).to eq('invalid_request') }
    end

    context 'with invalid authentication' do
      let(:shib_mock) { OmniAuth.config.mock_auth[:shibboleth] = :invalid }

      it 'redirects to auth failure url' do
        is_expected.to eq 302
        expect(response).to redirect_to(login_url)
        expect(follow_redirect!).to eq 302
        expect(response).to redirect_to(auth_failure_url)
      end
    end

    context 'when authenticated' do
      context 'with existing user' do
        include_context 'with consumer redirect url'

        it 'redirects to consumer url' do
          expect(user).to be_persisted
          is_expected.to eq 302
          expect(response).to redirect_to(login_url)
          expect(follow_redirect!).to eq 302
          expect(response).to redirect_to(tokenized_consumer_url)
        end
      end

      context 'with new user' do
        let(:user) { FactoryGirl.build(:user) }

        it 'redirects to consumer url' do
          expect(user).not_to be_persisted
          is_expected.to eq 302
          expect(response).to redirect_to(login_url)
          expect(follow_redirect!).to eq 302
          expect(response).to redirect_to(authorize_url)
          expect(follow_redirect!).to eq 200
        end
      end
    end
  end
  
  describe '#authorize' do
    subject { get url }
    let(:url) { authorize_url }

    it { is_expected.to eq 200 }
  end

  describe '#process_authorization' do
    subject { post url, request_params }
    let(:url) { process_authorization_url }
    let(:request_params) { {commit: 'allow'} }
    let(:consumer) { FactoryGirl.create(:consumer) }
    let(:user) { first_time_user }

    #it { is_expected.to eq 302 }
  end

  describe '#token_info' do
    let(:json_headers) { { 'Accept' => 'application/json', 'Content-Type' => 'application/json'} }
    let(:consumer) {FactoryGirl.create(:consumer)}
    let(:user) { FactoryGirl.create(:user) }
    let(:first_name) { Faker::Name.first_name }
    let(:last_name) { Faker::Name.last_name }
    let(:display_name) { Faker::Name.name }
    let(:email) { Faker::Internet.email }
    let(:scope) { 'display_name first_name last_name email uid' }
    let(:signed_info) {
      consumer.signed_token({
        uid: user.uid,
        first_name: first_name,
        last_name: last_name,
        display_name: display_name,
        email: email,
        service_id: Rails.application.secrets.service_id
      })
    }
    let (:token) {
      user.token(
        client_id: consumer.uuid,
        first_name: first_name,
        last_name: last_name,
        display_name: display_name,
        email: email,
        scope: scope
      )
    }
    subject { get url, {access_token: token}, json_headers }
    let(:url) { token_info_url }

    it { is_expected.to eq 200 }
  end
end
