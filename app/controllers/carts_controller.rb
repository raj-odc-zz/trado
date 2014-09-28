class CartsController < ApplicationController

    skip_before_action :authenticate_user!
    before_action :set_cart_details, only: [:checkout, :confirm]

    def mycart
    end

    def checkout
        if current_cart.order.nil?
            @order = Order.new
            @delivery_id = current_cart.estimate_delivery_id
            @delivery_address = @order.build_delivery_address
            @billing_address = @order.build_billing_address
        else
            @order = current_cart.order
            @delivery_id = @order.delivery_id
            @delivery_address = @order.delivery_address
            @billing_address = @order.billing_address
        end
        binding.pry
    end

    def confirm
        @order.attributes = params[:order]
        respond_to do |format|
            if @order.save
                @order.update_column(:cart_id, current_cart.id)
                @order.calculate(current_cart, Store::tax_rate)
                format.html { redirect_to Payatron4000::select_pay_provider(current_cart, @order, request.remote_ip) }
            else
                format.html { render action: 'checkout' }
            end
        end
    end

    def estimate
        respond_to do |format|
          if current_cart.update(params[:cart])
            format.js { render partial: 'carts/delivery_service_prices/estimate/success', format: [:js] }
          else
            format.json { render json: { errors: @order.errors.to_json(root: true) }, status: 422 }
          end
        end
    end

    def purge_estimate
        current_cart.update_attributes(estimate_delivery_id: nil, estimate_country_name: nil)
        render :partial => 'carts/delivery_service_prices/estimate/success', :format => [:js]
    end

    private

    def set_cart_details
        @order = current_cart.order.nil? ? Order.new : current_cart.order
        @cart_total = current_cart.calculate(Store::tax_rate)
        @country = @order.delivery_address.nil? ? current_cart.estimate_country_name : @order.delivery_address.country
        @delivery_service_prices = DeliveryServicePrice.find_collection(current_cart, @country) unless current_cart.estimate_delivery_id.nil? && @order.delivery_address.nil?
    end
end