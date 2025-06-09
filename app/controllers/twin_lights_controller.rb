class TwinLightsController < ApplicationController
  before_action :set_twin_light, only: [:show, :update]

  # GET /twin_lights/:uuid
  def show
    render json: {
      uuid: @twin_light.twins_uuid,
      castor_on: @twin_light.led_castor_on,
      pollux_on: @twin_light.led_pollux_on
    }
  end

  # PATCH /twin_lights/:uuid
  def update
    if @twin_light.update(twin_light_params)
      render json: {
        message: "LED states updated",
        castor_on: @twin_light.led_castor_on,
        pollux_on: @twin_light.led_pollux_on
      }
    else
      render json: { error: @twin_light.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

  def set_twin_light
    @twin_light = TwinLight.find_by!(twins_uuid: params[:uuid])
  end

  def twin_light_params
    params.require(:twin_light).permit(:led_castor_on, :led_pollux_on)
  end
end
