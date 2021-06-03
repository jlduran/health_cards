# frozen_string_literal: true

# AuthController exposes authorization endpoints for users to get access tokens
class AuthController < ApplicationController
  skip_before_action :verify_authenticity_token, only: :token

  def authorize
    params = request.params
    if params[:client_id] == Rails.application.config.client_id
      redirect_to "#{params[:redirect_uri]}?code=#{Rails.application.config.auth_code}&state=#{params[:state]}"
    else
      render json: { errors: ['Unauthorized client_id'] }, status: :unauthorized
    end
  end

  def token
    params = request.parameters
    if params[:code] == Rails.application.config.auth_code
      scope = ['launch/patient', 'patient/Immunization.read']
      header = { alg: 'ES256' }
      payload = { exp: Time.now.to_i + 3600, scope: scope }
      jws = HealthCards::JWS.new(header: header, payload: payload.to_json, key: Rails.application.config.hc_key)
      render json: {
        access_token: jws.to_s,
        token_type: 'Bearer',
        expires_in: 3600,
        scope: scope,
        patient: Patient.all.first.id
      }
    else
      render json: { errors: ['Unauthorized code'] }, status: :unauthorized
    end
  end
end